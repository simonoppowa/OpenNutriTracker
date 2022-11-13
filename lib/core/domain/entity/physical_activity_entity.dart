/// A physical activity with it's measured MET value by the
/// '2011 Compendium of Physical Activities'
/// https://pubmed.ncbi.nlm.nih.gov/21681120/
/// by Ainsworth et al.
class PhysicalActivityEntity {
  final String code;
  final String specificActivity;
  final double mets;
  final String? iconString;

  final List<String> tags;

  final PhysicalActivityTypeEntity type;

  PhysicalActivityEntity(this.code, this.specificActivity,
      this.mets, this.tags, this.iconString, this.type);
}

enum PhysicalActivityTypeEntity { bicycling, moderate, vigorous }

// TODO GROUP activities in effort categories (light, moderate, vigorous)
enum PhysicalActivityEffort { light, moderate, vigorous }
