import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:opennutritracker/core/utils/extensions.dart';

class DynamicOntLogo extends StatelessWidget {
  const DynamicOntLogo({super.key});

  static const _circleColor = 'circleColor';
  static const _spoonColor = 'spoonColor';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: DefaultAssetBundle.of(
        context,
      ).loadString('assets/icon/ont_logo_square.svg'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          String? svgString = snapshot.data!;

          // Replace the placeholders with desired colors.
          svgString = svgString.replaceAll(
            _circleColor,
            Theme.of(context).colorScheme.primaryContainer.toHex(),
          );
          svgString = svgString.replaceAll(
            _spoonColor,
            Theme.of(context).colorScheme.onSurface.toHex(),
          );
          return SvgPicture.string(svgString);
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        } else {
          // Match the active Material theme rather than the system
          // platformBrightness: when the user has overridden the app theme
          // to differ from system (e.g. forced dark while the device is on
          // light), the in-app logo should follow what they're actually
          // seeing. This also keeps the fallback consistent with the
          // primary SVG path above (which reads from Theme.of(context))
          // and with the About dialog in settings_screen.dart.
          return Image.asset(
            Theme.of(context).brightness == Brightness.light
                ? 'assets/icon/ont_logo_square_color_back_1024x1024.png'
                : 'assets/icon/ont_logo_square_color_white_1024x1024.png',
          );
        }
      },
    );
  }
}
