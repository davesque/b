# b, a simple bookmarking system
# by Rocky Meza

BOOKMARKS_FILE=$HOME/.b_bookmarks

__b_help() {
  cat <<HEREDOC
b, a simple bookmarking system

Usage:
      b [bookmark] [directory]
      b [bookmark] [file]

Options:
      -h, --help            Show this help screen

Notes:
      If b is run with no arguments, it will list all of the bookmarks.
      If it is given a bookmark that is a directory, it will attempt to cd into that bookmark.
      If it is given a bookmark that is a file, it will attempt to open that bookmark.
      If it is given a bookmark and directory or file, it will create that bookmark.

Examples:
    $ b home /home/user
      Added home,/home/user to bookmark list
    $ b p /home/user/.profile
      Added p,/home/user/.profile to bookmark list
    $ b
      List of bookmarks:
      home,/home/user
      p,/home/user/.profile
      ...
    $ b home
      will cd to the home directory
    $ echo \`b home\`
      /home/user
    $ b p
      will open ~/.profile with \`\$EDITOR\`
HEREDOC
}

# Creates the bookmark database if it doesn't exist.
__b_init() {
  if [[ ! -f "$BOOKMARKS_FILE" ]]; then
    touch $BOOKMARKS_FILE
  fi
}

# Lists all of the bookmarks in the database.
__b_list() {
  echo "List of bookmarks:"
  cat "$BOOKMARKS_FILE"
}

# Adds a bookmark to the database if it doesn't already exist.  Will also
# expand the bookmark.  You can use relative paths or things like `.`, `..`,
# and `~`.
__b_add() {
  local mark=$(__b_find_mark "$1")

  if [[ -n "$mark" ]]; then
    echo "That bookmark is already in use."
  else
    if [[ $(uname) == "Darwin" ]]; then
      dir=`stat -f $2`
    else
      dir=`readlink -f $2`
    fi

    echo "$1,$dir" >> $BOOKMARKS_FILE
    echo "Added $1,$dir to bookmarks list"
  fi
}

# Changes directories into to the bookmarked directory.  If bookmark refers to
# a file, will attempt to open with $EDITOR.
__b_cd() {
  local mark=$(__b_find_mark "$1")

  if [[ -n "$mark" ]]; then
    dir=$(echo $mark | sed 's/^[^,]*,\(.*\)/\1/')
    # if not a tty, print to stdout
    if [ ! -t 1 ] ; then
      echo -n "$dir"
    elif [[ -d $dir ]]; then
      pushd "$dir"
      if [[ -f "$dir/.b_hook" ]]; then
        source "$dir/.b_hook"
      fi
    # If file and $EDITOR set, open
    elif [[ -f "$dir" && -n "$EDITOR" ]]; then
      $EDITOR "$dir"
    else
      echo "Please set \$EDITOR environment variable to allow for edit bookmarking." >&2
    fi
  else
    echo "That bookmark does not exist." >&2
  fi
}

__b_find_mark() {
  grep "^$1," < $BOOKMARKS_FILE
}

# Switch board
b() {
  if [[ $# -eq 1 ]]; then
    if [[ $1 == "-h" || $1 == "--help" ]]; then
      __b_help
    else
      __b_cd $1
    fi
  elif [[ "$#" -eq 2 ]]; then
    __b_add $1 $2
  else
    __b_list
  fi
}

__b_init
