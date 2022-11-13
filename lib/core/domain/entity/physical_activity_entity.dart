import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A physical activity with it's measured MET value by the
/// '2011 Compendium of Physical Activities'
/// https://pubmed.ncbi.nlm.nih.gov/21681120/
/// by Ainsworth et al.
class PhysicalActivityEntity {
  final String code;
  final String specificActivity;
  final double mets;
  final IconData? _icon;

  get displayIcon => _icon ?? type.getTypeIcon();

  final List<String> tags;

  final PhysicalActivityTypeEntity type;

  PhysicalActivityEntity(this.code, this.specificActivity, this.mets, this.tags,
      this._icon, this.type);

  String getName(BuildContext context) {
    final physicalActivityMap = {
      "01009": S.of(context).paBicyclingMountainGeneral,
      "01015": S.of(context).paBicyclingGeneral,
      "01070": S.of(context).paUnicyclingGeneral,
      "02010": S.of(context).paBicyclingStationaryGeneral,
      "02030": S.of(context).paCalisthenicsGeneral,
      "02050": S.of(context).paResistanceTraining,
      "02068": S.of(context).paRopeSkippingGeneral,
      "02120": S.of(context).paWaterAerobics,
      "03015": S.of(context).paDancingAerobicGeneral,
      "12020": S.of(context).paJoggingGeneral,
      "12150": S.of(context).paRunningGeneral,
      "15010": S.of(context).paArcheryGeneral,
      "15055": S.of(context).paBasketballGeneral,
      "15080": S.of(context).paBilliardsGeneral,
      "15090": S.of(context).paBowlingGeneral,
      "15100": S.of(context).paBoxingGeneral,
      "15110": S.of(context).paBoxingBag,
      "15130": S.of(context).paBroomball,
      "15135": S.of(context).paChildrenGame,
      "15138": S.of(context).paCheerleading,
      "15150": S.of(context).paCricket,
      "15160": S.of(context).paCroquet,
      "15170": S.of(context).paCurling,
      "15192": S.of(context).paAutoRacing,
      "15200": S.of(context).paAmericanFootballGeneral,
      "15235": S.of(context).paCatch,
      "15240": S.of(context).paFrisbee,
      "15255": S.of(context).paGolfGeneral,
      "15300": S.of(context).paGymnasticsGeneral,
      "15310": S.of(context).paHackySack,
      "15320": S.of(context).paHandballGeneral,
      "15340": S.of(context).paHangGliding,
      "15350": S.of(context).paHockeyField,
      "15360": S.of(context).paIceHockeyGeneral,
      "15370": S.of(context).paHorseRidingGeneral,
      "15420": S.of(context).paJaiAlai,
      "15425": S.of(context).paMartialArtsSlower,
      "15430": S.of(context).paMartialArtsModerate,
      "15440": S.of(context).paJuggling,
      "15460": S.of(context).paLacrosse,
      "15465": S.of(context).paLawnBowling,
      "15470": S.of(context).paMotoCross,
      "15480": S.of(context).paOrienteering,
      "15510": S.of(context).paPoloHorse,
      "15530": S.of(context).paRacquetball,
      "15533": S.of(context).paMountainClimbing,
      "15544": S.of(context).paRodeoSportGeneralModerate,
      "15551": S.of(context).paRopeJumpingGeneral,
      "15560": S.of(context).paRugbyNonCompetitive,
      "15562": S.of(context).paRugbyNonCompetitive,
      "15570": S.of(context).paShuffleboard,
      "15580": S.of(context).paSkateboardingGeneral,
      "15590": S.of(context).paSkatingRoller,
      "15592": S.of(context).paRollerbladingLight,
      "15600": S.of(context).paSkydiving,
      "15610": S.of(context).paSoftballBaseballGeneral,
      "15652": S.of(context).paSquashGeneral,
      "15660": S.of(context).paTableTennisGeneral,
      "15670": S.of(context).paTaiChiQiGongGeneral,
      "15675": S.of(context).paTennisGeneral,
      "15700": S.of(context).paTrampolineLight,
      "15710": S.of(context).paVolleyballGeneral,
      "15730": S.of(context).paWrestling,
      "15731": S.of(context).paWallyball,
      "15732": S.of(context).paTrackField1,
      "15733": S.of(context).paTrackField2,
      "15734": S.of(context).paTrackField3,
      "17010": S.of(context).paBackpackingGeneral,
      "17080": S.of(context).paHikingCrossCountry,
      "17160": S.of(context).paWalkingForPleasure,
      "17165": S.of(context).paWalkingTheDog,
      "18070": S.of(context).paCanoeingGeneral,
      "18090": S.of(context).paDivingSpringboardPlatform,
      "18100": S.of(context).paKayakingModerate,
      "18110": S.of(context).paPaddleBoat,
      "18120": S.of(context).paSailingGeneral,
      "18150": S.of(context).paSkiingWaterWakeboarding,
      "18200": S.of(context).paDivingGeneral,
      "18210": S.of(context).paSnorkeling,
      "18220": S.of(context).paSurfing,
      "18225": S.of(context).paPaddleBoarding,
      "18350": S.of(context).paSwimmingGeneral,
      "18360": S.of(context).paWaterPolo,
      "19030": S.of(context).paIceSkatingGeneral,
      "19075": S.of(context).paSkiingGeneral,
      "19252": S.of(context).paSnowShovingModerate
    };
    return physicalActivityMap[code] ?? type.getName(context);
  }

