# Sistema - Construcao

## Objetivo

Controlar o placement inicial de estruturas e preparar a expansao futura para zonas, pisos e modulos de ambiente.

## Modelo atual

- o jogador seleciona uma estrutura no `BuildHUD`
- o cursor mostra preview no `GridOverlay`
- o `BuildManager` valida ocupacao por footprint
- uma `FactoryEntity` e instanciada no mundo

## Entradas

- `entity_id`
- celula alvo

## Saidas

- instancia colocada no container de entidades
- erro de placement quando a area esta ocupada

## Riscos futuros

- mistura entre placement de estruturas e placement de pisos
- necessidade de layers separadas para construcao, decoracao e zona funcional

