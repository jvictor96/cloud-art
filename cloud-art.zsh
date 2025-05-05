function cloud_accept_line() {
  local typed_command="$BUFFER"
  local command_head=$(echo "$typed_command" | cut -d" " --fields 1)

  # Execute command manually
  export FLAG=RUN
  if [[ "$command_head" == (ls|cd|mkdir|git|export|source|echo|witch|disown|find|cat) ]] && [[ "$ENABLE_CLOUD" ]]; then
    export FLAG=RUN
  else
    export FLAG=SKIP
  fi
  
  if [[ "$FLAG" == "SKIP" ]]; then
    BUFFER="$typed_command"  # Clear buffer so shell won't run it naturally
    rm -f /tmp/cloud_buffer_${USER}.txt
  else
    local new_buffer = "$typed_command | tee -a /tmp/cloud_buffer_${USER}.txt"
    print -P "${PS1}${new_buffer}" >> /tmp/cloud_buffer_${USER}.txt
    BUFFER="${new_buffer}"  # Clear buffer so shell won't run it naturally
  fi
  
  zle accept-line
  zle reset-prompt  # Bring prompt back manually
  
}
zle -N cloud_accept_line
bindkey "^M" cloud_accept_line
