# Plano de Evolução: Metas Personalizadas, Sincronização com a Home e Ajustes Automáticos de Macros

Este documento descreve as melhorias solicitadas na interface de configuração de metas diárias e na sincronização com a tela inicial (Home).

## Revisão Necessária pelo Usuário

> [!IMPORTANT]
> **1. Unidade Global de Macros:** A escolha da unidade (`%`, `g`, `g/kg`) passa a ser **global** para todos os macronutrientes em conjunto, e não mais individual por macro.
> **2. Cálculo Automático e Travas:**
> - Alterar as **Calorias (kcal)** recalcula automaticamente os 3 macros mantendo a proporção.
> - **Travado por Kcal (padrão):** Alterar um macro (ex: Proteína) recalcula automaticamente os outros dois para manter a meta calórica total inalterada.
> - **Travado por Macros:** Alterar os macros recalcula automaticamente a meta de calorias total (`kcal = carbs * 4 + protein * 4 + fat * 9`).
> **3. Sincronização com a Home:** O `HomeBloc` passará a verificar se existe um `TrackedDay` para o dia atual; se houver, usará as metas personalizadas (sejam definidas via UI no Diário ou via importação), sincronizando perfeitamente as telas de Diário e Home.

## Mudanças Propostas

### 1. Sincronização na Home
- **[MODIFY]** [home_bloc.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/home/presentation/bloc/home_bloc.dart):
  - Consultar `GetTrackedDayUsecase` para o dia lógico atual (`today`).
  - Se um `TrackedDay` com metas personalizadas existir, utilizá-lo como fonte principal para `totalKcalGoal`, `totalCarbsGoal`, `totalFatsGoal`, `totalProteinsGoal`. Caso contrário, manter o cálculo padrão via perfil.

### 2. Redesenho do Diálogo de Metas (`SetDayGoalsDialog`)
- **[MODIFY]** [set_day_goals_dialog.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/diary/presentation/widgets/set_day_goals_dialog.dart):
  - Inserir seletor global de unidade (`%`, `g`, `g/kg`) no topo.
  - Implementar lógica inteligente de rebalanceamento automático (ao mudar kcal, recalcular macros; ao mudar um macro, recalcular os demais mantendo kcal travada; ou opcionalmente recalcular kcal se travado por macros).

## Plano de Verificação

### Testes Automatizados
- Executar `flutter test` para validar o comportamento dos blocos e lógica de cálculo.

### Verificação Manual
- Testar alteração de calorias na tela de Diário e verificar recálculo automático dos macros.
- Testar alteração de um macro e verificar rebalanceamento dos demais mantendo a kcal total.
- Verificar se as alterações feitas no Diário refletem imediatamente na tela **Home**.
