import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/utils/custom_icons.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A physical activity with it's measured MET value by the
/// '2011 Compendium of Physical Activities'
/// https://pubmed.ncbi.nlm.nih.gov/21681120/
/// by Ainsworth et al.
class PhysicalActivityEntity extends Equatable {
  final String code;
  final String specificActivity;
  final String description;
  final double mets;

  get displayIcon => getDisplayIcon();

  final List<String> tags;

  final PhysicalActivityTypeEntity type;

  const PhysicalActivityEntity(this.code, this.specificActivity,
      this.description, this.mets, this.tags, this.type);

  @override
  List<Object?> get props => [code, specificActivity, description, mets];

  String getName(BuildContext context) {
    final physicalActivityMap = {
      "01015": S.of(context).paBicyclingGeneral,
      "01009": S.of(context).paBicyclingMountainGeneral,
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
      "15030": S.of(context).paBadmintonGeneral,
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
      "15180": S.of(context).paDartsWall,
      "15192": S.of(context).paAutoRacing,
      "15200": S.of(context).paFencing,
      "15230": S.of(context).paAmericanFootballGeneral,
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
      "15500": S.of(context).paPaddleball,
      "15510": S.of(context).paPoloHorse,
      "15530": S.of(context).paRacquetball,
      "15533": S.of(context).paMountainClimbing,
      "15544": S.of(context).paRodeoSportGeneralModerate,
      "15551": S.of(context).paRopeJumpingGeneral,
      "15560": S.of(context).paRugbyCompetitive,
      "15562": S.of(context).paRugbyNonCompetitive,
      "15570": S.of(context).paShuffleboard,
      "15580": S.of(context).paSkateboardingGeneral,
      "15590": S.of(context).paSkatingRoller,
      "15592": S.of(context).paRollerbladingLight,
      "15600": S.of(context).paSkydiving,
      "15610": S.of(context).paSoccerGeneral,
      "15620": S.of(context).paSoftballBaseballGeneral,
      "15652": S.of(context).paSquashGeneral,
      "15660": S.of(context).paTableTennisGeneral,
      "15670": S.of(context).paTaiChiQiGongGeneral,
      "15675": S.of(context).paTennisGeneral,
      "15700": S.of(context).paTrampolineLight,
      "15710": S.of(context).paVolleyballGeneral,
      "15730": S.of(context).paWrestling,
      "15731": S.of(context).paWallyball,
      "15732": S.of(context).paTrackField,
      "15733": S.of(context).paTrackField,
      "15734": S.of(context).paTrackField,
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
      "18355": S.of(context).paWaterAerobics,
      "18360": S.of(context).paWaterPolo,
      "19030": S.of(context).paIceSkatingGeneral,
      "19075": S.of(context).paSkiingGeneral,
      "19252": S.of(context).paSnowShovingModerate
    };
    return physicalActivityMap[code] ?? type.getName(context);
  }

