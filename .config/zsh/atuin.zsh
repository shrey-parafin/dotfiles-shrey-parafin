# Atuin shell history integration.
#
# Match the old dotfiles behavior:
# - record shell history into Atuin's local SQLite database
# - leave Ctrl-R and up-arrow available for other shell/history widgets
# - expose Atuin search on Ctrl-X Ctrl-R
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-ctrl-r --disable-up-arrow)"
  bindkey -M emacs '^X^R' _atuin_search_widget
  bindkey -M viins '^X^R' _atuin_search_widget
fi
