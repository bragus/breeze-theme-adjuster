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
