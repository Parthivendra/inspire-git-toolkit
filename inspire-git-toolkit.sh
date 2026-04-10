#!/usr/bin/env bash
# ================================================================
#  Inspire - Git Dev Toolkit
#  Source this file in your .bashrc / .zshrc:
#    source ~/.local/share/inspire-git-toolkit.sh
#
#  Functions:
#    gs   — Pretty git status
#    gq   — Manual quick commit (with conventional-commit validation)
#    gqa  — Smart automated commit (change analysis + split modes)
#    gl   — Pretty git log (last 10)
#
#  All functions support -h / --help for usage information.
#
#  Requirements: Bash 4+, Git
# ================================================================

# ── Guard: prevent double-sourcing ───────────────────────────────
[[ -n "$_INSPIRE_TOOLKIT_LOADED" ]] && return 0
_INSPIRE_TOOLKIT_LOADED=1

# ── Bash version guard ──
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    echo -e "${YELLOW}Warning: Bash 4+ required (you have ${BASH_VERSION}).${RESET}"
    echo "             macOS users: brew install bash"
    return 1
fi

# ── Colors ───────────────────────────────────────────────────────
# Defined once here; all functions below reference these globals.
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'


# ================================================================
#  gs — Pretty Git Status
# ================================================================
gs() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo -e ""
        echo -e "${BOLD}${BLUE}gs${RESET} — Pretty Git Status"
        echo -e "────────────────────────────────────────"
        echo -e "${BOLD}Usage:${RESET}"
        echo -e "   gs"
        echo -e ""
        echo -e "${BOLD}Description:${RESET}"
        echo -e "   Displays the current branch and a concise git status."
        echo -e "   Shows a clean message if the working tree is clean,"
        echo -e "   otherwise prints a short-format diff summary."
        echo -e ""
        echo -e "${BOLD}Options:${RESET}"
        echo -e "   ${CYAN}-h, --help${RESET}   Show this help message and exit."
        echo -e ""
        echo -e "${BOLD}Examples:${RESET}"
        echo -e "   ${GREEN}gs${RESET}            # Show status of current repo"
        echo -e ""
        return 0
    fi

    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${YELLOW}Warning: Not a git repository.${RESET}"
        return 1
    fi

    local branch
    branch=$(git branch --show-current 2>/dev/null)

    if [[ -z "$branch" ]]; then
        branch="(detached HEAD @ $(git rev-parse --short HEAD 2>/dev/null))"
    fi

    echo -e "${BLUE}📂 Branch:${RESET} ${BOLD}${branch}${RESET}"
    echo "────────────────────────────────────────"

    if [[ -z "$(git status --porcelain)" ]]; then
        echo -e "${GREEN}✅ Working tree clean.${RESET}"
    else
        git status -s
    fi
}


