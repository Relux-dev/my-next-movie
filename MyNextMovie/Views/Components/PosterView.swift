import SwiftUI

/// Posters are 2:3, like cinema posters.
private let posterAspectRatio: CGFloat = 2 / 3

private let placeholderTopGray = Color(white: 0.28)
private let placeholderBottomGray = Color(white: 0.06)

/// Size of the genre symbol as a share of the poster width.
private let genreSymbolSizeToPosterWidth: CGFloat = 0.3
private let genreSymbolOpacity = 0.2

/// Narrower posters are thumbnails, which get no title.
private let minimumPosterWidthForTitle: CGFloat = 100
private let posterTitleMaxLines = 3

/// Movie poster in a 2:3 frame.
/// Loads the TMDB image when the movie has one, otherwise draws a monochrome placeholder.
struct PosterView: View {
    let movie: Movie
    var cornerRadius = posterCornerRadius

    @Environment(\.redactionReasons) private var redactionReasons

    var body: some View {
        Color.clear
            .aspectRatio(posterAspectRatio, contentMode: .fit)
            .overlay { posterImage }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var posterImage: some View {
        if !redactionReasons.isEmpty {
            Rectangle().fill(.quaternary)
        } else if hasPoster(movie) {
            AsyncImage(url: posterURL(movie)) { loadedImage in
                loadedImage.resizable().scaledToFill()
            } placeholder: {
                PosterPlaceholder(movie: movie)
            }
        } else {
            PosterPlaceholder(movie: movie)
        }
    }
}

private struct PosterPlaceholder: View {
    let movie: Movie

    var body: some View {
        GeometryReader { geometry in
            PosterArt(movie: movie, posterWidth: geometry.size.width)
        }
    }
}

private struct PosterArt: View {
    let movie: Movie
    let posterWidth: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [placeholderTopGray, placeholderBottomGray],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            genreSymbol
            if posterWidth >= minimumPosterWidthForTitle {
                posterTitle
            }
        }
    }

    private var genreSymbol: some View {
        Image(systemName: genreSymbolName(mainGenreId(movie)))
            .font(.system(size: posterWidth * genreSymbolSizeToPosterWidth, weight: .light))
            .foregroundStyle(.white.opacity(genreSymbolOpacity))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var posterTitle: some View {
        Text(movie.title)
            .font(.system(.headline, design: .serif, weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(posterTitleMaxLines)
            .padding(spacingMedium)
    }
}

#Preview {
    PopularMoviesPreview { movies in
        PosterView(movie: movies[0])
            .frame(width: 180)
    }
}
