# b, a simple bookmarking system

## Acknowledgments

`b` was forked from <https://github.com/colinta/b> which was originally forked
from <https://github.com/rockymeza/b>.

## Usage

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
