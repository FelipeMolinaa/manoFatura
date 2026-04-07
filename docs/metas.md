# Metas - ManoFatura

## 1. MVP Proposto

Primeira entrega jogavel:

- Mapa simples com grid visivel
- Camera 2D de cima com leve inclinacao visual
- Colocacao de entidades no chao
- Funcionarios com movimentacao e pathfinding
- Tela de gerenciamento de funcionarios com configuracao de `Ponto A` e `Ponto B`
- Bau com 1 slot/1 unidade e fonte infinita fornecendo `aco`
- Painel lateral de selecao com informacoes e inventario de entidades e funcionarios
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

- [x] Jogador consegue comprar e posicionar entidades no mapa

### Etapa 3 - Funcionarios e Navegacao

Objetivo: colocar os funcionarios no centro da simulacao.

- [x] Criar entidade `Funcionario`
- [x] Implementar movimentacao livre com pathfinding
- [x] Permitir desvio de obstaculos a partir das entidades colocadas
- [x] Implementar tela de gerenciamento de funcionarios
- [x] Permitir configurar `Ponto A` e `Ponto B`
- [x] Fazer o funcionario circular entre os pontos quando estiver ocioso ou em modo de rota designada

Entrega esperada:

- [x] Funcionarios se movem pelo menor caminho valido e respeitam bloqueios do mapa

### Etapa 4 - Inventario, Peso e Transporte

Objetivo: transformar o funcionario em unidade logistica.

- [x] Implementar inventario com `1 slot`
- [x] Implementar regra de carga maxima de `5 kg`
- [x] Criar definicao de peso por item
- [x] Criar inventarios para maquinas, baus e funcionarios
- [x] Limitar o bau a `1 slot` e `1 unidade`
- [x] Permitir configurar acao e quantidade por ponto em unidade ou porcentagem
- [x] Permitir associar `Ponto A` e `Ponto B` clicando diretamente em entidades
- [x] Implementar coleta e entrega de itens entre entidades
- [x] Bloquear carregamento quando o peso ultrapassar o limite
- [ ] Exibir visualmente qual item o funcionario esta carregando

Entrega esperada:

- [x] Funcionarios conseguem buscar um item, carregar e entregar corretamente

### Etapa 5 - Maquinas e Producao

Objetivo: fazer a fabrica funcionar.

- [ ] Criar estado interno da maquina: aguardando, abastecida, produzindo, pronta para retirada
- [x] Implementar receitas iniciais
- [ ] Exigir funcionario para iniciar/abastecer/coletar producao da maquina
- [x] Permitir selecionar receita da maquina
- [ ] Conectar entrada e saida via trabalho dos funcionarios

Entrega esperada:

- [ ] Uma linha simples produz `parafuso` e `viga` a partir de `aco`

### Etapa 6 - Economia Basica

Objetivo: fechar o ciclo de progressao.

- [x] Definir preco de compra de cada entidade
- [x] Definir valor de venda dos itens
- [x] Implementar saldo do jogador
- [x] Descontar compras e creditar vendas
- [ ] Integrar o `Vendedor` como destino logistico de produtos

Entrega esperada:

- [ ] O jogador consegue investir em estrutura e recuperar dinheiro vendendo producao

### Etapa 7 - Interface de Gerenciamento

Objetivo: dar controle operacional ao jogador.

- [x] Painel de entidades selecionadas
- [x] Painel de funcionario com pontos `A` e `B`
- [x] Painel lateral no canto direito sem sobrepor o menu inferior
- [x] Separar informacoes/inventario, `Ponto A` e `Ponto B` em abas
- [x] Ocultar abas de `Ponto A` e `Ponto B` quando uma entidade esta selecionada
- [x] Permitir selecionar entidades e funcionarios no modo construcao quando nao ha placement pendente
- [x] Permitir menu suspenso com botao direito em entidades selecionaveis
- [ ] Indicacao de tarefa atual do funcionario
- [x] Indicacao de item carregado e peso atual
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

Seguir para o fechamento visual da `Etapa 4` e entrar no ciclo real de producao:

1. exibir visualmente qual item o funcionario esta carregando
2. criar estado interno da maquina: aguardando, abastecida, produzindo e pronta para retirada
3. exigir funcionario para iniciar, abastecer e coletar producao da maquina
4. conectar entrada e saida da maquina via trabalho dos funcionarios
5. integrar o `Vendedor` como destino logistico de produtos
