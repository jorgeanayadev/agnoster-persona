# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
# Make sure you have a recent version: the code points that Powerline
# uses changed in 2012, and older versions will display incorrectly,
# in confusing ways.
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](https://iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# If using with "light" variant of the Solarized color schema, set
# SOLARIZED_THEME variable to "light". If you don't specify, we'll assume
# you're using the "dark" variant.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'

#<PERSONA VARIABLES>
PERSONA_BG='black'
# >> USER CONTEXT %n@%m %n:user name | %m:machine name
PERSONA_USR="%n@%m"
# >> EMOJIS In this list are for random emoji (when the emoji name is not provided) also this list is used for the initial random emoji on start
EMOJIS=(earth_globe_americas octopus dizzy_face rainbow cyclone full_moon_symbol unicorn_face robot_face extraterrestrial_alien fire snake snail monkey)
CURRENT_EMOJI=${EMOJIS[$RANDOM % ${#EMOJIS[@]}]}

GRADIENT_SEPARATOR="\u2593\u2592\u2591"
END_SEPARATOR="%F{$PERSONA_BG}\ue0b0"
SEGMENT_SEPARATOR="%F{black}\ue0bb"
RSEGMENT_SEPARATOR="\ue0b2"

BOX_ST="\uff62"
BOX_EN="\uff63"
BOX_DL="\u256d"
BOX_UL="\u2570"
BOX_SH="\u02c3"
#</PERSONA VARIABLES>

case ${SOLARIZED_THEME:-dark} in
    light) CURRENT_FG='white';;
    *)     CURRENT_FG='black';;
esac

# Special Powerline characters

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  # NOTE: This segment separator character is correct.  In 2012, Powerline changed
  # the code points they use for their special characters. This is the new code point.
  # If this is not working for you, you probably have an old version of the
  # Powerline-patched fonts installed. Download and install the new version.
  # Do not submit PRs to change this unless you have reviewed the Powerline code point
  # history and have new information.
  # This is defined using a Unicode escape sequence so it is unambiguously readable, regardless of
  # what font the user is viewing this source code in. Do not replace the
  # escape sequence with a single literal character.
  # Do not change this! Do not make it '\u2b80'; that is the old, wrong code point.
  SEGMENT_SEPARATOR=$'\ue0b0'
}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
# * PERSONA Configurable context using a variable
prompt_context() {
  local fg
  if [[ $PERSONA_BG = "red" || $PERSONA_BG = "magenta" || $PERSONA_BG = "black" ]]; then
    fg='white'
  else
    fg='black'
  fi

  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment $PERSONA_BG $fg "%(!.%{%F{yellow}%}.)$PERSONA_USR%f"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  (( $+commands[git] )) || return
  if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
    return
  fi
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR=$'\ue0a0'         # 
  }
  local ref dirty mode repo_path

   if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]]; then
    repo_path=$(git rev-parse --git-dir 2>/dev/null)
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment green $CURRENT_FG
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:*' unstagedstr '●'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'
    vcs_info
    echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
  fi
}

prompt_bzr() {
  (( $+commands[bzr] )) || return

  # Test if bzr repository in directory hierarchy
  local dir="$PWD"
  while [[ ! -d "$dir/.bzr" ]]; do
    [[ "$dir" = "/" ]] && return
    dir="${dir:h}"
  done

  local bzr_status status_mod status_all revision
  if bzr_status=$(bzr status 2>&1); then
    status_mod=$(echo -n "$bzr_status" | head -n1 | grep "modified" | wc -m)
    status_all=$(echo -n "$bzr_status" | head -n1 | wc -m)
    revision=$(bzr log -r-1 --log-format line | cut -d: -f1)
    if [[ $status_mod -gt 0 ]] ; then
      prompt_segment yellow black "bzr@$revision ✚"
    else
      if [[ $status_all -gt 0 ]] ; then
        prompt_segment yellow black "bzr@$revision"
      else
        prompt_segment green black "bzr@$revision"
      fi
    fi
  fi
}

