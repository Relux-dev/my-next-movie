import SwiftUI

private let noPopularMoviesMessage = "TMDB returned no popular movies."

/// For previews that need a movie: loads popular movies from TMDB,
/// then shows `content` with them. Needs the TMDB key in `Config/Secrets.xcconfig`.
struct PopularMoviesPreview<Content: View>: View {
    private let content: ([Movie]) -> Content

    @State private var state = LoadState.idle
    @State private var movies: [Movie] = []
    @State private var errorMessage = ""

    init(@ViewBuilder content: @escaping ([Movie]) -> Content) {
        self.content = content
    }

    var body: some View {
        loadedContent
            .task { await loadMovies() }
    }

    @ViewBuilder
    private var loadedContent: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
        case .loaded:
            content(movies)
        case .failed:
            Text(errorMessage)
        }
    }

    private func loadMovies() async {
        state = .loading
        do {
            movies = try await fetchPopularMovies()
            if movies.isEmpty {
                throw TMDBError(message: noPopularMoviesMessage)
            }
            state = .loaded
        } catch {
            errorMessage = error.localizedDescription
            state = .failed
        }
    }
}
