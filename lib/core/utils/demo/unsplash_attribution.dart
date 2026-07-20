import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Photographer credit for one curated Unsplash photo used by the
/// demo-data seeder (`demo_seeder.dart`). Unsplash's general License
/// (unsplash.com/license) doesn't require attribution for these — the
/// seeder hand-picks specific, hardcoded photo URLs rather than querying
/// Unsplash's search API, so the stricter API Guidelines (which do require
/// attribution) never come into play. Credit is shown anyway, as a
/// courtesy to the photographers, wherever a curated photo is displayed
/// prominently — not on small list-row thumbnails, where there's no room
/// for a caption without breaking the layout.
class UnsplashCredit {
  final String name;
  final String profileUrl;

  const UnsplashCredit({required this.name, required this.profileUrl});
}

/// Builds a hotlinkable Unsplash CDN URL for a specific, hand-picked photo
/// id. Only ever called with the fixed ids in [_creditsByPhotoId] below —
/// the demo seeder never queries Unsplash's search API, so no API key is
/// needed and none of its rate limits or usage guidelines apply.
String unsplashImageUrl(String photoId, {int width = 800, int quality = 60}) =>
    'https://images.unsplash.com/photo-$photoId?fm=jpg&q=$quality&w=$width&fit=crop';

const _creditsByPhotoId = <String, UnsplashCredit>{
  '1548807371-30dc1bbe6cb5': UnsplashCredit(
    name: 'Alexandru Acea',
    profileUrl: 'https://unsplash.com/@alexacea',
  ), // oatmeal
  '1593357849627-cbbc9fda6b05': UnsplashCredit(
    name: 'bady abbas',
    profileUrl: 'https://unsplash.com/@bady',
  ), // brown rice
  '1552056413-b8b5eed0170b': UnsplashCredit(
    name: 'Youjeen Cho',
    profileUrl: 'https://unsplash.com/@youjeencho',
  ), // wholegrain bread
  '1762631934518-f75e233413ca': UnsplashCredit(
    name: 'joe boshra',
    profileUrl: 'https://unsplash.com/@joestudios',
  ), // chicken breast
  '1571212515416-fef01fc43637': UnsplashCredit(
    name: 'micheile henderson',
    profileUrl: 'https://unsplash.com/@micheile',
  ), // greek yogurt
  '1739785938237-73b3654200d5': UnsplashCredit(
    name: 'Mitili Mitili',
    profileUrl: 'https://unsplash.com/@mitiliemitili',
  ), // salmon fillet
  '1757801333069-f7b3cabaec4a': UnsplashCredit(
    name: 'Zoshua Colah',
    profileUrl: 'https://unsplash.com/@zoshuacolah',
  ), // olive oil
  '1627820752174-acae1b399128': UnsplashCredit(
    name: 'Towfiqu barbhuiya',
    profileUrl: 'https://unsplash.com/@towfiqu999999',
  ), // almonds
  '1757332050958-b797a022c910': UnsplashCredit(
    name: 'Daniel Dan',
    profileUrl: 'https://unsplash.com/@outsideclick',
  ), // banana
  '1567306226416-28f0efdc88ce': UnsplashCredit(
    name: 'Shelley Pauls',
    profileUrl: 'https://unsplash.com/@shelleypauls',
  ), // apple
  '1646161762904-043f71f256f1': UnsplashCredit(
    name: 'Mick Haupt',
    profileUrl: 'https://unsplash.com/@rocinante_11',
  ), // broccoli
  '1651684215020-f7a5b6610f23': UnsplashCredit(
    name: 'The Connected Narrative',
    profileUrl: 'https://unsplash.com/@theconnectednarrative',
  ), // demo profile picture
};

final _photoIdPattern = RegExp(r'/photo-([a-zA-Z0-9_-]+)');

/// The credit for [imageUrl], or null when it isn't one of the curated
/// demo photos (a real OFF/FDC product photo, a user's own photo, or no
/// image at all).
UnsplashCredit? unsplashCreditForUrl(String? imageUrl) {
  if (imageUrl == null) return null;
  final id = _photoIdPattern.firstMatch(imageUrl)?.group(1);
  if (id == null) return null;
  return _creditsByPhotoId[id];
}

/// Small tappable "Photo: NAME / Unsplash" credit line. Renders
/// nothing when [imageUrl] isn't one of the curated demo photos, so it's
/// safe to drop into a screen that also shows real users' own photos.
class UnsplashCreditLine extends StatelessWidget {
  final String? imageUrl;

  const UnsplashCreditLine({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final credit = unsplashCreditForUrl(imageUrl);
    if (credit == null) return const SizedBox.shrink();
    return _CreditText(credit: credit);
  }
}

/// Same as [UnsplashCreditLine], but for the profile picture: since that
/// photo is downloaded and stored locally rather than hotlinked (see
/// `UserImageStorage`), there's no URL left to look up at render time —
/// the credit comes from the on-disk sidecar file instead.
class UnsplashCreditFromSidecar extends StatelessWidget {
  final Future<({String name, String profileUrl})?> credit;

  const UnsplashCreditFromSidecar({super.key, required this.credit});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({String name, String profileUrl})?>(
      future: credit,
      builder: (context, snapshot) {
        final credit = snapshot.data;
        if (credit == null) return const SizedBox.shrink();
        return _CreditText(
          credit: UnsplashCredit(
            name: credit.name,
            profileUrl: credit.profileUrl,
          ),
        );
      },
    );
  }
}

class _CreditText extends StatelessWidget {
  final UnsplashCredit credit;

  const _CreditText({required this.credit});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: InkWell(
          onTap: () => launchUrl(
            Uri.parse(credit.profileUrl),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            'Photo: ${credit.name} / Unsplash',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.onSurfaceVariant,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}
