# Componentes Reutilizaveis

Este documento registra componentes genericos do projeto que devem ser reutilizados sempre que possivel.

## 1. ConfirmationPopup

Arquivos:

- `scenes/ui/confirmation_popup.tscn`
- `scripts/ui/confirmation_popup.gd`

Objetivo:

- Exibir confirmacao para acoes destrutivas ou sensiveis
- Centralizar o comportamento de popup de confirmacao em um unico componente

Como usar:

1. Instanciar a cena `confirmation_popup.tscn`
2. Chamar `show_confirmation(action_id, title_text, message, confirm_text, cancel_text)`
3. Escutar o sinal `action_confirmed(action_id)` para executar a acao confirmada

Quando reutilizar:

- destruir entidades
- resetar estado
- vender itens ou estruturas
- confirmar escolhas irreversiveis

Observacao:

- O componente e generico e nao deve conter regra de negocio da acao confirmada
- A regra deve ficar no sistema chamador

## 2. MoneySystem

Arquivo:

- `scripts/main/components/money_system.gd`

Objetivo:

- Ser a fonte unica de verdade para o dinheiro atual do jogador
- Tornar o saldo reativo por meio de sinais

API atual:

- propriedade `money`
- funcao `can_afford(amount: int) -> bool`
- funcao `spend(amount: int) -> bool`
- funcao `earn(amount: int) -> void`
- sinal `money_changed(current_money: int, delta: int)`

Quando reutilizar:

- compra de entidades
- venda de entidades
- recompensas
- custos operacionais
- qualquer UI que precise reagir ao saldo atual

Diretriz de uso:

- Nao duplicar saldo do jogador em outros scripts
- Nao alterar dinheiro diretamente fora do `MoneySystem` quando `spend` ou `earn` forem suficientes
- Preferir escutar `money_changed` para atualizar HUD, feedback visual e outros sistemas dependentes

## 3. InventoryUtils

Arquivo:

- `scripts/data/inventory_utils.gd`

Objetivo:

- Centralizar regras de inventario em funcoes reutilizaveis
- Evitar duplicacao de logica de slots, peso, quantidade maxima e transferencia de itens

API atual:

- funcao `make_empty_slot(label := "") -> Dictionary`
- funcao `make_inventory(slot_labels: Array, max_weight: float = -1.0) -> Dictionary`
- funcao `normalize_inventory(raw_inventory: Variant, default_slot_labels: Array, default_max_weight: float = -1.0, default_max_amount: int = -1, force_slot_count: int = -1) -> Dictionary`
- funcao `duplicate_inventory(inventory: Dictionary) -> Dictionary`
- funcao `get_total_amount(inventory: Dictionary) -> int`
- funcao `get_total_weight(inventory: Dictionary) -> float`
- funcao `get_item_amount(inventory: Dictionary, item_id: String) -> int`
- funcao `get_first_item_id(inventory: Dictionary) -> String`
- funcao `get_addable_amount(inventory: Dictionary, item_id: String, requested_amount: int) -> int`
- funcao `add_item(inventory: Dictionary, item_id: String, requested_amount: int) -> int`
- funcao `remove_item(inventory: Dictionary, item_id: String, requested_amount: int) -> int`

Regras atuais:

- Funcionarios usam 1 slot chamado `Carga` e limite de `5 kg`
- Maquinas usam slots `Entrada` e `Saida`, com limite de `25 kg`
- Baus usam 1 slot chamado `Item`, limite de `250 kg` e limite total de 1 unidade
- `max_weight <= 0` significa sem limite de peso
- `max_amount <= 0` significa sem limite total de quantidade
- `force_slot_count` deve ser usado quando um tipo de entidade precisa reduzir ou fixar a quantidade de slots, como o bau

Quando reutilizar:

- qualquer transferencia de item entre entidades
- qualquer exibicao ou persistencia de inventario
- qualquer regra nova de limite por peso, slots ou quantidade

Diretriz de uso:

