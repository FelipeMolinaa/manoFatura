# Sistema - Fundacao Tecnica

## Objetivo

Dar ao projeto uma base previsivel para evolucao incremental com Godot e Codex.

## Responsabilidade

- estruturar cenas e scripts principais
- separar dados estaticos de runtime
- garantir camera, grid, placement e persistencia inicial

## Fora de escopo

- inventario
- trabalhadores
- economia
- simulacao social

## Estados e eventos

- build selecionado
- preview valido ou invalido
- entidade selecionada
- save executado
- load executado

## Integracoes

- `BuildManager`
- `GridOverlay`
- `EntityInteractionController`
- `SaveStateManager`

## Criterios de aceite

- colocar estruturas no grid sem sobreposicao
- selecionar estruturas colocadas
- salvar e recarregar o placement
- manter docs e nomes consistentes
