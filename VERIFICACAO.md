# Verificação em 13/11/2026

- Compilação offline concluída com Rust 1.99.1, egui/eframe 0.36.2. Executável teve símbolos removidos.
- Aplicação real no Plasma 6.8.2, painel 523: altura 32 px; agrupamento 0; fill desativado nas tarefas; tray scaleIconsToFit=false.
- Restauração executada: altura voltou a 36 px, menu/tarefas/pager/separador/tray/relógio/mostrar desktop recuperaram a ordem, agrupamento permaneceu 0 e tray scaleIconsToFit voltou a true. Em seguida, personalização reaplicada com novo backup.
- Diagnóstico do auxiliar após estabilização: diferença do centro das tarefas em relação ao centro do painel de 1 px, com nove decorações de tarefas e nove fundos nativos ocultos no modo personalizado.
- Os cinco modos foram selecionados pela mesma configuração utilizada pelo editor. O modo Breeze original reativa o fundo nativo; os modos personalizados o ocultam. Após os testes, foi reaplicado o modo neutro, conforme as escolhas salvas no editor.
- Interface do editor aberta na sessão real e captura inspecionada: controles, textos, prévia e botões cabem na janela. Captura em editor.png.
- Estado final escolhido no editor: altura 40 px, raio 7 px, fundo neutro, barras dos aplicativos 24 px; centralização e tray menor mantidas. A altura de 40 px veio do perfil salvo, não de um aumento automático.
- O descarte explícito das decorações foi incluído na versão final para liberar os bindings ao remover o auxiliar.

A comparação de capturas do painel foi descartada porque um aplicativo em tela cheia passou a cobrir o painel durante a captura. Nenhuma imagem dessa aplicação integra a entrega. O redimensionamento com muitas janelas e a compatibilidade com versões futuras do Plasma não foram exaustivamente testados.

## Atualização: tray, relógio e animações

- Os três componentes QML finais foram carregados com QQmlComponent: Status.Ready.
- Teste real no Plasma: nove ícones visíveis da tray medidos em 20 × 20 px; células de 24 px (20 + 4 de espaço).
- Em repouso, o contador de atualizações estruturais permaneceu em 3 durante duas medições, e o temporizador de descoberta estava desligado.
- Abertura de uma janela isolada do Konsole, encerrada automaticamente após 2 s: detectada por sinal; centralização medida em 0 px de desvio após fechamento. Não foi feito benchmark de FPS.
- Hora e data passaram a usar toda a altura do painel. Tamanhos maiores que a área disponível são reduzidos proporcionalmente; a interface informa essa limitação.
- QSvgRenderer verificou pixels totalmente transparentes nos centros normal, focus, hover, attention e minimized, incluindo orientações alternativas. Progresso e expansores continuam no SVG.
- Preferências salvas pelo usuário preservadas: tray 20 px, espaço 4 px, hora 22 px, data 17 px, alpha ativo 8% e inativo 0%.

## Alinhamento, títulos e correção do tremor

- Removida a animação extra do espaçador e a realimentação baseada na sua própria largura. O centro é calculado a partir do menu, da largura desejada das tarefas e dos demais widgets.
- Testadas as quatro combinações centro/esquerda, com/sem títulos. Estilo, raio e cinza iguais nos dois alinhamentos; botões variaram no máximo 1 px por arredondamento do layout nativo.
- Oito títulos nativos visíveis no teste; largura total do grupo com títulos em 1280 px. Os apps pinados e o widget original foram mantidos.
- O teste sempre restaurou alinhamento e títulos conforme estavam antes de começar.

Conferência final após retirar a animação do espaçador: contador estrutural 5 → 5 em repouso, descoberta desligada; teste de abertura/fechamento passou com desvio do centro de -1 px. Relógio medido em 12/12 px conforme as últimas escolhas salvas. Interface final capturada e inspecionada em editor.png.
