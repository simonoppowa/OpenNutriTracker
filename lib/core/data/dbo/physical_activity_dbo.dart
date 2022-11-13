import 'package:flutter/material.dart';

/// A physical activity with it's measured MET value by the
/// '2011 Compendium of Physical Activities'
/// https://pubmed.ncbi.nlm.nih.gov/21681120/
/// by Ainsworth et al.
class PhysicalActivityDBO {
  final String code;
  final String specificActivity;
  final double mets;
  final IconData? icon;

  final List<String> tags;

  final PhysicalActivityTypeDBO type;

  PhysicalActivityDBO(this.code, this.specificActivity, this.mets, this.tags,
      this.icon, this.type);
}

enum PhysicalActivityTypeDBO {
  bicycling,
  conditioningExercise,
  dancing,
  running,
  sport,
  waterActivities,
  winterActivities,
}
