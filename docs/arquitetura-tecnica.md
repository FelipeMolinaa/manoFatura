# Arquitetura Tecnica

## Visao atual

O projeto foi dividido em quatro camadas iniciais:

- `data`: catalogos estaticos de itens, entidades e receitas
- `world`: grid, entidades colocadas e interacao de mundo
- `ui`: HUD, selecao e feedback
- `main/components`: coordenadores de camera, construcao, selecao e persistencia

## Contratos iniciais

### Entidade de fabrica

Toda entidade colocavel precisa fornecer:

- `entity_id`
- `display_name`
- `footprint_cells`
- `placement_cell`
- `cost`
- `contains_global_point(world_position)`
- `to_data()`

### BuildManager

Responsavel por:

- manter o build selecionado
- validar ocupacao no grid
- instanciar entidades
- serializar e restaurar entidades

Sinais atuais:

- `building_selected(entity_id: String)`
- `entity_placed(entity: FactoryEntity)`
- `entities_reloaded()`

### EntityInteractionController

Responsavel por:

- detectar clique em entidades
- manter a selecao atual
- emitir mudanca de selecao

### SaveStateManager

Responsavel por:

- salvar e carregar o estado de entidades no `user://save_game.json`

## Limites atuais

- ainda nao existe trabalhador
- ainda nao existe inventario
- ainda nao existe economia
- entidades sao placeholders visuais com footprint e metadata
