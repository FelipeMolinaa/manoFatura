# ManoFatura

## Sobre o jogo

ManoFatura e um jogo de gerenciamento e automacao de fabrica inspirado em Factorio, mas com um diferencial central: a fabrica nao funciona sozinha. Em vez de configurar uma estrutura 100% autonoma e livre de problemas, o jogador precisa lidar com o fator mais imprevisivel da producao: o ser humano.

Os funcionarios sao responsaveis por quase toda a operacao da fabrica. Eles controlam maquinas, movem itens, abastecem postos de trabalho, retiram producao, limpam sujeiras, bebem cafe, conversam, ficam insatisfeitos e podem transformar uma linha aparentemente perfeita em um pequeno caos operacional.

O desafio e construir uma fabrica eficiente sem ignorar as pessoas que a fazem funcionar.

## Mecanicas atuais

- Mapa 2D com camera de cima e grid de construcao.
- Sistema de compra e posicionamento de entidades no mapa.
- Entidades iniciais: maquina, bau, fonte de aco e vendedor.
- Funcionarios contrataveis com movimentacao por pathfinding.
- Configuracao de `Ponto A` e `Ponto B` para rotas de trabalho.
- Acoes de funcionario para pegar e largar itens em entidades.
- Inventario com limite de slots, quantidade e peso.
- Fonte infinita fornecendo `aco`.
- Maquina com selecao de receita, slot de entrada, slot de saida e estados de producao.
- Receitas iniciais para produzir `parafuso` e `viga` a partir de `aco`.
- Vendedor que compra qualquer item depositado e soma o valor ao dinheiro atual.
- Painel lateral com informacoes de entidades, funcionarios e inventarios.
- Sistema basico de dinheiro para comprar estruturas e vender producao.
- Salvamento local do estado de entidades, funcionarios, inventarios e dinheiro.

## Objetivo final

ManoFatura pretende ser um gerenciador de automacao de fabrica em que a eficiencia depende tanto das maquinas quanto da gestao humana. A fabrica produz caminhoes, comecando por pecas simples, como parafusos e vigas de aco, e evoluindo para componentes mais complexos fabricados em maquinas de usinagem, bancadas de trabalho e linhas de producao.

Com o tempo, pequenas pecas poderao ser combinadas em subconjuntos maiores, como chassi, motor e cabine, ate chegar ao produto final: o caminhao. A producao excedente tambem devera poder ser vendida para manter a fabrica financeiramente saudavel e evitar a falencia.

O jogador precisara construir e organizar a estrutura fisica da fabrica com paredes, grades, portas, pisos, calcadas, pistas de asfalto e sinalizacoes. A movimentacao pelo chao de fabrica sera parte essencial do desafio: funcionarios, carrinhos, empilhadeiras, veiculos internos e caminhoes de carga precisarao circular sem travar a operacao e sem causar acidentes.

A gestao dos funcionarios sera tao importante quanto o layout industrial. Humanos insatisfeitos com salarios baixos, carga horaria ruim ou excesso de funcoes podem reduzir a produtividade, reclamar, se organizar, entrar em greve ou criar novos problemas operacionais. Cabera ao jogador oferecer salarios melhores, bonus, premios, jornadas minimamente aceitaveis e ambientes de trabalho mais saudaveis.

Tambem fara parte da fabrica criar areas de descompressao com maquina de cafe, banheiro, mesa de sinuca e outros recursos. Esses espacos precisarao de manutencao, limpeza e reposicao, criando novas funcoes e novos funcionarios para manter o bem-estar da equipe.

O objetivo final e transformar uma operacao simples de parafusos e vigas em uma fabrica completa de caminhoes, equilibrando producao, logistica, seguranca, economia e satisfacao humana. Em ManoFatura, automatizar nao significa eliminar problemas: significa aprender a gerenciar pessoas, maquinas, rotas, prioridades e imprevistos ao mesmo tempo.
