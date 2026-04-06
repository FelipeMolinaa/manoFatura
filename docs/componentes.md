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

## Regra geral

Antes de criar um novo popup generico ou um novo controle de saldo, revisar estes componentes e estender o que ja existe quando isso mantiver a arquitetura mais simples.
