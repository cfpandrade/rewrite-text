#!/usr/bin/env bash
# Instalador de rewrite-text para Ubuntu / GNOME sobre Wayland.
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
KEY_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rewrite-text/"
KEY_SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
BINDING="${BINDING:-<Super>r}"

echo "==> Comprobando dependencias"
missing=()
command -v ydotool  >/dev/null || missing+=(ydotool)
command -v wl-copy  >/dev/null || missing+=(wl-clipboard)
python3 -c 'import gi; gi.require_version("Gtk","4.0"); gi.require_version("Adw","1")' 2>/dev/null \
  || missing+=(python3-gi gir1.2-gtk-4.0 gir1.2-adw-1)
if ((${#missing[@]})); then
  echo "Faltan paquetes. Instalalos con:"
  echo "  sudo apt install ${missing[*]}"
  exit 1
fi

echo "==> Instalando el script en $BIN_DIR"
mkdir -p "$BIN_DIR"
install -m 755 "$(dirname "$0")/rewrite-text" "$BIN_DIR/rewrite-text"

echo "==> Activando el demonio ydotoold"
# Se usa la unidad que trae el paquete. No crear una propia: dos demonios a la
# vez se pelean por el socket y duplican las pulsaciones.
systemctl --user enable --now ydotool
systemctl --user is-active --quiet ydotool \
  || { echo "ydotool.service no arranco. Revisa: systemctl --user status ydotool"; exit 1; }

echo "==> Registrando el atajo global ($BINDING)"
existing=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
if [[ "$existing" != *"$KEY_PATH"* ]]; then
  if [[ "$existing" == "@as []" || "$existing" == "[]" ]]; then
    nuevo="['$KEY_PATH']"
  else
    nuevo="${existing%]}, '$KEY_PATH']"
  fi
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$nuevo"
fi
gsettings set "$KEY_SCHEMA:$KEY_PATH" name    'Reescribir texto con IA'
gsettings set "$KEY_SCHEMA:$KEY_PATH" command "$BIN_DIR/rewrite-text"
gsettings set "$KEY_SCHEMA:$KEY_PATH" binding "$BINDING"

echo
echo "Listo. Selecciona texto en cualquier app y pulsa $BINDING."
