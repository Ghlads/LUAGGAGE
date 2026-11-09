#!/usr/bin/env bash
# platforms/ubuntu.sh : Ubuntu / Debian (apt)

PLATFORM_NAME="ubuntu"

platform_match() {
  [ -r /etc/os-release ] || return 1
  ( . /etc/os-release; case " ${ID:-} ${ID_LIKE:-} " in *" ubuntu "*|*" debian "*) exit 0 ;; esac; exit 1 )
}

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

apt_install() { run $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"; }

platform_init() {
  has apt-get || return 1
  [ -z "$SUDO" ] || has sudo || { err "sudo requis"; return 1; }
  run $SUDO apt-get update -y
}

dep_python()   { apt_install python3 python3-pip python3-venv pipx; }
dep_py_tools() {
  apt_install python3-pynvim pipx || return 1
  has black || run pipx install black || return 1
  has isort || run pipx install isort || return 1
  run pipx ensurepath
}
dep_node()     { apt_install nodejs npm; }
dep_trash()    { apt_install trash-cli; }
dep_pwsh()     {
  has snap || { err "snap absent : installe PowerShell manuellement"; return 1; }
  run $SUDO snap install powershell --classic
}
dep_fd() {
  apt_install fd-find || return 1
  # Sur Debian/Ubuntu le binaire s'appelle fdfind : on crée le lien fd
  mkdir -p "$HOME/.local/bin"
  if [ "${DRY_RUN:-0}" = 1 ]; then echo "  [dry-run] ln -sf \$(command -v fdfind) ~/.local/bin/fd"; else ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"; fi
}
dep_7z()       { apt_install p7zip-full; }
dep_wget()     { apt_install wget; }
dep_go()       { apt_install golang-go; }
dep_ruby()     { apt_install ruby-full; }
dep_composer() { apt_install php-cli composer; }
dep_julia() {
  if has snap; then run $SUDO snap install julia --classic
  else run bash -c 'curl -fsSL https://install.julialang.org | sh -s -- --yes'; fi
}
dep_cargo()    { apt_install cargo rustc; }
dep_luarocks() { apt_install luarocks lua5.1 liblua5.1-0-dev; }
dep_perl() {
  apt_install perl cpanminus build-essential || return 1
  run $SUDO cpanm --notest Neovim::Ext
}

platform_post() {
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) warn "ajoute \$HOME/.local/bin à ton PATH (fd, black, isort)" ;; esac
}