  String getDescription(BuildContext context) {
    final physicalActivityMap = {
      "01009": S.of(context).paBicyclingMountainGeneralDesc,
      "01015": S.of(context).paBicyclingGeneralDesc,
      "01070": S.of(context).paUnicyclingGeneralDesc,
      "02010": S.of(context).paBicyclingStationaryGeneralDesc,
      "02030": S.of(context).paCalisthenicsGeneralDesc,
      "02050": S.of(context).paResistanceTrainingDesc,
      "02068": S.of(context).paRopeSkippingGeneralDesc,
      "02120": S.of(context).paWaterAerobicsDesc,
      "03015": S.of(context).paDancingAerobicGeneralDesc,
      "12020": S.of(context).paJoggingGeneralDesc,
      "12150": S.of(context).paRunningGeneralDesc,
      "15010": S.of(context).paArcheryGeneralDesc,
      "15030": S.of(context).paBadmintonGeneralDesc,
      "15055": S.of(context).paBasketballGeneralDesc,
      "15080": S.of(context).paBilliardsGeneralDesc,
      "15090": S.of(context).paBowlingGeneralDesc,
      "15100": S.of(context).paBoxingGeneralDesc,
      "15110": S.of(context).paBoxingBagDesc,
      "15130": S.of(context).paBroomballDesc,
      "15135": S.of(context).paChildrenGameDesc,
      "15138": S.of(context).paCheerleadingDesc,
      "15150": S.of(context).paCricketDesc,
      "15160": S.of(context).paCroquetDesc,
      "15180": S.of(context).paDartsWallDesc,
      "15170": S.of(context).paCurlingDesc,
      "15192": S.of(context).paAutoRacingDesc,
      "15200": S.of(context).paFencingDesc,
      "15230": S.of(context).paAmericanFootballGeneralDesc,
      "15235": S.of(context).paCatchDesc,
      "15240": S.of(context).paFrisbeeDesc,
      "15255": S.of(context).paGolfGeneralDesc,
      "15300": S.of(context).paGymnasticsGeneralDesc,
      "15310": S.of(context).paHackySackDesc,
      "15320": S.of(context).paHandballGeneralDesc,
      "15340": S.of(context).paHangGlidingDesc,
      "15350": S.of(context).paHockeyFieldDesc,
      "15360": S.of(context).paIceHockeyGeneralDesc,
      "15370": S.of(context).paHorseRidingGeneralDesc,
      "15420": S.of(context).paJaiAlaiDesc,
      "15425": S.of(context).paMartialArtsSlowerDesc,
      "15430": S.of(context).paMartialArtsModerateDesc,
      "15440": S.of(context).paJugglingDesc,
      "15460": S.of(context).paLacrosseDesc,
      "15465": S.of(context).paLawnBowlingDesc,
      "15470": S.of(context).paMotoCrossDesc,
      "15480": S.of(context).paOrienteeringDesc,
      "15500": S.of(context).paPaddleballDesc,
      "15510": S.of(context).paPoloHorseDesc,
      "15530": S.of(context).paRacquetballDesc,
      "15533": S.of(context).paMountainClimbingDesc,
      "15544": S.of(context).paRodeoSportGeneralModerateDesc,
      "15551": S.of(context).paRopeJumpingGeneralDesc,
      "15560": S.of(context).paRugbyCompetitiveDesc,
      "15562": S.of(context).paRugbyNonCompetitiveDesc,
      "15570": S.of(context).paShuffleboardDesc,
      "15580": S.of(context).paSkateboardingGeneralDesc,
      "15590": S.of(context).paSkatingRollerDesc,
      "15592": S.of(context).paRollerbladingLightDesc,
      "15600": S.of(context).paSkydivingDesc,
      "15610": S.of(context).paSoccerGeneralDesc,
      "15620": S.of(context).paSoftballBaseballGeneralDesc,
      "15652": S.of(context).paSquashGeneralDesc,
      "15660": S.of(context).paTableTennisGeneralDesc,
      "15670": S.of(context).paTaiChiQiGongGeneralDesc,
      "15675": S.of(context).paTennisGeneralDesc,
      "15700": S.of(context).paTrampolineLightDesc,
      "15710": S.of(context).paVolleyballGeneralDesc,
      "15730": S.of(context).paWrestlingDesc,
      "15731": S.of(context).paWallyballDesc,
      "15732": S.of(context).paTrackField1Desc,
      "15733": S.of(context).paTrackField2Desc,
      "15734": S.of(context).paTrackField3Desc,
      "17010": S.of(context).paBackpackingGeneralDesc,
      "17080": S.of(context).paHikingCrossCountryDesc,
      "17160": S.of(context).paWalkingForPleasureDesc,
      "17165": S.of(context).paWalkingTheDogDesc,
      "18070": S.of(context).paCanoeingGeneralDesc,
      "18090": S.of(context).paDivingSpringboardPlatformDesc,
      "18100": S.of(context).paKayakingModerateDesc,
      "18110": S.of(context).paPaddleBoatDesc,
      "18120": S.of(context).paSailingGeneralDesc,
      "18150": S.of(context).paSkiingWaterWakeboardingDesc,
      "18200": S.of(context).paDivingGeneralDesc,
      "18210": S.of(context).paSnorkelingDesc,
      "18220": S.of(context).paSurfingDesc,
      "18225": S.of(context).paPaddleBoardingDesc,
      "18350": S.of(context).paSwimmingGeneralDesc,
      "18355": S.of(context).paWaterAerobicsDesc,
      "18360": S.of(context).paWaterPoloDesc,
      "19030": S.of(context).paIceSkatingGeneralDesc,
      "19075": S.of(context).paSkiingGeneralDesc,
      "19252": S.of(context).paSnowShovingModerateDesc
    };
    return physicalActivityMap[code] ?? type.getName(context);
  }

