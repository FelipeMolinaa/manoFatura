# Planejamento Inicial - ManoFatura

## 1. Visao do Projeto

Criar um jogo 2D de fabrica no estilo Factorio, com camera de cima levemente inclinada e grid visivel no chao.

Diferenca central do projeto:

- Toda acao operacional da fabrica deve ser executada por funcionarios.
- Funcionarios operam maquinas.
- Funcionarios transportam itens entre entidades.
- Funcionarios se locomovem com pathfinding e nao precisam obedecer rigidamente ao grid.

O grid serve como referencia de construcao e ocupacao de espaco. Exemplo inicial: uma maquina pequena ocupa `2x2` tiles.

## 2. Escopo Inicial

### Entidades

- `Maquina`
- `Bau`
- `Fonte infinita` (pode reutilizar a base de bau com comportamento especial)
- `Vendedor`
- `Funcionario`

### Itens

- `Aco`
- `Parafuso`
- `Viga`

### Receitas iniciais

- `1 aco -> 15 parafusos`
- `5 aco -> 1 viga`

### Peso dos itens

- `Aco`: `1 kg`
- `Parafuso`: `1 g`
- `Viga`: 5kg 

### Regras de funcionario

- Cada funcionario possui inventario de `1 item`
- Cada funcionario possui capacidade maxima de carga de `5 kg`
- Cada funcionario deve poder receber um `Ponto A` e um `Ponto B`
- Na tela de gerenciamento deve ser possivel configurar os pontos `A` e `B`
- O funcionario deve usar pathfinding para seguir o caminho mais curto entre os pontos e objetivos de trabalho

## 3. Principios de Design

- O jogador constroi a fabrica posicionando entidades sobre o grid.
- A automacao nasce da organizacao da equipe, nao de esteiras.
- O fluxo logistico depende da distancia, do caminho disponivel e da disponibilidade dos funcionarios.
- O jogo precisa deixar claro quem esta transportando, operando ou aguardando.

## 4. MVP Proposto

Primeira entrega jogavel:

- Mapa simples com grid visivel
- Camera 2D de cima com leve inclinacao visual
- Colocacao de entidades no chao
- Funcionarios com movimentacao e pathfinding
- Tela de gerenciamento de funcionarios com configuracao de `Ponto A` e `Ponto B`
- Bau/fonte infinita fornecendo `aco`
- Maquina consumindo `aco` e produzindo `parafuso` ou `viga`
- Funcionarios transportando itens entre entidades
- Vendedor recebendo itens para gerar dinheiro
- Sistema basico de compra de entidades

## 5. Roadmap em Etapas

### Etapa 1 - Fundacao do Projeto

Objetivo: criar a base tecnica e visual do jogo.

- Estruturar cenas principais do Godot
- Criar cena principal do mapa
- Implementar grid visual no chao
- Definir tamanho base do tile
- Implementar sistema de camera
- Definir formato de dados para entidades, itens e receitas

Entrega esperada:

- Projeto abre em uma fase jogavel vazia com grid e camera funcionando

### Etapa 2 - Construcao e Ocupacao do Mapa

Objetivo: permitir posicionar entidades e validar espaco ocupado.

- Criar sistema de placement no grid
- Registrar ocupacao por tile
- Implementar entidades base: maquina, bau, fonte infinita e vendedor
- Definir custo de compra de cada entidade
- Exibir preview de colocacao valida/invalida

Entrega esperada:

- Jogador consegue comprar e posicionar entidades no mapa

### Etapa 3 - Funcionarios e Navegacao

Objetivo: colocar os funcionarios no centro da simulacao.

- Criar entidade `Funcionario`
- Implementar movimentacao livre com pathfinding
- Permitir desvio de obstaculos a partir das entidades colocadas
- Implementar tela de gerenciamento de funcionarios
- Permitir configurar `Ponto A` e `Ponto B`
- Fazer o funcionario circular entre os pontos quando estiver ocioso ou em modo de rota designada

Entrega esperada:

- Funcionarios se movem pelo menor caminho valido e respeitam bloqueios do mapa

### Etapa 4 - Inventario, Peso e Transporte

Objetivo: transformar o funcionario em unidade logistica.

