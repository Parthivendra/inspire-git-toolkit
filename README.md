# Inspire — Git Dev Toolkit

**Beautiful, smart, and safe git shortcuts that make you faster every day.**

```bash
gs   →  pretty git status
gq   →  quick conventional commit + validation
gqa  →  smart automated commit (analysis + split modes)
gl   →  pretty git log
```

---

## 🚀 One-line install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/parthivendra/inspire-git-toolkit/main/install.sh | bash
```

Then reload your shell:

```bash
source ~/.bashrc   # or ~/.zshrc
```

---

## 🛠 Manual install

```bash
mkdir -p ~/.local/share

curl -o ~/.local/share/inspire-git-toolkit.sh \
https://raw.githubusercontent.com/parthivendra/inspire-git-toolkit/main/inspire-git-toolkit.sh

echo 'source ~/.local/share/inspire-git-toolkit.sh' >> ~/.bashrc   # or ~/.zshrc
source ~/.bashrc
```

---

## 🧰 Toolkit Management

### Inspire comes with a built-in CLI:

```
inspire update      # update to latest version
inspire uninstall   # remove toolkit
inspire version     # show installed version
```
---

## ✨ Features

### 🟢 `gs` — Pretty Git Status

* Clean, colorized output
* Shows current branch
* Displays concise working tree status

---

### 🔵 `gq` — Quick Commit (Validated)

* Stages all changes
* Enforces **Conventional Commits**
* Pushes automatically to current branch

#### ✔ Validation rules

* Format: `<type>: <description>`
* Minimum 10 characters in description
* Rejects vague messages like `update`, `fix`, `misc`

#### ✔ Supported types

```
feat, fix, docs, style, refactor, test,
chore, perf, build, ci, revert
```

---

### 🧠 `gqa` — Smart Automated Commit

> Fire-and-forget intelligent commit system.

Automatically:

* Analyzes changes
* Groups by module and file type
* Generates meaningful commit messages
* Pushes to remote

---

#### ⚙️ Modes

```bash
gqa              # Smart mode (auto or interactive)
gqa -n           # Dry-run (preview only)
gqa -f           # Force commit (bypass all checks)
gqa -f -n        # Preview force mode
```

---

#### 🧩 Decision Engine

| Condition          | Behavior                          |
| ------------------ | --------------------------------- |
| 1 file             | Auto commit                       |
| All low-risk files | Auto commit                       |
| Single module      | Auto commit                       |
| Multiple modules   | Interactive split                 |
| High complexity    | Stops (manual commit recommended) |

---

#### 🏷 Commit Message Logic

* `feat` → only new files
* `fix` → only modifications
* `chore` → mixed / deletes / renames

Tags:

* `[gqa]` → automatic
* `[split:gqa]` → split commits
* `[force:gqa]` → force mode

---

### 🟣 `gl` — Pretty Git Log

* Compact graph view
* Shows last 10 commits
* Includes branches and tags

---

## 📦 Example Usage

```bash
gqa
gqa -f
gq "feat: add login page with validation"
gs
gl
```

---

## ⚙️ Requirements

* Git
* Bash 4+

> macOS users:

```bash
brew install bash
```

---

## 🤝 Contributing

PRs are welcome! Especially for:

* Zsh/Fish completion support
* Better file-type detection
* Windows (Git Bash) support
* Performance improvements

---

## ✨ Bonus: Workspace Quick-Jump Pattern

Combine **navigation + environment activation + git status** into one command.

### Example

```bash
# ================================================================
#  Custom Workspace Shortcuts
#  Add these to your inspire-git-toolkit.sh or ~/.bashrc
# ================================================================

myproject() {
    local target="/path/to/your/project/folder"

    if [[ ! -d "$target" ]]; then
        echo -e "${RED}❌ Directory not found: $target${RESET}"
        return 1
    fi

    cd "$target" || return 1

    # Optional: activate conda environment (if available)
    if command -v conda >/dev/null 2>&1; then
        conda activate myproject 2>/dev/null || true
    fi

    # Show git status
    gs

    echo ""
    echo -e "${GREEN}🚀 Workspace ready. Build something meaningful.${RESET}"
}
```

---

### 💡 Why this is powerful

* Instant project navigation
* Auto environment setup
* Immediate git visibility
* Faster context switching

---

### 🔥 Pro Tips

* Name functions after projects → `backend`, `ml`, `portfolio`
* Combine with `gqa` for **1-command workflow**
* Create multiple workspace shortcuts

---

### ⚡ Optional Variations

#### Python venv

```bash
source venv/bin/activate 2>/dev/null || true
```

#### Open VS Code

```bash
code . 2>/dev/null || true
```

#### Multiple projects

```bash
backend() { cd ~/code/backend && gs; }
frontend() { cd ~/code/frontend && gs; }
```

---

## 🧠 Philosophy

Inspire is built around one idea:

> **Reduce friction between writing code and committing it.**

---

## ❤️ Author

Made with intent by
**Parthivendra Singh**
🔗 [https://github.com/parthivendra](https://github.com/parthivendra)

---

