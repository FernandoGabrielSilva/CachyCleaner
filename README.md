# 🧹 CachyCleaner

> Limpe seu sistema com segurança e elegância.

**CachyCleaner** é um limpador de sistema **moderno, seguro e multiplataforma**, construído em **Python + Qt (PySide6/QML)**. Ele analisa caches, arquivos temporários e resíduos, mostra **exatamente o que será removido** e só apaga depois que você confirma. Por padrão, tudo vai para a **lixeira** — nada é destruído sem sua autorização.

---

## ✨ Funcionalidades

| Recurso | Descrição |
|---|---|
| 🔍 **Análise detalhada** | Varredura não bloqueante (QThread) com progresso em tempo real e lista de cada arquivo encontrado, tamanho e data de modificação. |
| ✅ **Seleção granular** | Marque/desmarque item por item, selecione tudo, limpe a seleção ou filtre por nome/categoria. |
| 🗑️ **Lixeira primeiro** | `send2trash` → `gio trash` → `kioclient` → lixeira XDG / Recycle Bin / `.Trash`. Exclusão permanente só com opção explícita. |
| ⚙️ **Pastas personalizadas** | Adicione e remova pastas/padrões glob próprios em **Configurações → Pastas personalizadas**, além dos padrões embutidos. |
| 📏 **Regras configuráveis** | Ative/desative cada categoria (sistema, navegadores, desenvolvimento, mídia, pacotes) e defina idade mínima dos arquivos. |
| 🚫 **Exclusões** | Pastas que nunca devem ser analisadas. |
| 🌍 **13 idiomas** | PT-BR, EN, ES, FR, DE, IT, JA, KO, ZH-CN, RU, HI, AR + detecção automática pelo locale do sistema. |
| 🎨 **Interface moderna** | QML com design system próprio: tema claro/escuro/sistema, animações suaves, High-DPI e fontes Inter/JetBrains Mono. |
| ⬆️ **Verificação de atualizações** | Consulta a API de releases do GitHub, avisa quando há versão nova e abre a página de download. |
| 📦 **Múltiplos formatos** | AppImage, `.deb`, `.rpm`, `.pacman`, `.tar.gz`, `.msi`, `.dmg`, `.exe` portátil e `.app`, para x86_64, ARM64 e mais. |

---

## 🚀 Instalação

### Baixar binário pronto
Acesse **[Releases](https://github.com/FernandoGabrielSilva/CachyCleaner/releases)** e baixe o pacote para seu sistema:

| Sistema | Formatos |
|---|---|
| Linux | `.AppImage`, `.deb`, `.rpm`, `.pkg.tar.zst`, `.tar.gz` |
| Windows | `.msi`, `.exe` portátil (x86_64 / ARM64) |
| macOS | `.dmg`, `.app` (Intel / Apple Silicon) |

Torne o AppImage executável:

```bash
chmod +x CachyCleaner-*.AppImage
./CachyCleaner-*.AppImage
```

### Rodar do código-fonte

Requisitos: **Python 3.10+**, pip e (no Linux) dependências de sistema do Qt.

```bash
git clone https://github.com/FernandoGabrielSilva/CachyCleaner.git
cd CachyCleaner
python3 -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python run.py
```

---

## 🧭 Como usar

1. **Visão geral** — veja quanto espaço é recuperável e clique em **Analisar sistema**.
2. **Analisar** — a varredura lista cada arquivo encontrado. Use a busca, marque o que deseja remover e clique em **Limpar selecionados**.
3. **Confirmação** — o app mostra quantos itens serão removidos e se vão para a lixeira ou exclusão permanente.
4. **Configurações** — idioma, tema, segurança, pastas extras, exclusões, regras e atualizações.
5. **Sobre** — versão, licença, link do GitHub e verificação manual de updates.

> 💡 **Dica:** o botão *Analisar sistema* pode ser clicado quantas vezes quiser. A limpeza nunca começa sozinha.

---

## 🏗️ Arquitetura

```
CachyCleaner/
├── app/
│   ├── main.py                 # Entry point Qt
│   ├── core/
│   │   ├── models.py           # Rule, ScanItem, CleanTarget, TrashResult
│   │   ├── system.py           # XDG, home, paths, platform helpers
│   │   ├── settings.py         # JSON atômico por usuário
│   │   ├── rules.py            # Regras embutidas + customizadas
│   │   ├── scanner.py          # ScanWorker (QThread)
│   │   ├── cleaner.py          # CleanWorker + estratégias de lixeira
│   │   └── updater.py          # UpdateChecker (QThread)
│   ├── ui/
│   │   ├── controller.py       # AppController (QmlElement)
│   │   ├── i18n/               # 12 catálogos JSON + detector de locale
│   │   └── qml/                # Interface declarativa + components/
│   └── assets/                 # Ícones SVG/PNG/ICO
├── tests/                      # unittest do core
├── packaging/linux/            # AppRun, .desktop, scripts AppImage
├── .github/workflows/          # Builds multiplataforma
├── CachyCleaner.spec           # PyInstaller
└── requirements.txt
```

**Decisões de design**
- **Nada é apagado sem confirmação explícita.** A lixeira é o destino padrão.
- **Regras conservadoras:** apenas caches/temp, nunca documentos do usuário.
- **I/O fora da UI:** `ScanWorker` e `CleanWorker` rodam em `QThread`, com sinais Qt.
- **Config resistente a crash:** escrita via `tempfile` + `os.replace`.
- **Fallback de i18n:** chave faltante cai para PT-BR → EN, nunca aparece texto cru.

---

## 🛠️ Desenvolvimento

```bash
# Testes do core
python3 -m unittest discover -s tests -v

# Rodar com update desligado
python3 run.py --no-update

# Ver versão
python3 run.py --version
```

### Gerar binário localmente (PyInstaller)

```bash
pip install pyinstaller
pyinstaller CachyCleaner.spec --noconfirm
```

O resultado fica em `dist/CachyCleaner/`.

### Gerar AppImage localmente

```bash
cd packaging/linux
./build-appimage.sh
```

---

## 🤝 Contribuindo

1. Faça um fork.
2. Crie uma branch: `git checkout -b feature/minha-feature`.
3. Commite: `git commit -m "feat: minha feature"`.
4. Push e abra um Pull Request.

Para adicionar idiomas, crie `app/ui/i18n/<codigo>.json` copiando `en.json` e registre em `LANGUAGES` em `translator.py`.

---

## 📄 Licença

Distribuído sob a licença **MIT**. Veja [LICENSE](LICENSE).

---

## 🔗 Links

- **Repositório:** https://github.com/FernandoGabrielSilva/CachyCleaner
- **Releases:** https://github.com/FernandoGabrielSilva/CachyCleaner/releases
- **Issues:** https://github.com/FernandoGabrielSilva/CachyCleaner/issues

Feito com 🐍 Python, ⚛️ Qt e carinho.
