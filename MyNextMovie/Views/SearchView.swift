import SwiftUI

/// How long to wait after the last keystroke before searching.
private let searchDelayAfterTyping = Duration.milliseconds(300)

private let searchResultThumbnailWidth: CGFloat = 56
private let searchResultTitleMaxLines = 2
private let searchInputKeySeparator = "|"

struct SearchView: View {
    @State private var viewModel: SearchViewModel
    private let loadDetails: MovieDetailsLoader

    init(viewModel: SearchViewModel, loadDetails: @escaping MovieDetailsLoader) {
        _viewModel = State(initialValue: viewModel)
        self.loadDetails = loadDetails
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                genreFilter
                content.frame(maxHeight: .infinity)
            }
            .navigationTitle("Search")
            .searchable(text: $viewModel.query, prompt: "Title or keyword")
            .navigationDestination(for: Movie.self, destination: movieDetail)
            .task(id: searchInputKey(viewModel.query, viewModel.selectedGenreId)) {
                await searchAfterPause()
            }
        }
    }

    private func movieDetail(_ movie: Movie) -> some View {
        MovieDetailView(movie: movie, loadDetails: loadDetails)
    }

    private var genreFilter: some View {
        GenreFilter(selectedGenreId: viewModel.selectedGenreId, toggleGenre: viewModel.toggleGenre)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView(
                "Find a movie",
                systemImage: symbolNameSearch,
                description: Text("Search by title or keyword, or pick a genre.")
            )
        case .loading:
            ProgressView()
        case .loaded:
            SearchResults(movies: viewModel.movies, query: viewModel.query)
        case .failed:
            ErrorView(title: "Search failed", message: viewModel.errorMessage) {
                Task { await viewModel.search() }
            }
        }
    }

    /// Waits until the user stops typing. Every keystroke cancels the previous wait.
    private func searchAfterPause() async {
        try? await Task.sleep(for: searchDelayAfterTyping)
        if Task.isCancelled {
            return
        }
        await viewModel.search()
    }
}

/// Changes whenever the search input changes, which restarts the search task.
private func searchInputKey(_ query: String, _ selectedGenreId: Int) -> String {
    return String(selectedGenreId) + searchInputKeySeparator + query
}

/// Every genre from `genreTable` as a chip in one row that scrolls sideways.
/// Tapping a chip selects its genre, tapping it again clears the selection.
private struct GenreFilter: View {
    let selectedGenreId: Int
    let toggleGenre: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            chips
        }
    }

    private var chips: some View {
        HStack(spacing: spacingSmall) {
            ForEach(genreTable) { genre in
                genreFilterChip(genre.id)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, spacingSmall)
    }

    private func genreFilterChip(_ genreId: Int) -> some View {
        Button {
            toggleGenre(genreId)
        } label: {
            GenreChip(genreId: genreId, isSelected: genreId == selectedGenreId)
        }
        .buttonStyle(.plain)
    }
}

/// Found movies as a list, or a "no results" message when nothing matches.
private struct SearchResults: View {
    let movies: [Movie]
    let query: String

    @ViewBuilder
    var body: some View {
        if movies.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            List(movies) { movie in
                SearchResultRow(movie: movie)
            }
            .listStyle(.plain)
        }
    }
}

/// One found movie: a small poster on the left, the title, subtitle and rating on the right.
/// Tapping it opens the movie details.
private struct SearchResultRow: View {
    let movie: Movie

    var body: some View {
        NavigationLink(value: movie) {
            HStack(spacing: spacingMedium) {
                thumbnail
                details
            }
            .padding(.vertical, spacingExtraSmall)
        }
    }

    private var thumbnail: some View {
        PosterView(movie: movie, cornerRadius: thumbnailCornerRadius)
            .frame(width: searchResultThumbnailWidth)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: spacingExtraSmall) {
            Text(movie.title)
                .font(.headline)
                .lineLimit(searchResultTitleMaxLines)
            Text(movieSubtitle(movie))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(ratingWithStar(movie))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SearchView(
        viewModel: SearchViewModel(searchMovies: searchTMDBMovies),
        loadDetails: fetchMovieDetails
    )
}
