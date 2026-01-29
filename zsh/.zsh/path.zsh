# PATH and Tool Setup

# Homebrew (Apple Silicon Mac) - prioritize
eval "$(/opt/homebrew/bin/brew shellenv)"

# nvm (lazy loading for faster startup)
export NVM_DIR="$HOME/.nvm"
nvm() {
  unset -f nvm node npm npx
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
  nvm "$@"
}
node() { nvm && node "$@"; }
npm() { nvm && npm "$@"; }
npx() { nvm && npx "$@"; }

# Wasmer
export WASMER_DIR="/Users/$USER/.wasmer"
[ -s "$WASMER_DIR/wasmer.sh" ] && source "$WASMER_DIR/wasmer.sh"

# bun
[ -s "/Users/$USER/.bun/_bun" ] && source "/Users/$USER/.bun/_bun"

# LM Studio
export PATH="$PATH:/Users/$USER/.lmstudio/bin"

# Antigravity
export PATH="/Users/$USER/.antigravity/antigravity/bin:$PATH"

# Amp
export PATH="/Users/$USER/.amp/bin:$PATH"

# gem (Ruby) - hardcoded path for speed
export PATH="/Library/Ruby/Gems/2.6.0/bin:$PATH"

# SDKMAN - THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# zoxide
eval "$(zoxide init zsh)"
