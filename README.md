# b, a simple bookmarking system

## Acknowledgments

`b` was forked from <https://github.com/colinta/b> which was originally forked
from <https://github.com/rockymeza/b>.

## Usage

    b [-h] [BOOKMARK_NAME] [DIRECTORY_PATH|FILE_PATH]

## Options

    -h, --help      show help message and exit

## Examples

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

To open the file bookmarked by "p" with `$EDITOR`:

    $ b p

To list stored bookmarks:

    $ b
    List of bookmarks:
    home,/home/user
    p,/home/user/.profile
    ...

To get the path of the directory bookmarked by "home":

    $ echo `b home`
    /home/user