# ================================================================
#  gq — Manual Quick Commit  (conventional commit + validation)
#
#  Usage: gq "feat: add login form"
# ================================================================
gq() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo -e ""
        echo -e "${BOLD}${BLUE}gq${RESET} — Manual Quick Commit"
        echo -e "────────────────────────────────────────"
        echo -e "${BOLD}Usage:${RESET}"
        echo -e "   gq \"<type>: <description>\""
        echo -e ""
        echo -e "${BOLD}Description:${RESET}"
        echo -e "   Stages all changes, validates a conventional commit message,"
        echo -e "   commits, and pushes to the current branch's remote."
        echo -e ""
        echo -e "${BOLD}Options:${RESET}"
        echo -e "   ${CYAN}-h, --help${RESET}   Show this help message and exit."
        echo -e ""
        echo -e "${BOLD}Commit Types:${RESET}"
        echo -e "   ${CYAN}feat${RESET}      A new feature"
        echo -e "   ${CYAN}fix${RESET}       A bug fix"
        echo -e "   ${CYAN}docs${RESET}      Documentation changes only"
        echo -e "   ${CYAN}style${RESET}     Formatting, whitespace (no logic change)"
        echo -e "   ${CYAN}refactor${RESET}  Code restructuring (no feature/fix)"
        echo -e "   ${CYAN}test${RESET}      Adding or updating tests"
        echo -e "   ${CYAN}chore${RESET}     Build process, tooling, maintenance"
        echo -e "   ${CYAN}perf${RESET}      Performance improvements"
        echo -e "   ${CYAN}build${RESET}     Build system or dependency changes"
        echo -e "   ${CYAN}ci${RESET}        CI/CD configuration changes"
        echo -e "   ${CYAN}revert${RESET}    Reverting a previous commit"
        echo -e ""
        echo -e "${BOLD}Validation Rules:${RESET}"
        echo -e "   • Must match pattern:  ${YELLOW}<type>: <description>${RESET}"
        echo -e "   • Description must be at least 10 characters"
        echo -e "   • Vague single-word descriptions are rejected"
        echo -e "     (e.g. update, changes, fix, minor, misc, wip, temp)"
        echo -e ""
        echo -e "${BOLD}Examples:${RESET}"
        echo -e "   ${GREEN}gq \"feat: add user login form with validation\"${RESET}"
        echo -e "   ${GREEN}gq \"fix: resolve null pointer in auth middleware\"${RESET}"
        echo -e "   ${GREEN}gq \"docs: update README with setup instructions\"${RESET}"
        echo -e "   ${GREEN}gq \"chore: update dependencies to latest versions\"${RESET}"
        echo -e ""
        return 0
    fi

    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${RED}❌ Not inside a git repository.${RESET}"
        return 1
    fi

    if [[ -z "$(git status --porcelain)" ]]; then
        echo -e "${YELLOW}⚠️  Nothing to commit — working tree clean.${RESET}"
        return 0
    fi

    if [[ -z "$1" ]]; then
        echo -e "${YELLOW}⚠️  Commit message required.${RESET}"
        echo "   Usage: gq \"type: meaningful message\""
        return 1
    fi

    local msg="$1"

    # ── Validation 1: conventional commit prefix ─────────────────
    if ! echo "$msg" | grep -qE "^(feat|fix|docs|style|refactor|test|chore|perf|build|ci|revert): "; then
        echo -e "${RED}❌ Invalid commit type.${RESET}"
        echo "   Use one of: feat, fix, docs, style, refactor, test, chore, perf, build, ci, revert"
        echo "   Example:    feat: add login form"
        return 1
    fi

    # ── Validation 2: minimum description length ─────────────────
    local content
    content=$(echo "$msg" | cut -d':' -f2- | xargs)

    if [[ ${#content} -lt 10 ]]; then
        echo -e "${RED}❌ Message too short (min 10 chars after the type prefix).${RESET}"
        return 1
    fi

    # ── Validation 3: reject single-word vague descriptions ──────
    if echo "$content" | grep -qiE "^(update|changes|fix|minor|misc|stuff|wip|temp|test|cleanup)$"; then
        echo -e "${RED}❌ Vague commit message — be specific about what changed.${RESET}"
        return 1
    fi

    local branch
    branch=$(git branch --show-current)
    if [[ -z "$branch" ]]; then
        echo -e "${YELLOW}⚠️  Detached HEAD — cannot push.${RESET}"
        return 1
    fi

    git add . &&
    git commit -m "$msg" || { echo -e "${RED}❌ Commit failed.${RESET}"; return 1; }
    git push -u origin "$branch" || { echo -e "${RED}❌ Push failed.${RESET}"; return 1; }

    echo -e "${GREEN}🚀 Pushed to ${BOLD}$branch${RESET}"
}


# ================================================================
#  gqa — Smart Automated Commit
#
#  Fire-and-forget by default. Narrates every action in color.
#  Only asks for input when a split decision genuinely matters.
#  Never asks for commit message confirmation — no _prompt_message.
#
#  Usage:
#    gqa              → smart mode (auto or interactive based on complexity)
#    gqa -f           → force mode (bypasses ALL safety checks, pushes instantly)
#    gqa [-n|--dry-run] → dry-run mode (shows what would happen, no git writes)
#    gqa [-h|--help]  → show this help message
# ================================================================
gqa() {

    # ── Help check (must come before other flag parsing) ─────────
    for arg in "$@"; do
        if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
            echo -e ""
            echo -e "${BOLD}${BLUE}gqa${RESET} — Smart Automated Commit"
            echo -e "────────────────────────────────────────"
            echo -e "${BOLD}Usage:${RESET}"
            echo -e "   gqa [options]"
            echo -e ""
            echo -e "${BOLD}Description:${RESET}"
            echo -e "   Analyzes all uncommitted changes, groups them by module and"
            echo -e "   file type, generates conventional commit messages automatically,"
            echo -e "   and pushes to the current branch."
            echo -e ""
            echo -e "   In smart mode, gqa decides the commit strategy based on:"
            echo -e "   • Number of changed files"
            echo -e "   • Number of distinct top-level modules (directories)"
            echo -e "   • File risk level (source code vs config vs docs)"
            echo -e ""
            echo -e "${BOLD}Options:${RESET}"
            echo -e "   ${CYAN}-f${RESET}              Force mode — bypasses ALL safety checks and"
            echo -e "                   complexity analysis. Commits everything in one"
            echo -e "                   shot with a generic chore message and pushes."
            echo -e "                   ${YELLOW}Use with caution.${RESET}"
            echo -e ""
            echo -e "   ${CYAN}-n, --dry-run${RESET}   Dry-run mode — performs the full analysis and"
            echo -e "                   shows exactly what would be staged, committed,"
            echo -e "                   and pushed — without writing anything to git."
            echo -e "                   Safe to use anytime for a preview."
            echo -e ""
            echo -e "   ${CYAN}-h, --help${RESET}      Show this help message and exit."
            echo -e ""
            echo -e "${BOLD}Decision Engine (priority order):${RESET}"
            echo -e "   ${GREEN}Auto-commit${RESET}   Single file, all low-risk files, or single module"
            echo -e "   ${YELLOW}Interactive${RESET}   Multiple modules or file types — choose single"
            echo -e "                   commit or split by module / file type"
            echo -e "   ${RED}Hard stop${RESET}     >4 modules, high-risk source files, >8 files —"
            echo -e "                   too complex for a single automated message"
            echo -e ""
            echo -e "${BOLD}Commit Message Format:${RESET}"
            echo -e "   Messages are generated automatically using conventional commits:"
            echo -e "   ${CYAN}feat${RESET}   — pure additions (new files only)"
            echo -e "   ${CYAN}fix${RESET}    — pure modifications (existing files updated)"
            echo -e "   ${CYAN}chore${RESET}  — deletions, renames, or mixed operations"
            echo -e ""
            echo -e "   Tagged with ${CYAN}[gqa]${RESET} (auto) or ${CYAN}[split:gqa]${RESET} (per-module split)."
            echo -e "   Force mode tags with ${CYAN}[force:gqa]${RESET}."
            echo -e ""
            echo -e "${BOLD}Examples:${RESET}"
            echo -e "   ${GREEN}gqa${RESET}             # Smart commit — auto or interactive"
            echo -e "   ${GREEN}gqa -n${RESET}          # Preview what gqa would do (no writes)"
            echo -e "   ${GREEN}gqa --dry-run${RESET}   # Same as above"
            echo -e "   ${GREEN}gqa -f${RESET}          # Force-commit everything immediately"
            echo -e "   ${GREEN}gqa -f -n${RESET}       # Preview a force commit without writing"
            echo -e ""
            return 0
        fi
    done

    # ── Flag parsing ─────────────────────────────────────────────
    local FORCE=0
    local DRY_RUN=0
    while [[ "$1" == -* ]]; do
        case "$1" in
            -f) FORCE=1 ;;
            -n|--dry-run) DRY_RUN=1 ;;
            *)
                echo -e "${RED}❌ Unknown flag: $1${RESET}"
                echo "   Usage: gqa [-f] [-n|--dry-run] [-h|--help]"
                return 1
                ;;
        esac
        shift
    done

    # ── Guards ───────────────────────────────────────────────────
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Not inside a git repository.${RESET}"
        return 1
    fi

    local raw_status
    raw_status=$(git status --porcelain)

    if [[ -z "$raw_status" ]]; then
        echo -e "${YELLOW}⚠️  Nothing to commit — working tree clean.${RESET}"
        return 0
    fi

    local branch
    branch=$(git branch --show-current)
    if [[ -z "$branch" ]]; then
        echo -e "${YELLOW}⚠️  Could not determine current branch (detached HEAD?).${RESET}"
        return 1
    fi

    # ── Parse git status into parallel arrays ────────────────────
    declare -a all_files=()
    declare -a all_statuses=()

    while IFS= read -r line; do
        local xy="${line:0:2}"
        local filepath="${line:3}"

        if [[ "$xy" =~ ^R ]]; then
            filepath="${line##* -> }"
        fi

        # git wraps paths that contain spaces or special chars in double
        # quotes. Strip them so `git add -- "$f"` resolves correctly.
        if [[ "$filepath" == '"'*'"' ]]; then
            filepath="${filepath:1:${#filepath}-2}"
        fi

        local status_code
        if   [[ "$xy" == "??" ]];    then status_code="A"
        elif [[ "$xy" =~ [A] ]];     then status_code="A"
        elif [[ "$xy" =~ [D] ]];     then status_code="D"
        elif [[ "$xy" =~ [R] ]];     then status_code="R"
        else                              status_code="M"
        fi

        all_files+=("$filepath")
        all_statuses+=("$status_code")
    done <<< "$raw_status"

    # ── Module grouping ──────────────────────────────────────────
    declare -A module_files
    declare -A module_counts
    declare -A module_added module_modified module_deleted module_renamed

    # ── File-type grouping ───────────────────────────────────────
    declare -A type_files
    declare -A type_counts
    declare -A type_added type_modified type_deleted

    # ── Risk-based file classifier ───────────────────────────────
    # low    → .md .txt .sh — safe to auto-commit without review
    # medium → .json .yaml  — config that affects behaviour
    # high   → source code  — needs accurate commit context
    _file_risk() {
        case "$1" in
            *.md|*.txt|*.rst|*.sh|*.bash) echo "low"    ;;
            *.lock|*.sum|*.pyc)           echo "low"    ;;
            .gitignore|.env*|*.cfg|*.ini) echo "low"    ;;
            *.json|*.yaml|*.yml|*.toml)   echo "medium" ;;
            *)                            echo "high"   ;;
        esac
    }

    local file_count=0
    local has_high_risk=0
    local all_low_risk=1

    for i in "${!all_files[@]}"; do
        local file="${all_files[$i]}"
        local sc="${all_statuses[$i]}"
        local top
        top=$(echo "$file" | cut -d'/' -f1)

        # Module buckets
        module_files["$top"]+="${file}"$'\n'
        (( module_counts["$top"]++ ))
        case "$sc" in
            A) (( module_added["$top"]++    )) ;;
            M) (( module_modified["$top"]++ )) ;;
            D) (( module_deleted["$top"]++  )) ;;
            R) (( module_renamed["$top"]++  )) ;;
        esac

        # File-type buckets
        local key
        case "$file" in
            *.py)                       key="python"     ;;
            *.js|*.ts|*.jsx|*.tsx)      key="javascript" ;;
            *.html)                     key="html"       ;;
            *.css|*.scss|*.sass)        key="css"        ;;
            *.c|*.cpp|*.h|*.hpp)        key="cpp"        ;;
            *.java)                     key="java"       ;;
            *.md|*.txt|*.rst)           key="docs"       ;;
            *.json|*.yaml|*.yml|*.toml) key="config"     ;;
            *.sh|*.bash)                key="shell"      ;;
            *.lock|*.sum|*.pyc)         key="generated"  ;;
            *)                          key="other"      ;;
        esac

        type_files["$key"]+="${file}"$'\n'
        (( type_counts["$key"]++ ))
        case "$sc" in
            A) (( type_added["$key"]++    )) ;;
            M) (( type_modified["$key"]++ )) ;;
            D) (( type_deleted["$key"]++  )) ;;
        esac

        # Risk tally
        local risk
        risk=$(_file_risk "$file")
        (( file_count++ ))
        if [[ "$risk" == "high" ]]; then
            has_high_risk=1
            all_low_risk=0
        elif [[ "$risk" == "medium" ]]; then
            all_low_risk=0
        fi
    done

    local module_count=${#module_counts[@]}
    local type_count=${#type_counts[@]}

    # ── Helpers ──────────────────────────────────────────────────

    # Returns: feat | fix | chore
    # feat  → pure adds    (new content arrived)
    # fix   → pure modifies (existing content updated)
    # chore → deletes, renames, or any mixed operation
    _commit_type() {
        local added="${1:-0}" modified="${2:-0}" deleted="${3:-0}" renamed="${4:-0}"
        if   [[ "$added"    -gt 0 && "$modified" -eq 0 && "$deleted" -eq 0 && "$renamed" -eq 0 ]]; then
            echo "feat"
        elif [[ "$modified" -gt 0 && "$added"    -eq 0 && "$deleted" -eq 0 && "$renamed" -eq 0 ]]; then
            echo "fix"
        else
            echo "chore"
        fi
    }

    # Builds a descriptive commit subject line.
    #
    # Args:
    #   $1  added count
    #   $2  modified count
    #   $3  deleted count
    #   $4  renamed count
    #   $5  module path (e.g. "Deep Learning")  — pass "" for multi-module
    #   $6  newline-delimited file list          — used for extensions + subfolder hints
    #
    # Examples:
    #   feat: add 15 pdf/pptx files to Deep Learning/ (U3-4 CNN, U5 GANS)
    #   fix: update ipynb file in NLP/
    #   chore: remove 15 pdf/pptx files from Deep Learning/ (U3-4 CNN, U5 GANS)
    #   chore: reorganize 3 py/md files in NLP/
    _build_msg() {
        local added="${1:-0}" modified="${2:-0}" deleted="${3:-0}" renamed="${4:-0}"
        local module="${5:-}"
        local filelist="${6:-}"
        local tag="${7:-[gqa]}"

        local type verb prep
        type=$(_commit_type "$added" "$modified" "$deleted" "$renamed")
        local count=$(( added + modified + deleted + renamed ))

        # Verb + preposition pair driven by dominant operation
        if   [[ "$added"    -gt 0 && "$modified" -eq 0 && "$deleted" -eq 0 ]]; then
            verb="add";        prep="to"
        elif [[ "$deleted"  -gt 0 && "$added"    -eq 0 && "$modified" -eq 0 ]]; then
            verb="remove";     prep="from"
        elif [[ "$modified" -gt 0 && "$added"    -eq 0 && "$deleted" -eq 0 ]]; then
            verb="update";     prep="in"
        else
            verb="reorganize"; prep="in"
        fi

        # ── Extension summary: up to 2 unique types, lowercase, no dot ──
        local -A _seen_exts=()
        local ext_list="" ext_count=0
        while IFS= read -r f; do
            [[ -z "$f" ]] && continue
            local ext="${f##*.}"
            [[ "$ext" == "$f" || -z "$ext" ]] && continue   # no extension
            ext="${ext,,}"
            if [[ -z "${_seen_exts[$ext]+x}" ]]; then
                _seen_exts["$ext"]=1
                (( ext_count++ ))
                if   [[ $ext_count -eq 1 ]]; then ext_list="$ext"
                elif [[ $ext_count -eq 2 ]]; then ext_list="$ext_list/$ext"
                fi
            fi
        done <<< "$filelist"

        # ── File noun with optional count prefix ──────────────────────
        local file_noun
        if [[ -n "$ext_list" ]]; then
            [[ "$count" -gt 1 ]] && file_noun="${ext_list} files" || file_noun="${ext_list} file"
        else
            [[ "$count" -gt 1 ]] && file_noun="files"             || file_noun="file"
        fi
        local count_part=""
        [[ "$count" -gt 1 ]] && count_part="$count "

        # ── Module path segment ───────────────────────────────────────
        local path_part=""
        [[ -n "$module" ]] && path_part=" $prep $module/"

        # ── Subfolder hints: up to 2 unique immediate subdirs ─────────
        local -A _seen_dirs=()
        local dir_hints="" dir_count=0
        while IFS= read -r f; do
            [[ -z "$f" ]] && continue
            local rel subdir
            if [[ -n "$module" ]]; then
                # Within a single module: hint = first subdir inside it
                rel="${f#"$module"/}"
                subdir="${rel%%/*}"
                [[ "$subdir" == "$rel" ]] && continue   # top-level file, no subdir
            else
                # Multi-module: hint = top-level directory name
                subdir="${f%%/*}"
                [[ "$subdir" == "$f" ]] && continue     # root-level file, skip
            fi
            [[ -z "${_seen_dirs[$subdir]+x}" ]] || continue
            _seen_dirs["$subdir"]=1
            (( dir_count++ ))
            local hint="${subdir:0:15}"   # cap hint length
            if   [[ $dir_count -eq 1 ]]; then dir_hints="$hint"
            elif [[ $dir_count -eq 2 ]]; then dir_hints="$dir_hints, $hint"
            fi
        done <<< "$filelist"

        local hint_part=""
        [[ -n "$dir_hints" ]] && hint_part=" ($dir_hints)"

        echo "${type}: ${verb} ${count_part}${file_noun}${path_part}${hint_part} ${tag}"
    }

    _stage_files() {
        local filelist="$1"
        while IFS= read -r f; do
            [[ -z "$f" ]] && continue
            if [[ "$DRY_RUN" -eq 1 ]]; then
                echo -e "   ${CYAN}[dry-run]${RESET} would stage: $f"
            else
                git add -- "$f" || echo -e "${YELLOW}⚠️  Could not stage: $f (skipped)${RESET}"
            fi
        done <<< "$filelist"
    }

    _do_commit() {
        local msg="$1"
        if [[ "$DRY_RUN" -eq 1 ]]; then
            echo -e "   ${CYAN}[dry-run]${RESET} would commit: $msg"
            commit_messages+=("$msg")
            return 0
        fi
        if git diff --cached --quiet; then
            echo -e "${YELLOW}⚠️  Nothing staged for this commit — skipping.${RESET}"
            return 0
        fi
        git commit -m "$msg" || {
            echo -e "${RED}❌ Commit failed (pre-commit hook rejected it?).${RESET}"
            return 1
        }
        commit_messages+=("$msg")
    }

    _show_analysis() {
        echo ""
        echo -e "${BLUE}${BOLD}📊 Change analysis — $file_count file(s) on branch ${CYAN}$branch${RESET}"
        echo ""
        echo -e "${BOLD}  📂 Module breakdown:${RESET}"
        for key in "${!module_counts[@]}"; do
            local s=""
            [[ "${module_added[$key]:-0}"    -gt 0 ]] && s="added"
            [[ "${module_modified[$key]:-0}" -gt 0 ]] && s="${s:+$s + }modified"
            [[ "${module_deleted[$key]:-0}"  -gt 0 ]] && s="${s:+$s + }removed"
            [[ "${module_renamed[$key]:-0}"  -gt 0 ]] && s="${s:+$s + }renamed"
            printf "     %-24s %s file(s)  ${CYAN}[%s]${RESET}\n" \
                "$key" "${module_counts[$key]}" "$s"
        done
        echo ""
        echo -e "${BOLD}  📄 File-type breakdown:${RESET}"
        for key in "${!type_counts[@]}"; do
            local s=""
            [[ "${type_added[$key]:-0}"    -gt 0 ]] && s="added"
            [[ "${type_modified[$key]:-0}" -gt 0 ]] && s="${s:+$s + }modified"
            [[ "${type_deleted[$key]:-0}"  -gt 0 ]] && s="${s:+$s + }removed"
            printf "     %-24s %s file(s)  ${CYAN}[%s]${RESET}\n" \
                "$key" "${type_counts[$key]}" "$s"
        done
        echo ""
    }

    # ── Build totals used by all paths ───────────────────────────
    local total_a=0 total_m=0 total_d=0
    for sc in "${all_statuses[@]}"; do
        case "$sc" in A) (( total_a++ )) ;; M) (( total_m++ )) ;; D) (( total_d++ )) ;; esac
    done

    # ── Dry-run banner ───────────────────────────────────────────
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${CYAN}ℹ️  DRY-RUN MODE — no git writes will occur.${RESET}"
    fi

    # ── Force mode ───────────────────────────────────────────────
    # Placed here so $file_count and op totals are fully available.
    if [[ "$FORCE" -eq 1 ]]; then
        local summary
        [[ "$total_a" -gt 0 ]] && summary="added"
        [[ "$total_m" -gt 0 ]] && summary="${summary:+$summary + }modified"
        [[ "$total_d" -gt 0 ]] && summary="${summary:+$summary + }removed"
        echo -e "${RED}⚠️  FORCE MODE ACTIVE — Bypassing safety checks.${RESET}"
        local force_msg="chore: force commit $file_count files ($summary) [force:gqa]"
        if [[ "$DRY_RUN" -eq 1 ]]; then
            echo -e "   ${CYAN}[dry-run]${RESET} would git add ."
            echo -e "   ${CYAN}[dry-run]${RESET} would commit: $force_msg"
            echo -e "   ${CYAN}[dry-run]${RESET} would push to $branch"
        else
            git add .
            git commit -m "$force_msg" || { echo -e "${RED}❌ Commit failed.${RESET}"; return 1; }
            git push -u origin "$branch" || { echo -e "${RED}❌ Push failed.${RESET}"; return 1; }
            echo -e "${GREEN}🚀 Force pushed to ${BOLD}$branch${RESET}"
            echo -e "   ${CYAN}↳${RESET} $force_msg"
        fi
        return 0
    fi

    # ═════════════════════════════════════════════════════════════
    # 🧠 DECISION ENGINE  (strict priority order)
    #
    #   file_count    — total changed files
    #   module_count  — distinct top-level directories
    #   type_count    — distinct file-type buckets
    #   has_high_risk — 1 if any source code file changed
    #   all_low_risk  — 1 if every file is .md/.sh/.txt etc.
    #
    # The guiding principle: interactive mode is a last resort, not a
    # default. Auto-commit whenever the change is coherent enough that
    # a single commit message won't be misleading. Only escalate to
    # interactive when splitting would genuinely improve history clarity.
    #
    # Priority order:
    #   Step 2 — 1 file                              → auto
    #   Step 3 — all low-risk                        → auto
    #   Step 4 — 1 module (any file count)           → auto
    #   Step 5 — (reserved / removed)
    #   Step 6 — hard stop (many modules, high risk,
    #             large batch)                        → exit, guide manually
    #   Step 7 — 2+ modules, any size                → interactive
    # ═════════════════════════════════════════════════════════════

    declare -a commit_messages=()
    local default_msg choice

    # ── STEP 2: Exactly 1 file ───────────────────────────────────
    if [[ "$file_count" -eq 1 ]]; then
        local only_mod="${!module_counts[@]}"
        local only_file="${all_files[0]}"
        default_msg=$(_build_msg "$total_a" "$total_m" "$total_d" "0" \
            "$only_mod" "$only_file" "[gqa]")
        echo -e "${GREEN}✅ Single file — auto-committing.${RESET}"
        echo -e "   ${CYAN}↳${RESET} $default_msg"
        if [[ "$DRY_RUN" -eq 1 ]]; then
            echo -e "   ${CYAN}[dry-run]${RESET} would git add ."
        else
            git add .
        fi
        _do_commit "$default_msg" || return 1

    # ── STEP 3: All files are low-risk ───────────────────────────
    elif [[ "$all_low_risk" -eq 1 ]]; then
        local all_filelist
        printf -v all_filelist '%s\n' "${all_files[@]}"
        default_msg=$(_build_msg "$total_a" "$total_m" "$total_d" "0" "" "$all_filelist" "[gqa]")
        echo -e "${GREEN}✅ Low-risk files only — auto-committing.${RESET}"
        echo -e "   ${CYAN}↳${RESET} $default_msg"
        if [[ "$DRY_RUN" -eq 1 ]]; then
            echo -e "   ${CYAN}[dry-run]${RESET} would git add ."
        else
            git add .
        fi
        _do_commit "$default_msg" || return 1

    # ── STEP 4: Single module, focused ───────────────────────────
    elif [[ "$module_count" -eq 1 ]]; then
        local only_mod="${!module_counts[@]}"
        local all_filelist
        printf -v all_filelist '%s\n' "${all_files[@]}"
        default_msg=$(_build_msg "$total_a" "$total_m" "$total_d" "0" \
            "$only_mod" "$all_filelist" "[gqa]")
        echo -e "${GREEN}✅ Single module — auto-committing.${RESET}"
        echo -e "   ${CYAN}↳${RESET} $default_msg"
        if [[ "$DRY_RUN" -eq 1 ]]; then
            echo -e "   ${CYAN}[dry-run]${RESET} would git add ."
        else
            git add .
        fi
        _do_commit "$default_msg" || return 1

    # ── STEP 5: (multi-module auto-commit removed) ───────────────
    # Any change spanning 2+ modules goes directly to Step 7
    # interactive, regardless of file count. Auto-commit is only
    # safe when all changes are within a single module (Step 4).

    # ── STEP 6: Hard stop ────────────────────────────────────────
    # Only fires when: high-risk source files span many modules AND
    # the file count is large enough that a single message is genuinely
    # misleading. Don't hard-stop on medium complexity — that's Step 7.
    elif [[ "$module_count" -gt 4 && "$has_high_risk" -eq 1 && "$file_count" -gt 8 ]]; then
        _show_analysis
        echo -e "${RED}🚨 High complexity — gqa won't auto-commit this.${RESET}"
        echo -e "   $file_count high-risk files across $module_count modules."
        echo -e "   A single commit message would be misleading here."
        echo ""
        echo -e "   ${YELLOW}Stage and commit each module manually with git add / git commit.${RESET}"
        return 1

    # ── STEP 7: Interactive — genuinely split-worthy ─────────────
    # Reaches here only when: multiple modules, more than a small batch,
    # and not so extreme that it warrants a hard stop.
    # This is where splitting actually improves history clarity.
    else
        _show_analysis
        echo -e "${YELLOW}⚠️  Note:${RESET} Splitting is heuristic — may break cross-module features."
        echo ""

        if [[ "$module_count" -gt 1 ]]; then
            echo "  Changes span $module_count modules. Choose commit mode:"
            echo "    [1] Single commit (recommended if this is one feature)"
            echo "    [2] Split by module"
            echo ""
            read -rp "  Enter choice (1/2): " choice
            while [[ "$choice" != "1" && "$choice" != "2" ]]; do
                echo -e "${YELLOW}Invalid choice. Please type 1 or 2.${RESET}"
                read -rp "  Enter choice (1/2): " choice
            done

            if [[ "$choice" == "2" ]]; then
                for key in "${!module_files[@]}"; do
                    default_msg=$(_build_msg \
                        "${module_added[$key]:-0}" \
                        "${module_modified[$key]:-0}" \
                        "${module_deleted[$key]:-0}" \
                        "${module_renamed[$key]:-0}" \
                        "$key" "${module_files[$key]}" "[split:gqa]")
                    echo ""
                    echo -e "  ${BOLD}📦 Staging & committing $key/...${RESET}"
                    echo -e "   ${CYAN}↳${RESET} $default_msg"
                    _stage_files "${module_files[$key]}"
                    _do_commit "$default_msg" || return 1
                done
            else
                local all_filelist
                printf -v all_filelist '%s\n' "${all_files[@]}"
                default_msg=$(_build_msg "$total_a" "$total_m" "$total_d" "0" "" "$all_filelist" "[gqa]")
                echo ""
                echo -e "  ${BOLD}📦 Staging & committing all files...${RESET}"
                echo -e "   ${CYAN}↳${RESET} $default_msg"
                if [[ "$DRY_RUN" -eq 1 ]]; then
                    echo -e "   ${CYAN}[dry-run]${RESET} would git add ."
                else
                    git add .
                fi
                _do_commit "$default_msg" || return 1
            fi
        else
            echo "  Multiple file types in one module. Choose commit mode:"
            echo "    [1] Single commit (recommended if this is one feature)"
            echo "    [2] Split by file type"
            echo ""
            read -rp "  Enter choice (1/2): " choice
            while [[ "$choice" != "1" && "$choice" != "2" ]]; do
                echo -e "${YELLOW}Invalid choice. Please type 1 or 2.${RESET}"
                read -rp "  Enter choice (1/2): " choice
            done

            if [[ "$choice" == "2" ]]; then
                for key in "${!type_files[@]}"; do
                    default_msg=$(_build_msg \
                        "${type_added[$key]:-0}" \
                        "${type_modified[$key]:-0}" \
                        "${type_deleted[$key]:-0}" \
                        "0" "" "${type_files[$key]}" "[split:gqa]")
                    echo ""
                    echo -e "  ${BOLD}📦 Staging & committing $key files...${RESET}"
                    echo -e "   ${CYAN}↳${RESET} $default_msg"
                    _stage_files "${type_files[$key]}"
                    _do_commit "$default_msg" || return 1
                done
            else
                local all_filelist
                printf -v all_filelist '%s\n' "${all_files[@]}"
                default_msg=$(_build_msg "$total_a" "$total_m" "$total_d" "0" "" "$all_filelist" "[gqa]")
                echo ""
                echo -e "  ${BOLD}📦 Staging & committing all files...${RESET}"
                echo -e "   ${CYAN}↳${RESET} $default_msg"
                if [[ "$DRY_RUN" -eq 1 ]]; then
                    echo -e "   ${CYAN}[dry-run]${RESET} would git add ."
                else
                    git add .
                fi
                _do_commit "$default_msg" || return 1
            fi
        fi
    fi

    # ── Push (always automatic — no confirmation prompt) ─────────
    if [[ ${#commit_messages[@]} -eq 0 ]]; then
        echo -e "\n${YELLOW}⚠️  No commits were made.${RESET}"
        return 0
    fi

    # ── Remote origin check ──────────────────────────────────────
    if ! git remote get-url origin > /dev/null 2>&1; then
        echo -e "\n${YELLOW}⚠️  No remote 'origin' found — skipping push.${RESET}"
        echo -e "   Add one with: git remote add origin <url>"
        echo -e "\n${GREEN}✅ ${#commit_messages[@]} commit(s) made locally on ${BOLD}$branch${RESET}"
        for msg in "${commit_messages[@]}"; do
            echo -e "   ${CYAN}✔${RESET}  $msg"
        done
        return 0
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "\n${CYAN}[dry-run]${RESET} would push ${#commit_messages[@]} commit(s) to ${BOLD}$branch${RESET}"
        for msg in "${commit_messages[@]}"; do
            echo -e "   ${CYAN}✔${RESET}  $msg"
        done
        return 0
    fi

    git push -u origin "$branch" || {
        echo -e "${RED}❌ Push failed. Run manually: git push -u origin $branch${RESET}"
        return 1
    }
    echo -e "\n${GREEN}🚀 Pushed ${#commit_messages[@]} commit(s) to ${BOLD}$branch${RESET}"
    for msg in "${commit_messages[@]}"; do
        echo -e "   ${CYAN}✔${RESET}  $msg"
    done
}


# ================================================================
#  gl — Pretty Git Log (last 10 commits)
# ================================================================
gl() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo -e ""
        echo -e "${BOLD}${BLUE}gl${RESET} — Pretty Git Log"
        echo -e "────────────────────────────────────────"
        echo -e "${BOLD}Usage:${RESET}"
        echo -e "   gl"
        echo -e ""
        echo -e "${BOLD}Description:${RESET}"
        echo -e "   Displays the last 10 commits as a compact, decorated graph."
        echo -e "   Output includes branch pointers, tags, and merge topology."
        echo -e ""
        echo -e "${BOLD}Options:${RESET}"
        echo -e "   ${CYAN}-h, --help${RESET}   Show this help message and exit."
        echo -e ""
        echo -e "${BOLD}Examples:${RESET}"
        echo -e "   ${GREEN}gl${RESET}            # Show last 10 commits with graph"
        echo -e ""
        return 0
    fi

    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Not a git repository.${RESET}"
        return 1
    fi
    git log --oneline --graph --decorate -10
}

igt() {
    case "$1" in
        update)
            echo -e "${CYAN}🔄 Updating Inspire Git Toolkit...${RESET}"
            curl -fsSL https://raw.githubusercontent.com/parthivendra/inspire-git-toolkit/main/install.sh | bash
            ;;

        uninstall)
            echo -e "${RED}🧹 Uninstalling Inspire Git Toolkit...${RESET}"
            curl -fsSL https://raw.githubusercontent.com/parthivendra/inspire-git-toolkit/main/install.sh | bash -s -- --uninstall
            ;;

        version)
            echo "Inspire Git Toolkit v1.1.0"
            ;;

        *)
            echo -e "${BOLD}${BLUE}igt${RESET} — Inspire Git Toolkit CLI"
            echo "────────────────────────────────────"
            echo "Usage:"
            echo "  igt update"
            echo "  igt uninstall"
            echo "  igt version"
            ;;
    esac
}
