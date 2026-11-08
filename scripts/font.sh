#!/usr/bin/env bash

# Version et police à installer (Modifiez JetBrainsMono par Hack, FiraCode, etc. si besoin)
FONT_NAME="JetBrainsMono"
URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"

echo "📥 Téléchargement de ${FONT_NAME} Nerd Font..."

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # --- LINUX ---
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    curl -fLO "$URL"
    unzip -o "${FONT_NAME}.zip" -d "$FONT_DIR"
    rm "${FONT_NAME}.zip"
    fc-cache -fv
    echo "✅ Police installée sur Linux !"

elif [[ "$OSTYPE" == "darwin"* ]]; then
    # --- MACOS ---
    FONT_DIR="$HOME/Library/Fonts"
    curl -fLO "$URL"
    unzip -o "${FONT_NAME}.zip" -d "$FONT_DIR"
    rm "${FONT_NAME}.zip"
    echo "✅ Police installée sur macOS !"

elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # --- WINDOWS (Git Bash / WSL) ---
    # Détecte le dossier de polices de l'utilisateur Windows actif
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    FONT_DIR="/c/Users/${WIN_USER}/AppData/Local/Microsoft/Windows/Fonts"
    
    mkdir -p "$FONT_DIR"
    curl -fLO "$URL"
    unzip -o "${FONT_NAME}.zip" -d "$FONT_DIR"
    rm "${FONT_NAME}.zip"
    
    # Enregistrement dans la base de registre Windows pour que l'OS la reconnaisse immédiatement
    echo "⚙️ Enregistrement de la police dans Windows..."
    REG_SCRIPT="import-font.reg"
    echo "Windows Registry Editor Version 5.00" > "$REG_SCRIPT"
    echo "" >> "$REG_SCRIPT"
    echo "[HKEY_CURRENT_USER\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts]" >> "$REG_SCRIPT"
    
    # Parcourt les fichiers décompressés pour les ajouter au registre
    for f in "$FONT_DIR"/*.ttf "$FONT_DIR"/*.otf; do
        [ -e "$f" ] || continue
        base=$(basename "$f")
        # Échappe les anti-slashs pour le fichier .reg Windows
        win_path="C:\\\\Users\\\\${WIN_USER}\\\\AppData\\\\Local\\\\Microsoft\\\\Windows\\\\Fonts\\\\${base}"
        echo "\"${base%.*}\"=\"${win_path}\"" >> "$REG_SCRIPT"
    done
    
    # Exécute l'importation de registre en tâche de fond (Windows demandera une validation)
    regedit.exe /s "$(cygpath -w "$REG_SCRIPT")" 2>/dev/null
    rm "$REG_SCRIPT"
    
    echo "✅ Police installée sur Windows !"
    echo "⚠️ Pensez à redémarrer Git Bash pour appliquer les changements."
else
    echo "❌ OS non supporté automatiquement par ce script."
    exit 1
fi


