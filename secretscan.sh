#!/bin/bash
# secretscan pre-commit hook: blocks commits that contain likely secrets
# Usage: bash secretscan.sh [scan|install|uninstall] [repo]

RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

names=(
    "AWS access key"
    "GitHub token"
    "API secret key"
    "private key"
    "hardcoded password or token"
)

patterns=(
    'AKIA[0-9A-Z]{16}'
    'ghp_[A-Za-z0-9]{36}'
    'sk-[A-Za-z0-9]{20,}'
    '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
    $'(password|passwd|secret|api_?key|token)[[:space:]]*[=:][[:space:]]*[\'"][^\'"]{6,}[\'"]'
)

usage() {
    echo "Usage: bash secretscan.sh scan                 scan staged changes"
    echo "       bash secretscan.sh install [repo]       install as a pre-commit hook"
    echo "       bash secretscan.sh uninstall [repo]     remove the hook"
    exit 1 
}

staged_added_lines() {
    git diff --cached -UO --no-color --diff-filter=ACM \
        | awk '/^\+\+\+ b\// { file = substr($0, 7); next }
               /^\+/ { print file "\t" substr($0, 2) }' 
}

run_scan() {
    local found=0 file content i 

    while IFS=$'\t' read -r file content; do 
        [[ "$content" == *"secretscan:ignore"* ]] && continue 

        for i in "${!patterns[@]}"; do 
            if grep -Eiq -e "${patterns[$i]}" <<< "$content"; then 
                echo -e "${RED}BLOCKED${RESET} $file: possible ${names[$i]}"
                found=$((found + 1))
                break
            fi 
        done 
    done < <(staged_added_lines)

    if [ "$found" -gt 0 ]; then 
        echo 
        echo "Commit blocked: $found possible secret(s) in staged changes."
        echo "Remove them (use environment variables instead)."
        echo "If it is a false alarm: add 'secretscan:ignore' to that line,"
        echo "or bypass once with: git commit --no-verify"
        exit 1
    fi 

    echo -e "${GREEN}secretscan: no secrets found.${RESET}"
}

hook_path() {
    local gitdir
    gitdir=$(git -C "${1:-.}" rev-parse --absolute-git-dir 2>/dev/null) || {
        echo "Error: '${1:-.}'is not a git repository"
        exit 1
    }
    echo "$gitdir/hooks/pre-commit"
}

install_hook() {
    local dest 
    dest=$(hook_path "$1") || exit 1

    if [ -f "$dest" ] && ! grep -q "secretscan pre-commit hook" "$dest"; then 
        echo "Error: a different pre-commit hook already exists. Not overwriting."
        exit 1
    fi 

    mkdir -p "$(dirname "$dest")"
    cp "$0" "$dest"
    chmod +x "$dest"
    echo "Installed secret scanner hook: $dest"
}

uninstall_hook() {
    local dest 
    dest=$(hook_path "$1") || exit 1

    if [ -f "$dest" ] && grep -q "secretscan pre-commit hook" "$dest"; then 
        rm "$dest"
        echo "Removed hook: $dest"
    else 
        echo "No secretscan hook found."
    fi 
}

case "${1:-scan}" in 
    scan)       run_scan ;;
    install)    install_hook "$2" ;;
    uninstall)  uninstall_hook "$2" ;;
    *)          usage ;;
esac 