prompt_hg() {
  (( $+commands[hg] )) || return
  local rev st branch
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files are not added
        prompt_segment red white
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        prompt_segment yellow black
        st='±'
      else
        # if working copy is clean
        prompt_segment green $CURRENT_FG
      fi
      echo -n $(hg prompt "☿ {rev}@{branch}") $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if `hg st | grep -q "^\?"`; then
        prompt_segment red black
        st='±'
      elif `hg st | grep -q "^[MA]"`; then
        prompt_segment yellow black
        st='±'
      else
        prompt_segment green $CURRENT_FG
      fi
      echo -n "☿ $rev@$branch" $st
    fi
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue $CURRENT_FG '\uf07c %~'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment blue black "(`basename $virtualenv_path`)"
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
# * PERSONA - add time of the command execution
prompt_status() {
  local -a symbols

  if [[ $RETVAL -ne 0 ]]; then 
     symbols+="%{%F{red}%}✘"
  else
     symbols+="%{%F{green}%}\uf00c"
  fi

  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols %@"
}

#AWS Profile:
# - display current AWS_PROFILE name
# - displays yellow on red if profile name contains 'production' or
#   ends in '-prod'
# - displays black on green otherwise
prompt_aws() {
  [[ -z "$AWS_PROFILE" ]] && return
  case "$AWS_PROFILE" in
    *-prod|*production*) prompt_segment red yellow  "AWS: $AWS_PROFILE" ;;
    *) prompt_segment green black "AWS: $AWS_PROFILE" ;;
  esac
}

# ==============================
# >> P E R S O N A 
# by jorgeanayadev (hey@jorgeanaya.dev)
# https://github.com/jorgeanayadev/agnoster-persona
# ==============================

function persona() {
    if [[ $1 = "list" ]]; then
	display_emoji $2
	return 
    fi

    if [[ $1 = "title" ]]; then
       echo "Title change ... "
       PERSONA_USR=$2
       [[ -z $PERSONA_USR ]] && PERSONA_USR="%n@%m"       
       return
    fi

    echo "Personality change ... "
    PERSONA_BG=$1
    prompt_emoji $2 $3

    if [[ $3 = "title" ]]; then
       PERSONA_USR=$4
       [[ -z $PERSONA_USR ]] && PERSONA_USR="%n@%m"       
    fi

    END_SEPARATOR="%K{$PERSONA_BG}%F{$CURRENT_FG}\ue0b0"
    clear
}

prompt_emoji() {
    if [[ -z "$1" ]]; then
      EMOJI_NAME=${EMOJIS[$RANDOM % ${#EMOJIS[@]}]}
      CURRENT_EMOJI=$emoji[$EMOJI_NAME]
    elif [[ $1 = "any" ]]; then
	if [[ -z "$2" ]]; then
	   CURRENT_EMOJI=$(random_emoji)
         else
	   CURRENT_EMOJI=$(random_emoji $2)
         fi
    else
      EMOJI_NAME=$(emoji_fav $1)
      CURRENT_EMOJI=$emoji[$EMOJI_NAME]
      if [[ -z $CURRENT_EMOJI ]]; then
        CURRENT_EMOJI=$1
      fi
    fi
    echo -n "$BOX_UL$BOX_ST$CURRENT_EMOJI$BOX_EN$BOX_SH"
}

# Shortcut for favorites, to see all emojis use $> persona list. Then add your shortname and the emoji name
emoji_fav() {
case "$1" in
    (globe)   echo 'earth_globe_americas';;
    (moon)    echo 'full_moon_symbol';;
    (unicorn) echo 'unicorn_face';;
    (robot)   echo 'robot_face' ;;
    (alien)   echo 'extraterrestrial_alien' ;;
    (python)  echo 'snake' ;;
    (star)    echo 'white_medium_star' ;;
    (docker)  echo 'spouting_whale' ;;
    (really)  echo 'unamused_face' ;;
    (dizzy)   echo 'dizzy_face' ;;
    (lol)     echo 'face_with_stuck_out_tongue_and_tightly_closed_eyes' ;;
    (spock)    echo 'raised_hand_with_part_between_middle_and_ring_fingers' ;;
    (*) echo $1;;
esac
}

prompt_os() {
  # Mac emoticon
  # echo -n "%F{$CURRENT_FG} \ue711"

  # Window emoticon
  # echo -n "%F{$CURRENT_FG} 💻"
}

prompt_newline () {
  printf "\n"
  CURRENT_BG=''
}

# ==============================
# </PERSONA> 
# ==============================


## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_aws
  prompt_context
  prompt_dir
  prompt_git
  prompt_bzr
  prompt_hg
  prompt_end
  prompt_newline 
  prompt_emoji $CURRENT_EMOJI
}

PROMPT='%{%f%b%k%}$(build_prompt) '
