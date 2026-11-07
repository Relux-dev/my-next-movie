import Foundation

// TMDB API address parts.
// See https://developer.themoviedb.org/reference/intro/getting-started
let tmdbScheme = "https"
let tmdbHost = "api.themoviedb.org"
let tmdbPopularPath = "/3/movie/popular"
let tmdbSearchPath = "/3/search/movie"
let tmdbDiscoverPath = "/3/discover/movie"
/// Movie id goes after it: "/3/movie/603".
let tmdbMovieDetailsPathPrefix = "/3/movie/"

// Names of the query parameters.
let tmdbParameterAPIKey = "api_key"
let tmdbParameterQuery = "query"
let tmdbParameterWithGenres = "with_genres"
let tmdbParameterAppendToResponse = "append_to_response"

/// Parts that the details request adds to the movie, in one response.
let tmdbDetailsAppendedParts = "credits,videos,release_dates,watch/providers,recommendations"

let httpStatusOK = 200
let httpStatusUnauthorized = 401

let missingAPIKeyMessage = "Missing TMDB API key. Add it to Config/Secrets.xcconfig."
let unauthorizedMessage = "TMDB rejected the API key. Check it in Config/Secrets.xcconfig."
let invalidAddressMessage = "Could not build the TMDB address."
let unexpectedResponseMessage = "TMDB sent an unexpected response."

/// One page of a TMDB movie list.
nonisolated struct TMDBMoviePage: Decodable {
    let results: [Movie]
}

/// A TMDB error with a message for the user.
/// `error.localizedDescription` gives the message, so view models show it as it is.
nonisolated struct TMDBError: LocalizedError {
    let message: String

    var errorDescription: String? {
        return message
    }
}

/// TMDB address with `api_key` as the first parameter, then `parameters`.
func tmdbURL(path: String, parameters: [URLQueryItem], apiKey: String) -> URL? {
    var components = URLComponents()
    components.scheme = tmdbScheme
    components.host = tmdbHost
    components.path = path
    components.queryItems = [URLQueryItem(name: tmdbParameterAPIKey, value: apiKey)] + parameters
    return components.url
}

func tmdbPopularURL(apiKey: String) -> URL? {
    return tmdbURL(path: tmdbPopularPath, parameters: [], apiKey: apiKey)
}

/// With text: `/search/movie` with `query`. Without text: `/discover/movie` with `with_genres`.
/// `/search/movie` cannot filter by genre, so `searchTMDBMovies` filters its results.
func tmdbSearchURL(query: String, genreId: Int, apiKey: String) -> URL? {
    if query.isEmpty {
        let genreParameter = URLQueryItem(name: tmdbParameterWithGenres, value: String(genreId))
        return tmdbURL(path: tmdbDiscoverPath, parameters: [genreParameter], apiKey: apiKey)
    }
    let queryParameter = URLQueryItem(name: tmdbParameterQuery, value: query)
    return tmdbURL(path: tmdbSearchPath, parameters: [queryParameter], apiKey: apiKey)
}

func tmdbMovieDetailsURL(movieId: Int, apiKey: String) -> URL? {
    let appendParameter = URLQueryItem(
        name: tmdbParameterAppendToResponse,
        value: tmdbDetailsAppendedParts
    )
    let path = tmdbMovieDetailsPathPrefix + String(movieId)
    return tmdbURL(path: path, parameters: [appendParameter], apiKey: apiKey)
}

/// TMDB JSON keys are snake_case, Swift properties camelCase.
private func makeTMDBDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}

func decodeTMDBMovies(_ data: Data) throws -> [Movie] {
    let moviePage = try makeTMDBDecoder().decode(TMDBMoviePage.self, from: data)
    return moviePage.results
}

func decodeTMDBMovieDetails(_ data: Data) throws -> MovieDetails {
    return try makeTMDBDecoder().decode(MovieDetails.self, from: data)
}

/// `URLSession` does not throw for error status codes, so this checks them.
func checkTMDBResponse(_ response: URLResponse) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw TMDBError(message: unexpectedResponseMessage)
    }
    if httpResponse.statusCode == httpStatusUnauthorized {
        throw TMDBError(message: unauthorizedMessage)
    }
    if httpResponse.statusCode != httpStatusOK {
        throw TMDBError(message: "TMDB responded with status \(httpResponse.statusCode).")
    }
}

/// Has the type `MovieLoader`.
func fetchPopularMovies() async throws -> [Movie] {
    let apiKey = try requireTMDBAPIKey()
    let data = try await fetchTMDBData(tmdbPopularURL(apiKey: apiKey))
    return try decodeTMDBMovies(data)
}

/// Has the type `MovieSearch`.
func searchTMDBMovies(query: String, genreId: Int) async throws -> [Movie] {
    let apiKey = try requireTMDBAPIKey()
    let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
    let address = tmdbSearchURL(query: trimmedQuery, genreId: genreId, apiKey: apiKey)
    let foundMovies = try decodeTMDBMovies(try await fetchTMDBData(address))
    return filterMovies(foundMovies, query: "", genreId: genreId)
}

/// Has the type `MovieDetailsLoader`.
func fetchMovieDetails(movieId: Int) async throws -> MovieDetails {
    let apiKey = try requireTMDBAPIKey()
    let address = tmdbMovieDetailsURL(movieId: movieId, apiKey: apiKey)
    return try decodeTMDBMovieDetails(try await fetchTMDBData(address))
}

private func requireTMDBAPIKey() throws -> String {
    let apiKey = tmdbAPIKey()
    if apiKey.isEmpty {
        throw TMDBError(message: missingAPIKeyMessage)
    }
    return apiKey
}

/// Sends a GET request, checks the status code and returns the response body.
private func fetchTMDBData(_ address: URL?) async throws -> Data {
    guard let address else {
        throw TMDBError(message: invalidAddressMessage)
    }
    let (data, response) = try await URLSession.shared.data(from: address)
    try checkTMDBResponse(response)
    return data
}
