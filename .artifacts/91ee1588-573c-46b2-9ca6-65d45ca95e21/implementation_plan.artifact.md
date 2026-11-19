# Plano de Implementação: Novo Módulo de Medicamentos

Este documento descreve a arquitetura e o plano de implementação para o novo módulo de **Medicamentos** no OpenNutriTracker, permitindo o acompanhamento diário de doses (`mL`, `mg`, `mcg`) com marcação de concluído (*checkbox*), integrado tanto no **Diário** quanto na **Home**.

## Revisão Necessária pelo Usuário

> [!IMPORTANT]
> **1. Armazenamento Local (Hive):** Será criado um novo objeto DBO (`MedicationDBO`) e uma nova Hive Box (`MedicationBox`), salvos por perfil de usuário.
> **2. Flexibilidade por Dia:** Cada registro de medicamento pertence a um dia específico (`day`), permitindo doses variáveis conforme o dia (ex: 10 mL hoje, 15 mL amanhã).
> **3. Unidades de Medida:** Suporte estrito às unidades `mL`, `mg` e `mcg`.
> **4. Diário e Home:** O painel de medicamentos será exibido no Diário (para a data selecionada) e na Home (para o dia atual), contendo caixas de seleção (*checkboxes*) para marcar facilmente se já tomou ou não.

## Questões em Aberto

- Nenhuma questão pendente; o escopo atende a acompanhamento simples com unidades em mL, mg e mcg e checagem diária.

## Mudanças Propostas

### 1. Camada de Dados (`core/data`)
- **[NEW]** [medication_dbo.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/core/data/dbo/medication_dbo.dart): Objeto Hive annotado (`typeId` livre, ex: 31) com campos `id`, `day`, `name`, `amount`, `unit` e `taken`.
- **[MODIFY]** [hive_db_provider.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/core/utils/hive_db_provider.dart): Registrar a nova `medicationBoxName` e incluí-la em `perProfileBoxNames`.
- **[NEW]** [medication_data_source.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/core/data/data_source/medication_data_source.dart): Acesso à Hive Box de medicamentos.
- **[NEW]** [medication_repository.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/core/data/repository/medication_repository.dart): Repositório mediador.

### 2. Camada de Domínio (`core/domain`)
- **[NEW]** [medication_entity.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/core/domain/entity/medication_entity.dart): Entidade de domínio.
- **[NEW]** Casos de uso: `AddMedicationUsecase`, `GetMedicationUsecase`, `DeleteMedicationUsecase`, `ToggleMedicationTakenUsecase`.

### 3. Camada de Apresentação (UI e BLoC)
- **[NEW]** [add_medication_dialog.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/medications/presentation/widgets/add_medication_dialog.dart): Diálogo para incluir/editar medicamento (Nome, Quantidade, Unidade: mL/mg/mcg).
- **[NEW]** [medications_section_widget.dart](file:///C:/Users/Alec/Desktop/repos_git/OpenNutriTracker/lib/features/medications/presentation/widgets/medications_section_widget.dart): Widget de lista com *checkboxes* para marcar os medicamentos como tomados.
- **[MODIFY]** Integração na `DayInfoWidget` (Diário) e `HomePage` / `HomeBloc` (Home).

## Plano de Verificação

### Testes Automatizados
- Executar `flutter test` após a geração dos adaptadores do Hive (`just build` / `build_runner`).

### Verificação Manual
- Adicionar medicamentos com diferentes unidades (`mL`, `mg`, `mcg`) no Diário.
- Marcar e desmarcar o *checkbox* de tomados.
- Verificar a exibição na tela Home.
