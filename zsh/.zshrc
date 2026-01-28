# .zshrc - Main configuration file
# Loads modular configuration files

ZDOTDIR="${${(%):-%x}:A:h}"

# Load configuration files in order
[[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"  # API keys, secrets, DB functions (machine-specific)
source "$ZDOTDIR/path.zsh"       # PATH and tool setup (nvm, bun, sdkman, etc.)
source "$ZDOTDIR/plugins.zsh"    # Plugins and UI (zsh-autosuggestions, starship, zellij)
source "$ZDOTDIR/alias.zsh"      # Aliases
