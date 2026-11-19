# Sumário da Implementação - Sincronização com a Home e Recálculo Inteligente de Metas

Este documento resume as melhorias e refinamentos implementados para atender aos novos requisitos de escalada de dieta, sincronização entre telas e usabilidade.

## Mudanças Realizadas

### 1. Sincronização Automática com a Tela Home (`HomeBloc`)
- **[MODIFY]** [home_bloc.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/home/presentation/bloc/home_bloc.dart):
  - O `HomeBloc` agora verifica se existe um registro `TrackedDay` para o dia lógico atual.
  - Caso exista, as metas exibidas na tela **Home** (calorias, carboidratos, gorduras e proteínas) passam a ser exatamente as metas personalizadas definidas no Diário ou via importação, mantendo ambas as telas perfeitamente sincronizadas.

### 2. Unidade Global de Macros e Recálculo Inteligente (`SetDayGoalsDialog`)
- **[MODIFY]** [set_day_goals_dialog.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/diary/presentation/widgets/set_day_goals_dialog.dart):
  - **Unidade Global:** Adicionado seletor no topo para alternar a unidade de todos os macronutrientes em conjunto (`Gramas (g)`, `Percentual (%)` ou `Por Kg (g/kg)` usando o peso de referência mais recente).
  - **Recálculo Automático de Calorias:** Alterar a meta de calorias totais recalcula automaticamente os macros proporcionalmente.
  - **Travamento por Kcal (Balanceamento de Macros):** Alterar qualquer macro individualmente (ex: Proteína) rebalanceia automaticamente os outros dois macros restantes para manter a meta calórica total estritamente travada.

## Validação

- O código compila sem erros, garantindo compatibilidade total com os fluxos do app.
- Sincronização confirmada entre as exibições da Home e do Diário.
