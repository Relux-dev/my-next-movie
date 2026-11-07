import SwiftUI

private let gridMinimumColumnWidth: CGFloat = 150

/// Gray cards shown while the real movies load.
private let placeholderMovieCount = 6
/// `.redacted` draws text as a gray bar, so only the length of the title matters.
private let placeholderMovieTitle = "Movie title"

struct MovieListView: View {
    @State private var viewModel: MovieListViewModel
    private let loadDetails: MovieDetailsLoader

    init(viewModel: MovieListViewModel, loadDetails: @escaping MovieDetailsLoader) {
        _viewModel = State(initialValue: viewModel)
        self.loadDetails = loadDetails
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("My Next Movie")
                .navigationDestination(for: Movie.self, destination: movieDetail)
        }
        .task { await viewModel.loadIfNeeded() }
    }

    private func movieDetail(_ movie: Movie) -> some View {
        MovieDetailView(movie: movie, loadDetails: loadDetails)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingGrid
        case .loaded:
            loadedGrid
        case .failed:
            ErrorView(title: "Could not load movies", message: viewModel.errorMessage) {
                Task { await viewModel.load() }
            }
        }
    }

    /// Empty movies drawn as gray shapes while the real ones load.
    private var loadingGrid: some View {
        MovieGrid(title: "Popular", movies: makePlaceholderMovies())
            .redacted(reason: .placeholder)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var loadedGrid: some View {
        if viewModel.movies.isEmpty {
            ContentUnavailableView("No movies", systemImage: symbolNameMovies)
        } else {
            MovieGrid(title: "Popular", movies: viewModel.movies)
        }
    }
}

private struct MovieGrid: View {
    let title: String
    let movies: [Movie]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacingLarge) {
                Text(title).font(.title2.bold())
                grid
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var grid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: gridMinimumColumnWidth), spacing: spacingLarge)],
            spacing: spacingExtraLarge
        ) {
            ForEach(movies) { movie in
                MovieGridItem(movie: movie)
            }
        }
    }
}

/// One cell of the grid. Tapping it opens the movie details.
private struct MovieGridItem: View {
    let movie: Movie

    var body: some View {
        NavigationLink(value: movie) {
            MovieCardView(movie: movie)
        }
        .buttonStyle(.plain)
    }
}

/// Movies with consecutive ids and a title, the rest empty.
private func makePlaceholderMovies() -> [Movie] {
    var placeholderMovies: [Movie] = []
    for movieId in 1...placeholderMovieCount {
        let placeholderMovie = Movie(
            id: movieId,
            title: placeholderMovieTitle,
            overview: "",
            releaseDate: "",
            posterPath: nil,
            voteAverage: 0,
            genreIds: []
        )
        placeholderMovies.append(placeholderMovie)
    }
    return placeholderMovies
}

#Preview {
    MovieListView(
        viewModel: MovieListViewModel(loadMovies: fetchPopularMovies),
        loadDetails: fetchMovieDetails
    )
}
