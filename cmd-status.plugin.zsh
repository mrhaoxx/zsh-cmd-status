# load colors module that allows things like $fg[red]
autoload colors && colors

# Load the zsh/datetime module for high-precision timestamps
zmodload zsh/datetime

: ${ZSH_CMD_STATUS_DURATION_THRESHOLD:=10}

function _zsh_cmd_return_code() {
  local code=$?
  if [[ code -ne 0 ]]; then
    printf "${fg_bold[red]}returned ${code}${reset_color}"
  fi
}

function _zsh_cmd_render_duration() {
  local duration=$1
  # Fix: use truncation via arithmetic instead of int() function
  local ms=$(( (duration - ${duration%.*}) * 1000 ))
  local sec=$(( ${duration%.*} % 60 ))
  local min=$(( ${duration%.*} % 3600 / 60 ))
  local hour=$(( ${duration%.*} / 3600 ))
  if [[ $hour -gt 0 ]]; then
    printf '%dh %dm %ds %dms' $hour $min $sec $ms
  elif [[ $min -gt 0 ]]; then
    printf '%dm %ds %dms' $min $sec $ms
  elif [[ $sec -gt 0 ]]; then
    printf '%ds %dms' $sec $ms
  else
    printf '%dms' $ms
  fi
}

function _zsh_cmd_duration() {
  if [ -z "${_zsh_cmd_status_start_time}" ]; then
      return 0
  fi
  local end_time
  end_time="$EPOCHREALTIME"
  local duration=$(( end_time - _zsh_cmd_status_start_time ))
  local threshold=${ZSH_CMD_STATUS_DURATION_THRESHOLD:=10}
  # Fix: compare the integer part using parameter expansion
  if (( ${duration%.*} < threshold )); then
    return 0
  fi
  pretty="$(_zsh_cmd_render_duration ${duration})"
  printf "${fg_bold[yellow]}took ${pretty}${reset_color}"
}

function _zsh-cmd-status-preexec() {
  _zsh_cmd_status_preexec_was_run=true
  _zsh_cmd_status_start_time="$EPOCHREALTIME"
}

function _zsh-cmd-status-precmd() {
  # First thing MUST be to get return code
  local ret="$(_zsh_cmd_return_code)"
  local dur="$(_zsh_cmd_duration)"

  # If a command isn't present when enter/return is pressed, preexec functions
  # don't execute. If this happens, don't output any stats.
  if [[ -z "${_zsh_cmd_status_preexec_was_run}" ]]; then
    return 0
  fi

  # Join the retcode and duration with an ampersand
  # If one is unset, no ampersand will be added
  # if both are unset, nothing will be added
  local out=(${ret} ${dur})
  out="${(j: & :)out}"
  if [[ -n "${out}" ]]; then
    printf "\n${out}\n"
  fi

  unset _start_time
  unset _zsh_cmd_status_preexec_was_run
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _zsh-cmd-status-preexec
add-zsh-hook precmd _zsh-cmd-status-precmd
