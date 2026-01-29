# .zshrc - Main configuration file
# Loads modular configuration files

ZDOTDIR="${${(%):-%x}:A:h}"

# Load configuration files in order
[[ -f "$ZDOTDIR/.zsh/local.zsh" ]] && source "$ZDOTDIR/.zsh/local.zsh"  # API keys, secrets, DB functions (machine-specific)
source "$ZDOTDIR/.zsh/path.zsh"       # PATH and tool setup (nvm, bun, sdkman, etc.)
source "$ZDOTDIR/.zsh/plugins.zsh"    # Plugins and UI (zsh-autosuggestions, starship, zellij)
source "$ZDOTDIR/.zsh/alias.zsh"      # Aliases
