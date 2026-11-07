import Foundation
import Testing

@testable import MyNextMovie

/// A genre id that TMDB does not use.
let genreIdUnknownToTMDB = 1

@MainActor
struct MovieTests {
    @Test func releaseYearIsFirstFourCharactersOfDate() {
        #expect(releaseYear(makeMovie(releaseDate: "1999-03-31")) == "1999")
    }

    @Test func releaseYearIsEmptyWithoutDate() {
        #expect(releaseYear(makeMovie(releaseDate: "")) == "")
    }

    @Test func releaseYearIsEmptyForTooShortDate() {
        #expect(releaseYear(makeMovie(releaseDate: "199")) == "")
    }

    @Test func ratingHasOneDecimal() {
        #expect(formattedRating(makeMovie(voteAverage: 8.24)) == "8.2")
        #expect(formattedRating(makeMovie(voteAverage: 7)) == "7.0")
    }

    @Test func ratingWithStarStartsWithStar() {
        #expect(ratingWithStar(makeMovie(voteAverage: 8.24)) == "★ 8.2")
    }

    @Test func yearAndRatingLeavesOutUnknownYear() {
        let movieFrom2014 = makeMovie(releaseDate: "2014-11-05", voteAverage: 8.4)
        #expect(yearAndRating(movieFrom2014) == "2014 · ★ 8.4")
        #expect(yearAndRating(makeMovie(releaseDate: "", voteAverage: 8.4)) == "★ 8.4")
    }

    @Test func posterURLUsesTMDBImageHost() {
        let posterAddress = posterURL(makeMovie(posterPath: "/poster.jpg"))
        #expect(posterAddress == URL(string: tmdbPosterBaseURL + "/poster.jpg"))
    }

    @Test func movieWithoutPosterPathHasNoPoster() {
        #expect(posterURL(makeMovie(posterPath: nil)) == nil)
        #expect(!hasPoster(makeMovie(posterPath: nil)))
        #expect(!hasPoster(makeMovie(posterPath: "")))
    }

    @Test func subtitleJoinsYearAndMainGenre() {
        let actionMovieFrom1999 = makeMovie(
            releaseDate: "1999-03-31",
            genreIds: [genreIdAction, genreIdScienceFiction]
        )
        #expect(movieSubtitle(actionMovieFrom1999) == "1999 · Action")
    }

    @Test func subtitleLeavesOutMissingParts() {
        #expect(movieSubtitle(makeMovie(genreIds: [genreIdScienceFiction])) == "Science Fiction")
        #expect(movieSubtitle(makeMovie(releaseDate: "1999-03-31")) == "1999")
        #expect(movieSubtitle(makeMovie()) == "")
    }
}

@MainActor
struct GenreTests {
    @Test func tableHasEveryTMDBGenre() {
        let numberOfTMDBMovieGenres = 19
        #expect(genreTable.count == numberOfTMDBMovieGenres)
    }

    @Test func tableIsSortedByName() {
        for tablePosition in 1..<genreTable.count {
            let previousGenreName = genreTable[tablePosition - 1].name
            #expect(previousGenreName < genreTable[tablePosition].name)
        }
    }

    @Test func nameAndSymbolForKnownGenreId() {
        #expect(genreName(genreIdScienceFiction) == "Science Fiction")
        #expect(genreSymbolName(genreIdScienceFiction) == "atom")
    }

    @Test func fallbacksForUnknownGenreId() {
        #expect(positionInGenreTable(genreIdUnknownToTMDB) == genreNotInTable)
        #expect(genreName(genreIdUnknownToTMDB) == unknownGenreName)
        #expect(genreSymbolName(genreIdUnknownToTMDB) == unknownGenreSymbolName)
    }

    @Test func knownGenreIdsSkipUnknownIds() {
        let movieWithUnknownGenre = makeMovie(
            genreIds: [genreIdAction, genreIdUnknownToTMDB, genreIdScienceFiction]
        )
        #expect(knownGenreIds(movieWithUnknownGenre) == [genreIdAction, genreIdScienceFiction])
    }

    @Test func mainGenreIdIsFirstKnownGenre() {
        let movieWithUnknownFirst = makeMovie(
            genreIds: [genreIdUnknownToTMDB, genreIdScienceFiction, genreIdAction]
        )
        #expect(mainGenreId(movieWithUnknownFirst) == genreIdScienceFiction)
        #expect(mainGenreId(makeMovie(genreIds: [genreIdUnknownToTMDB])) == noGenreId)
    }
}

func makeMovie(
    releaseDate: String = "",
    posterPath: String? = nil,
    voteAverage: Double = 0,
    genreIds: [Int] = []
) -> Movie {
    return Movie(
        id: 1,
        title: "Test",
        overview: "",
        releaseDate: releaseDate,
        posterPath: posterPath,
        voteAverage: voteAverage,
        genreIds: genreIds
    )
}
