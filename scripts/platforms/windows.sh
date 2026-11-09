#!/usr/bin/env bash
# platforms/windows.sh : Windows 10/11 via Git Bash / MSYS2 (winget, scoop en secours)
# NB : les IDs winget sont à vérifier avec `winget search <nom>` si un échec apparaît.

PLATFORM_NAME="windows"

platform_match() {
  case "$(uname -s 2>/dev/null)" in MINGW*|MSYS*|CYGWIN*) return 0 ;; esac
  return 1
}

# ---------------------------------------------------------------- helpers PATH
# Recharge le PATH Windows (Machine+User) dans le shell courant.
refresh_path() {
  local raw
  raw="$(powershell.exe -NoProfile -Command \
    "[Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path','Machine')+';'+[Environment]::GetEnvironmentVariable('Path','User'))" \
    2>/dev/null | tr -d '\r')"
  [ -n "$raw" ] && PATH="$PATH:$(cygpath -u -p "$raw" 2>/dev/null)"
  export PATH; hash -r
}

# PowerShell avec le PATH *Windows* (sans /usr/bin de Git : sinon `perl` = celui de Git, pas Strawberry).
win_ps() {
  powershell.exe -NoProfile -Command "\$env:Path=[Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path','Machine')+';'+[Environment]::GetEnvironmentVariable('Path','User')); $*"
}

# add_user_path <chemin windows> : ajoute au PATH utilisateur (permanent, REG_EXPAND_SZ préservé)
# + broadcast du changement + PATH du shell courant.
add_user_path() {
  local wp="$1" ps
  if [ "${DRY_RUN:-0}" = 1 ]; then log "[dry-run] ajout au PATH utilisateur : $wp"; return 0; fi
  ps="\$k=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment',\$true); \$p=\$k.GetValue('Path','',[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames); if((\$p -split ';') -notcontains '$wp'){ \$k.SetValue('Path',(\$p.TrimEnd(';')+';$wp'),[Microsoft.Win32.RegistryValueKind]::ExpandString) }; \$k.Close(); [Environment]::SetEnvironmentVariable('NVIMDEPS_REFRESH','1','User'); [Environment]::SetEnvironmentVariable('NVIMDEPS_REFRESH',\$null,'User')"
  powershell.exe -NoProfile -Command "$ps" || return 1
  PATH="$PATH:$(cygpath -u "$wp")"; export PATH; hash -r
  ok "PATH utilisateur : +$wp"
}

# ensure_in_path <cmd> <glob-unix>... : si <cmd> n'est pas dans le PATH, cherche son dossier et l'ajoute.
ensure_in_path() {
  local cmd="$1" g d e; shift
  has "$cmd" && return 0
  for g in "$@"; do
    for d in $g; do
      [ -d "$d" ] || continue
      for e in "" .exe .cmd .bat; do
        if [ -f "$d/$cmd$e" ]; then add_user_path "$(cygpath -w "$d")"; return $?; fi
      done
    done
  done
  warn "$cmd : dossier introuvable, ajoute-le manuellement au PATH"
  return 1
}

# ---------------------------------------------------------------- installeurs
winget_install() {
  if winget.exe list --id "$1" -e >/dev/null 2>&1; then log "winget: $1 déjà installé"; refresh_path; return 0; fi
  run winget.exe install --id "$1" -e --silent --accept-package-agreements --accept-source-agreements || return 1
  [ "${DRY_RUN:-0}" = 1 ] || refresh_path
}

has_scoop() { win_ps "if(Get-Command scoop -ErrorAction SilentlyContinue){exit 0}else{exit 1}" >/dev/null 2>&1; }

scoop_install() {
  has_scoop || { err "scoop absent (installe-le : https://scoop.sh)"; return 1; }
  [ "${DRY_RUN:-0}" = 1 ] && { log "[dry-run] scoop install $*"; return 0; }
  win_ps "scoop install $*" || return 1
  refresh_path
}

platform_init() {
  has winget.exe || { err "winget.exe introuvable (App Installer du Microsoft Store)"; return 1; }
  has powershell.exe || { err "powershell.exe introuvable"; return 1; }
  refresh_path
}

# ---------------------------------------------------------------- checks spécifiques
# Git Bash a son propre perl : on teste celui du PATH Windows (Strawberry), celui que voit nvim.
check_perl() { win_ps "perl -MNeovim::Ext -e1" >/dev/null 2>&1; }

# ---------------------------------------------------------------- deps
dep_python() {
  winget_install Python.Python.3.13 || return 1
  if ! python -c "" >/dev/null 2>&1; then
    warn "'python' pointe vers l'alias Microsoft Store : Paramètres > Applications > Paramètres avancés > Alias d'exécution d'application, désactive python.exe / python3.exe (manuel)."
  fi
}

dep_py_tools() {
  local py=python sd
  python -c "" >/dev/null 2>&1 || py="py -3"
  run $py -m pip install --upgrade black isort pynvim || return 1
  [ "${DRY_RUN:-0}" = 1 ] && return 0
  # black/isort sont installés dans <Python>\Scripts, souvent absent du PATH
  if ! { has black && has isort; }; then
    sd="$($py -c "import sysconfig;print(sysconfig.get_path('scripts'))" | tr -d '\r')"
    add_user_path "$sd"
  fi
}

dep_node()     { winget_install OpenJS.NodeJS.LTS; }
dep_trash()    { run npm install -g trash-cli; }
dep_pwsh()     { winget_install Microsoft.PowerShell; }
dep_fd()       { winget_install sharkdp.fd; }

dep_7z() {
  winget_install 7zip.7zip || return 1
  # l'installeur 7-Zip n'ajoute pas son dossier au PATH
  ensure_in_path 7z "$(cygpath -u "${PROGRAMFILES:-C:\\Program Files}")/7-Zip"
}

dep_wget() {
  winget_install JernejSimoncic.Wget && return 0
  warn "winget wget en échec (souvent hash invalide côté éditeur) : essai via scoop"
  scoop_install wget && return 0
  warn "wget est optionnel pour mason quand curl est présent."
  return 1
}

dep_go()   { winget_install GoLang.Go; }
dep_ruby() { winget_install RubyInstallerTeam.RubyWithDevKit.3.4; }

dep_composer() {
  winget_install PHP.PHP.8.4 || return 1
  if [ "${DRY_RUN:-0}" = 1 ]; then log "[dry-run] installation composer.phar + wrappers"; return 0; fi
  has php || { err "php introuvable après installation"; return 1; }

  # php.ini minimal (le zip PHP n'en fournit pas) : openssl & co requis par Composer
  local phpbin phpdir
  phpbin="$(php -r 'echo PHP_BINARY;' | tr -d '\r')"; phpdir="$(dirname "$(cygpath -u "$phpbin")")"
  if [ ! -f "$phpdir/php.ini" ] && [ -f "$phpdir/php.ini-development" ]; then
    cp "$phpdir/php.ini-development" "$phpdir/php.ini"
    sed -i -E 's/^;(extension=(openssl|curl|mbstring|fileinfo|zip))$/\1/; s/^;(extension_dir = "ext")$/\1/' "$phpdir/php.ini"
    log "php.ini créé dans $phpdir (openssl, curl, mbstring, fileinfo, zip activés)"
  fi

  # winget n'a pas de paquet Composer : installation officielle (vérif sha384) + wrappers
  local dir sig actual setup
  dir="$(cygpath -u "${LOCALAPPDATA}")/ComposerBin"; mkdir -p "$dir"
  setup="$dir/composer-setup.php"
  sig="$(curl -fsSL https://composer.github.io/installer.sig)" || return 1
  curl -fsSL https://getcomposer.org/installer -o "$setup" || return 1
  actual="$(php -r "echo hash_file('sha384','$(cygpath -m "$setup")');")"
  [ "$sig" = "$actual" ] || { err "hash composer-setup invalide"; rm -f "$setup"; return 1; }
  php "$(cygpath -m "$setup")" --quiet --install-dir="$(cygpath -m "$dir")" --filename=composer.phar || return 1
  rm -f "$setup"
  printf '@php "%%~dp0composer.phar" %%*\r\n' > "$dir/composer.bat"
  printf '#!/usr/bin/env sh\nexec php "$(dirname "$0")/composer.phar" "$@"\n' > "$dir/composer"
  add_user_path "$(cygpath -w "$dir")"
}

dep_julia() {
  winget_install Julialang.Julia || return 1
  local lad; lad="$(cygpath -u "${LOCALAPPDATA}")"
  ensure_in_path julia "$lad/Programs/Julia-*/bin" "$lad/Julia-*/bin" "$lad/Microsoft/WindowsApps"
}

dep_cargo() {
  winget_install Rustlang.Rustup || return 1
  ensure_in_path cargo "$(cygpath -u "$USERPROFILE")/.cargo/bin"
  has rustup && run rustup default stable
}

dep_luarocks() { scoop_install lua luarocks; }

dep_perl() {
  winget_install StrawberryPerl.StrawberryPerl || return 1
  # cpanm du Strawberry Perl, via le PATH Windows (pas le perl de Git Bash)
  run win_ps "cpanm --notest Neovim::Ext" || {
    warn "échec cpanm : voir %USERPROFILE%\\.cpanm\\build.log"; return 1; }
}

platform_post() {
  log "Windows : les binaires installés ne sont visibles dans nvim qu'après redémarrage complet du terminal."
}
