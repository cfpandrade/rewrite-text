# Alt+E en zsh:
#   - con texto en la línea: la corrige, o la convierte en comando si es lenguaje natural
#   - con la línea vacía: propone el último comando corregido, usando su salida de error
# Nunca ejecuta nada: deja el resultado en el prompt para revisarlo.

(( $+commands[rewrite-text] )) || return 0

typeset -g _rewrite_text_status=0
_rewrite_text_save_status() { _rewrite_text_status=$? }
# Primero de la lista: cualquier otro hook cambiaría $? antes de guardarlo
precmd_functions=(_rewrite_text_save_status ${precmd_functions:#_rewrite_text_save_status})

_rewrite_text_widget() {
  local out rc
  if [[ -n $BUFFER ]]; then
    zle -R "Corrigiendo la línea…"
    out=$(rewrite-text --shell -- "$BUFFER" </dev/null 2>&1)
    rc=$?
  else
    local last=$(fc -ln -1 2>/dev/null)
    if [[ -z $last ]]; then
      zle -M "No hay comando anterior que corregir."
      return
    fi
    zle -R "Corrigiendo: $last"
    # La salida del comando anterior solo se puede leer en kitty (shell integration + remote control)
    if [[ -n $KITTY_WINDOW_ID ]] && (( $+commands[kitty] )); then
      out=$(kitty @ get-text --match "id:$KITTY_WINDOW_ID" --extent last_non_empty_output 2>/dev/null \
            | rewrite-text --shell --status "$_rewrite_text_status" -- "$last" 2>&1)
    else
      out=$(rewrite-text --shell --status "$_rewrite_text_status" -- "$last" </dev/null 2>&1)
    fi
    rc=$?
  fi

  if (( rc )) || [[ -z $out ]]; then
    zle -M "${out:-rewrite-text no devolvió nada}"
    return
  fi
  BUFFER=$out
  CURSOR=$#BUFFER
  zle -M ""
}

zle -N _rewrite_text_widget
bindkey '^[e' _rewrite_text_widget
