import SwiftUI

private let ratingBadgeBackground = Color.black.opacity(0.6)

struct RatingBadge: View {
    let movie: Movie

    var body: some View {
        HStack(spacing: spacingTiny) {
            Image(systemName: symbolNameRatingStar)
            Text(formattedRating(movie))
                .monospacedDigit()
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, spacingSmall)
        .padding(.vertical, spacingExtraSmall)
        .background(ratingBadgeBackground, in: Capsule())
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rating \(formattedRating(movie))")
    }
}

#Preview {
    PopularMoviesPreview { movies in
        RatingBadge(movie: movies[0])
            .padding()
            .background(.gray)
    }
}
