import SwiftUI

@main
struct MyNextMovieApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

private struct RootView: View {
    var body: some View {
        TabView {
            Tab("Movies", systemImage: symbolNameMovies) {
                movieList
            }
            Tab("Search", systemImage: symbolNameSearch, role: .search) {
                search
            }
        }
    }

    private var movieList: some View {
        MovieListView(
            viewModel: MovieListViewModel(loadMovies: fetchPopularMovies),
            loadDetails: fetchMovieDetails
        )
    }

    private var search: some View {
        SearchView(
            viewModel: SearchViewModel(searchMovies: searchTMDBMovies),
            loadDetails: fetchMovieDetails
        )
    }
}
