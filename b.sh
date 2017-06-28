# Switch board
function b {
  if [[ $1 == '-?' || $1 == '-h' || $1 == '--help' ]]; then
    __b_help
  elif [[ $1 == '-n' || $1 == '-t' || $1 == '-c' ]]; then
    __b_list $1
  elif [[ $# -eq 2 ]]; then
    __b_add "$1" "$2"
  elif [[ $# -eq 1 ]]; then
    __b_cd "$1"
  else
    __b_list
  fi
}

# Creates the bookmark database if it doesn't exist
function __b_init {
  if [[ -z "$BOOKMARKS_FILE" ]]; then
    BOOKMARKS_FILE="$HOME/.b_bookmarks"
  fi

  if [[ ! -f "$BOOKMARKS_FILE" ]]; then
    touch "$BOOKMARKS_FILE"
  fi
}

# Pretty prints a list of all bookmarks in the database
function __b_list {
  local col1="Name" col2="Target" col3="Count"
  local colpad=1

  local len1=${#col1} len2=${#col2} len3=${#col3}
  local len1_=0 len2_=0 len3_=0

  # Determine column widths
  local n=0
  while read -r line; do
    ((n++))

    if [[ $line =~ ^([^,]+),([^,]+),(.+)$ ]]; then
      len1_=${#BASH_REMATCH[1]}
      len2_=${#BASH_REMATCH[2]}
      len3_=${#BASH_REMATCH[3]}

      if (( len1_ > len1 )); then len1=$len1_; fi
      if (( len2_ > len2 )); then len2=$len2_; fi
      if (( len3_ > len3 )); then len3=$len3_; fi
    else
      __b_err 'line %d in %s has bad format' $n "$BOOKMARKS_FILE"
      return 1
    fi
  done < "$BOOKMARKS_FILE"

  # Print header
  __b_out "%-$((len1 + colpad))s %-$((len2 + colpad))s %-${len3}s" "$col1" "$col2" "$col3"
  __b_out '~%.0s' $(seq 1 $(( len1 + len2 + len3 + 2 + 2 * colpad )))

  case $1 in
    -n) local sortargs=(-k1) ;;
    -t) local sortargs=(-k2) ;;
    -c) local sortargs=(-rn -k3) ;;
    *)  local sortargs=(-k1) ;;
  esac

  # Print rows
  local name= target= count=
  sort --field-separator=, "${sortargs[@]}" "$BOOKMARKS_FILE" |
  {
    while read -r line; do
      if [[ $line =~ ^([^,]+),([^,]+),(.+)$ ]]; then
        name=${BASH_REMATCH[1]}
        target=${BASH_REMATCH[2]}
        count=${BASH_REMATCH[3]}

        __b_out "%-$((len1 + colpad))s %-$((len2 + colpad))s %${len3}s" "$name" "$target" "$count"
      fi
    done
  }
}

# Adds a bookmark to the database if it doesn't already exist.  Will also
# expand the bookmark.  You can use relative paths or things like `.`, `..`,
# and `~`.
function __b_add {
  local mark="$(__b_find_mark "$1")"

  if [[ -n "$mark" ]]; then
    __b_err 'that bookmark is already in use'
    return 1
  else
    local dir="$(perl -e 'use Cwd "abs_path"; print abs_path(shift)' "$2")"

    printf '%s,%s,0' "$1" "$dir" >> "$BOOKMARKS_FILE"
    __b_err 'added %s to bookmarks list' "$1"
  fi
}

# Changes directories into to the bookmarked directory.  If bookmark refers to
# a file, will attempt to open with $EDITOR.
function __b_cd {
  local mark="$(__b_find_mark "$1")"

  if [[ -n "$mark" ]]; then
    # Get bookmark path
    local path="$(cut -f2 -d, <<< "$mark")"

    if [[ ! -t 1 ]]; then
      # If not a terminal, print to stdout
      printf '%s' "$path"
    elif [[ -d "$path" ]]; then
      # If path, pushd and source .b_hook
      pushd "$path"
      if [[ -f "$path/.b_hook" ]]; then
        source "$path/.b_hook"
      fi
    elif [[ -f "$path" ]]; then
      # If file, attempt to open in $EDITOR
      if [[ -n "$EDITOR" ]]; then
        "$EDITOR" "$path"
      else
        __b_err 'please set the \$EDITOR environment variable to allow for file bookmarking'
        return 1
      fi
    else
      __b_err 'bookmarked file or directory not found'
      return 1
    fi
  else
    __b_err 'bookmark not found'
    return 1
  fi
}

function __b_find_mark {
  grep "^$1," < "$BOOKMARKS_FILE"
}

function __b_inc_mark {
  local mark="$(__b_find_mark "$1")"

  if [[ -n "$mark" ]]; then
    # Get bookmark info
    local path="$(cut -f2 -d, <<< "$mark")"
    local count="$(cut -f3 -d, <<< "$mark")"
  else
    __b_err 'bookmark not found'
    return 1
  fi
}

function __b_out {
  printf "$1" "${@:2}"
  printf '\n'
}

function __b_err {
  __b_out "b: $1" "${@:2}" >&2
}

function __b_help {
  cat <<EOF
usage: b [-?|-h|--help|-n|-t|-c] [<bookmark name>] [<dir path>|<file path>]

help:
  -?, -h, --help    show this help message and exit

listing/sorting:
  -n                list bookmarks, sorting by name ascending
  -t                list bookmarks, sorting by target ascending
  -c                list bookmarks, sorting by hit count descending

examples:

To bookmark directories:

  $ b home /home/user
  Added home,/home/user to bookmark list

  $ cd /home/user
  $ b home .
  Added home,/home/user to bookmark list

To bookmark files:

  $ b p /home/user/.profile
  Added p,/home/user/.profile to bookmark list

To go to the directory bookmarked by "home":

  $ b home

To open the file bookmarked by "p" with \$EDITOR:

  $ b p

To get the path of the directory or file bookmarked by "home":

  $ echo \`b home\`
  /home/user

Specifying no arguments or one of the sorting arguments will list bookmarks in
the database.
EOF
}

__b_init
