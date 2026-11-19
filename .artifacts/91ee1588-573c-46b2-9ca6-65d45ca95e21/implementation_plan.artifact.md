# Plano de Evolução: Sistema de Travas (Locks) e Simplificação de Unidades no Diálogo de Metas

Este documento descreve as alterações para implementar botões de trava (*lock/unlock*) independentes para Calorias e cada um dos 3 macronutrientes, além de simplificar os botões de unidade para `%`, `g` e `g/kg`.

## Revisão Necessária pelo Usuário

> [!IMPORTANT]
> **1. Botões de Trava (Lock):** Cada campo (Calorias, Proteína, Carboidratos e Gordura) terá um botão de trava (`IconButton` com ícone de cadeado). O que estiver travado **não pode mudar** ao alterar outros campos.
> **2. Regras de Recálculo com Travas:**
> - Se **Kcal estiver travada**, alterar Kcal preenche automaticamente os macros não travados (padrão inicial: Proteína = 2g/kg, Gordura = 1g/kg, Carboidratos = restante).
> - Se **Kcal e Proteína estiverem travadas**, alterar Carboidratos ajustará apenas a Gordura.
> - Se **Kcal, Proteína e Carboidratos estiverem travadas**, a Gordura se ajustará automaticamente para fechar a meta calórica exata.
> **3. Simplificação dos Botões de Unidade:** Os botões de unidade global agora exibirão apenas `%`, `g` e `g/kg`.

## Mudanças Propostas

### 1. Refatoração do `SetDayGoalsDialog`
- **[MODIFY]** [set_day_goals_dialog.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/diary/presentation/widgets/set_day_goals_dialog.dart):
  - Adicionar estados booleanos de trava (`_isKcalLocked`, `_isProteinLocked`, `_isCarbsLocked`, `_isFatLocked`).
  - Adicionar ícones de cadeado (`Icons.lock_rounded` / `Icons.lock_open_rounded`) em cada linha (Kcal, Proteína, Carboidratos, Gordura).
  - Implementar o motor de balanceamento que respeita as travas ativas ao recalcular valores.
  - Simplificar os rótulos dos botões de unidade para `%`, `g`, `g/kg`.

## Plano de Verificação

### Testes Automatizados
- Executar `flutter test` para garantir a integridade dos testes do projeto.

### Verificação Manual
- Testar o bloqueio de campos via ícone de cadeado no diálogo de metas do Diário.
- Validar se os cálculos respeitam estritamente os itens travados.