- Implementar inventario com `1 slot`
- Implementar regra de carga maxima de `5 kg`
- Criar definicao de peso por item
- Implementar coleta e entrega de itens entre entidades
- Bloquear carregamento quando o peso ultrapassar o limite
- Exibir visualmente qual item o funcionario esta carregando

Entrega esperada:

- Funcionarios conseguem buscar um item, carregar e entregar corretamente

### Etapa 5 - Maquinas e Producao

Objetivo: fazer a fabrica funcionar.

- Criar estado interno da maquina: aguardando, abastecida, produzindo, pronta para retirada
- Implementar receitas iniciais
- Exigir funcionario para iniciar/abastecer/coletar producao da maquina
- Permitir selecionar receita da maquina
- Conectar entrada e saida via trabalho dos funcionarios

Entrega esperada:

- Uma linha simples produz `parafuso` e `viga` a partir de `aco`

### Etapa 6 - Economia Basica

Objetivo: fechar o ciclo de progressao.

- Definir preco de compra de cada entidade
- Definir valor de venda dos itens
- Implementar saldo do jogador
- Descontar compras e creditar vendas
- Integrar o `Vendedor` como destino logistico de produtos

Entrega esperada:

- O jogador consegue investir em estrutura e recuperar dinheiro vendendo producao

### Etapa 7 - Interface de Gerenciamento

Objetivo: dar controle operacional ao jogador.

- Painel de entidades selecionadas
- Painel de funcionario com pontos `A` e `B`
- Indicacao de tarefa atual do funcionario
- Indicacao de item carregado e peso atual
- Indicacao de maquina ativa, receita e estoque interno

Entrega esperada:

- O jogador entende o estado da fabrica sem depender de debug tecnico

### Etapa 8 - Polimento e Balanceamento

Objetivo: preparar a base para expansao.

- Ajustar velocidades de caminhada e producao
- Ajustar precos, pesos e ritmo economico
- Melhorar feedback visual de tarefas e rotas
- Revisar gargalos de pathfinding e desempenho
- Preparar adicao de novas maquinas, itens e receitas

Entrega esperada:

- Vertical slice estavel, clara e pronta para evolucao

## 6. Estrutura Tecnica Recomendada

### Sistemas principais

- `GridSystem`: ocupacao, validacao e posicionamento
- `EntitySystem`: registro e ciclo de vida das entidades
- `ItemDatabase`: definicao de itens, pesos e valores
- `RecipeDatabase`: definicao das receitas
- `WorkerAI`: decisao de tarefas, movimento e transporte
- `PathfindingSystem`: navegacao dos funcionarios
- `EconomySystem`: compras, vendas e saldo
- `ManagementUI`: telas de controle e configuracao

### Dados recomendados

Criar recursos ou estruturas de dados para:

- tipos de item
- receitas
- custos de compra
- tamanho das entidades no grid
- configuracoes de funcionario

## 7. Tabela Inicial de Dados

### Itens

| Item     | Peso     | Valor de venda | Observacao                |
| -------- | -------- | -------------- | ------------------------- |
| Aco      | 1 kg     | pendente       | materia-prima base        |
| Parafuso | 1 g      | pendente       | produzido a partir de aco |
| Viga     | pendente | pendente       | produzido a partir de aco |

### Entidades

| Entidade        | Tamanho             | Custo    | Observacao                        |
| --------------- | ------------------- | -------- | --------------------------------- |
| Maquina pequena | 2x2                 | pendente | produz itens a partir de receitas |
| Bau             | pendente            | pendente | armazenamento comum               |
| Fonte infinita  | pendente            | pendente | gera recurso base                 |
| Vendedor        | pendente            | pendente | converte itens em dinheiro        |
| Funcionario     | nao usa grid rigido | pendente | executa operacao e transporte     |

## 8. Riscos e Decisoes Pendentes

Pontos que precisam ser definidos cedo para evitar retrabalho:

- `Viga` ainda nao possui peso definido
- Falta definir valor de compra de cada entidade
- Falta definir valor de venda de cada item
- Falta definir se `inventario de 1 item` significa `1 unidade` ou `1 slot com stack`
- Falta definir capacidade interna de bau e maquina
- Falta definir se o funcionario apenas patrulha entre `A` e `B` ou se esses pontos servem como area preferencial de trabalho
- Falta definir tempos de producao das receitas
- Falta definir velocidade do funcionario e prioridade de tarefas
- Falta definir se o vendedor compra qualquer item ou apenas produtos finais

## 9. Proxima Acao Recomendada

Comecar pela `Etapa 1` e `Etapa 2`, porque elas criam a base para todo o restante:

1. mapa com grid
2. camera
3. placement de entidades
4. ocupacao por tiles
5. definicao em dados de itens, entidades e receitas

Depois disso, seguir direto para `Funcionario + Pathfinding`, que e o diferencial principal do projeto.

## 10. Plugins e Ferramentas para Economizar Tempo

Objetivo desta secao: priorizar ferramentas que reduzam trabalho repetitivo sem adicionar complexidade cedo demais.

### Recomendacao geral

Para este projeto, o melhor ganho de tempo nao vem de encher o Godot de addons logo no inicio. O maior retorno vem de combinar:

- recursos nativos do Godot para grid, navegacao, UI e debug
- alguns plugins pequenos e maduros para produtividade
- ferramentas externas para arte, mapa, dados e automacao do pipeline

Se eu tivesse que priorizar, eu faria nesta ordem:

1. usar bem os sistemas nativos do Godot
2. adicionar plugin de `Git` dentro do editor
3. usar editor de tiles/mapa externo
4. usar ferramenta de pixel art/animacao
5. adicionar plugins de inspecao e debug apenas quando a simulacao crescer

### Plugins mais recomendados para este jogo

#### 1. Git Plugin para Godot

Por que vale a pena:

- acelera commit, diff e revisao sem sair do editor
- ajuda muito quando voces estiverem iterando cenas, recursos e scripts
- reduz chance de esquecer arquivos `.tscn`, `.tres` e configuracoes

Melhor uso no projeto:

- desde o inicio
- especialmente util porque o jogo vai ter muitas cenas pequenas e recursos de dados

Prioridade: `Alta`

#### 2. Plugin de Inspector / Debug visual

Categoria recomendada:

- plugins que ajudam a visualizar estado em runtime
- overlays para mostrar caminho, destino, ocupacao do grid e estado de entidades

Por que vale a pena:

- o diferencial do jogo esta em `Funcionario + transporte + pathfinding`
- depurar isso so por log costuma desperdiçar muito tempo
- visualizar tarefas, alvo atual, carga e rota economiza horas

Melhor uso no projeto:

- a partir da `Etapa 3`
- quando os funcionarios comecarem a disputar tarefas e rotas

Prioridade: `Alta`

Observacao:

- se nao encontrarem um addon maduro, vale mais criar um `DebugOverlay` proprio do que adotar plugin ruim

#### 3. Plugin de Nodes / State Machine

Categoria recomendada:

- plugins leves de state machine para Godot

Por que pode valer a pena:

- o comportamento da maquina e do funcionario tem estados bem claros
- ajuda a organizar `ocioso`, `indo buscar`, `carregando`, `entregando`, `operando`, `aguardando`

Melhor uso no projeto:

- somente se a logica comecar a ficar espalhada demais
- muito util para `Funcionario` e `Maquina`

Prioridade: `Media`

Observacao:

- se a equipe for pequena e quiser manter controle total, um sistema proprio simples pode ser melhor que plugin

#### 4. Plugin de serializacao / inspeção de Resources

Categoria recomendada:

- addons que melhoram edicao de `Resource`, tabelas e dados customizados

Por que vale a pena:

- o jogo depende fortemente de dados de itens, receitas, custos, pesos e tamanhos
- editar isso de forma consistente economiza muito tempo e evita erro manual

Melhor uso no projeto:

- da `Etapa 1` em diante
- especialmente quando o numero de itens e receitas crescer

Prioridade: `Media`

#### 5. Plugin de save system

Categoria recomendada:

- addons focados em persistencia e serializacao de estado

Por que pode valer a pena:

- salvar estado de fabrica, entidades, estoque e funcionarios da trabalho
- um sistema pronto pode encurtar bastante a implementacao

