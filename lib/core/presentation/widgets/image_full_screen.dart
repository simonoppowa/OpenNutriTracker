import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_placeholder.dart';

class ImageFullScreen extends StatefulWidget {

  static const fullScreenHeroTag = 'fullScreenTag';

  const ImageFullScreen({super.key});

  @override
  State<ImageFullScreen> createState() => _ImageFullScreenState();
}

class _ImageFullScreenState extends State<ImageFullScreen> {
  late String imageUrl;

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as ImageFullScreenArguments;
    imageUrl = args.imageUrl;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: InteractiveViewer(
        child: Hero(
          tag: ImageFullScreen.fullScreenHeroTag,
          child: CachedNetworkImage(
            width: double.infinity,
            height: double.infinity,
            cacheManager: locator<CacheManager>(),
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, string) => const MealPlaceholder(),
            errorWidget: (context, url, error) => const MealPlaceholder(),
          ),
        ),
      ),
    );
  }
}

class ImageFullScreenArguments {
  final String imageUrl;

  ImageFullScreenArguments(this.imageUrl);
}
