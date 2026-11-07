import Foundation

/// TMDB image server address for actor photos 185 pixels wide.
let tmdbProfileBaseURL = "https://image.tmdb.org/t/p/w185"

/// TMDB image server address for streaming service logos 92 pixels wide.
let tmdbLogoBaseURL = "https://image.tmdb.org/t/p/w92"

let youTubeWatchBaseURL = "https://www.youtube.com/watch?v="
let videoSiteYouTube = "YouTube"
let videoTypeTrailer = "Trailer"
let crewJobDirector = "Director"

/// Separates names in a list: "Lana Wachowski, Lilly Wachowski".
let nameSeparator = ", "

let minutesPerHour = 60

/// Country used for the age certification and the streaming services
/// when the phone settings have no region.
let defaultRegionCode = "PL"

/// Country from the phone settings, e.g. "PL".
let watchRegionCode = Locale.current.region?.identifier ?? defaultRegionCode

/// Movie details from one TMDB request with `append_to_response`.
nonisolated struct MovieDetails: Decodable {
    let id: Int
    let tagline: String
    let runtime: Int?  // nil for announced movies
    let credits: Credits
    let videos: VideoList
    let releaseDates: ReleaseDateList
    let watchProviders: WatchProviderList
    let recommendations: TMDBMoviePage

    /// "watch/providers" has a slash, so it cannot be a Swift property name.
    /// With `CodingKeys` every property has to be listed, also the unchanged ones.
    enum CodingKeys: String, CodingKey {
        case id
        case tagline
        case runtime
        case credits
        case videos
        case releaseDates
        case watchProviders = "watch/providers"
        case recommendations
    }
}

nonisolated struct Credits: Decodable {
    let cast: [CastMember]
    let crew: [CrewMember]
}

nonisolated struct CastMember: Decodable, Identifiable {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?  // nil when TMDB has no photo
}

nonisolated struct CrewMember: Decodable {
    let id: Int
    let name: String
    let job: String
}

nonisolated struct VideoList: Decodable {
    let results: [Video]
}

nonisolated struct Video: Decodable {
    let key: String
    let site: String
    let type: String
    let official: Bool
}

nonisolated struct ReleaseDateList: Decodable {
    let results: [CountryReleaseDates]
}

nonisolated struct CountryReleaseDates: Decodable {
    let countryCode: String
    let releaseDates: [ReleaseDate]

    /// `.convertFromSnakeCase` turns "iso_3166_1" into "iso31661".
    enum CodingKeys: String, CodingKey {
        case countryCode = "iso31661"
        case releaseDates
    }
}

nonisolated struct ReleaseDate: Decodable {
    let certification: String
}

nonisolated struct WatchProviderList: Decodable {
    /// The key is a country code, e.g. "PL".
    let results: [String: CountryWatchProviders]
}

/// TMDB leaves out the lists that the country does not have.
nonisolated struct CountryWatchProviders: Decodable {
    let link: String
    let flatrate: [WatchProvider]?
    let rent: [WatchProvider]?
    let buy: [WatchProvider]?
}

nonisolated struct WatchProvider: Decodable, Identifiable {
    let providerId: Int
    let providerName: String
    let logoPath: String?

    var id: Int {
        return providerId
    }
}

/// Shown until the real details arrive.
let emptyMovieDetails = MovieDetails(
    id: 0,
    tagline: "",
    runtime: nil,
    credits: Credits(cast: [], crew: []),
    videos: VideoList(results: []),
    releaseDates: ReleaseDateList(results: []),
    watchProviders: WatchProviderList(results: [:]),
    recommendations: TMDBMoviePage(results: [])
)

/// Streaming services of a country without data.
let noWatchProviders = CountryWatchProviders(link: "", flatrate: nil, rent: nil, buy: nil)

/// 136 -> "2h 16m", 45 -> "45m", "" when unknown or 0.
func formattedRuntime(_ details: MovieDetails) -> String {
    let runtime = details.runtime ?? 0
    if runtime <= 0 {
        return ""
    }
    let hours = runtime / minutesPerHour
    let minutes = runtime % minutesPerHour
    if hours == 0 {
        return "\(minutes)m"
    }
    return "\(hours)h \(minutes)m"
}

/// Directors joined with ", ". TMDB may list one person more than once, each is named once.
func directorNames(_ details: MovieDetails) -> String {
    var names: [String] = []
    for crewMember in details.credits.crew {
        if crewMember.job != crewJobDirector {
            continue
        }
        if names.contains(crewMember.name) {
            continue
        }
        names.append(crewMember.name)
    }
    return names.joined(separator: nameSeparator)
}

/// First non-empty age certification in the country, "" when there is none.
func ageCertification(_ details: MovieDetails, regionCode: String) -> String {
    for country in details.releaseDates.results {
        if country.countryCode == regionCode {
            return firstCertification(country.releaseDates)
        }
    }
    return ""
}

private func firstCertification(_ releaseDates: [ReleaseDate]) -> String {
    for releaseDate in releaseDates {
        if !releaseDate.certification.isEmpty {
            return releaseDate.certification
        }
    }
    return ""
}

/// YouTube key of the trailer. An official one wins, otherwise the first unofficial one.
/// "" when there is no trailer.
func trailerKey(_ details: MovieDetails) -> String {
    var unofficialKey = ""
    for video in details.videos.results {
        if video.site != videoSiteYouTube || video.type != videoTypeTrailer {
            continue
        }
        if video.official {
            return video.key
        }
        if unofficialKey.isEmpty {
            unofficialKey = video.key
        }
    }
    return unofficialKey
}

func trailerURL(_ details: MovieDetails) -> URL? {
    let key = trailerKey(details)
    if key.isEmpty {
        return nil
    }
    return URL(string: youTubeWatchBaseURL + key)
}

func hasTrailer(_ details: MovieDetails) -> Bool {
    return trailerURL(details) != nil
}

/// "1999 · ★ 8.2 · 2h 16m · 16", without the parts that are missing.
func movieFactsLine(_ movie: Movie, _ details: MovieDetails, regionCode: String) -> String {
    var parts = [yearAndRating(movie)]
    let runtime = formattedRuntime(details)
    if !runtime.isEmpty {
        parts.append(runtime)
    }
    let certification = ageCertification(details, regionCode: regionCode)
    if !certification.isEmpty {
        parts.append(certification)
    }
    return parts.joined(separator: textSeparator)
}

func watchProviders(_ details: MovieDetails, regionCode: String) -> CountryWatchProviders {
    return details.watchProviders.results[regionCode] ?? noWatchProviders
}

func hasWatchProviders(_ countryProviders: CountryWatchProviders) -> Bool {
    let streamCount = countryProviders.flatrate?.count ?? 0
    let rentCount = countryProviders.rent?.count ?? 0
    let buyCount = countryProviders.buy?.count ?? 0
    return streamCount + rentCount + buyCount > 0
}

func profileURL(_ castMember: CastMember) -> URL? {
    return imageURL(baseURL: tmdbProfileBaseURL, path: castMember.profilePath)
}

func logoURL(_ provider: WatchProvider) -> URL? {
    return imageURL(baseURL: tmdbLogoBaseURL, path: provider.logoPath)
}

/// Image address on the TMDB image server, nil when there is no path.
private func imageURL(baseURL: String, path: String?) -> URL? {
    let imagePath = path ?? ""
    if imagePath.isEmpty {
        return nil
    }
    return URL(string: baseURL + imagePath)
}
