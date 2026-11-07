// TMDB movie genre ids.
// See https://developer.themoviedb.org/reference/genre-movie-list
let genreIdAction = 28
let genreIdAdventure = 12
let genreIdAnimation = 16
let genreIdComedy = 35
let genreIdCrime = 80
let genreIdDocumentary = 99
let genreIdDrama = 18
let genreIdFamily = 10751
let genreIdFantasy = 14
let genreIdHistory = 36
let genreIdHorror = 27
let genreIdMusic = 10402
let genreIdMystery = 9648
let genreIdRomance = 10749
let genreIdScienceFiction = 878
let genreIdTVMovie = 10770
let genreIdThriller = 53
let genreIdWar = 10752
let genreIdWestern = 37

/// Stands for "no genre": a movie without known genres, or no genre filter.
let noGenreId = 0

/// Returned by `positionInGenreTable` when TMDB does not know the genre.
let genreNotInTable = -1

let unknownGenreName = "Unknown"
let unknownGenreSymbolName = "film"

/// A TMDB movie genre and the SF Symbol drawn for it.
struct Genre: Identifiable {
    let id: Int
    let name: String
    let symbolName: String
}

/// Every TMDB movie genre, sorted by name.
let genreTable: [Genre] = [
    Genre(id: genreIdAction, name: "Action", symbolName: "flame"),
    Genre(id: genreIdAdventure, name: "Adventure", symbolName: "mountain.2"),
    Genre(id: genreIdAnimation, name: "Animation", symbolName: "paintpalette"),
    Genre(id: genreIdComedy, name: "Comedy", symbolName: "theatermasks"),
    Genre(id: genreIdCrime, name: "Crime", symbolName: "magnifyingglass"),
    Genre(id: genreIdDocumentary, name: "Documentary", symbolName: "video"),
    Genre(id: genreIdDrama, name: "Drama", symbolName: "theatermasks.fill"),
    Genre(id: genreIdFamily, name: "Family", symbolName: "figure.2.and.child.holdinghands"),
    Genre(id: genreIdFantasy, name: "Fantasy", symbolName: "wand.and.stars"),
    Genre(id: genreIdHistory, name: "History", symbolName: "building.columns"),
    Genre(id: genreIdHorror, name: "Horror", symbolName: "moon.stars"),
    Genre(id: genreIdMusic, name: "Music", symbolName: "music.note"),
    Genre(id: genreIdMystery, name: "Mystery", symbolName: "questionmark.circle"),
    Genre(id: genreIdRomance, name: "Romance", symbolName: "heart"),
    Genre(id: genreIdScienceFiction, name: "Science Fiction", symbolName: "atom"),
    Genre(id: genreIdTVMovie, name: "TV Movie", symbolName: "tv"),
    Genre(id: genreIdThriller, name: "Thriller", symbolName: "eye"),
    Genre(id: genreIdWar, name: "War", symbolName: "shield"),
    Genre(id: genreIdWestern, name: "Western", symbolName: "sun.dust"),
]

/// Position of the genre in `genreTable`, `genreNotInTable` when TMDB does not know it.
func positionInGenreTable(_ genreId: Int) -> Int {
    for tablePosition in 0..<genreTable.count {
        if genreTable[tablePosition].id == genreId {
            return tablePosition
        }
    }
    return genreNotInTable
}

func genreName(_ genreId: Int) -> String {
    let tablePosition = positionInGenreTable(genreId)
    if tablePosition == genreNotInTable {
        return unknownGenreName
    }
    return genreTable[tablePosition].name
}

func genreSymbolName(_ genreId: Int) -> String {
    let tablePosition = positionInGenreTable(genreId)
    if tablePosition == genreNotInTable {
        return unknownGenreSymbolName
    }
    return genreTable[tablePosition].symbolName
}

/// Genre ids of the movie that TMDB knows, in the original order.
func knownGenreIds(_ movie: Movie) -> [Int] {
    var knownIds: [Int] = []
    for genreId in movie.genreIds {
        if positionInGenreTable(genreId) != genreNotInTable {
            knownIds.append(genreId)
        }
    }
    return knownIds
}

/// First genre of the movie that TMDB knows, `noGenreId` when there is none.
func mainGenreId(_ movie: Movie) -> Int {
    let knownIds = knownGenreIds(movie)
    if knownIds.isEmpty {
        return noGenreId
    }
    return knownIds[0]
}

/// "1999 · Action"
/// "1999" when the main genre is unknown, "Action" when the year is unknown, "" without both.
func movieSubtitle(_ movie: Movie) -> String {
    var parts: [String] = []
    let year = releaseYear(movie)
    if !year.isEmpty {
        parts.append(year)
    }
    // `genreName` would give "Unknown" for `noGenreId`, so leave the genre out instead.
    let genreId = mainGenreId(movie)
    if genreId != noGenreId {
        parts.append(genreName(genreId))
    }
    return parts.joined(separator: textSeparator)
}
