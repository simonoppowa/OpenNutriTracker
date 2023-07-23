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
      future: DefaultAssetBundle.of(context)
          .loadString('assets/icon/ont_logo_square.svg'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          String? svgString = snapshot.data!;

          // Replace the placeholders with desired colors.
          svgString = svgString.replaceAll(_circleColor,
              Theme.of(context).colorScheme.primaryContainer.toHex());
          svgString = svgString.replaceAll(
              _spoonColor, Theme.of(context).colorScheme.onBackground.toHex());
          return SvgPicture.string(svgString);
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        } else {
          return Image.asset(
              MediaQuery.of(context).platformBrightness == Brightness.light
                  ? 'assets/icon/ont_logo_square.png'
                  : 'assets/icon/ont_logo_square_light.png');
        }
      },
    );
  }
}
