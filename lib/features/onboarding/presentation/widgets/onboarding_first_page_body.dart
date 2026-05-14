import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/calories_profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/presentation/sources_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/calories_profile_info_dialog.dart';
import 'package:opennutritracker/core/utils/bounds/validator.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_gender_selection_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingFirstPageBody extends StatefulWidget {
  final Function(
    bool active,
    UserGenderSelectionEntity? gender,
    CaloriesProfileEntity? caloriesProfile,
    DateTime? birthday,
  ) setPageContent;

  final UserGenderSelectionEntity? initialGender;
  final CaloriesProfileEntity? initialCaloriesProfile;
  final DateTime? initialBirthday;

  const OnboardingFirstPageBody({
    super.key,
    required this.setPageContent,
    this.initialGender,
    this.initialCaloriesProfile,
    this.initialBirthday,
  });

  @override
  State<OnboardingFirstPageBody> createState() =>
      _OnboardingFirstPageBodyState();
}

class _OnboardingFirstPageBodyState extends State<OnboardingFirstPageBody> {
  final _dateInput = TextEditingController();
  DateTime? _selectedDate;

  UserGenderSelectionEntity? _selectedGender;
  CaloriesProfileEntity? _selectedCaloriesProfile;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGender;
    _selectedCaloriesProfile = widget.initialCaloriesProfile;
    _selectedDate = widget.initialBirthday;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedDate != null && _dateInput.text.isEmpty) {
      _dateInput.text =
          MaterialLocalizations.of(context).formatCompactDate(_selectedDate!);
    }
  }

  UserGenderEntity _toEntity(UserGenderSelectionEntity selection) {
    switch (selection) {
      case UserGenderSelectionEntity.genderMale:
        return UserGenderEntity.male;
      case UserGenderSelectionEntity.genderFemale:
        return UserGenderEntity.female;
      case UserGenderSelectionEntity.genderNonBinary:
        return UserGenderEntity.nonBinary;
    }
  }

  void _onGenderSelected(UserGenderSelectionEntity selection) {
    setState(() {
      _selectedGender = selection;
      if (selection != UserGenderSelectionEntity.genderNonBinary) {
        _selectedCaloriesProfile = null;
      }
      checkCorrectInput();
    });
  }

  Future<void> _openCaloriesProfileDialog() async {
    final selected = await showDialog<CaloriesProfileEntity>(
      context: context,
      builder: (context) => CaloriesProfileInfoDialog(
        initialProfile:
            _selectedCaloriesProfile ?? CaloriesProfileEntity.averaged,
      ),
    );
    if (selected == null) return;
    setState(() {
      _selectedCaloriesProfile = selected;
      checkCorrectInput();
    });
  }

  @override
  Widget build(BuildContext context) {
    final showNonBinaryNotice =
        _selectedGender == UserGenderSelectionEntity.genderNonBinary;
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                S.of(context).genderLabel,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: S.of(context).sourcesIconTooltip,
                icon: const Icon(Icons.info_outline),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SourcesScreen()),
                ),
              ),
            ],
          ),
          Text(
            S.of(context).onboardingGenderQuestionSubtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildGenderChip(UserGenderSelectionEntity.genderMale),
              _buildGenderChip(UserGenderSelectionEntity.genderFemale),
              _buildGenderChip(UserGenderSelectionEntity.genderNonBinary),
            ],
          ),
          if (showNonBinaryNotice) ...[
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          S.of(context).onboardingNonBinaryDisclaimer,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _openCaloriesProfileDialog,
                      icon: const Icon(Icons.tune_outlined, size: 18),
                      label: Text(
                        (_selectedCaloriesProfile ??
                                CaloriesProfileEntity.averaged)
                            .getName(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32.0),
          Text(
            S.of(context).ageLabel,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            S.of(context).onboardingBirthdayQuestionSubtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16.0),
          Semantics(
            identifier: 'onboarding-birthday-field',
            child: TextFormField(
              controller: _dateInput,
              readOnly: true,
              decoration: InputDecoration(
                hintText: S.of(context).onboardingEnterBirthdayLabel,
                labelText: S.of(context).onboardingEnterBirthdayLabel,
                prefixIcon: const Icon(Icons.calendar_month_outlined),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onTap: onDateInputClicked,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(UserGenderSelectionEntity selection) {
    final entity = _toEntity(selection);
    return Semantics(
      identifier: 'onboarding-gender-${selection.name}',
      child: ChoiceChip(
        label: Text(entity.getName(context)),
        avatar: entity.getIcon(size: 18),
        selected: _selectedGender == selection,
        onSelected: (_) => _onGenderSelected(selection),
      ),
    );
  }

  void onDateInputClicked() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: ValueValidator.getLastDate(),
      firstDate: ValueValidator.getFirstDate(),
      lastDate: ValueValidator.getLastDate(),
    );
    if (pickedDate == null || !mounted) return;
    final localizations = MaterialLocalizations.of(context);
    final formattedDate = localizations.formatCompactDate(pickedDate);
    setState(() {
      _selectedDate = pickedDate;
      _dateInput.text = formattedDate;
      checkCorrectInput();
    });
  }

  void checkCorrectInput() {
    if (_selectedGender != null && _selectedDate != null) {
      widget.setPageContent(
        true,
        _selectedGender,
        _selectedCaloriesProfile,
        _selectedDate,
      );
    } else {
      widget.setPageContent(false, null, null, null);
    }
  }
}
