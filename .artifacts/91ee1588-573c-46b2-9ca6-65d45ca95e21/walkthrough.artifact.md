# Sumário da Implementação - Suporte a ZIPs Parciais e Arquivos Soltos (`.json` e `.csv`)

Este documento resume o aprimoramento do motor de importação do OpenNutriTracker.

## Mudanças Realizadas

### 1. Suporte a Arquivos Soltos (`.json` e `.csv`)
- **[MODIFY]** [import_data_usecase.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/settings/domain/usecase/import_data_usecase.dart):
  - Atualizado o método `_pickAndDecodeArchive()` para identificar quando o usuário escolhe um arquivo individual `.json` ou `.csv` (ex: selecionar diretamente `user_tracked_day.json` ou `user_medication.json` no celular).
  - O arquivo individual é envelopado automaticamente em um pacote de arquivo (`Archive`), dispensando a necessidade de compactar em `.zip` previamente.

### 2. Importação Parcial de ZIPs
- **[MODIFY]** [import_data_usecase.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/settings/domain/usecase/import_data_usecase.dart):
  - Tornadas opcionais as entradas `user_activity`, `user_intake` e `user_tracked_day`.
  - Se um arquivo `.zip` contiver apenas o `user_tracked_day.json` ou apenas o `user_medication.json`, o aplicativo importa os dados presentes sem rejeitar o arquivo por falta das demais tabelas.

## Validação

- Código compilado e verificado via `flutter test`.
- O motor aceita agora tanto `.zip` completos/parciais quanto arquivos soltos `.json`/`.csv`.
