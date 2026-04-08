# Inspire — Git Dev Toolkit

Beautiful, smart, and safe git shortcuts that make you faster every day.

```bash
gs   →  pretty git status
gq   →  quick conventional commit + validation
gqa  →  smart auto-commit (or split by module/file-type)
gl   →  pretty git log
````

## One-line install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/parthivendra/inspire-git-toolkit/main/install.sh | bash
```

Then reload your shell:

```bash
source ~/.bashrc   # or ~/.zshrc
```

## Manual install

```bash
mkdir -p ~/.local/share
curl -o ~/.local/share/inspire-git-toolkit.sh \
  https://raw.githubusercontent.com/parthivendra/inspire-git-toolkit/main/inspire-git-toolkit.sh

echo 'source ~/.local/share/inspire-git-toolkit.sh' >> ~/.bashrc   # or ~/.zshrc
source ~/.bashrc
```

## Features

* **gs** — Clean colored status with branch info
* **gq** — Enforces conventional commits + smart validation
* **gqa** — AI-like smart commit:

  * Auto-detects single file, low-risk files, single module
  * Splits intelligently when needed
  * Force mode (`gqa -f`) for quick commits
* **gl** — Beautiful git log graph

Works on **Bash 4+** (macOS users: `brew install bash`).

## Example usage

```bash
gqa
gqa -f
gq "feat: add login page"
gs
gl
```

## Requirements

* Git
* Bash 4+

## Contributing

PRs welcome! Especially:

* Fish/Zsh completion support
* More file-type detection
* Windows (Git Bash) testing

---

Made with ❤️ by [Parthivendra](https://github.com/parthivendra)

