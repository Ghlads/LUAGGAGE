#!/usr/bin/env bash
# =============================================================================
# install_extern_dep.sh : installe les dépendances externes vues par :checkhealth
#
# Usage :
#   ./install_extern_dep.sh [--platform NOM] [--dry-run] [--only a,b] [--skip a,b] [--list]
#
# Windows : à lancer depuis Git Bash (mintty). Linux : Ubuntu/Debian.
#
# Structure :
#   install_extern_dep.sh   <- ce fichier (orchestrateur, liste des deps logiques)
#   lib/common.sh           <- helpers (log, run, has...)
#   platforms/ubuntu.sh     <- implémentation Ubuntu/Debian
#   platforms/windows.sh    <- implémentation Windows (Git Bash + winget/scoop)
#   platforms/_template.sh  <- squelette pour une nouvelle cible (ignoré par l'auto-détection)
#
# AJOUTER UNE NOUVELLE CONFIG / UN NOUVEL OS :
#   1. Copier platforms/_template.sh vers platforms/<nom>.sh
#   2. Remplir platform_match() + les fonctions dep_<nom>()
#   3. C'est tout : l'auto-détection parcourt platforms/*.sh (ou --platform <nom>)
#
# AJOUTER UNE NOUVELLE DÉPENDANCE :
#   - Ajouter son nom dans DEPS ci-dessous + son test dans dep_is_installed()
#   - Implémenter dep_<nom>() dans chaque platforms/*.sh (sinon : "non supporté", ignoré)
#   - Ou, pour une cible seulement : PLATFORM_EXTRA_DEPS=(ma_dep) + check_ma_dep()
#     + dep_ma_dep() directement dans platforms/<nom>.sh
#
# -----------------------------------------------------------------------------
# TEMPLATE DE PROMPT (à me donner pour générer un nouveau platforms/<nom>.sh)
# -----------------------------------------------------------------------------
# Voici mon install_extern_dep.sh et platforms/_template.sh (colle-les).
# Génère-moi platforms/<nom>.sh pour cette nouvelle cible :
#
#   - OS / distribution / version      : (ex: Fedora 41, Arch, macOS 15, Alpine, WSL2 Debian...)
#   - Architecture                     : (x86_64 / arm64)
#   - Shell utilisé pour lancer        : (bash, zsh, git-bash, msys2...)
#   - Gestionnaire(s) de paquets       : (dnf, pacman, brew, apk, nix, scoop, choco...)
#   - Droits admin                     : (sudo dispo ? root ? pas de droits ?)
#   - Commande de détection            : (ex: `uname -s`, contenu de /etc/os-release...)
#   - Particularités                   : (proxy, pas de snap, pas de systemd, container...)
#   - Deps à gérer                     : (toutes celles de DEPS, ou liste réduite)
#   - Sortie :checkhealth de la cible  : (colle les warnings/erreurs si utile)
#
# Contraintes : respecter le contrat de _template.sh (PLATFORM_NAME, platform_match,
# platform_init optionnel, dep_<nom>, platform_post optionnel), utiliser run/has/log
# de lib/common.sh, être idempotent, et ne jamais `exit` dans une fonction dep_*.
# =============================================================================

set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$ROOT_DIR/lib/common.sh"

# Ordre important : node avant trash (trash-cli passe par npm sur Windows).
DEPS=(python py_tools node trash pwsh fd 7z wget go ruby composer julia cargo luarocks perl)

FORCE_PLATFORM=""; ONLY=""; SKIP=""; LIST=0
export DRY_RUN=0

