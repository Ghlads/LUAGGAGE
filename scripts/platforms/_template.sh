#!/usr/bin/env bash
# platforms/_template.sh : squelette d'une nouvelle cible.
# Copier vers platforms/<nom>.sh (les fichiers commençant par "_" sont ignorés à l'auto-détection).
#
# CONTRAT
#   PLATFORM_NAME           (obligatoire) nom affiché
#   platform_match()        (obligatoire) code retour 0 si on tourne sur cette cible
#   platform_init()         (optionnel)   préparation (update index, vérif gestionnaire...) ; retour != 0 = abandon
#   dep_<nom>()             (une par dépendance de DEPS) ; retour 0 = OK ; ne jamais `exit`
#   check_<nom>()           (optionnel)   remplace le test par défaut de install_extern_dep.sh
#   PLATFORM_EXTRA_DEPS=()  (optionnel)   deps propres à cette cible
#   platform_post()         (optionnel)   message / actions finales
#
# Helpers dispo (lib/common.sh) : log ok warn err die has run csv_has
# Utiliser `run <cmd>` pour que --dry-run fonctionne. Rester idempotent.
#
# Deps actuelles : python py_tools node trash pwsh fd 7z wget go ruby composer julia cargo luarocks perl

PLATFORM_NAME="changeme"

platform_match() {
  # ex: [ "$(uname -s)" = "Darwin" ]
  return 1
}

platform_init() { return 0; }

dep_python()   { err "TODO"; return 1; }
dep_py_tools() { err "TODO"; return 1; }   # black, isort, pynvim
dep_node()     { err "TODO"; return 1; }   # node + npm
dep_trash()    { err "TODO"; return 1; }
dep_pwsh()     { err "TODO"; return 1; }
dep_fd()       { err "TODO"; return 1; }
dep_7z()       { err "TODO"; return 1; }
dep_wget()     { err "TODO"; return 1; }
dep_go()       { err "TODO"; return 1; }
dep_ruby()     { err "TODO"; return 1; }   # ruby + gem
dep_composer() { err "TODO"; return 1; }   # php + composer
dep_julia()    { err "TODO"; return 1; }
dep_cargo()    { err "TODO"; return 1; }
dep_luarocks() { err "TODO"; return 1; }
dep_perl()     { err "TODO"; return 1; }   # perl + Neovim::Ext

platform_post() { :; }
