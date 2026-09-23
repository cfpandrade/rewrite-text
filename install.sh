#!/usr/bin/env bash
# Instalador de rewrite-text para Ubuntu / GNOME sobre Wayland.
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
KEY_SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
MEDIA_KEYS="org.gnome.settings-daemon.plugins.media-keys"
BINDING="${BINDING:-<Super>r}"
BINDING_PROFESSIONAL="${BINDING_PROFESSIONAL:-<Control><Super>p}"
BINDING_FRIENDLY="${BINDING_FRIENDLY:-<Control><Super>f}"

registrar_atajo() {
  local slug="$1" nombre="$2" comando="$3" combinacion="$4"
  local path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/$slug/"
  local existing nuevo
  existing=$(gsettings get "$MEDIA_KEYS" custom-keybindings)
  if [[ "$existing" != *"$path"* ]]; then
    if [[ "$existing" == "@as []" || "$existing" == "[]" ]]; then
      nuevo="['$path']"
    else
      nuevo="${existing%]}, '$path']"
    fi
    gsettings set "$MEDIA_KEYS" custom-keybindings "$nuevo"
  fi
  gsettings set "$KEY_SCHEMA:$path" name    "$nombre"
  gsettings set "$KEY_SCHEMA:$path" command "$comando"
  gsettings set "$KEY_SCHEMA:$path" binding "$combinacion"
}

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
# ydotoold abre /dev/uinput, que es root:input 0660. Sin pertenecer al grupo la
# unidad arranca y muere en bucle, y is-active puede pillarla viva de rebote.
if ! id -nG | tr ' ' '\n' | grep -qx input; then
  echo "Tu usuario no esta en el grupo 'input' y ydotoold no podra abrir /dev/uinput."
  echo "Ejecuta esto y vuelve a iniciar sesion (el grupo no se aplica hasta entonces):"
  echo "  sudo usermod -aG input $USER"
  exit 1
fi
# Se usa la unidad que trae el paquete. No crear una propia: dos demonios a la
# vez se pelean por el socket y duplican las pulsaciones.
systemctl --user enable --now ydotool
sleep 1
systemctl --user is-active --quiet ydotool \
  || { echo "ydotool.service no arranco. Revisa: systemctl --user status ydotool"; exit 1; }

echo "==> Registrando los atajos globales"
registrar_atajo rewrite-text 'Reescribir texto con IA' \
  "$BIN_DIR/rewrite-text" "$BINDING"
registrar_atajo rewrite-text-professional 'Reescribir texto: profesional (directo)' \
  "$BIN_DIR/rewrite-text --direct professional" "$BINDING_PROFESSIONAL"
registrar_atajo rewrite-text-friendly 'Reescribir texto: amigable (directo)' \
  "$BIN_DIR/rewrite-text --direct friendly" "$BINDING_FRIENDLY"

echo
echo "Listo. Selecciona texto en cualquier app y pulsa:"
echo "  $BINDING -> ventana con todos los tonos"
echo "  $BINDING_PROFESSIONAL -> reescribe en profesional y reemplaza"
echo "  $BINDING_FRIENDLY -> reescribe en amigable y reemplaza"