usage() { sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

# Test "est-ce déjà installé ?" : un check_<dep>() défini par la platform prend la priorité.
dep_is_installed() {
  local d="$1"
  if declare -F "check_$d" >/dev/null; then "check_$d"; return; fi
  case "$d" in
    python)   has python3 || { has python && python -c "" >/dev/null 2>&1; } ;;
    py_tools) has black && has isort && { python3 -c "import pynvim" || python -c "import pynvim"; } >/dev/null 2>&1 ;;
    node)     has node && has npm ;;
    trash)    has trash ;;
    pwsh)     has pwsh ;;
    fd)       has fd ;;
    7z)       has 7z || has 7zz || has 7za ;;
    wget)     has wget ;;
    go)       has go ;;
    ruby)     has ruby && has gem ;;
    composer) has php && has composer ;;
    julia)    has julia ;;
    cargo)    has cargo && cargo --version >/dev/null 2>&1 ;;
    luarocks) has luarocks ;;
    perl)     has perl && perl -MNeovim::Ext -e1 >/dev/null 2>&1 ;;
    *)        return 1 ;;
  esac
}

load_platform() {
  local f
  if [ -n "$FORCE_PLATFORM" ]; then
    f="$ROOT_DIR/platforms/$FORCE_PLATFORM.sh"
    [ -f "$f" ] || die "platform introuvable : $f"
    # shellcheck disable=SC1090
    . "$f"; return 0
  fi
  for f in "$ROOT_DIR"/platforms/*.sh; do
    case "$(basename "$f")" in _*) continue ;; esac
    # match dans un sous-shell pour ne pas polluer l'environnement
    if ( . "$f"; platform_match ) >/dev/null 2>&1; then
      # shellcheck disable=SC1090
      . "$f"; return 0
    fi
  done
  return 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --platform) FORCE_PLATFORM="${2:-}"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    --only)     ONLY=",${2:-},"; shift 2 ;;
    --skip)     SKIP=",${2:-},"; shift 2 ;;
    --list)     LIST=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *)          err "option inconnue : $1"; usage; exit 2 ;;
  esac
done

load_platform || die "aucune platform ne correspond à ce système. Voir le template de prompt en tête de ce fichier."
log "Platform : ${PLATFORM_NAME:-?}  (dry-run=$DRY_RUN)"

# Deps supplémentaires propres à la platform
if [ -n "${PLATFORM_EXTRA_DEPS+x}" ]; then DEPS+=("${PLATFORM_EXTRA_DEPS[@]}"); fi

if [ "$LIST" = 1 ]; then printf '%s\n' "${DEPS[@]}"; exit 0; fi

declare -F platform_init >/dev/null && { platform_init || die "platform_init a échoué"; }

R_OK=(); R_SKIP=(); R_FAIL=(); R_PATH=(); R_UNSUP=()

for dep in "${DEPS[@]}"; do
  if [ -n "$ONLY" ] && ! csv_has "$ONLY" "$dep"; then continue; fi
  if [ -n "$SKIP" ] && csv_has "$SKIP" "$dep"; then continue; fi

  if dep_is_installed "$dep"; then
    ok "$dep : déjà présent"; R_SKIP+=("$dep"); continue
  fi
  if ! declare -F "dep_$dep" >/dev/null; then
    warn "$dep : non supporté par la platform ${PLATFORM_NAME}"; R_UNSUP+=("$dep"); continue
  fi

  log "$dep : installation..."
  if "dep_$dep"; then
    hash -r
    if [ "$DRY_RUN" = 1 ] || dep_is_installed "$dep"; then
      ok "$dep : installé"; R_OK+=("$dep")
    else
      warn "$dep : installé mais pas visible dans ce shell (PATH ? relance le terminal)"; R_PATH+=("$dep")
    fi
  else
    err "$dep : échec"; R_FAIL+=("$dep")
  fi
done

declare -F platform_post >/dev/null && platform_post

echo
echo "================ Résumé ================"
echo "Installés          : ${R_OK[*]:-aucun}"
echo "Déjà présents      : ${R_SKIP[*]:-aucun}"
echo "Installés, PATH ?  : ${R_PATH[*]:-aucun}"
echo "Non supportés      : ${R_UNSUP[*]:-aucun}"
echo "Échecs             : ${R_FAIL[*]:-aucun}"
echo "========================================"
echo "Relance ton terminal puis :checkhealth dans nvim."
[ "${#R_FAIL[@]}" -eq 0 ]
