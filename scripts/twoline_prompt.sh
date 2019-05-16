# A two-line colored Bash prompt (PS1) with a line decoration of <pwd> <git branch> ... <time>
# which adjusts automatically to the width of the terminal.
# Usage: source twoline_prompt.sh

function parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (git \1)/'
}

function prompt {
  local BLACK="\[\033[0;30m\]"
  local BLACKBOLD="\[\033[1;30m\]"
  local RED="\[\033[0;31m\]"
  local REDBOLD="\[\033[1;31m\]"
  local GREEN="\[\033[0;32m\]"
  local GREENBOLD="\[\033[1;32m\]"
  local YELLOW="\[\033[0;33m\]"
  local YELLOWBOLD="\[\033[1;33m\]"
  local BLUE="\[\033[0;34m\]"
  local BLUEBOLD="\[\033[1;34m\]"
  local PURPLE="\[\033[0;35m\]"
  local PURPLEBOLD="\[\033[1;35m\]"
  local CYAN="\[\033[0;36m\]"
  local CYANBOLD="\[\033[1;36m\]"
  local WHITE="\[\033[0;37m\]"
  local WHITEBOLD="\[\033[1;37m\]"
  local RESETCOLOR="\[\e[00m\]"
  local RESET="\[\033[0m\]"
  local PS_LINE=`printf -- '- %.0s' {1..200}`

  local PS_BRANCH=''
  local PS_FILL=${PS_LINE:0:$COLUMNS}
  local PS_BRANCH="(git $(parse_git_branch)) "
  local PS_INFO="$BLUE\u@$RESETCOLOR:$GREEN\w"
  local PS_GIT="$YELLOW$PS_BRANCH"
  local PS_TIME="\[\033[\$((COLUMNS-10))G\] $RED[\t]"
  export PS1="\${PS_FILL}\[\033[0G\]${PS_INFO} $YELLOW\$(parse_git_branch)${PS_TIME}\n${RESET}\$ "
  #export PS1="\[\033[0G\]${PS_INFO} ${PS_TIME}\n${RESET}\$ "
  export PS2=" | → $RESETCOLOR"
}
prompt

