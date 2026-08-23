import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/delete_profile_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/features/profile/presentation/utils/profile_switch_coordinator.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_activity_selection_entity.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_gender_selection_entity.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_goal_selection_entity.dart';
import 'package:opennutritracker/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:opennutritracker/features/onboarding/presentation/onboarding_intro_page_body.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_goal_page_body.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/run_ai_endpoint_probe_usecase.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_other_options_page_body.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_overview_page_body.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_activity_page_body.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/highlight_button.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_about_you_page_body.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_body_measurements_page_body.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// The onboarding pages, in the order they are shown.
///
/// The pager addresses pages by index, so inserting one used to silently
/// retarget every jump after it. Declaring the order once means a new page
/// is added here and the jumps keep pointing at the page they name.
enum _OnboardingPage {
  intro,
  aboutYou,
  bodyMeasurements,
  activity,
  goal,
  otherOptions,
  overview,
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late OnboardingBloc _onboardingBloc;
  final _introKey = GlobalKey<IntroductionScreenState>();

  final _pageDecoration = const PageDecoration(
    safeArea: 0,
    bodyAlignment: Alignment.topCenter,
    bodyFlex: 6,
  );

  final _defaultImageWidget = null;

  bool _introPageButtonActive = false;
  bool _aboutYouPageButtonActive = false;
  bool _bodyMeasurementsPageButtonActive = false;
  bool _activityPageButtonActive = false;
  bool _goalPageButtonActive = false;
  bool _overviewPageButtonActive = false;

  /// Ticked when the height/weight page's Next is tapped while blocked, so
  /// that page reveals the errors for fields the user never left.
  final _bodyMeasurementsShowErrors = ValueNotifier<int>(0);

  @override
  void initState() {
    _onboardingBloc = locator<OnboardingBloc>();
    // The bloc is a singleton and its state persists, so a second trip
    // through onboarding (adding a profile) used to skip loading entirely:
    // the event only fired from the initial state, which meant the unit and
    // food-source seeding never ran and the previous run's answers were
    // still in the selection. Reset and reload on every entry instead.
    _onboardingBloc.resetSelection();
    _onboardingBloc.add(LoadOnboardingEvent());
    super.initState();
  }

