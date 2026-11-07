import Foundation
import Observation

/// A class only because SwiftUI's @Observable requires one.
@Observable
final class MovieDetailViewModel {
    private(set) var state = LoadState.idle
    private(set) var details = emptyMovieDetails
    private(set) var errorMessage = ""

    private let movieId: Int
    private let loadDetails: MovieDetailsLoader

    init(movieId: Int, loadDetails: @escaping MovieDetailsLoader) {
        self.movieId = movieId
        self.loadDetails = loadDetails
    }

    /// Loads the details the first time the screen appears.
    func loadIfNeeded() async {
        if state == .idle {
            await load()
        }
    }

    func load() async {
        state = .loading
        do {
            details = try await loadDetails(movieId)
            state = .loaded
        } catch {
            errorMessage = error.localizedDescription
            state = .failed
        }
    }
}
