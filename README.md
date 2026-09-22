# rewrite-text

Reescribe el texto que tengas seleccionado en cualquier aplicacion, desde un atajo
global de teclado. Pensado para emails y mensajes de chat de trabajo: seleccionas,
pulsas `Super+R`, eliges un tono y reemplazas el original.

Funciona en Ubuntu con GNOME sobre Wayland.

## Por que un atajo y no el menu contextual

En GNOME/Wayland no existe ningun punto de extension que permita anadir entradas al
menu del boton derecho de aplicaciones ajenas (Teams, Outlook, el navegador...). Un
atajo global es el equivalente funcional y funciona en todas partes por igual.

## Como funciona

1. Seleccionas texto en cualquier aplicacion.
2. Pulsas `Super+R`. El script copia la seleccion con un `Ctrl+C` simulado.
3. Se abre una ventana con el original y cinco tonos:
   **Profesional**, **Amigable**, **Mas corto**, **Corregir** e **Ingles**.
4. Eliges uno y esperas unos segundos.
5. **Reemplazar** sustituye el texto original con un `Ctrl+V` simulado,
   **Copiar** lo deja solo en el portapapeles y `Esc` cancela.

El motor se elige en el desplegable de la barra de titulo y la preferencia se
guarda en `~/.config/rewrite-text.json`.

## Requisitos

- Python 3 con GTK 4 y libadwaita:
  `sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-adw-1`
- `ydotool` y `wl-clipboard`: `sudo apt install ydotool wl-clipboard`
- Al menos uno de los dos motores, ya instalado y autenticado:
  - el CLI `codex`, que se invoca como `codex exec`
  - el CLI `claude`, que se invoca como `claude -p`

## Instalacion

```sh
git clone https://github.com/cfpandrade/rewrite-text.git
cd rewrite-text
./install.sh
```

El instalador copia el script a `~/.local/bin`, activa el demonio `ydotoold` y
registra el atajo. Para usar otra combinacion:

```sh
BINDING='<Super><Shift>r' ./install.sh
```

## Detalles de implementacion

Tres cosas que no son evidentes y que hacen falta para que esto funcione:

- **El demonio de ydotool.** En Wayland `xdotool` no sirve para simular teclas en
  aplicaciones nativas. Se usa `ydotool`, que necesita `ydotoold` corriendo. Hay que
  usar la unidad que trae el paquete (`systemctl --user enable --now ydotool`) y no
  crear una propia: dos demonios a la vez se pelean por el socket y acaban
  duplicando las pulsaciones.

- **Soltar los modificadores.** Al dispararse el atajo, la tecla `Super` sigue
  fisicamente pulsada cuando el script envia el `Ctrl+C`. El resultado seria
  `Super+Ctrl+C`, que no copia nada. Por eso se envia un *keyup* de todos los
  modificadores antes de simular cualquier combinacion.

- **Mantener viva la aplicacion para poder pegar.** Una `Gtk.Application` sale del
  bucle principal en cuanto se destruye su ultima ventana. Cerrar la ventana y
  programar el pegado con `GLib.timeout_add` no funciona: el proceso termina antes
  de que venza el temporizador. Hay que llamar a `hold()` antes de cerrar, guardar
  la referencia a la aplicacion (una vez destruida la ventana `get_application()`
  devuelve `None`) y hacer `release()` y `quit()` despues de pegar.

## Licencia

MIT
