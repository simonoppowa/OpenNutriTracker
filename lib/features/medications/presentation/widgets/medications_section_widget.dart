import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/dbo/medication_dbo.dart';
import 'package:opennutritracker/core/domain/entity/medication_entity.dart';
import 'package:opennutritracker/core/domain/usecase/delete_medication_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/toggle_medication_taken_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/styles/dimens.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/medications/presentation/widgets/add_medication_dialog.dart';

class MedicationsSectionWidget extends StatelessWidget {
  final DateTime selectedDay;

  const MedicationsSectionWidget({
    super.key,
    required this.selectedDay,
  });

  Future<void> _toggleTaken(MedicationEntity med) async {
    await locator<ToggleMedicationTakenUsecase>().toggleTaken(med.id);
  }

  Future<void> _deleteMedication(MedicationEntity med) async {
    await locator<DeleteMedicationUsecase>().deleteEntry(med.id);
  }

  void _showAddDialog(BuildContext context, [MedicationEntity? med]) {
    showDialog(
      context: context,
      builder: (context) => AddMedicationDialog(
        day: selectedDay,
        medication: med,
        onSaved: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final targetDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.spacing16,
        vertical: Dimens.spacing8,
      ),
      child: ValueListenableBuilder<Box<MedicationDBO>>(
        valueListenable: locator<HiveDBProvider>().medicationBox.listenable(),
        builder: (context, box, _) {
          final medications = box.values
              .where((entry) =>
                  entry.day.year == targetDay.year &&
                  entry.day.month == targetDay.month &&
                  entry.day.day == targetDay.day)
              .map(MedicationEntity.fromMedicationDBO)
              .toList();

          return AppCard(
            padding: const EdgeInsets.all(Dimens.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medication_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: Dimens.spacing8),
                        Text(
                          'Medicamentos',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.spacing8),
                if (medications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Dimens.spacing8),
                    child: Text(
                      'Nenhum medicamento registrado para este dia.',
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: medications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final med = medications[index];
                      final amountStr = med.amount % 1 == 0
                          ? med.amount.toInt().toString()
                          : med.amount.toString();

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Checkbox(
                          value: med.taken,
                          onChanged: (_) => _toggleTaken(med),
                        ),
                        title: Text(
                          med.name,
                          style: TextStyle(
                            decoration: med.taken ? TextDecoration.lineThrough : null,
                            color: med.taken ? Colors.grey : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '$amountStr ${med.unit}',
                          style: TextStyle(
                            color: med.taken ? Colors.grey : null,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _showAddDialog(context, med),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _deleteMedication(med),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