- Nao manipular diretamente slots em outros scripts quando `add_item`, `remove_item` ou `get_addable_amount` forem suficientes
- Ao persistir inventario, duplicar o dicionario com `duplicate_inventory`
- Ao carregar inventario de save ou metadata, normalizar com `normalize_inventory`

## 4. SelectionInfoPanel

Arquivos:

- `scenes/ui/selection_info_panel.tscn`
- `scripts/ui/selection_info_panel.gd`

Objetivo:

- Exibir o painel lateral direito de selecao
- Mostrar informacoes e inventario de entidades e funcionarios
- Configurar rotas de funcionarios sem abrir dialogos separados

Comportamento atual:

- O painel fica no canto direito e nao deve sobrepor o menu inferior
- Entidades mostram apenas a aba `Info`
- Funcionarios mostram as abas `Info`, `Ponto A` e `Ponto B`
- A aba atual do funcionario deve ser preservada durante atualizacoes automaticas da rota
- Pontos sem entidade associada exibem local vazio e escondem acao/quantidade
- Pontos associados a `Fonte de Aco` ou entidade com inventario exibem local, acao, quantidade e alternancia `un/%`

Sinais atuais:

- `worker_action_requested(worker_id: String, action_id: String)`
- `entity_move_requested(entity: Node2D)`
- `entity_destroy_requested(entity: Node2D)`
- `entity_config_requested(entity: Node2D)`
- `worker_point_config_changed(worker_id: String, point_kind: String, config: Dictionary)`

Quando reutilizar:

- selecao por clique de entidades
- selecao por clique de funcionarios
- configuracao de `Ponto A` e `Ponto B`
- exibicao de inventarios no HUD lateral

Diretriz de uso:

- O painel nao deve conter a regra de negocio de mover, destruir, configurar receita ou transferir itens
- O painel deve emitir sinais e deixar `main.gd`, `WorkerManager` e demais componentes aplicarem a regra
- Para entidades sem inventario, manter a exibicao de inventario vazia/explicativa em vez de criar inventario artificial

## 5. WorkerManager

Arquivo:

- `scripts/main/components/worker_manager.gd`

Objetivo:

- Gerenciar funcionarios contratados
- Controlar acoes de mundo como reposicionar funcionario e definir `Ponto A`/`Ponto B`
- Calcular pathfinding, desvios e patrulha entre pontos
- Executar coleta e entrega de itens entre entidades

Comportamento atual de rotas:

- `Ponto A` e `Ponto B` podem ser definidos clicando no mapa ou diretamente em uma entidade
- Clique em entidade calcula uma posicao andavel proxima dos bounds da entidade
- A associacao entre ponto e entidade e inferida por proximidade
- Quando uma entidade e movida, pontos associados a ela acompanham o mesmo deslocamento
- Se o movimento de entidade for cancelado, os vinculos temporarios de movimento sao descartados

Comportamento atual de transporte:

- Acao `pickup` pega itens da entidade do ponto
- Acao `dropoff` larga itens na entidade do ponto
- `Fonte de Aco` fornece `aco` como fonte infinita
- Entidades com `inventory_data` respeitam slots, peso e quantidade maxima via `InventoryUtils`
- Quantidade pode ser configurada em unidades (`amount`) ou porcentagem (`percent`)
- Transferencia por porcentagem usa a capacidade como base quando a fonte for infinita

Sinais observados do `BuildManager`:

- `entity_placed`: recalcula rotas
- `entity_move_started`: registra quais pontos estavam associados antes da entidade sair do mapa
- `entity_move_cancelled`: limpa registros temporarios
- `entity_moved`: desloca pontos associados e recalcula rotas
- `entity_sold`: recalcula rotas

Diretriz de uso:

- Nao duplicar logica de transferencia fora do `WorkerManager` sem motivo forte
- Ao adicionar novos tipos de entidade logistica, garantir que tenham `inventory_data` ou tratamento explicito equivalente
- Ao mudar raio de associacao, revisar tambem `SelectionInfoPanel`, que usa regra parecida para exibir o local dos pontos

