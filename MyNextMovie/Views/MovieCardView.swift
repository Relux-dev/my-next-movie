import SwiftUI

private let cardShadowColor = Color.black.opacity(0.15)
private let cardShadowRadius: CGFloat = 8
private let cardShadowOffset: CGFloat = 4
private let cardTextMaxLines = 1

/// One movie in the grid: the poster with a rating badge, the title and the subtitle under it.
struct MovieCardView: View {
    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: spacingSmall) {
            poster
            caption
        }
    }

    private var poster: some View {
        PosterView(movie: movie)
            .overlay(alignment: .topTrailing) { ratingBadge }
            .shadow(color: cardShadowColor, radius: cardShadowRadius, y: cardShadowOffset)
    }

    private var ratingBadge: some View {
        RatingBadge(movie: movie)
            .padding(spacingSmall)
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: spacingTiny) {
            Text(movie.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(cardTextMaxLines)
            Text(movieSubtitle(movie))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(cardTextMaxLines)
        }
    }
}

#Preview {
    PopularMoviesPreview { movies in
        MovieCardView(movie: movies[0])
            .frame(width: 170)
            .padding()
    }
}