  @override
  void dispose() {
    _bodyMeasurementsShowErrors.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When onboarding is reached by adding a new profile, the route carries
    // the id of the profile to return to if the user backs out. First-run
    // onboarding has no argument, so this stays null and back behaves as
    // before (exits the app).
    final cancelToProfileId =
        ModalRoute.of(context)?.settings.arguments as String?;

    final scaffold = Scaffold(
      body: SafeArea(
        child: BlocBuilder<OnboardingBloc, OnboardingState>(
          bloc: _onboardingBloc,
          builder: (context, state) {
            if (state is OnboardingLoadedState) {
              return _getLoadedContent(context);
            }
            return _getLoadingContent();
          },
        ),
      ),
    );

    if (cancelToProfileId == null) return scaffold;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onCancelAddProfile(cancelToProfileId);
      },
      child: scaffold,
    );
  }

  /// Backs out of onboarding for a freshly-added profile: deletes that
  /// half-created profile and its boxes, then returns to the profile the
  /// user came from. Keeps an abandoned add from stranding them on an
  /// empty profile on the next launch.
  Future<void> _onCancelAddProfile(String cancelToProfileId) async {
    final getProfiles = locator<GetProfilesUsecase>();
    final draft = getProfiles.getActiveProfile();
    ProfileEntity? cancelTo;
    for (final profile in getProfiles.getProfiles()) {
      if (profile.id == cancelToProfileId) {
        cancelTo = profile;
        break;
      }
    }

    if (draft != null && draft.id != cancelToProfileId) {
      await locator<DeleteProfileUsecase>().deleteProfile(draft);
    }
    if (!mounted) return;

    if (cancelTo != null) {
      await locator<ProfileSwitchCoordinator>().switchTo(context, cancelTo);
    } else {
      ProfileSwitchCoordinator.reloadTabBlocs();
      Navigator.pushReplacementNamed(context, NavigationOptions.mainRoute);
    }
  }

  Widget _getLoadingContent() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _getLoadedContent(BuildContext context) {
    return IntroductionScreen(
      key: _introKey,
      scrollPhysics: const NeverScrollableScrollPhysics(),
      back: const Icon(Icons.arrow_back_outlined),
      showBackButton: true,
      showNextButton: false,
      showDoneButton: false,
      isProgressTap: false,
      dotsFlex: 0,
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        activeColor: Theme.of(context).colorScheme.primary,
        activeSize: const Size(22.0, 10.0),
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      onChange: onPageChanged,
      pages: _getPageViewModels(),
    );
  }

  /// Builds the pages in [_OnboardingPage] order. The two have to stay in
  /// step, since every jump resolves through that enum's indices.
  List<PageViewModel> _getPageViewModels() {
    final selection = _onboardingBloc.userSelection;
    final pages = <PageViewModel>[
        PageViewModel(
          title: S.of(context).onboardingWelcomeLabel,
          decoration: _pageDecoration,
          image: _defaultImageWidget,
          bodyWidget: OnboardingIntroPageBody(
            setPageContent: _setIntroPageData,
            initialAcceptedPolicy: _introPageButtonActive,
            initialAcceptedDataCollection: selection.acceptDataCollection,
          ),
          footer: HighlightButton(
            buttonLabel: S.of(context).buttonStartLabel,
            onButtonPressed: () => _scrollToPage(_OnboardingPage.aboutYou),
            buttonActive: _introPageButtonActive,
            inactiveMessage: S.of(context).onboardingBlockedPolicySnack,
          ),
        ),
        PageViewModel(
          titleWidget: const SizedBox(),
          // empty
          decoration: _pageDecoration,
          image: _defaultImageWidget,
          bodyWidget: OnboardingAboutYouPageBody(
            setPageContent: _setAboutYouPageData,
            initialGender: selection.gender,
            initialCaloriesProfile: selection.caloriesProfile,
            initialBirthday: selection.birthday,
          ),
          footer: HighlightButton(
            buttonLabel: S.of(context).buttonNextLabel,
            onButtonPressed: () =>
                _scrollToPage(_OnboardingPage.bodyMeasurements),
            buttonActive: _aboutYouPageButtonActive,
            inactiveMessage: S.of(context).onboardingBlockedProfileSnack,
          ),
        ),
        PageViewModel(
          titleWidget: const SizedBox(),
          // empty
          decoration: _pageDecoration,
          image: _defaultImageWidget,
          bodyWidget: OnboardingBodyMeasurementsPageBody(
            setButtonContent: _setBodyMeasurementsPageData,
            initialHeightCm: selection.height,
            initialWeightKg: selection.weight,
            initialTargetWeightKg: selection.targetWeight,
            initialHeightImperial: selection.heightUsesImperial,
            initialBodyWeightUnit: selection.bodyWeightUnit,
            initialFoodImperial: selection.foodUsesImperial,
            showErrorsSignal: _bodyMeasurementsShowErrors,
          ),
          footer: HighlightButton(
            buttonLabel: S.of(context).buttonNextLabel,
            onButtonPressed: () => _scrollToPage(_OnboardingPage.activity),
            buttonActive: _bodyMeasurementsPageButtonActive,
            inactiveMessage: S.of(context).onboardingBlockedBodySnack,
            onBlockedPressed: () => _bodyMeasurementsShowErrors.value++,
          ),
        ),
        PageViewModel(
          titleWidget: const SizedBox(),
          // empty
          decoration: _pageDecoration,
          image: _defaultImageWidget,
          bodyWidget: OnboardingActivityPageBody(
            setButtonContent: _setActivityPageData,
            initialActivity: selection.activity,
          ),
          footer: HighlightButton(
            buttonLabel: S.of(context).buttonNextLabel,
            onButtonPressed: () => _scrollToPage(_OnboardingPage.goal),
            buttonActive: _activityPageButtonActive,
            inactiveMessage: S.of(context).onboardingBlockedActivitySnack,
          ),
        ),
        PageViewModel(
          titleWidget: const SizedBox(),
          // empty
          decoration: _pageDecoration,
          image: _defaultImageWidget,
          bodyWidget: OnboardingGoalPageBody(
            setButtonContent: _setGoalPageData,
            initialGoal: selection.goal,
            heightCm: selection.height,
            weightKg: selection.weight,
            targetWeightKg: selection.targetWeight,
          ),
          footer: HighlightButton(
            buttonLabel: S.of(context).buttonNextLabel,
            onButtonPressed: () => _scrollToPage(_OnboardingPage.otherOptions),
            buttonActive: _goalPageButtonActive,
            inactiveMessage: S.of(context).onboardingBlockedGoalSnack,
          ),
        ),
        PageViewModel(
          titleWidget: const SizedBox(),
          // empty
          decoration: _pageDecoration,
          image: _defaultImageWidget,
          bodyWidget: OnboardingOtherOptionsPageBody(
            setPageContent: _setOtherOptionsPageData,
            initialTheme: selection.appTheme,
            initialFoodSourceToggles: selection.foodSourceToggles,
            initialDailyReminderEnabled: selection.dailyReminderEnabled,
            initialUseMaterialYou: selection.useMaterialYou,
            initialAccentColor: selection.accentColor,
            // The one dependency on this page the bloc does not carry: the AI
            // row reads and writes the keystore directly rather than staging
            // through onboarding's save. #728.
            aiCredentials: locator<AiCredentialStorage>(),
            aiProbeRunner: locator<AiEndpointProbeRunner>(),
          ),
          // Everything on this page is optional and pre-filled with
          // defaults, so the button is always active.
          footer: HighlightButton(
            buttonLabel: S.of(context).buttonNextLabel,
            onButtonPressed: () => _scrollToPage(_OnboardingPage.overview),
            buttonActive: true,
          ),
        ),
        PageViewModel(
          titleWidget: const SizedBox(),
          // empty
          decoration: _pageDecoration,
          image: _defaultImageWidget,
          bodyWidget: OnboardingOverviewPageBody(
            calorieGoalDayString:
                _onboardingBloc.getOverviewCalorieGoal()?.toInt().toString() ??
                    "?",
            carbsGoalString:
                _onboardingBloc.getOverviewCarbsGoal()?.toInt().toString() ??
                    "?",
            fatGoalString:
                _onboardingBloc.getOverviewFatGoal()?.toInt().toString() ?? "?",
            proteinGoalString:
                _onboardingBloc.getOverviewProteinGoal()?.toInt().toString() ??
                    "?",
            setButtonActive: _setOverviewPageContent,
            breakdown: _onboardingBloc.getOverviewBreakdown(),
            showLowKcalWarning:
                _onboardingBloc.isOverviewBelowRecommendedKcalFloor(),
            lowKcalWarningThreshold:
                _onboardingBloc.getOverviewRecommendedKcalFloor(),
          ),
          footer: HighlightButton(
            buttonLabel: S.of(context).buttonStartLabel,
            onButtonPressed: () {
              _onOverviewStartButtonPressed(context);
            },
            buttonActive: _overviewPageButtonActive,
            inactiveMessage: S.of(context).onboardingBlockedOverviewSnack,
          ),
        ),
      ];
    assert(
      pages.length == _OnboardingPage.values.length,
      'a page was added or removed without updating _OnboardingPage',
    );
    return pages;
  }

  void _scrollToPage(_OnboardingPage page) {
    FocusScope.of(context).requestFocus(FocusNode()); // Dismiss Keyboard
    _introKey.currentState?.animateScroll(page.index);
  }

  void _setIntroPageData(bool active, bool acceptedDataCollection) {
    setState(() {
      _onboardingBloc.userSelection.acceptDataCollection =
          acceptedDataCollection;

      _introPageButtonActive = active;
    });
  }

  void _setAboutYouPageData(
    bool active,
    UserGenderSelectionEntity? selectedGender,
    CaloriesProfileEntity? selectedCaloriesProfile,
    DateTime? selectedBirthday,
  ) {
    setState(() {
      _onboardingBloc.userSelection.gender = selectedGender;
      _onboardingBloc.userSelection.caloriesProfile = selectedCaloriesProfile;
      _onboardingBloc.userSelection.birthday = selectedBirthday;

      _aboutYouPageButtonActive = active;
    });
  }

  void _setBodyMeasurementsPageData(
    bool active,
    double? selectedHeight,
    double? selectedWeight,
    double? selectedTargetWeight,
    bool heightImperial,
    BodyWeightUnit bodyWeightUnit,
    bool foodImperial,
  ) {
    setState(() {
      _onboardingBloc.userSelection.height = selectedHeight;
      _onboardingBloc.userSelection.weight = selectedWeight;
      _onboardingBloc.userSelection.targetWeight = selectedTargetWeight;
      _onboardingBloc.userSelection.heightUsesImperial = heightImperial;
      _onboardingBloc.userSelection.bodyWeightUnit = bodyWeightUnit;
      _onboardingBloc.userSelection.foodUsesImperial = foodImperial;

      _bodyMeasurementsPageButtonActive = active;
    });
  }

  void _setActivityPageData(
    bool active,
    UserActivitySelectionEntity? selectedActivity,
  ) {
    setState(() {
      _onboardingBloc.userSelection.activity = selectedActivity;

      _activityPageButtonActive = active;
    });
  }

  void _setGoalPageData(
    bool active,
    UserGoalSelectionEntity? selectedGoal,
  ) {
    setState(() {
      _onboardingBloc.userSelection.goal = selectedGoal;

      _goalPageButtonActive = active;
    });
  }

  void _setOtherOptionsPageData(
    AppThemeEntity selectedTheme,
    Map<String, bool> foodSourceToggles,
    bool dailyReminderEnabled,
    bool useMaterialYou,
    int? accentColor,
  ) {
    // No setState: nothing on this screen depends on these values and the
    // page's button is always active. The selection is read back when the
    // user finishes onboarding.
    _onboardingBloc.userSelection.appTheme = selectedTheme;
    _onboardingBloc.userSelection.foodSourceToggles = foodSourceToggles;
    _onboardingBloc.userSelection.dailyReminderEnabled = dailyReminderEnabled;
    _onboardingBloc.userSelection.useMaterialYou = useMaterialYou;
    _onboardingBloc.userSelection.accentColor = accentColor;
  }

  void onPageChanged(int page) {
    checkUserDataProvided();
  }

  void checkUserDataProvided() {
    _onboardingBloc.userSelection.checkDataProvided()
        ? _setOverviewPageContent(true)
        : _setOverviewPageContent(false);
  }

  void _setOverviewPageContent(bool active) {
    setState(() {
      _overviewPageButtonActive = active;
    });
  }

  /// Requests the notification permission and schedules the daily reminder
  /// when the user opted in on the "Other options" page. Returns the flag
  /// to persist: false when the user declined the system permission, so
  /// the stored config never claims a reminder that cannot fire.
  Future<bool> _setUpDailyReminder(BuildContext context) async {
    if (!_onboardingBloc.userSelection.dailyReminderEnabled) return false;

    final l10n = S.of(context);
    final notificationService = locator<NotificationService>();
    await notificationService.initialize();
    final granted = await notificationService.requestPermission();
    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notificationsPermissionDeniedSnack)),
        );
      }
      return false;
    }
    // 8:00 matches the default reminder time in ConfigEntity; the user can
    // change it later in Settings → Daily Reminder.
    await notificationService.scheduleDailyReminder(
      hour: 8,
      minute: 0,
      title: l10n.notificationsDailyReminderTitle,
      body: l10n.notificationsDailyReminderBody,
      channelName: l10n.notificationsDailyReminderChannelName,
      channelDescription: l10n.notificationsDailyReminderChannelDescription,
    );
    return true;
  }

  Future<void> _onOverviewStartButtonPressed(BuildContext context) async {
    final userEntity = _onboardingBloc.userSelection.toUserEntity();
    final hasAcceptedDataCollection =
        _onboardingBloc.userSelection.acceptDataCollection;
    final heightImperial = _onboardingBloc.userSelection.heightUsesImperial;
    final bodyWeightUnit = _onboardingBloc.userSelection.bodyWeightUnit;
    final foodImperial = _onboardingBloc.userSelection.foodUsesImperial;
    if (userEntity != null) {
      final dailyReminderEnabled = await _setUpDailyReminder(context);
      await _onboardingBloc.saveOnboardingData(
        userEntity,
        hasAcceptedDataCollection,
        heightImperial,
        bodyWeightUnit,
        foodImperial,
        appTheme: _onboardingBloc.userSelection.appTheme,
        foodSourceToggles: _onboardingBloc.userSelection.foodSourceToggles,
        dailyReminderEnabled: dailyReminderEnabled,
        useMaterialYou: _onboardingBloc.userSelection.useMaterialYou,
        accentColor: _onboardingBloc.userSelection.accentColor,
      );
      if (!context.mounted) return;
      // Onboarding can run for a profile added after the app has been in
      // use, so the screen-persistent tab BLoCs may still hold the previous
      // profile's data. Refresh them against the now-populated active
      // profile before landing on the main screen.
      ProfileSwitchCoordinator.reloadTabBlocs();
      Navigator.pushReplacementNamed(context, NavigationOptions.mainRoute);
    } else {
      // Error with user input
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).onboardingSaveUserError)),
      );
      _scrollToPage(_OnboardingPage.aboutYou);
    }
  }
}
