import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/generated/l10n.dart';

class ImportTemplatesDialog extends StatefulWidget {
  const ImportTemplatesDialog({super.key});

  @override
  State<ImportTemplatesDialog> createState() => _ImportTemplatesDialogState();
}

class _ImportTemplatesDialogState extends State<ImportTemplatesDialog> {
  int _selectedFormatIndex = 0; // 0 = JSON, 1 = CSV
  int _selectedCategoryIndex = 0; // 0 = Metas, 1 = Medicamentos, 2 = Refeições, 3 = Atividades

  static const _jsonTrackedDayTemplate = '''[
  {
    "day": "2026-11-20T00:00:00.000",
    "calorieGoal": 1800.0,
    "caloriesTracked": 0.0,
    "carbsGoal": 150.0,
    "carbsTracked": 0.0,
    "fatGoal": 60.0,
    "fatTracked": 0.0,
    "proteinGoal": 160.0,
    "proteinTracked": 0.0
  }
]''';

  static const _csvTrackedDayTemplate = '''day,calorie_goal,calories_tracked,carbs_goal,carbs_tracked,fat_goal,fat_tracked,protein_goal,protein_tracked
2026-11-20T00:00:00.000,1800.0,0.0,150.0,0.0,60.0,0.0,160.0,0.0''';

  static const _jsonMedicationTemplate = '''[
  {
    "id": "med-1700000000000",
    "day": "2026-11-20T00:00:00.000",
    "name": "Vitamina D",
    "amount": 10.0,
    "unit": "mL",
    "taken": false
  }
]''';

  static const _csvMedicationTemplate = '''id,day,name,amount,unit,taken
med-1700000000000,2026-11-20T00:00:00.000,Vitamina D,10.0,mL,false''';

  static const _jsonIntakeTemplate = '''[
  {
    "id": "intake-uuid-12345",
    "unit": "g",
    "amount": 150.0,
    "type": "breakfast",
    "dateTime": "2026-11-20T08:00:00.000",
    "meal": {
      "code": "123456789",
      "name": "Arroz Integral Cozido",
      "brands": "Marca Exemplo",
      "mealQuantity": "100",
      "mealUnit": "g",
      "source": "custom",
      "nutriments": {
        "energyKcal100": 130.0,
        "carbohydrates100": 28.0,
        "fat100": 1.0,
        "proteins100": 2.7
      }
    }
  }
]''';

  static const _csvIntakeTemplate = '''id,date_time,type,amount,unit,meal_code,meal_name,meal_brands,meal_source,meal_quantity,meal_unit,kcal_per_100g,carbs_per_100g,fat_per_100g,protein_per_100g
intake-uuid-12345,2026-11-20T08:00:00.000,breakfast,150.0,g,123456789,Arroz Integral Cozido,Marca Exemplo,custom,100,g,130.0,28.0,1.0,2.7''';

  static const _jsonActivityTemplate = '''[
  {
    "id": "act-uuid-67890",
    "duration": 45.0,
    "burnedKcal": 300.0,
    "date": "2026-11-20T18:00:00.000",
    "physicalActivityDBO": {
      "code": "01010",
      "specificActivity": "Corrida 8km/h",
      "description": "Corrida moderada",
      "mets": 8.0,
      "tags": ["cardio"],
      "type": "running"
    }
  }
]''';

  static const _csvActivityTemplate = '''id,date,duration,burned_kcal,activity_code,specific_activity,description,mets,tags,type
act-uuid-67890,2026-11-20T18:00:00.000,45.0,300.0,01010,Corrida 8km/h,Corrida moderada,8.0,cardio,running''';

  String _getFileName() {
    final isJson = _selectedFormatIndex == 0;
    switch (_selectedCategoryIndex) {
      case 0:
        return isJson ? 'user_tracked_day.json' : 'user_tracked_day.csv';
      case 1:
        return isJson ? 'user_medication.json' : 'user_medication.csv';
      case 2:
        return isJson ? 'user_intake.json' : 'user_intake.csv';
      case 3:
        return isJson ? 'user_activity.json' : 'user_activity.csv';
      default:
        return 'template.txt';
    }
  }

  String _getTemplateText() {
    final isJson = _selectedFormatIndex == 0;
    switch (_selectedCategoryIndex) {
      case 0:
        return isJson ? _jsonTrackedDayTemplate : _csvTrackedDayTemplate;
      case 1:
        return isJson ? _jsonMedicationTemplate : _csvMedicationTemplate;
      case 2:
        return isJson ? _jsonIntakeTemplate : _csvIntakeTemplate;
      case 3:
        return isJson ? _jsonActivityTemplate : _csvActivityTemplate;
      default:
        return '';
    }
  }

  void _copyToClipboard() {
    final text = _getTemplateText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modelo para ${_getFileName()} copiado com sucesso!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Modelos de Importação (Templates)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha o formato e a categoria para visualizar e copiar o modelo. Salve o arquivo com o nome indicado e compacte em um arquivo .zip antes de importar.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Center(
              child: ToggleButtons(
                isSelected: [
                  _selectedFormatIndex == 0,
                  _selectedFormatIndex == 1,
                ],
                onPressed: (index) {
                  setState(() => _selectedFormatIndex = index);
                },
                constraints: const BoxConstraints(minHeight: 32, minWidth: 80),
                children: const [
                  Text('JSON'),
                  Text('CSV'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ToggleButtons(
                isSelected: [
                  _selectedCategoryIndex == 0,
                  _selectedCategoryIndex == 1,
                  _selectedCategoryIndex == 2,
                  _selectedCategoryIndex == 3,
                ],
                onPressed: (index) {
                  setState(() => _selectedCategoryIndex = index);
                },
                constraints: const BoxConstraints(minHeight: 32, minWidth: 80),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Metas'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Medicamentos'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Refeições'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Atividades'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nome do Arquivo: ${_getFileName()}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Copiar Modelo',
                  onPressed: _copyToClipboard,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _getTemplateText(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.dialogOKLabel),
        ),
      ],
    );
  }
}
