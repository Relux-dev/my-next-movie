import Foundation
import Testing

@testable import MyNextMovie

/// Details of The Matrix, shortened: an actor without a photo, a director listed twice,
/// an unofficial trailer before the official one, an empty Polish certification before "16",
/// and in Poland one streaming service and one to rent.
private let matrixDetailsJSON = """
    {
      "id": 603,
      "tagline": "Believe the unbelievable.",
      "runtime": 136,
      "credits": {
        "cast": [
          {"id": 6384, "name": "Keanu Reeves", "character": "Neo", "profile_path": "/8RZL.jpg"},
          {"id": 2975, "name": "Laurence Fishburne", "character": "Morpheus", "profile_path": null}
        ],
        "crew": [
          {"id": 9340, "name": "Lana Wachowski", "job": "Director"},
          {"id": 9340, "name": "Lana Wachowski", "job": "Writer"},
          {"id": 9339, "name": "Lilly Wachowski", "job": "Director"},
          {"id": 9340, "name": "Lana Wachowski", "job": "Director"}
        ]
      },
      "videos": {
        "results": [
          {"key": "fanMade", "site": "YouTube", "type": "Trailer", "official": false},
          {"key": "vKQi3bBA1y8", "site": "YouTube", "type": "Trailer", "official": true}
        ]
      },
      "release_dates": {
        "results": [
          {"iso_3166_1": "PL", "release_dates": [{"certification": ""}, {"certification": "16"}]},
          {"iso_3166_1": "US", "release_dates": [{"certification": "R"}]}
        ]
      },
      "watch/providers": {
        "results": {
          "PL": {
            "link": "https://www.themoviedb.org/movie/603-the-matrix/watch?locale=PL",
            "flatrate": [
              {"provider_id": 119, "provider_name": "Amazon Prime Video", "logo_path": "/gMZd.png"}
            ],
            "rent": [
              {"provider_id": 2, "provider_name": "Apple TV", "logo_path": "/peURl.png"}
            ]
          }
        }
      },
      "recommendations": {
        "results": [
          {
            "id": 604,
            "title": "The Matrix Reloaded",
            "overview": "Neo and the rebels fight the machines.",
            "release_date": "2003-05-15",
            "poster_path": "/9TGHDvWrqKBzwDxDodHYXEmOE6J.jpg",
            "vote_average": 7.1,
            "genre_ids": [12, 28, 53, 878]
          }
        ]
      }
    }
    """

/// A movie that is only announced: no runtime and empty lists.
private let announcedMovieJSON = """
    {
      "id": 1000,
      "tagline": "",
      "runtime": null,
      "credits": {"cast": [], "crew": []},
      "videos": {"results": []},
      "release_dates": {"results": []},
      "watch/providers": {"results": {}},
      "recommendations": {"results": []}
    }
    """

private let regionCodePoland = "PL"
private let regionCodeUSA = "US"
private let regionCodeWithoutData = "JP"

@MainActor
struct MovieDetailsDecodingTests {
    @Test func decodesTaglineAndRuntime() throws {
        let details = try decodeTMDBMovieDetails(Data(matrixDetailsJSON.utf8))

        #expect(details.id == 603)
        #expect(details.tagline == "Believe the unbelievable.")
        #expect(details.runtime == 136)
    }

    @Test func decodesCastWithAndWithoutPhoto() throws {
        let details = try decodeTMDBMovieDetails(Data(matrixDetailsJSON.utf8))

        #expect(details.credits.cast[0].profilePath == "/8RZL.jpg")
        #expect(details.credits.cast[1].profilePath == nil)
    }

    @Test func decodesWatchProvidersUnderSlashKey() throws {
        let details = try decodeTMDBMovieDetails(Data(matrixDetailsJSON.utf8))
        let polishProviders = watchProviders(details, regionCode: regionCodePoland)

        #expect(polishProviders.flatrate?.first?.providerName == "Amazon Prime Video")
        #expect(polishProviders.rent?.first?.providerName == "Apple TV")
        #expect(polishProviders.buy == nil)
    }

    @Test func decodesCountryCodeOfReleaseDates() throws {
        let details = try decodeTMDBMovieDetails(Data(matrixDetailsJSON.utf8))

        #expect(details.releaseDates.results[0].countryCode == "PL")
    }

    @Test func decodesRecommendationsAsMovies() throws {
        let details = try decodeTMDBMovieDetails(Data(matrixDetailsJSON.utf8))
        let recommendedMovie = try #require(details.recommendations.results.first)

        #expect(recommendedMovie.title == "The Matrix Reloaded")
        #expect(recommendedMovie.releaseDate == "2003-05-15")
    }

