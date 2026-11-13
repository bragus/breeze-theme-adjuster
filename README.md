# Breeze compacto

Editor gráfico em Rust + egui para o seu Plasma 6.8.2. O código da aplicação está em `src/main.rs`; os pequenos scripts de integração estão em `src/*.js` e no widget QML `helper/`. O executável já está compilado para Linux x86_64 e não precisa de Cargo para abrir.

Abra `abrir.sh`, ou procure **Breeze compacto** no menu de aplicativos.

## Controles

- Painel: altura de 28–48 px e raio de 2–16 px, com fallback para os demais elementos do Breeze.
- Tarefas centralizadas, menu na esquerda e **não agrupar** sempre preservado ao aplicar. Quando faltar espaço, a centralização cede para evitar sobreposição.
- Tray: tamanho menor nativo do Plasma, limitado a 22 px, e espaçamento independente. Não é um seletor arbitrário de tamanho em pixels.
- Ícones de barras dos aplicativos Qt/KDE: 16, 22, 24 ou 32 px. Reabra os aplicativos para refletir o ajuste. Aplicativos com interface própria podem ignorá-lo.
- Breeze Enhanced: ativar/desativar cantos arredondados; o tema instalado não expõe um raio variável para janelas. O raio ajustável do editor se aplica ao painel e às tarefas, não ao conteúdo de todos os aplicativos.
- Fundos: Breeze original, suave com traço, suave com ponto, contorno ou neutro; cor e opacidade ajustáveis. Alertas de atenção continuam em laranja.

A prévia é ilustrativa. **Aplicar** altera o painel escolhido; o estilo do Plasma e os tamanhos de barras são configurações globais. O editor não precisa ficar aberto. Um widget QML de aproximadamente 75 linhas cuida da centralização e dos fundos; ele usa a árvore visual interna do Plasma e foi verificado na versão 6.8.2. Uma futura atualização do Plasma pode exigir adaptar esse widget.

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
