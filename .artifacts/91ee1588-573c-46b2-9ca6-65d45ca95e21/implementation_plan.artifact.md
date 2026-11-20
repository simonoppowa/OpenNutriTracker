# Plano de Implementação: Botão de Modelos (Templates) e Importação/Exportação de Medicamentos

Este documento descreve a adição do botão de **Modelos de Importação (Templates)** no diálogo de Importação/Exportação (`ExportImportDialog`) e o suporte completo a importação/exportação de medicamentos (`user_medication.json` e `user_medication.csv`).

## Revisão Necessária pelo Usuário

> [!IMPORTANT]
> **1. Importação/Exportação de Medicamentos:** Adicionar suporte a `user_medication.json` e `user_medication.csv` no `ImportDataUsecase` e `ExportDataUsecase` para backup/restauração completa do módulo de medicamentos.
> **2. Botão de Templates:** No menu **Configurações → Importar/Exportar dados do app**, será adicionado o botão **"Modelos de Importação"**.
> **3. Diálogo de Modelos (`ImportTemplatesDialog`):**
> - Exibirá modelos prontos para **Metas Diárias** (`user_tracked_day`), **Medicamentos** (`user_medication`), **Alimentos/Refeições** (`user_intake`) e **Atividades** (`user_activity`).
> - Permitirá alternar entre os formatos **JSON** e **CSV**.
> - Incluirá o botão **"Copiar Modelo"** para copiar o código diretamente para a área de transferência.

## Questões em Aberto

- Nenhuma questão pendente.

## Mudanças Propostas

### 1. Suporte a Importação/Exportação do Módulo de Medicamentos
- **[MODIFY]** [export_data_usecase.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/settings/domain/usecase/export_data_usecase.dart): Incluir `user_medication.json` e `user_medication.csv` no zip de exportação.
- **[MODIFY]** [import_data_usecase.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/settings/domain/usecase/import_data_usecase.dart): Ler `user_medication.json` / `user_medication.csv` do zip (se presente) e importar via `MedicationRepository`.

### 2. Interface de Usuário
- **[NEW]** [import_templates_dialog.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/settings/presentation/widgets/import_templates_dialog.dart): Diálogo para visualizar e copiar modelos de importação (JSON/CSV) com suporte a cópia via `Clipboard.setData`.
- **[MODIFY]** [export_import_dialog.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/settings/presentation/widgets/export_import_dialog.dart): Adicionar o botão **"Modelos de Importação"** nas ações do diálogo.

## Plano de Verificação

### Testes Automatizados
- Executar `flutter test` para validar a compilação e suíte de testes.

### Verificação Manual
- Abrir o diálogo de Importação/Exportação e testar os modelos no novo diálogo.
- Testar exportação e importação de arquivo `.zip` contendo `user_medication.json` ou `user_medication.csv`.
