import Foundation
import Testing

@testable import MyNextMovie

private let testAPIKey = "test-key"

private let popularMoviesJSON = """
    {
      "page": 1,
      "results": [
        {
          "id": 603,
          "title": "The Matrix",
          "overview": "A hacker learns that the world is a simulation.",
          "release_date": "1999-03-31",
          "poster_path": "/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg",
          "vote_average": 8.2,
          "genre_ids": [28, 878]
        },
        {
          "id": 1,
          "title": "No Poster",
          "overview": "",
          "release_date": "",
          "poster_path": null,
          "vote_average": 0,
          "genre_ids": []
        }
      ]
    }
    """

private let errorJSON = """
    {"status_code": 7, "status_message": "Invalid API key."}
    """

@MainActor
struct TMDBTests {
    @Test func decodesSnakeCaseKeys() throws {
        let movies = try decodeTMDBMovies(Data(popularMoviesJSON.utf8))

        #expect(movies.count == 2)
        #expect(movies[0].releaseDate == "1999-03-31")
        #expect(movies[0].posterPath == "/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg")
        #expect(movies[0].voteAverage == 8.2)
        #expect(movies[0].genreIds == [genreIdAction, genreIdScienceFiction])
    }

    @Test func decodesMissingPosterAsNil() throws {
        let movies = try decodeTMDBMovies(Data(popularMoviesJSON.utf8))

        #expect(movies[1].posterPath == nil)
    }

    @Test func decodingFailsForOtherJSON() {
        #expect(throws: DecodingError.self) {
            try decodeTMDBMovies(Data(errorJSON.utf8))
        }
    }

    @Test func popularURLHasAPIKey() throws {
        let popularURL = try #require(tmdbPopularURL(apiKey: testAPIKey))

        #expect(
            popularURL.absoluteString
                == "https://api.themoviedb.org/3/movie/popular?api_key=test-key"
        )
    }

    @Test func searchWithTextUsesSearchEndpoint() throws {
        let searchURL = try #require(
            tmdbSearchURL(query: "matrix", genreId: noGenreId, apiKey: testAPIKey)
        )

        #expect(searchURL.path() == "/3/search/movie")
        #expect(queryValue(searchURL, name: "query") == "matrix")
        #expect(queryValue(searchURL, name: "api_key") == testAPIKey)
    }

    @Test func searchWithGenreOnlyUsesDiscoverEndpoint() throws {
        let searchURL = try #require(
            tmdbSearchURL(query: "", genreId: genreIdAnimation, apiKey: testAPIKey)
        )

        #expect(searchURL.path() == "/3/discover/movie")
        #expect(queryValue(searchURL, name: "with_genres") == String(genreIdAnimation))
        #expect(queryValue(searchURL, name: "query") == nil)
    }

    @Test func searchTextIsPercentEncoded() throws {
        let searchURL = try #require(
            tmdbSearchURL(query: "pan tadeusz", genreId: noGenreId, apiKey: testAPIKey)
        )

        #expect(searchURL.absoluteString.contains("query=pan%20tadeusz"))
    }

    @Test func detailsURLAppendsEveryPart() throws {
        let detailsURL = try #require(tmdbMovieDetailsURL(movieId: 603, apiKey: testAPIKey))
        let appendedParts = queryValue(detailsURL, name: "append_to_response") ?? ""

        #expect(detailsURL.path() == "/3/movie/603")
        for part in ["credits", "videos", "release_dates", "watch/providers", "recommendations"] {
            #expect(appendedParts.split(separator: ",").contains(Substring(part)))
        }
    }

    @Test func okResponsePasses() throws {
        try checkTMDBResponse(try makeResponse(statusCode: 200))
    }

    @Test func unauthorizedResponseMentionsAPIKey() throws {
        let response = try makeResponse(statusCode: 401)

        let thrownError = #expect(throws: TMDBError.self) {
            try checkTMDBResponse(response)
        }

        #expect(thrownError?.message.contains("API key") == true)
    }

    @Test func otherErrorResponseShowsStatus() throws {
        let response = try makeResponse(statusCode: 404)

        let thrownError = #expect(throws: TMDBError.self) {
            try checkTMDBResponse(response)
        }

        #expect(thrownError?.message.contains("404") == true)
    }
}

@MainActor
private func queryValue(_ address: URL, name: String) -> String? {
    let components = URLComponents(url: address, resolvingAgainstBaseURL: false)
    for queryItem in components?.queryItems ?? [] {
        if queryItem.name == name {
            return queryItem.value
        }
    }
    return nil
}

@MainActor
private func makeResponse(statusCode: Int) throws -> HTTPURLResponse {
    let address = try #require(tmdbPopularURL(apiKey: testAPIKey))
    return try #require(
        HTTPURLResponse(url: address, statusCode: statusCode, httpVersion: nil, headerFields: nil)
    )
}