  factory PhysicalActivityEntity.fromPhysicalActivityDBO(
          PhysicalActivityDBO activityDBO) =>
      PhysicalActivityEntity(
          activityDBO.code,
          activityDBO.specificActivity,
          activityDBO.mets,
          activityDBO.tags,
          activityDBO.icon,
          PhysicalActivityTypeEntity.fromPhysicalActivityTypeDBO(
              activityDBO.type));
}

extension ActivityIcon on PhysicalActivityTypeEntity {
  String getName(BuildContext context) {
    String name;
    switch (this) {
      case PhysicalActivityTypeEntity.bicycling:
        name = S.of(context).paHeadingBicycling;
        break;
      case PhysicalActivityTypeEntity.conditioningExercise:
        name = S.of(context).paHeadingConditionalExercise;
        break;
      case PhysicalActivityTypeEntity.dancing:
        name = S.of(context).paHeadingDancing;
        break;
      case PhysicalActivityTypeEntity.running:
        name = S.of(context).paHeadingRunning;
        break;
      case PhysicalActivityTypeEntity.sport:
        name = S.of(context).paHeadingSports;
        break;
      case PhysicalActivityTypeEntity.waterActivities:
        name = S.of(context).paHeadingWaterActivities;
        break;
      case PhysicalActivityTypeEntity.winterActivities:
        name = S.of(context).paHeadingWinterActivities;
        break;
    }
    return name;
  }

  IconData getTypeIcon() {
    IconData icon;
    switch (this) {
      case PhysicalActivityTypeEntity.bicycling:
        icon = Icons.directions_bike_outlined;
        break;
      case PhysicalActivityTypeEntity.conditioningExercise:
        icon = Icons.sports_gymnastics_outlined;
        break;
      case PhysicalActivityTypeEntity.dancing:
        icon = Icons.music_note_outlined;
        break;
      case PhysicalActivityTypeEntity.running:
        icon = Icons.directions_run_outlined;
        break;
      case PhysicalActivityTypeEntity.sport:
        icon = Icons.sports_outlined;
        break;
      case PhysicalActivityTypeEntity.waterActivities:
        icon = Icons.water_outlined;
        break;
      case PhysicalActivityTypeEntity.winterActivities:
        icon = Icons.ac_unit_outlined;
        break;
    }
    return icon;
  }
}

enum PhysicalActivityTypeEntity {
  bicycling,
  conditioningExercise,
  dancing,
  running,
  sport,
  waterActivities,
  winterActivities;

  factory PhysicalActivityTypeEntity.fromPhysicalActivityTypeDBO(
      PhysicalActivityTypeDBO typeDBO) {
    PhysicalActivityTypeEntity typeEntity;
    switch (typeDBO) {
      case PhysicalActivityTypeDBO.bicycling:
        typeEntity = PhysicalActivityTypeEntity.bicycling;
        break;
      case PhysicalActivityTypeDBO.conditioningExercise:
        typeEntity = PhysicalActivityTypeEntity.conditioningExercise;
        break;
      case PhysicalActivityTypeDBO.dancing:
        typeEntity = PhysicalActivityTypeEntity.dancing;
        break;
      case PhysicalActivityTypeDBO.running:
        typeEntity = PhysicalActivityTypeEntity.running;
        break;
      case PhysicalActivityTypeDBO.sport:
        typeEntity = PhysicalActivityTypeEntity.sport;
        break;
      case PhysicalActivityTypeDBO.waterActivities:
        typeEntity = PhysicalActivityTypeEntity.waterActivities;
        break;
      case PhysicalActivityTypeDBO.winterActivities:
        typeEntity = PhysicalActivityTypeEntity.winterActivities;
        break;
    }
    return typeEntity;
  }
}

// TODO GROUP activities in effort categories (light, moderate, vigorous)
enum PhysicalActivityEffort { light, moderate, vigorous }
