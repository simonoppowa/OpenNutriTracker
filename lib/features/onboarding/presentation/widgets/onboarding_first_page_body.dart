import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/features/onboarding/domain/entity/user_gender_selection_entity.dart';
import 'package:opennutritracker/generated/l10n.dart';

class OnboardingFirstPageBody extends StatefulWidget {
  final Function(
          bool active, UserGenderSelectionEntity? gender, DateTime? birthday)
      setPageContent;

  const OnboardingFirstPageBody({super.key, required this.setPageContent});

  @override
  State<OnboardingFirstPageBody> createState() =>
      _OnboardingFirstPageBodyState();
}

class _OnboardingFirstPageBodyState extends State<OnboardingFirstPageBody> {
  final _dateInput = TextEditingController();
  DateTime? _selectedDate;

  bool _maleSelected = false;
  bool _femaleSelected = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context).genderLabel,
              style: Theme.of(context).textTheme.headlineSmall),
          Text(S.of(context).onboardingGenderQuestionSubtitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16.0),
          ChoiceChip(
            label: Text(S.of(context).genderMaleLabel),
            selected: _maleSelected,
            onSelected: (bool selected) {
              setState(() {
                _maleSelected = true;
                _femaleSelected = false;
                checkCorrectInput();
              });
            },
          ),
          ChoiceChip(
            label: Text(S.of(context).genderFemaleLabel),
            selected: _femaleSelected,
            onSelected: (bool selected) {
              setState(() {
                _maleSelected = false;
                _femaleSelected = true;
                checkCorrectInput();
              });
            },
          ),
          const SizedBox(height: 32.0),
          Text(S.of(context).ageLabel,
              style: Theme.of(context).textTheme.headlineSmall),
          Text(S.of(context).onboardingBirthdayQuestionSubtitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16.0),
          TextFormField(
            controller: _dateInput,
            readOnly: true,
            decoration: InputDecoration(
              hintText: S.of(context).onboardingEnterBirthdayLabel,
              labelText: S.of(context).onboardingEnterBirthdayLabel,
              prefixIcon: const Icon(Icons.calendar_month_outlined),
              //fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onTap: onDateInputClicked,
          ),
        ],
      ),
    );
  }

  void onDateInputClicked() async {
    final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2100));
    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        _selectedDate = pickedDate;
        _dateInput.text = formattedDate;
        checkCorrectInput();
      });
    }
  }

  void checkCorrectInput() {
    UserGenderSelectionEntity? selectedGender;
    if (_maleSelected) {
      selectedGender = UserGenderSelectionEntity.genderMale;
    } else if (_femaleSelected) {
      selectedGender = UserGenderSelectionEntity.genderFemale;
    }

    if (selectedGender != null && _selectedDate != null) {
      widget.setPageContent(true, selectedGender, _selectedDate);
    } else {
      widget.setPageContent(false, null, null);
    }
  }
}
