# Componentes Reutilizaveis

## GridOverlay

Arquivos:

- `scenes/main/main.tscn`
- `scripts/grid_overlay.gd`

Responsabilidade:

- desenhar o grid
- converter mundo <-> celula
- exibir hover e preview de placement

## BuildManager

Arquivo:

- `scripts/main/components/build_manager.gd`

Responsabilidade:

- selecionar o tipo de construcao
- validar ocupacao
- instanciar entidades
- serializar e restaurar entidades

## FactoryEntity

Arquivos:

- `scenes/entities/factory_entity.tscn`
- `scripts/entities/factory_entity.gd`

Responsabilidade:

- representar no mundo uma entidade colocavel
- desenhar footprint, estado de selecao e metadata basica

## BuildHUD

Arquivos:

- `scenes/ui/build_hud.tscn`
- `scripts/ui/build_hud.gd`

Responsabilidade:

- listar estruturas buildaveis
- mostrar item selecionado
- exibir dicas de input e status curto

## SelectionInfoPanel

Arquivos:

- `scenes/ui/selection_info_panel.tscn`
- `scripts/ui/selection_info_panel.gd`

Responsabilidade:

- exibir informacoes da entidade selecionada
- manter o estado de inspecao desacoplado da logica de construcao

## SaveStateManager

Arquivo:

- `scripts/main/components/save_state_manager.gd`

Responsabilidade:

- salvar e carregar o placement atual para iteracao rapida
