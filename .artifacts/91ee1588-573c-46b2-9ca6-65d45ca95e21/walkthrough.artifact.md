# Sumário da Implementação - Sistema de Travas (Locks) e Simplificação de Unidades

Este documento resume as melhorias implementadas no diálogo de definição de metas diárias (`SetDayGoalsDialog`).

## Mudanças Realizadas

### 1. Sistema de Travas Independentes (Locks)
- **[MODIFY]** [set_day_goals_dialog.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/diary/presentation/widgets/set_day_goals_dialog.dart):
  - Adicionado um botão de cadeado (`lock_rounded` / `lock_open_rounded`) ao lado de cada campo (Calorias, Proteína, Carboidratos e Gordura).
  - O campo travado fica bloqueado para edição direta (`readOnly: true`) e serve como âncora fixa para o motor de balanceamento.
  - Se Kcal estiver travada, alterar um macro rebalanceia automaticamente os demais macros livres para manter a meta calórica exata. Se múltiplos campos estiverem travados, o algoritmo distribui proporcionalmente o restante entre os campos livres remanescentes.

### 2. Inicialização com Padrões Inteligentes
- Dias sem metas personalizadas iniciam automaticamente com valores sugeridos com base no peso corporal (Proteína = 2.0 g/kg, Gordura = 1.0 g/kg e o restante preenchido com Carboidratos).

### 3. Simplificação das Unidades
- Os botões de unidade global foram simplificados para exibir apenas **`g`**, **`%`** e **`g/kg`**.

## Validação

- O código compila com sucesso e o comportamento das travas e recálculo automático foi validado.
