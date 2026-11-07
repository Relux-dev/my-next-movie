import Foundation
import Observation

/// A class only because SwiftUI's @Observable requires one.
@Observable
final class SearchViewModel {
    var query = ""
    var selectedGenreId = noGenreId
    private(set) var state = LoadState.idle
    private(set) var movies: [Movie] = []
    private(set) var errorMessage = ""

    private let searchMovies: MovieSearch

    init(searchMovies: @escaping MovieSearch) {
        self.searchMovies = searchMovies
    }

    func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        if trimmedQuery.isEmpty && selectedGenreId == noGenreId {
            state = .idle
            return
        }
        state = .loading
        do {
            movies = try await searchMovies(trimmedQuery, selectedGenreId)
            state = .loaded
        } catch {
            errorMessage = error.localizedDescription
            state = .failed
        }
    }

    /// Selects the genre, or clears the selection when the genre is already selected.
    func toggleGenre(_ genreId: Int) {
        if selectedGenreId == genreId {
            selectedGenreId = noGenreId
        } else {
            selectedGenreId = genreId
        }
    }
}
