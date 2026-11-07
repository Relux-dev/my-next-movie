import Testing

@testable import MyNextMovie

@MainActor
struct MovieListViewModelTests {
    @Test func startsIdle() {
        let viewModel = MovieListViewModel(loadMovies: { [] })

        #expect(viewModel.state == .idle)
        #expect(viewModel.movies.isEmpty)
    }

    @Test func loadsMovies() async {
        let viewModel = MovieListViewModel(loadMovies: { testMovies })

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.movies == testMovies)
    }

    @Test func showsErrorWhenLoadingFails() async {
        let viewModel = MovieListViewModel(loadMovies: { throw NoConnection() })

        await viewModel.load()

        #expect(viewModel.state == .failed)
        #expect(viewModel.errorMessage == "No connection")
    }

    @Test func loadIfNeededLoadsOnlyOnce() async {
        var loadCount = 0
        let viewModel = MovieListViewModel(loadMovies: {
            loadCount += 1
            return testMovies
        })

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(loadCount == 1)
    }
}
