import 'package:flutter/widgets.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The name to show for a profile. An unnamed profile (e.g. the default
/// profile auto-created when an existing user upgrades) falls back to a
/// localised placeholder rather than rendering blank.
String profileDisplayName(BuildContext context, ProfileEntity profile) {
  final name = profile.name.trim();
  return name.isEmpty ? S.of(context).defaultProfileName : name;
}