## 6. BuildManager

Arquivo:

- `scripts/main/components/build_manager.gd`

Objetivo:

- Gerenciar placement, movimento, remocao e estado das entidades no grid
- Aplicar defaults de entidades posicionadas
- Persistir informacoes de entidade relevantes para o save

Comportamento atual:

- Maquinas recebem inventario default e receita default `parafuso`
- Baus recebem inventario default limitado a 1 slot e 1 unidade
- Entidades com `inventory_data` persistem o inventario no estado do mapa
- Entidades movidas preservam metadata, inventario e receita
- Movimento de entidade emite sinais para que os pontos associados de funcionarios acompanhem o deslocamento

Sinais relevantes:

- `building_selected(entity_id: String)`
- `entity_placed(entity_id: String, cell: Vector2i)`
- `entity_move_started(entity: Node2D)`
- `entity_move_cancelled(entity: Node2D)`
- `entity_moved(entity: Node2D, movement_delta: Vector2)`
- `entity_sold(entity_id: String, value: int)`

Diretriz de uso:

- Nao criar defaults de inventario fora do `BuildManager` sem motivo forte
- Ao adicionar nova entidade com inventario, atualizar `_get_default_inventory_for_entity`
- Ao mudar o movimento de entidades, preservar os sinais usados pelo `WorkerManager`

## 7. EntityInteractionController

Arquivo:

- `scripts/main/components/entity_interaction_controller.gd`

Objetivo:

- Centralizar interacoes de clique com entidades e funcionarios
- Emitir selecao para o painel lateral
- Manter o menu suspenso de entidade no botao direito

Comportamento atual:

- Clique esquerdo seleciona entidade ou funcionario quando a interacao esta ativa
- Clique direito em entidade abre o menu suspenso de acoes
- A selecao de entidades pode ser habilitada/desabilitada por `set_allow_entity_selection`
- Em modo `Construir`, a selecao continua disponivel quando nao ha placement pendente

Diretriz de uso:

- Nao espalhar deteccao de clique de selecao por outros scripts sem necessidade
- Regras especificas de acao devem ficar no chamador ou nos managers dedicados
- Usar sinais para manter UI e regras de jogo desacopladas

## 8. SaveStateManager

Arquivo:

- `scripts/main/components/save_state_manager.gd`

Objetivo:

- Persistir e restaurar o estado jogavel do mapa e dos funcionarios

Comportamento atual:

- Salva e carrega inventario de entidades
- Salva e carrega inventario de funcionarios
- Salva e carrega configuracao de `Ponto A` e `Ponto B`
- Codifica `Vector2` dos pontos em dicionarios para persistencia

Diretriz de uso:

- Ao adicionar novo estado persistente em entidade ou funcionario, atualizar encode/decode correspondente
- Ao persistir inventarios, usar `InventoryUtils` para manter o formato normalizado
- Evitar salvar referencias diretas de Node; salvar ids, posicoes ou dicionarios serializaveis

## 9. WorkerAgent

Arquivo:

- `scripts/worker_agent.gd`

Objetivo:

- Representar um funcionario no mundo
- Guardar dados proprios de rota, inventario, movimento e configuracao dos pontos

Comportamento atual:

- Possui `point_a`, `point_b`, `has_point_a` e `has_point_b`
- Possui inventario de carga via `InventoryUtils`
- Possui configuracoes por ponto em `point_configs`
- Exibe visualmente pontos, rota e item carregado no `_draw`
- Serializa dados em `to_data`

Diretriz de uso:

- Manter o `WorkerAgent` focado no estado e comportamento local do funcionario
- Regras de transferencia entre entidades devem continuar no `WorkerManager`
- Ao adicionar novos campos persistentes, atualizar `configure_from_data` e `to_data`

## Regra geral

Antes de criar um novo popup generico, controle de saldo, painel de selecao, inventario ou sistema de transporte, revisar estes componentes e estender o que ja existe quando isso mantiver a arquitetura mais simples.