Melhor uso no projeto:

- depois do MVP principal estar estavel
- nao e prioridade para a primeira entrega jogavel

Prioridade: `Media`

### Funcionalidades nativas do Godot que devem ser prioridade antes de procurar plugin

Estas sao as ferramentas com maior retorno para `ManoFatura` e ja estao no motor:

#### 1. `NavigationAgent2D` e sistema de navegacao 2D

Ideal para:

- pathfinding dos funcionarios
- recalculo de rota
- desvio de obstaculos

Motivo:

- cobre justamente o coracao do diferencial do jogo
- evita implementar navegacao do zero cedo demais

#### 2. `TileMapLayer` / grid baseado em tiles

Ideal para:

- ocupacao de espaco
- placement
- preview de area valida
- leitura de coordenadas do mapa

Motivo:

- resolve boa parte da base de construcao sem depender de plugin

#### 3. `Resource` e `ResourceLoader`

Ideal para:

- banco de itens
- banco de receitas
- definicao de entidades
- custos, pesos e tempos

Motivo:

- muito melhor do que hardcode em script
- acelera balanceamento e expansao

#### 4. `Autoload`

Ideal para:

- `EconomySystem`
- registries globais
- controle de selecao
- debug flags

Motivo:

- ajuda a manter a estrutura simples no MVP

#### 5. Profiler, Remote SceneTree e Debugger

Ideal para:

- gargalos de simulacao
- excesso de chamadas por frame
- depurar AI e UI

Motivo:

- antes de instalar plugin de performance, esgotem o que o proprio editor ja mostra

### Ferramentas externas com melhor custo-beneficio

Estas provavelmente vao economizar mais tempo que muitos plugins do editor:

#### 1. `Aseprite`

Melhor para:

- sprites
- animacoes curtas
- iteracao rapida de pixel art

Recomendacao:

- altissima prioridade se a direcao visual for pixel art ou low-res estilizado

#### 2. `Tiled`

Melhor para:

- prototipar mapas
- testar layout de fabrica
- desenhar blocos, piso e zonas rapidamente

Recomendacao:

- muito util se voces quiserem montar fases ou presets de mapa fora do editor

#### 3. `LibreSprite` ou `Piskel`

Melhor para:

- alternativa gratuita para arte 2D simples

Recomendacao:

- boa opcao se nao quiserem comecar com custo de licenca

#### 4. `GitHub Actions`

Melhor para:

- export automatizado
- validacao de build
- checagem de projeto em cada push

Recomendacao:

- util assim que o projeto deixar de ser prototipo local

#### 5. Planilha ou banco de dados simples para balanceamento

Exemplos:

- Google Sheets
- CSV
- JSON gerado a partir de planilha

Melhor para:

- peso
- custo
- valor de venda
- tempo de producao

Recomendacao:

- muito eficiente para um jogo de fabrica, porque o balanceamento vai mudar bastante

### O que eu evitaria no inicio

- plugins grandes de inventario generico, porque normalmente trazem mais sistema do que o jogo precisa
- frameworks pesados de AI, porque a necessidade atual e bem especifica
- plugins de quest/dialogo, porque nao atacam o problema central do MVP
- addons pouco mantidos so porque parecem acelerar alguma etapa

### Pilha recomendada para o MVP

Se a meta for economizar tempo com baixo risco, eu recomendaria esta pilha:

- `Godot nativo` para grid, navegacao, UI e dados
- `Git Plugin` para fluxo diario
- `Aseprite` para arte e animacao
- `Tiled` se o mapa ficar mais complexo do que um prototipo direto no editor
- `DebugOverlay` proprio para rota, tarefa, carga e ocupacao do grid
- `Resources` para itens, receitas, custos e configuracoes

### Acao recomendada

Adicionar cedo ao backlog tecnico:

1. definir o formato dos `Resources` de item, receita e entidade
2. criar um `DebugOverlay` para exibir rota, estado e item carregado pelos funcionarios
3. instalar um plugin de `Git` no Godot
4. decidir se o mapa inicial sera montado direto no editor ou com `Tiled`
5. escolher a ferramenta de arte 2D para nao travar a producao visual depois
