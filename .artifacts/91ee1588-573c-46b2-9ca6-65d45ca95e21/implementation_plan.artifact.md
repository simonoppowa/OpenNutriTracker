# Plano de Implementação: Suporte a Importação Parcial e Arquivos JSON/CSV Individuais

Este documento descreve as melhorias no motor de importação (`ImportDataUsecase`) para permitir a importação de **arquivos ZIP parciais** (ex: contendo apenas `user_tracked_day.json` ou `user_medication.json`) e a importação de **arquivos individuais `.json` ou `.csv`** diretamente sem a necessidade de criar um ZIP.

## Revisão Necessária pelo Usuário

> [!IMPORTANT]
> **1. Aceitar Arquivos Indivíduais Directamente:** O seletor de arquivos passará a aceitar diretamente arquivos `.json` e `.csv` soltos (ex: selecionar diretamente `user_tracked_day.json` no celular), envelopando o arquivo temporariamente como um pacote de importação válido.
> **2. Suporte a ZIPs Parciais:** Todos os arquivos dentro do ZIP passarão a ser opcionais. Se o ZIP contiver apenas `user_tracked_day.json` (ou apenas `user_medication.json`), o aplicativo importará esses dados com sucesso sem exigir que `user_activity.json` ou `user_intake.json` estejam presentes.

## Mudanças Propostas

### Camada de Domínio / Configurações
- **[MODIFY]** [import_data_usecase.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/settings/domain/usecase/import_data_usecase.dart):
  - Refatorar `_pickAndDecodeArchive()` para detectar se o arquivo selecionado é um `.zip` ou um arquivo individual (`.json` ou `.csv`). Caso seja um arquivo solto, envelopá-lo automaticamente em um objeto de arquivo (`Archive`).
  - Tornar a leitura de `user_activity`, `user_intake` e `user_tracked_day` opcional (retornando lista vazia `[]` caso não estejam no ZIP, em vez de rejeitar todo o arquivo).
  - Garantir que pelo menos 1 arquivo válido seja processado durante a importação.

## Plano de Verificação

### Testes Automatizados
- Executar `flutter test` para validar o comportamento do `ImportDataUsecase` e garantir ausência de erros de regressão.

### Verificação Manual
- Testar a importação de um arquivo `.json` individual (ex: `user_tracked_day.json`) direto pelo menu de importação do celular.
- Testar a importação de um arquivo `.zip` parcial contendo apenas `user_tracked_day.json` ou `user_medication.json`.