  IconData getDisplayIcon() {
    IconData iconData;
    switch (code) {
      case "01015":
        iconData = Icons.directions_bike_outlined;
        break;
      case "01009":
        iconData = Icons.directions_bike_outlined;
        break;
      case "01070":
        iconData = CustomIcons.unicycle;
        break;
      case "02010":
        iconData = CustomIcons.bike_pedal;
        break;
      case "02030":
        iconData = Icons.sports_gymnastics;
        break;
      case "02050":
        iconData = CustomIcons.kettlebell;
        break;
      case "02068":
        iconData = CustomIcons.jump_rope;
        break;
      case "02120":
        iconData = Icons.water;
        break;
      case "03015":
        iconData = Icons.music_note;
        break;
      case "12020":
        iconData = Icons.directions_run;
        break;
      case "12150":
        iconData = CustomIcons.run_fast;
        break;
      case "15010":
        iconData = CustomIcons.bow_arrow;
        break;
      case "15030":
        iconData = CustomIcons.badminton;
        break;
      case "15055":
        iconData = Icons.sports_basketball;
        break;
      case "15080":
        iconData = CustomIcons.billiards;
        break;
      case "15090":
        iconData = CustomIcons.bowling;
        break;
      case "15100":
        iconData = CustomIcons.boxing_glove;
        break;
      case "15110":
        iconData = CustomIcons.boxing_glove;
        break;
      case "15130":
        iconData = Icons.snowshoeing;
        break;
      case "15135":
        iconData = CustomIcons.seesaw;
        break;
      case "15138":
        iconData = CustomIcons.podium;
        break;
      case "15150":
        iconData = Icons.sports_cricket;
        break;
      case "15160":
        iconData = CustomIcons.trophy;
        break;
      case "15170":
        iconData = CustomIcons.curling;
        break;
      case "15180":
        iconData = CustomIcons.bullseye_arrow;
        break;
      case "15192":
        iconData = Icons.directions_car;
        break;
      case "15200":
        iconData = CustomIcons.fencing;
        break;
      case "15230":
        iconData = Icons.sports_football;
        break;
      case "15235":
        iconData = Icons.sports_baseball;
        break;
      case "15255":
        iconData = Icons.sports_golf;
        break;
      case "15300":
        iconData = Icons.sports_gymnastics;
        break;
      case "15320":
        iconData = Icons.sports_handball;
        break;
      case "15350":
        iconData = Icons.sports_hockey;
        break;
      case "15360":
        iconData = CustomIcons.hockey_puck;
        break;
      case "15370":
        iconData = CustomIcons.horseshoe;
        break;
      case "15425":
        iconData = Icons.sports_martial_arts;
        break;
      case "15430":
        iconData = Icons.sports_martial_arts;
        break;
      case "15460":
        iconData = CustomIcons.racquetball;
        break;
      case "15465":
        iconData = Icons.grass;
        break;
      case "15470":
        iconData = Icons.sports_motorsports;
        break;
      case "15480":
        iconData = CustomIcons.compass;
        break;
      case "15510":
        iconData = CustomIcons.polo;
        break;
      case "15530":
        iconData = CustomIcons.racquetball;
        break;
      case "15533":
        iconData = CustomIcons.carabiner;
        break;
      case "15544":
        iconData = CustomIcons.horseshoe;
        break;
      case "15551":
        iconData = CustomIcons.jump_rope;
        break;
      case "15560":
        iconData = Icons.sports_rugby;
        break;
      case "15562":
        iconData = Icons.sports_rugby;
        break;
      case "15580":
        iconData = Icons.skateboarding;
        break;
      case "15590":
        iconData = Icons.roller_skating;
        break;
      case "15592":
        iconData = CustomIcons.rollerblade;
        break;
      case "15600":
        iconData = CustomIcons.parachute;
        break;
      case "15610":
        iconData = Icons.sports_soccer;
        break;
      case "15620":
        iconData = Icons.sports_baseball;
        break;
      case "15652":
        iconData = CustomIcons.racquetball;
        break;
      case "15660":
        iconData = CustomIcons.table_tennis;
        break;
      case "15670":
        iconData = CustomIcons.karate;
        break;
      case "15675":
        iconData = CustomIcons.tennis;
        break;
      case "15710":
        iconData = Icons.sports_volleyball;
        break;
      case "15730":
        iconData = Icons.sports_kabaddi;
        break;
      case "15732":
        iconData = Icons.stadium;
        break;
      case "15733":
        iconData = Icons.stadium;
        break;
      case "15734":
        iconData = Icons.stadium;
        break;
      case "17010":
        iconData = Icons.hiking;
        break;
      case "17080":
        iconData = Icons.hiking;
        break;
      case "17160":
        iconData = Icons.directions_walk;
        break;
      case "17165":
        iconData = CustomIcons.dog;
        break;
      case "18070":
        iconData = Icons.water;
        break;
      case "18090":
        iconData = CustomIcons.diving;
        break;
      case "18100":
        iconData = Icons.kayaking;
        break;
      case "18110":
        iconData = Icons.water;
        break;
      case "18120":
        iconData = Icons.sailing;
        break;
      case "18150":
        iconData = CustomIcons.ski_water;
        break;
      case "18200":
        iconData = CustomIcons.diving_scuba;
        break;
      case "18210":
        iconData = CustomIcons.diving_snorkel;
        break;
      case "18220":
        iconData = Icons.surfing;
        break;
      case "18225":
        iconData = Icons.water;
        break;
      case "18350":
        iconData = CustomIcons.swim;
        break;
      case "18355":
        iconData = Icons.water;
        break;
      case "18360":
        iconData = CustomIcons.water_polo;
        break;
      case "19030":
        iconData = Icons.ice_skating;
        break;
      case "19075":
        iconData = Icons.downhill_skiing;
        break;
      case "19252":
        iconData = CustomIcons.snowflake;
        break;
      default:
        iconData = CustomIcons.medal;
    }
    return iconData;
  }

  factory PhysicalActivityEntity.fromPhysicalActivityDBO(
          PhysicalActivityDBO activityDBO) =>
      PhysicalActivityEntity(
          activityDBO.code,
          activityDBO.specificActivity,
          activityDBO.description,
          activityDBO.mets,
          activityDBO.tags,
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
