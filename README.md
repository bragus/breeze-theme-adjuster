# Breeze compacto

Editor gráfico em Rust + egui para o seu Plasma 6.8.2. O código da aplicação está em `src/main.rs`; os pequenos scripts de integração estão em `src/*.js` e no widget QML `helper/`. O executável já está compilado para Linux x86_64 e não precisa de Cargo para abrir.

Abra `abrir.sh`, ou procure **Breeze compacto** no menu de aplicativos.

## Controles

- Painel: altura de 28–48 px e raio de 2–16 px, com fallback para os demais elementos do Breeze.
- Tarefas centralizadas ou à esquerda, sempre com o mesmo estilo, raio e largura dos botões. Menu na esquerda e **não agrupar** preservados. Quando faltar espaço, a centralização cede para evitar sobreposição.
- **Mostrar títulos das janelas**: usa o texto nativo de cada janela no mesmo gerenciador de ícones; os pinados são mantidos. A largura máxima dos botões com título vai de 80 a 240 px, com reticências quando necessário.
- Tray: ícones de 12–32 px e espaço de 0–24 px entre eles, independentes da altura do painel. O tamanho fica limitado à área disponível no painel; os ícones do pop-up de itens ocultos mantêm o tamanho nativo.
- Ícones de barras dos aplicativos Qt/KDE: 16, 22, 24 ou 32 px. Reabra os aplicativos para refletir o ajuste. Aplicativos com interface própria podem ignorá-lo.
- Breeze Enhanced: ativar/desativar cantos arredondados; o tema instalado não expõe um raio variável para janelas. O raio ajustável do editor se aplica ao painel e às tarefas, não ao conteúdo de todos os aplicativos.
- Fundos: Breeze original, suave com traço, suave com ponto, contorno ou neutro; destaque, opacidade ativa e inativa e tom de cinza do modo Neutro ajustáveis. Alertas continuam em laranja.
- Espaçadores: mínimo após o menu e à direita das tarefas; espaço entre widgets e deslocamento do centro. Com centralização ligada, os espaçadores continuam flexíveis.
- Relógio: tamanhos separados de hora e data, em pixels. As proporções são reduzidas quando a soma dos textos não cabe na altura do painel. Formatos, fuso, atualização e clique para abrir o calendário são mantidos. Desative o tamanho personalizado para usar o relógio nativo.

A prévia é ilustrativa. **Aplicar** altera o painel escolhido; o estilo do Plasma e os tamanhos de barras são configurações globais. O editor não precisa ficar aberto. Um pequeno auxiliar QML cuida da centralização, dos fundos, da tray e do relógio; ele usa a árvore visual interna do Plasma e foi verificado na versão 6.8.2. Uma futura atualização do Plasma pode exigir adaptar esse widget.

As tarefas são acompanhadas por sinais de criação/remoção. Não há uma varredura periódica do painel em repouso, nem gravações de diagnóstico em loop. O posicionamento usa medidas estáveis, sem animação adicional do espaçador: as animações nativas do Plasma continuam responsáveis pelas tarefas. No modo personalizado, o SVG do tema já contém molduras transparentes desde o primeiro quadro, evitando que o fundo Breeze antigo pisque enquanto o app está iniciando. Progresso e expansores foram preservados.

## Restaurar

**Restaurar anterior** remove os dois espaçadores e o auxiliar, devolve altura, ordem, agrupamento e configurações da tray, além do tema anterior e das chaves alteradas de Breeze/barras. Não substitui todo o arquivo de configurações. O backup é capturado antes da primeira aplicação e mantido enquanto você experimenta as alternativas. Após restaurar, uma nova aplicação cria outro backup.

Os backups ficam em `~/.local/share/breeze-editor/`. Incluem cópia de referência do layout original, que não é sobrescrita enquanto o Plasma está em execução. A restauração também pode ser executada pelo terminal:

```sh
./abrir.sh --restore
```

Os pacotes auxiliares e os dois estilos locais `breeze-compact-a/b` permanecem instalados, mas inativos após restaurar. Nenhum arquivo em `/usr` é alterado.

## Compilar

Requer Rust 1.95 ou superior e as bibliotecas de desenvolvimento de Wayland/X11/OpenGL da distribuição. A integração usa `gdbus`, `kwriteconfig6`, `kpackagetool6` e `plasma-apply-desktoptheme`.

```sh
cargo build --release
cp target/release/breeze-editor ./breeze-editor
./abrir.sh
```

O Cargo.lock acompanha o projeto. O binário entregue foi compilado com o perfil de desenvolvimento e teve os símbolos removidos; a compilação release acima reduz ainda mais o tamanho.
