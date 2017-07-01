# Switch board
function b {
  __b_init_db

  if [[ $1 == '-?' || $1 == '-h' || $1 == '--help' ]]; then
    __b_help
  elif [[ $1 == '-n' || $1 == '-t' || $1 == '-c' ]]; then
    __b_list $1
  elif [[ $1 == '-r' || $1 == '-d' ]]; then
    __b_rm "$2"
  elif [[ $# -eq 2 ]]; then
    __b_add "$1" "$2"
  elif [[ $# -eq 1 ]]; then
    __b_cd "$1"
  else
    __b_list
  fi
}

# Printf wrappers
function __b_out {
  printf "$1" "${@:2}"
  printf '\n'
}
function __b_msg {
  __b_out "$@" >&2
}
function __b_err {
  __b_out "b: $1" "${@:2}" >&2
}

# Ensures that the booksmarks file exists
function __b_init_db {
  if [[ ! -f "$BOOKMARKS_FILE" ]]; then
    touch "$BOOKMARKS_FILE"
  fi
}

# Ensures that required env vars are set
function __b_init_env {
  if [[ -z "$BOOKMARKS_FILE" ]]; then
    BOOKMARKS_FILE="$HOME/.b_bookmarks"
  fi
}

# Pretty prints a list of all bookmarks in the bookmarks file
function __b_list {
  local col1=Name col2=Target col3=Count
  local colpad=1

  local len1=${#col1} len2=${#col2} len3=${#col3}
  local len1_=0 len2_=0 len3_=0

  # Determine column widths
  local n=0
  while read -r line; do
    (( n++ ))

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
  __b_out '~%.0s' $(seq 1 $((len1 + len2 + len3 + 2 + 2 * colpad)))

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

# Attempts to retrieve an entry from the bookmarks file
function __b_get {
  if ! grep "^$1," < "$BOOKMARKS_FILE"; then
    __b_err 'bookmark not found'
    return 1
  fi
}

# Adds a bookmark to the booksmarks file if it doesn't already exist.  Will
# also expand the path being bookmarked.
function __b_add {
  if __b_get "$1" &> /dev/null; then
    __b_err 'that bookmark is already in use'
    return 1
  fi

  local path="$(perl -e 'use Cwd "abs_path"; print abs_path(shift)' "$2")"

  if [[ -f "$path/.b_hook" ]]; then
    cat <<EOF
!!!! WARNING !!!!
A .b_hook file already exists in this location.  This file will be sourced
whenever you visit this bookmark.
EOF
    read -p $'\nDo you still want to continue? [y/n] ' -n 1 -r
    printf '\n'

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      return 1
    fi
  fi

  printf '%s,%s,0\n' "$1" "$path" >> "$BOOKMARKS_FILE"

  __b_msg 'added "%s" to bookmarks list' "$1"
}

# Increments the count of a bookmark
function __b_inc {
  __b_get "$1" &> /dev/null || return $?

  local mark="$(__b_get "$1")"
  local path="$(cut -f2 -d, <<< "$mark")"
  local count="$(cut -f3 -d, <<< "$mark")"

  # Build line with new count
  local newline="$1,$path,$(( count + 1 ))"
  local escaped="$(sed -e 's/[\/&]/\\&/g' <<< "$newline")"

  # Insert new line
  perl -pi -e "s/^$1,.*$/$escaped/g" "$BOOKMARKS_FILE"
}

# Changes directories into to the bookmarked directory.  If the bookmark refers
# to a file, opens it with $EDITOR.
function __b_cd {
  __b_get "$1" 1> /dev/null || return $?

  local mark="$(__b_get "$1")"
  local path="$(cut -f2 -d, <<< "$mark")"

  __b_inc "$1"

  # If not a terminal, print to stdout
  if [[ ! -t 1 ]]; then
    printf '%s' "$path"
    return 0
  fi

  # If directory, pushd and source .b_hook
  if [[ -d "$path" ]]; then
    pushd "$path"
    if [[ -f "$path/.b_hook" ]]; then
      source "$path/.b_hook"
    fi
    return 0
  fi

  # Otherwise, must be file bookmark
  if [[ ! -f "$path" ]]; then
    __b_err 'bookmarked file or directory not found'
    return 1
  fi

  if [[ ! -n "$EDITOR" ]]; then
    __b_err 'please set the \$EDITOR environment variable to visit file bookmarks'
    return 1
  fi

  "$EDITOR" "$path"
}

# Removes a bookmark from the bookmarks file
function __b_rm {
  __b_get "$1" 1> /dev/null || return $?

  # Remove line
  perl -ni -e "/^$1,.*$/ || print" "$BOOKMARKS_FILE"

  __b_msg 'deleted "%s" from bookmarks list' "$1"
}

function __b_help {
  cat <<EOF
usage: b [-?|-h|--help]
         [<bookmark name>]
         [<bookmark name> (<dir path>|<file path>)]
         [-n|-t|-c]
         [(-r|-d) <bookmark name>]

help:
  -?, -h, --help    show this help message and exit

listing/sorting:
  -n                list bookmarks, sorting by name ascending
  -t                list bookmarks, sorting by target ascending
  -c                list bookmarks, sorting by hit count descending

other:
  -r, -d            delete the named bookmark

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
the booksmarks file.
EOF
}

__b_init_env
