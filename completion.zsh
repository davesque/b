function _b {
  reply=($(cut -f1 -d, $HOME/.b_bookmarks))
}
compctl -K _b b