    @Test func decodesAnnouncedMovieWithoutRuntime() throws {
        let details = try decodeTMDBMovieDetails(Data(announcedMovieJSON.utf8))
        let polishProviders = watchProviders(details, regionCode: regionCodePoland)

        #expect(details.runtime == nil)
        #expect(formattedRuntime(details) == "")
        #expect(!hasWatchProviders(polishProviders))
    }
}

@MainActor
struct MovieDetailsTests {
    @Test func runtimeInHoursAndMinutes() {
        #expect(formattedRuntime(makeMovieDetails(runtime: 136)) == "2h 16m")
        #expect(formattedRuntime(makeMovieDetails(runtime: 120)) == "2h 0m")
    }

    @Test func runtimeUnderAnHourHasOnlyMinutes() {
        #expect(formattedRuntime(makeMovieDetails(runtime: 45)) == "45m")
    }

    @Test func runtimeIsEmptyWhenUnknown() {
        #expect(formattedRuntime(makeMovieDetails(runtime: nil)) == "")
        #expect(formattedRuntime(makeMovieDetails(runtime: 0)) == "")
    }

    @Test func directorsAreListedOnceEach() throws {
        let details = try decodeTMDBMovieDetails(Data(matrixDetailsJSON.utf8))

        #expect(directorNames(details) == "Lana Wachowski, Lilly Wachowski")
    }

    @Test func directorsAreEmptyWithoutDirector() {
        #expect(directorNames(makeMovieDetails()) == "")
    }

    @Test func certificationSkipsEmptyOnes() throws {
        let details = try decodeTMDBMovieDetails(Data(matrixDetailsJSON.utf8))

        #expect(ageCertification(details, regionCode: regionCodePoland) == "16")
        #expect(ageCertification(details, regionCode: regionCodeUSA) == "R")
    }

    @Test func certificationIsEmptyForOtherCountry() throws {
        let details = try decodeTMDBMovieDetails(Data(matrixDetailsJSON.utf8))

        #expect(ageCertification(details, regionCode: regionCodeWithoutData) == "")
    }

    @Test func officialTrailerWins() throws {
        let details = try decodeTMDBMovieDetails(Data(matrixDetailsJSON.utf8))

        #expect(trailerKey(details) == "vKQi3bBA1y8")
    }

    @Test func unofficialTrailerWhenNoOfficial() {
        let details = makeMovieDetails(videos: [
            Video(key: "teaser", site: "YouTube", type: "Teaser", official: true),
            Video(key: "fanMade", site: "YouTube", type: "Trailer", official: false),
        ])

        #expect(trailerKey(details) == "fanMade")
    }

    @Test func trailerOnOtherSiteIsSkipped() {
        let details = makeMovieDetails(videos: [
            Video(key: "vimeoTrailer", site: "Vimeo", type: "Trailer", official: true)
        ])

        #expect(trailerKey(details) == "")
        #expect(trailerURL(details) == nil)
        #expect(!hasTrailer(details))
    }

    @Test func trailerURLPointsToYouTube() throws {
        let details = try decodeTMDBMovieDetails(Data(matrixDetailsJSON.utf8))

        #expect(trailerURL(details) == URL(string: "https://www.youtube.com/watch?v=vKQi3bBA1y8"))
    }

    @Test func factsLineAddsRuntimeAndCertification() throws {
        let details = try decodeTMDBMovieDetails(Data(matrixDetailsJSON.utf8))
        let matrix = makeMovie(releaseDate: "1999-03-31", voteAverage: 8.2)

        let factsLine = movieFactsLine(matrix, details, regionCode: regionCodePoland)

        #expect(factsLine == "1999 · ★ 8.2 · 2h 16m · 16")
    }

    @Test func factsLineBeforeDetailsLoad() {
        let matrix = makeMovie(releaseDate: "1999-03-31", voteAverage: 8.2)

        let factsLine = movieFactsLine(matrix, emptyMovieDetails, regionCode: regionCodePoland)

        #expect(factsLine == "1999 · ★ 8.2")
    }

    @Test func profileURLIsNilWithoutPhoto() throws {
        let details = try decodeTMDBMovieDetails(Data(matrixDetailsJSON.utf8))

        let photoAddress = URL(string: tmdbProfileBaseURL + "/8RZL.jpg")
        #expect(profileURL(details.credits.cast[0]) == photoAddress)
        #expect(profileURL(details.credits.cast[1]) == nil)
    }
}

/// Short details for testing one function at a time, like `makeMovie`.
@MainActor
private func makeMovieDetails(runtime: Int? = nil, videos: [Video] = []) -> MovieDetails {
    return MovieDetails(
        id: 1,
        tagline: "",
        runtime: runtime,
        credits: Credits(cast: [], crew: []),
        videos: VideoList(results: videos),
        releaseDates: ReleaseDateList(results: []),
        watchProviders: WatchProviderList(results: [:]),
        recommendations: TMDBMoviePage(results: [])
    )
}
