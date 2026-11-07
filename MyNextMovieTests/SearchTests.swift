import Testing

@testable import MyNextMovie

@MainActor
struct FilterMoviesTests {
    @Test func emptyQueryAndNoGenreReturnsEveryMovie() {
        #expect(filterMovies(testMovies, query: "", genreId: noGenreId) == testMovies)
    }

    @Test func matchesTitleIgnoringCase() {
        let foundMovies = filterMovies(testMovies, query: "matrix", genreId: noGenreId)
        #expect(titlesOf(foundMovies) == ["The Matrix"])
    }

    @Test func matchesKeywordInOverview() {
        let foundMovies = filterMovies(testMovies, query: "wormhole", genreId: noGenreId)
        #expect(titlesOf(foundMovies) == ["Interstellar"])
    }

    @Test func ignoresDiacritics() {
        let amelie = Movie(
            id: 194,
            title: "Amélie",
            overview: "",
            releaseDate: "",
            posterPath: nil,
            voteAverage: 0,
            genreIds: []
        )
        let foundMovies = filterMovies([amelie], query: "amelie", genreId: noGenreId)
        #expect(titlesOf(foundMovies) == ["Amélie"])
    }

    @Test func filtersByGenre() {
        let foundMovies = filterMovies(testMovies, query: "", genreId: genreIdAnimation)
        #expect(titlesOf(foundMovies) == ["Spirited Away"])
    }

    @Test func combinesQueryAndGenre() {
        let foundMovies = filterMovies(testMovies, query: "matrix", genreId: genreIdAnimation)
        #expect(foundMovies.isEmpty)
    }

    @Test func trimsSpacesAroundQuery() {
        let foundMovies = filterMovies(testMovies, query: "  inception ", genreId: noGenreId)
        #expect(titlesOf(foundMovies) == ["Inception"])
    }
}

@MainActor
struct SearchViewModelTests {
    @Test func staysIdleWithoutQueryOrGenre() async {
        let viewModel = SearchViewModel(searchMovies: { _, _ in testMovies })
        viewModel.query = "   "

        await viewModel.search()

        #expect(viewModel.state == .idle)
    }

    @Test func passesTrimmedQueryAndGenreToSearch() async {
        var receivedQuery = ""
        var receivedGenreId = noGenreId
        let viewModel = SearchViewModel(searchMovies: { query, genreId in
            receivedQuery = query
            receivedGenreId = genreId
            return []
        })
        viewModel.query = " matrix "
        viewModel.selectedGenreId = genreIdAction

        await viewModel.search()

        #expect(receivedQuery == "matrix")
        #expect(receivedGenreId == genreIdAction)
        #expect(viewModel.state == .loaded)
        #expect(viewModel.movies.isEmpty)
    }

    @Test func showsErrorWhenSearchFails() async {
        let viewModel = SearchViewModel(searchMovies: { _, _ in throw NoConnection() })
        viewModel.query = "matrix"

        await viewModel.search()

        #expect(viewModel.state == .failed)
        #expect(viewModel.errorMessage == "No connection")
    }

    @Test func togglingSelectedGenreClearsIt() {
        let viewModel = SearchViewModel(searchMovies: { _, _ in [] })

        viewModel.toggleGenre(genreIdAction)
        #expect(viewModel.selectedGenreId == genreIdAction)

        viewModel.toggleGenre(genreIdAction)
        #expect(viewModel.selectedGenreId == noGenreId)
    }
}

private func titlesOf(_ movies: [Movie]) -> [String] {
    var movieTitles: [String] = []
    for movie in movies {
        movieTitles.append(movie.title)
    }
    return movieTitles
}
