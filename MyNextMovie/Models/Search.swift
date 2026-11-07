import Foundation

/// Movies whose title or overview contains the query and which have the genre.
/// Case and diacritics are ignored. An empty query or `noGenreId` matches every movie.
func filterMovies(_ movies: [Movie], query: String, genreId: Int) -> [Movie] {
    let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
    var matchingMovies: [Movie] = []
    for movie in movies {
        if genreId != noGenreId && !movie.genreIds.contains(genreId) {
            continue
        }
        if !trimmedQuery.isEmpty && !movieContainsText(movie, trimmedQuery) {
            continue
        }
        matchingMovies.append(movie)
    }
    return matchingMovies
}

private func movieContainsText(_ movie: Movie, _ searchedText: String) -> Bool {
    return textContains(movie.title, searchedText) || textContains(movie.overview, searchedText)
}

/// Whether `fullText` contains `searchedText`, ignoring case and diacritics.
private func textContains(_ fullText: String, _ searchedText: String) -> Bool {
    let comparisonOptions: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
    return fullText.range(of: searchedText, options: comparisonOptions) != nil
}
