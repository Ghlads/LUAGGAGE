#!/usr/bin/env bash
# lib/common.sh : helpers partagés (sourcé par install_extern_dep.sh et les platforms/*.sh)

if [ -t 1 ]; then
  C_B=$'\033[1;34m'; C_G=$'\033[1;32m'; C_Y=$'\033[1;33m'; C_R=$'\033[1;31m'; C_0=$'\033[0m'
else
  C_B=""; C_G=""; C_Y=""; C_R=""; C_0=""
fi

log()  { printf '%s[INFO]%s %s\n' "$C_B" "$C_0" "$*"; }
ok()   { printf '%s[ OK ]%s %s\n' "$C_G" "$C_0" "$*"; }
warn() { printf '%s[WARN]%s %s\n' "$C_Y" "$C_0" "$*" >&2; }
err()  { printf '%s[FAIL]%s %s\n' "$C_R" "$C_0" "$*" >&2; }
die()  { err "$*"; exit 1; }

# has <cmd> : la commande existe dans le PATH ?
has() { command -v "$1" >/dev/null 2>&1; }

# run <cmd...> : exécute, ou affiche seulement en mode --dry-run
run() {
  if [ "${DRY_RUN:-0}" = 1 ]; then
    printf '  [dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

# csv_has ",a,b," "a" : l'élément est-il dans la liste CSV (entourée de virgules) ?
csv_has() { case "$1" in *",$2,"*) return 0 ;; esac; return 1; }
