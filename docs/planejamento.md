# Planejamento - ManoFatura

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

- `0,1 aco -> 1 parafuso`
- `5 aco -> 1 viga`

### Tempos de producao iniciais

- `Parafuso`: `1000 ms`
- `Viga`: `60000 ms`

### Peso dos itens

- `Aco`: `1 kg`
- `Parafuso`: `1 g`
- `Viga`: `5 kg`

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

## 4. Estrutura Tecnica Recomendada

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

## 5. Tabela Inicial de Dados

### Itens

| Item     | Peso | Valor de compra | Valor de venda | Observacao                |
| -------- | ---- | --------------- | -------------- | ------------------------- |
| Aco      | 1 kg | 75              | 50             | materia-prima base        |
| Parafuso | 1 g  | 10              | 5              | produzido a partir de aco |
| Viga     | 5 kg | 35              | 25             | produzido a partir de aco |

### Entidades

| Entidade        | Tamanho             | Custo    | Observacao                        |
| --------------- | ------------------- | -------- | --------------------------------- |
| Maquina pequena | 2x2                 | 100      | produz itens a partir de receitas |
| Bau             | 2x2                 | 50       | armazenamento comum               |
| Fonte infinita  | 2x2                 | 200      | gera recurso base                 |
| Vendedor        | pendente            | pendente | converte itens em dinheiro        |
| Funcionario     | nao usa grid rigido | pendente | executa operacao e transporte     |

### Receitas

| Receita  | Entrada     | Saida        | Tempo      |
| -------- | ----------- | ------------ | ---------- |
| Parafuso | 0,1 `aco`   | 1 `parafuso` | 1000 ms    |
| Viga     | 5 `aco`     | 1 `viga`     | 60000 ms   |

## 6. Estado Atual da Implementacao

Base ja implementada no projeto:

- Cena principal com grid visivel e camera funcional
- HUD de construcao separada da cena principal
- Sistema de placement com preview de area valida e invalida
- Controle de ocupacao do grid
- Entidades base de construcao: `Maquina`, `Bau`, `Fonte de Aco` e `Vendedor`
- Bancos de dados em GDScript para entidades, itens e receitas
- Sistema de dinheiro reativo com compra e venda de entidades
- Refatoracao da cena principal em componentes de construcao, camera e HUD

## 7. Riscos e Decisoes Pendentes

Pontos que precisam ser definidos cedo para evitar retrabalho:

- Falta definir se `inventario de 1 item` significa `1 unidade` ou `1 slot com stack`
- Falta definir capacidade interna de bau e maquina
- Falta definir custo e papel de placement do `Vendedor`
- Falta definir custo de contratacao ou manutencao do `Funcionario`
- Falta definir se o funcionario apenas patrulha entre `A` e `B` ou se esses pontos servem como area preferencial de trabalho
- Falta definir velocidade do funcionario e prioridade de tarefas
- Falta definir se o vendedor compra qualquer item ou apenas produtos finais
