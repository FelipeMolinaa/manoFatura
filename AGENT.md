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

## Componentes reutilizaveis

Antes de criar novos sistemas genericos, verificar se algum destes ja atende a necessidade:

- `ConfirmationPopup`
  Arquivos: `scenes/ui/confirmation_popup.tscn` e `scripts/ui/confirmation_popup.gd`
  Uso: confirmacao de acoes destrutivas ou sensiveis por meio de `show_confirmation(...)` e sinal `action_confirmed`
- `MoneySystem`
  Arquivo: `scripts/main/components/money_system.gd`
  Uso: fonte unica do dinheiro atual do jogador, com propriedade `money`, funcoes `spend` e `earn`, e sinal `money_changed`

Ao implementar fluxos de compra, venda, confirmacao ou interacoes semelhantes, preferir reutilizar esses componentes em vez de recriar logica paralela.

## Regras de alteracao

- Nao alterar cenas fora do escopo da tarefa atual
- Preferir mudancas pequenas, incrementais e faceis de revisar
- Preservar comportamento existente quando a tarefa nao pedir refatoracao ampla
- Ao mexer em dados, manter coerencia entre cenas, scripts e documentacao

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

## Estilo de execucao

- Preferir a menor mudanca que entregue valor real
- Evitar alterar sistemas paralelos no mesmo passo sem necessidade
- Atualizar `docs/planejamento.md` e `docs/metas.md` quando a mudanca afetar escopo ou andamento
