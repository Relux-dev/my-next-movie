@testable import MyNextMovie

// Movies written out in the tests, so the tests do not depend on TMDB.
// Poster paths are real ones from TMDB.

@MainActor
let testMovies: [Movie] = [
    Movie(
        id: 603,
        title: "The Matrix",
        overview: "A hacker named Neo learns that the world he lives in is a simulation.",
        releaseDate: "1999-03-31",
        posterPath: "/f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg",
        voteAverage: 8.2,
        genreIds: [genreIdAction, genreIdScienceFiction]
    ),
    Movie(
        id: 27205,
        title: "Inception",
        overview: "A thief who steals secrets from dreams is asked to plant an idea instead.",
        releaseDate: "2010-07-15",
        posterPath: "/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg",
        voteAverage: 8.4,
        genreIds: [genreIdAction, genreIdScienceFiction, genreIdAdventure]
    ),
    Movie(
        id: 157336,
        title: "Interstellar",
        overview:
            "A team of astronauts travels through a wormhole to find a new home for humanity.",
        releaseDate: "2014-11-05",
        posterPath: "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
        voteAverage: 8.4,
        genreIds: [genreIdAdventure, genreIdDrama, genreIdScienceFiction]
    ),
    Movie(
        id: 680,
        title: "Pulp Fiction",
        overview: "Several intertwined stories from the Los Angeles criminal underworld.",
        releaseDate: "1994-09-10",
        posterPath: "/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg",
        voteAverage: 8.5,
        genreIds: [genreIdThriller, genreIdCrime]
    ),
    Movie(
        id: 129,
        title: "Spirited Away",
        overview: "Ten-year-old Chihiro wanders into a world of spirits and must save her parents.",
        releaseDate: "2001-07-20",
        posterPath: "/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg",
        voteAverage: 8.5,
        genreIds: [genreIdAnimation, genreIdFamily, genreIdFantasy]
    ),
    Movie(
        id: 546554,
        title: "Knives Out",
        overview: "A detective investigates the death of a crime novelist at his family estate.",
        releaseDate: "2019-11-27",
        posterPath: "/pThyQovXQrw2m0s9x82twj48Jq4.jpg",
        voteAverage: 7.8,
        genreIds: [genreIdComedy, genreIdCrime, genreIdMystery]
    ),
    Movie(
        id: 597,
        title: "Titanic",
        overview: "A young aristocrat falls in love with a poor artist aboard an ill-fated ship.",
        releaseDate: "1997-11-18",
        posterPath: "/9xjZS2rlVxm8SFx8kPC3aIGCOYQ.jpg",
        voteAverage: 7.9,
        genreIds: [genreIdDrama, genreIdRomance]
    ),
]

/// Details of The Matrix, shortened.
@MainActor
let testMovieDetails = MovieDetails(
    id: 603,
    tagline: "Believe the unbelievable.",
    runtime: 136,
    credits: Credits(
        cast: [
            CastMember(id: 6384, name: "Keanu Reeves", character: "Neo", profilePath: "/8RZL.jpg")
        ],
        crew: [CrewMember(id: 9340, name: "Lana Wachowski", job: "Director")]
    ),
    videos: VideoList(results: [
        Video(key: "vKQi3bBA1y8", site: "YouTube", type: "Trailer", official: true)
    ]),
    releaseDates: ReleaseDateList(results: [
        CountryReleaseDates(countryCode: "PL", releaseDates: [ReleaseDate(certification: "16")])
    ]),
    watchProviders: WatchProviderList(results: [:]),
    recommendations: TMDBMoviePage(results: [])
)
