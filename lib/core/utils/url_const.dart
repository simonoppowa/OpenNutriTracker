class URLConst {
  static const paCompendium2011URL = "https://pacompendium.com/";
  static const privacyPolicyURLEn =
      "https://www.iubenda.com/privacy-policy/53501884";
  static const privacyPolicyURLDe =
      "https://www.iubenda.com/privacy-policy/53922100";

  /// The privacy policy to open for [languageCode], English by default.
  ///
  /// Nine locales ship and exactly two policy documents exist, so this is a
  /// deliberately narrow rule rather than a lookup table: German has its own
  /// document, and every other language gets the English one because there is
  /// nothing else to send them to. Do not add a locale here without a policy
  /// actually existing for it — pointing a Czech user at a German document is
  /// worse than the English fallback.
  ///
  /// Both entry points route through here so the two cannot drift; before
  /// this existed they each hardcoded the English URL and the German document
  /// was maintained for nobody.
  static String privacyPolicyFor(String languageCode) =>
      languageCode == 'de' ? privacyPolicyURLDe : privacyPolicyURLEn;

  /// The current privacy-policy revision, compared against
  /// `ConfigEntity.policyNoticeRevisionSeen` to decide whether a user still
  /// needs the one-time change notice (#887).
  ///
  /// **Bump this only for a change that is material to a reader** — a recipient
  /// named for the first time, a new category of data, a legal basis. Not for a
  /// typo, a reworded sentence, or a translation fix. Every bump shows a dialog
  /// to every existing user on their next launch, and a notice that cries wolf
  /// is worth less than no notice at all.
  ///
  /// Revision 1 is the correction that followed the audit in #867: recipients
  /// that were always receiving data got named, a health-data section was
  /// added for the Health Connect / Apple Health import, and an approximate
  /// location the Supabase gateway keeps for a day was disclosed. None of it
  /// changed what the app does.
  static const policyRevision = 1;

  // Citations for the in-app medical/health calculations. Surfaced on the
  // Sources & References screen (see `sources_screen.dart`) so that users
  // can verify each number we show against its peer-reviewed source.
  static const sourceEnergyIomDriURL =
      "https://nap.nationalacademies.org/catalog/10490";
  // Per-nutrient reference intakes shown on the diary's daily nutrient
  // panel (fibre, iron, calcium, vitamins, etc.) come from this Summary
  // Report, which covers the broader DRI tables — distinct from the
  // energy-specific 2005 catalogue cited above.
  static const sourceNutrientReferenceIomURL =
      "https://www.nationalacademies.org/our-work/summary-report-of-the-dietary-reference-intakes";
  static const sourceBmiWhoURL =
      "https://www.who.int/data/gho/data/themes/topics/topic-details/GHO/body-mass-index";
  static const sourceMacrosWhoTrs916URL =
      "https://iris.who.int/handle/10665/42665";
  static const sourceActivityCompendium2024URL =
      "https://pubmed.ncbi.nlm.nih.gov/38242596/";
  static const sourceInclusiveDesignLinsenmeyer2021URL =
      "https://doi.org/10.1186/s12937-021-00662-z";
  static const sourceTransMetabolismWiik2018URL =
      "https://pmc.ncbi.nlm.nih.gov/articles/PMC6046513/";
  static const sourceTransNutritionLinsenmeyer2020URL =
      "https://link.springer.com/article/10.1186/s12937-020-00590-4";
  static const sourceEnergyCompensationCareau2021URL =
      "https://pubmed.ncbi.nlm.nih.gov/34453886/";
  static const sourceBodyCompositionBorrud2010URL =
      "https://www.cdc.gov/nchs/data/series/sr_11/sr11_250.pdf";

  // Wiki page documenting every in-app calculation in full — linked from
  // the calorie-goal transparency screen for people who want the complete
  // derivation including sources.
  static const wikiCalculationsURL =
      "https://github.com/simonoppowa/OpenNutriTracker/wiki/Calculations";
}
