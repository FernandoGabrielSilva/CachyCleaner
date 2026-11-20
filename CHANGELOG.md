# Changelog

Todas as mudanças relevantes deste projeto são documentadas aqui.

## [1.0.0] — 20/11/2026

Primeira versão pública do CachyCleaner.

### Interface
- Interface Qt Quick / QML com visual moderno e **tema escuro por padrão**.
- Paleta revisada para o tema escuro (fundo, superfícies, bordas e textos com contraste adequado).
- Correção dos espaçamentos: os cards de Configurações tinham altura zero e se sobrepunham; agora cada card dimensiona seu conteúdo corretamente.
- Barras laterais, cabeçalho, páginas, tabelas, diálogos e notificações com margens, raios e hierarquia tipográfica consistentes.
- Botões com texto centralizado, alinhamento vertical correto e **feedback visual ao pressionar**.
- Opção de tema claro/escuro/sistema nas Configurações.

### Funcionalidades
- Análise de arquivos inúteis (caches, temporários, lixeira do sistema, resíduos de navegadores etc.) antes de qualquer remoção.
- Tela de análise com busca, seleção individual, selecionar tudo, limpar seleção e detalhes de caminho/tamanho/data.
- Fluxo seguro: **analisar → selecionar → limpar**, com confirmação e envio para a lixeira por padrão.
- Pastas personalizadas, exclusões, regras habilitáveis e idade mínima dos arquivos configuráveis.
- 13 idiomas selecionáveis (incluindo português, inglês, espanhol, francês, alemão, italiano, japonês, coreano, chinês, russo, hindi e árabe).
- Verificação automática de atualizações via API do GitHub e link direto para a release.
- Configurações persistidas de forma atômica em `~/.config/CachyCleaner/settings.json`.

### Correções
- Textos da interface apareciam vazios porque o método de tradução exposto ao QML não declarava o tipo de retorno; corrigido.
- Exceção `TypeError: busyChanged(bool) needs 1 argument(s), 0 given!` ao iniciar uma análise: os sinais de notificação agora não exigem argumentos.
- Botões com texto descentralizado e sem indicação visual de clique; corrigido.

### Entregáveis
- Linux: AppImage `x86_64` e `aarch64`, `.deb`, `.pkg.tar.zst` (pacman/Arch/CachyOS) e `.tar.gz` portátil.
- Windows: instalador `.msi` e `.zip` portátil (`x86_64`).
- macOS: `.dmg` para `x86_64` e `arm64`.
- Workflows GitHub Actions para testes (Python 3.10–3.13), build multiplataforma e publicação automática da release.
