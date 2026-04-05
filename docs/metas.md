# Metas - ManoFatura

## 1. MVP Proposto

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

## 2. Roadmap em Etapas

### Etapa 1 - Fundacao do Projeto

Objetivo: criar a base tecnica e visual do jogo.

- [x] Estruturar cenas principais do Godot
- [x] Criar cena principal do mapa
- [x] Implementar grid visual no chao
- [x] Definir tamanho base do tile
- [x] Implementar sistema de camera
- [x] Definir formato de dados para entidades, itens e receitas

Entrega esperada:

- [x] Projeto abre em uma fase jogavel vazia com grid e camera funcionando

### Etapa 2 - Construcao e Ocupacao do Mapa

Objetivo: permitir posicionar entidades e validar espaco ocupado.

- [x] Criar sistema de placement no grid
- [x] Registrar ocupacao por tile
- [x] Implementar entidades base: maquina, bau, fonte infinita e vendedor
- [x] Definir custo de compra de cada entidade
- [x] Exibir preview de colocacao valida/invalida

Entrega esperada:

- [ ] Jogador consegue comprar e posicionar entidades no mapa

### Etapa 3 - Funcionarios e Navegacao

Objetivo: colocar os funcionarios no centro da simulacao.

- [ ] Criar entidade `Funcionario`
- [ ] Implementar movimentacao livre com pathfinding
- [ ] Permitir desvio de obstaculos a partir das entidades colocadas
- [ ] Implementar tela de gerenciamento de funcionarios
- [ ] Permitir configurar `Ponto A` e `Ponto B`
- [ ] Fazer o funcionario circular entre os pontos quando estiver ocioso ou em modo de rota designada

Entrega esperada:

- [ ] Funcionarios se movem pelo menor caminho valido e respeitam bloqueios do mapa

### Etapa 4 - Inventario, Peso e Transporte

Objetivo: transformar o funcionario em unidade logistica.

- [ ] Implementar inventario com `1 slot`
- [ ] Implementar regra de carga maxima de `5 kg`
- [ ] Criar definicao de peso por item
- [ ] Implementar coleta e entrega de itens entre entidades
- [ ] Bloquear carregamento quando o peso ultrapassar o limite
- [ ] Exibir visualmente qual item o funcionario esta carregando

Entrega esperada:

- [ ] Funcionarios conseguem buscar um item, carregar e entregar corretamente

### Etapa 5 - Maquinas e Producao

Objetivo: fazer a fabrica funcionar.

- [ ] Criar estado interno da maquina: aguardando, abastecida, produzindo, pronta para retirada
- [ ] Implementar receitas iniciais
- [ ] Exigir funcionario para iniciar/abastecer/coletar producao da maquina
- [ ] Permitir selecionar receita da maquina
- [ ] Conectar entrada e saida via trabalho dos funcionarios

Entrega esperada:

- [ ] Uma linha simples produz `parafuso` e `viga` a partir de `aco`

### Etapa 6 - Economia Basica

Objetivo: fechar o ciclo de progressao.

- [ ] Definir preco de compra de cada entidade
- [ ] Definir valor de venda dos itens
- [ ] Implementar saldo do jogador
- [ ] Descontar compras e creditar vendas
- [ ] Integrar o `Vendedor` como destino logistico de produtos

Entrega esperada:

- [ ] O jogador consegue investir em estrutura e recuperar dinheiro vendendo producao

### Etapa 7 - Interface de Gerenciamento

Objetivo: dar controle operacional ao jogador.

- [ ] Painel de entidades selecionadas
- [ ] Painel de funcionario com pontos `A` e `B`
- [ ] Indicacao de tarefa atual do funcionario
- [ ] Indicacao de item carregado e peso atual
- [ ] Indicacao de maquina ativa, receita e estoque interno

Entrega esperada:

- [ ] O jogador entende o estado da fabrica sem depender de debug tecnico

### Etapa 8 - Polimento e Balanceamento

Objetivo: preparar a base para expansao.

- [ ] Ajustar velocidades de caminhada e producao
- [ ] Ajustar precos, pesos e ritmo economico
- [ ] Melhorar feedback visual de tarefas e rotas
- [ ] Revisar gargalos de pathfinding e desempenho
- [ ] Preparar adicao de novas maquinas, itens e receitas

Entrega esperada:

- [ ] Vertical slice estavel, clara e pronta para evolucao

## 3. Proxima Acao Recomendada

Seguir para a conclusao da `Etapa 2` e depois entrar na `Etapa 3`:

1. definir custo de compra das entidades
2. concluir o fluxo de compra e posicionamento no mapa
3. criar a entidade `Funcionario`
4. implementar navegacao com pathfinding
5. criar a base da tela de gerenciamento com `Ponto A` e `Ponto B`
