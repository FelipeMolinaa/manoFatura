# Sistema - Dados Estaticos

## Objetivo

Centralizar ids, nomes e metadata de itens, receitas e entidades.

## Regras

- ids tecnicos sao estaveis
- nomes exibidos ficam nos catalogos, nao hardcoded na UI
- receitas referenciam itens por id
- entidades buildaveis referenciam cor, custo e footprint

## Catalogos atuais

- `EntityDatabase`
- `ItemDatabase`
- `RecipeDatabase`

## Expansao prevista

- validadores de consistencia
- dependencias de progressao
- grupos de tags por item e por entidade
