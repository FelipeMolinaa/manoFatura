# AGENT.md

## Projeto

- Nome: `ManoFatura`
- Engine: `Godot 4.6`
- Linguagem principal: `GDScript`

## Resumo do jogo

Jogo 2D de fabrica com construcao em grid e operacao baseada em funcionarios. O diferencial do projeto e que a logistica e a operacao devem acontecer por meio de funcionarios com movimentacao livre e pathfinding, e nao por esteiras.

## Convencoes de nomes

- Usar `snake_case` para variaveis, funcoes, sinais e nomes de arquivos `.gd`
- Usar `PascalCase` para `class_name`
- Usar ids de dados em `snake_case`, como `fonte_aco` e `valor_compra` somente quando um novo formato interno exigir esse padrao
- Manter nomes exibidos para jogador separados dos ids tecnicos
- Preferir nomes curtos, literais e consistentes com o dominio do jogo

## Estrutura de pastas

- `docs/`: documentacao de produto, planejamento e metas
- `docs/componentes.md`: catalogo de componentes reutilizaveis do projeto
- `scenes/`: cenas do Godot
- `scenes/main/`: cena principal e composicao geral
- `scenes/entities/`: entidades posicionaveis no mapa
- `scripts/`: scripts principais do projeto
- `scripts/data/`: bancos de dados e definicoes estaticas de itens, entidades e receitas
- `scripts/main/components/`: componentes da cena principal, como construcao, interacao, save, dinheiro e funcionarios
- `scripts/ui/`: componentes de interface reutilizaveis

## Componentes reutilizaveis

Antes de criar novos sistemas genericos, verificar se algum destes ja atende a necessidade:

- `ConfirmationPopup`
  Arquivos: `scenes/ui/confirmation_popup.tscn` e `scripts/ui/confirmation_popup.gd`
  Uso: confirmacao de acoes destrutivas ou sensiveis por meio de `show_confirmation(...)` e sinal `action_confirmed`
- `MoneySystem`
  Arquivo: `scripts/main/components/money_system.gd`
  Uso: fonte unica do dinheiro atual do jogador, com propriedade `money`, funcoes `spend` e `earn`, e sinal `money_changed`
- `InventoryUtils`
  Arquivo: `scripts/data/inventory_utils.gd`
  Uso: funcoes puras para criar, normalizar, duplicar e transferir itens em inventarios com limite de slots, peso e quantidade
- `SelectionInfoPanel`
  Arquivos: `scenes/ui/selection_info_panel.tscn` e `scripts/ui/selection_info_panel.gd`
  Uso: painel lateral direito para inspecionar entidades/funcionarios e configurar rotas de funcionarios
- `WorkerManager`
  Arquivo: `scripts/main/components/worker_manager.gd`
  Uso: gerencia contratacao, rotas, pathfinding, acoes de mundo, coleta/entrega e atualizacao dos pontos quando entidades sao movidas

Ao implementar fluxos de compra, venda, confirmacao, inventario, transporte ou interacoes semelhantes, preferir reutilizar esses componentes em vez de recriar logica paralela.

## Regras atuais de logistica e inventario

- Funcionarios possuem inventario de 1 slot chamado `Carga` e limite de `5 kg`
- Maquinas possuem inventario interno com slots `Entrada` e `Saida`
- Baus possuem 1 slot chamado `Item` e limite de 1 unidade total
- `Fonte de Aco` funciona como fonte infinita de `aco` e nao precisa de inventario persistido
- Acoes de rota de funcionarios usam `point_a` e `point_b`
- Cada ponto pode configurar `action`, `quantity_mode`, `quantity_value` e `item_id`
- `quantity_mode` pode ser `amount` para unidades ou `percent` para porcentagem
- Ao clicar em uma entidade com `Ponto A` ou `Ponto B` pendente, o ponto deve ser colocado em uma posicao andavel proxima da entidade
- Se uma entidade que possui pontos associados for movida, os pontos associados devem acompanhar o mesmo deslocamento da entidade
- A associacao entre ponto e entidade e inferida pela proximidade com os bounds da entidade; evitar criar estado paralelo de vinculo sem necessidade clara

## Regras atuais de selecao e UI

- O painel de selecao fica no lado direito da tela e nao deve sobrepor o menu inferior
- Entidades selecionadas mostram apenas a aba `Info`
- Funcionarios selecionados mostram as abas `Info`, `Ponto A` e `Ponto B`
- O painel nao deve trocar de aba sozinho quando o funcionario alterna entre `Ponto A` e `Ponto B`
- Em modo `Camera`, o jogador pode selecionar entidades e funcionarios
- Em modo `Construir`, o jogador tambem pode selecionar entidades e funcionarios quando nao houver placement pendente
- O botao direito em entidades selecionaveis deve abrir o menu suspenso de acoes da entidade
- O painel de entidade deve exibir informacoes e inventario quando a entidade possuir `inventory_data`
- O painel de funcionario deve exibir inventario/carga e permitir configurar acao e quantidade de cada ponto

## Regras de alteracao

- Nao alterar cenas fora do escopo da tarefa atual
- Preferir mudancas pequenas, incrementais e faceis de revisar
- Preservar comportamento existente quando a tarefa nao pedir refatoracao ampla
- Ao mexer em dados, manter coerencia entre cenas, scripts e documentacao
- Ao alterar inventario, rotas ou selecao, atualizar `docs/componentes.md` quando a regra afetar componentes reutilizaveis

## Checklist de impacto em cada mudanca

Sempre explicar no resumo final se houve impacto em:

- input
- fisica
- sinais

Se nao houver impacto, dizer explicitamente que nao houve.

## Validacao

- Sempre validar o fluxo principal afetado pela mudanca
- Em alteracoes de construcao, validar selecao, preview, placement e ocupacao
- Em alteracoes de entidade, validar spawn, exibicao visual e integracao com dados
- Em alteracoes de UI, validar navegação basica e feedback visual principal
- Em alteracoes de logistica, validar ponto A/B, coleta, entrega, limites de peso/quantidade e movimentacao de entidades com pontos associados

## Estilo de execucao

- Preferir a menor mudanca que entregue valor real
- Evitar alterar sistemas paralelos no mesmo passo sem necessidade
- Atualizar `docs/planejamento.md` e `docs/metas.md` quando a mudanca afetar escopo ou andamento
