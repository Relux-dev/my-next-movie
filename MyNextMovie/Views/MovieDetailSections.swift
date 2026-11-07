import SwiftUI

private let maxCastCount = 15
private let castPhotoSize: CGFloat = 80
private let castItemWidth: CGFloat = 96
private let castTextMaxLines = 2
private let providerLogoSize: CGFloat = 56
private let providerItemWidth: CGFloat = 72
private let providerNameMaxLines = 2
private let recommendationCardWidth: CGFloat = 140

private let symbolNameTrailer = "play.fill"
private let symbolNamePerson = "person.fill"

/// Sections under the movie overview. Each one shows only when it has data.
struct MovieDetailSections: View {
    let details: MovieDetails

    var body: some View {
        let countryProviders = watchProviders(details, regionCode: watchRegionCode)

        VStack(alignment: .leading, spacing: spacingExtraLarge) {
            if let address = trailerURL(details) {
                TrailerButton(address: address)
            }
            if !details.credits.cast.isEmpty {
                CastSection(cast: Array(details.credits.cast.prefix(maxCastCount)))
            }
            if hasWatchProviders(countryProviders) {
                WhereToWatchSection(countryProviders: countryProviders)
            }
            if !details.recommendations.results.isEmpty {
                MoreLikeThisSection(movies: details.recommendations.results)
            }
        }
        .padding(.horizontal)
    }
}

/// Opens the trailer on YouTube.
private struct TrailerButton: View {
    let address: URL

    var body: some View {
        Link(destination: address) {
            Label("Watch Trailer", systemImage: symbolNameTrailer)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

private struct SectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3.bold())
    }
}

private struct CastSection: View {
    let cast: [CastMember]

    var body: some View {
        VStack(alignment: .leading, spacing: spacingMedium) {
            SectionTitle(title: "Cast")
            ScrollView(.horizontal, showsIndicators: false) {
                castRow
            }
            .scrollClipDisabled()
        }
    }

    private var castRow: some View {
        HStack(alignment: .top, spacing: spacingMedium) {
            ForEach(cast) { castMember in
                CastMemberView(castMember: castMember)
            }
        }
    }
}

/// A round photo with the actor's name and the character under it.
private struct CastMemberView: View {
    let castMember: CastMember

    var body: some View {
        VStack(spacing: spacingExtraSmall) {
            photo
            Text(castMember.name)
                .font(.caption.weight(.semibold))
                .lineLimit(castTextMaxLines)
            Text(castMember.character)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(castTextMaxLines)
        }
        .multilineTextAlignment(.center)
        .frame(width: castItemWidth)
    }

    /// Without a photo `AsyncImage` keeps showing the placeholder.
    private var photo: some View {
        AsyncImage(url: profileURL(castMember)) { loadedImage in
            loadedImage.resizable().scaledToFill()
        } placeholder: {
            photoPlaceholder
        }
        .frame(width: castPhotoSize, height: castPhotoSize)
        .clipShape(Circle())
    }

    private var photoPlaceholder: some View {
        Image(systemName: symbolNamePerson)
            .font(.title)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.quaternary)
    }
}

private struct WhereToWatchSection: View {
    let countryProviders: CountryWatchProviders

    var body: some View {
        VStack(alignment: .leading, spacing: spacingMedium) {
            SectionTitle(title: "Where to Watch")
            ProviderGroup(title: "Stream", providers: countryProviders.flatrate ?? [])
            ProviderGroup(title: "Rent", providers: countryProviders.rent ?? [])
            ProviderGroup(title: "Buy", providers: countryProviders.buy ?? [])
            // Required by the TMDB terms of use.
            Text("Streaming data from JustWatch")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

/// One kind of service, e.g. "Stream", as a row that scrolls sideways. Empty without services.
private struct ProviderGroup: View {
    let title: String
    let providers: [WatchProvider]

    @ViewBuilder
    var body: some View {
        if !providers.isEmpty {
            group
        }
    }

    private var group: some View {
        VStack(alignment: .leading, spacing: spacingSmall) {
            groupTitle
            ScrollView(.horizontal, showsIndicators: false) {
                providerRow
            }
            .scrollClipDisabled()
        }
    }

    private var groupTitle: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private var providerRow: some View {
        HStack(alignment: .top, spacing: spacingMedium) {
            ForEach(providers) { provider in
                ProviderView(provider: provider)
            }
        }
    }
}

private struct ProviderView: View {
    let provider: WatchProvider

    var body: some View {
        VStack(spacing: spacingExtraSmall) {
            logo
            Text(provider.providerName)
                .font(.caption2)
                .lineLimit(providerNameMaxLines)
        }
        .multilineTextAlignment(.center)
        .frame(width: providerItemWidth)
    }

    private var logo: some View {
        AsyncImage(url: logoURL(provider)) { loadedImage in
            loadedImage.resizable().scaledToFit()
        } placeholder: {
            Rectangle().fill(.quaternary)
        }
        .frame(width: providerLogoSize, height: providerLogoSize)
        .clipShape(RoundedRectangle(cornerRadius: thumbnailCornerRadius, style: .continuous))
    }
}

private struct MoreLikeThisSection: View {
    let movies: [Movie]

    var body: some View {
        VStack(alignment: .leading, spacing: spacingMedium) {
            SectionTitle(title: "More Like This")
            ScrollView(.horizontal, showsIndicators: false) {
                movieRow
            }
            .scrollClipDisabled()
        }
    }

    private var movieRow: some View {
        HStack(alignment: .top, spacing: spacingLarge) {
            ForEach(movies) { movie in
                RecommendationItem(movie: movie)
            }
        }
    }
}

/// Tapping it opens the details of this movie, like `MovieGridItem` in the grid.
private struct RecommendationItem: View {
    let movie: Movie

    var body: some View {
        NavigationLink(value: movie) {
            MovieCardView(movie: movie)
                .frame(width: recommendationCardWidth)
        }
        .buttonStyle(.plain)
    }
}
