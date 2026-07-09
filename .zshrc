# User-local binaries.
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# bun completions
[ -s "/Users/shrey/.bun/_bun" ] && source "/Users/shrey/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/opt/homebrew/opt/python@3.14/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Parafin dotfiles shell integrations.
if [[ -r "$HOME/Desktop/dev/dotfiles-shrey-parafin/.config/zsh/atuin.zsh" ]]; then
  source "$HOME/Desktop/dev/dotfiles-shrey-parafin/.config/zsh/atuin.zsh"
fi
