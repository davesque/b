#!/usr/bin/env bash

# b, a simple bookmarking system
# by Rocky Meza

# Switch board
function b {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    __b_help
  elif [[ $# -eq 2 ]]; then
    __b_add "$1" "$2"
  elif [[ $# -eq 1 ]]; then
    __b_cd "$1"
  else
    __b_list
  fi
}

# Creates the bookmark database if it doesn't exist.
function __b_init {
  if [[ -z "$BOOKMARKS_FILE" ]]; then
    BOOKMARKS_FILE="$HOME/.b_bookmarks"
  fi

  if [[ ! -f "$BOOKMARKS_FILE" ]]; then
    touch "$BOOKMARKS_FILE"
  fi
}

# Lists all of the bookmarks in the database.
function __b_list {
  echo "${fg_bold[yellow]}List of bookmarks:${reset_color}"
  cat "$BOOKMARKS_FILE"
}

# Adds a bookmark to the database if it doesn't already exist.  Will also
# expand the bookmark.  You can use relative paths or things like `.`, `..`,
# and `~`.
function __b_add {
  local mark="$(__b_find_mark "$1")"

  if [[ -n "$mark" ]]; then
    echo "That bookmark is already in use" >& 2
    return 1
  else
    local dir="$(perl -e 'use Cwd "abs_path"; print abs_path(shift)' "$2")"

    echo "$1,$dir" >> "$BOOKMARKS_FILE"
    echo "Added $1,$dir to bookmarks list"
  fi
}

# Changes directories into to the bookmarked directory.  If bookmark refers to
# a file, will attempt to open with $EDITOR.
function __b_cd {
  local mark="$(__b_find_mark "$1")"

  if [[ -n "$mark" ]]; then
    # Get bookmark path
    local dir="$(echo "$mark" | sed 's/^[^,]*,\(.*\)/\1/')"

    # If not a terminal, print to stdout
    if [[ ! -t 1 ]]; then
      echo -n "$dir"
    # If dir, pushd and source .b_hook
    elif [[ -d "$dir" ]]; then
      pushd "$dir"
      if [[ -f "$dir/.b_hook" ]]; then
        source "$dir/.b_hook"
      fi
    # If file and $EDITOR set, open
    elif [[ -f "$dir" && -n "$EDITOR" ]]; then
      $EDITOR "$dir"
    else
      echo "Please set the \$EDITOR environment variable to allow for edit bookmarking" >&2
      return 1
    fi
  else
    echo "That bookmark does not exist" >&2
    return 1
  fi
}

function __b_find_mark {
  grep "^$1," < "$BOOKMARKS_FILE"
}

function __b_help {
  cat <<HELP
b, a simple bookmarking system

usage: b [-h] [BOOKMARK_NAME] [DIRECTORY_PATH|FILE_PATH]

options:
  -h, --help      show this help message and exit

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

  $ cd /home/user
  $ b p .profile
  Added p,/home/user/.profile to bookmark list

To go to the directory bookmarked by "home":

  $ b home

To open the file bookmarked by "p" with \$EDITOR:

  $ b p

To list stored bookmarks:

  $ b
  List of bookmarks:
  home,/home/user
  p,/home/user/.profile
  ...

To get the path of the directory bookmarked by "home":

  $ echo \`b home\`
  /home/user

HELP
}

__b_init
