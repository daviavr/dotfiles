# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# kimi-code
export PATH="/home/davi/.kimi-code/bin:$PATH"

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select

# noctalia completions (cached, regenerated when the binary is newer)
_noc_comp_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
if (( $+commands[noctalia] )); then
  if [[ ! -f "$_noc_comp_dir/_noctalia" || $commands[noctalia] -nt "$_noc_comp_dir/_noctalia" ]]; then
    mkdir -p "$_noc_comp_dir" && noctalia completions zsh >| "$_noc_comp_dir/_noctalia"
  fi
fi
fpath=("$_noc_comp_dir" $fpath)
unset _noc_comp_dir

source $HOME/.antidote/antidote.zsh

antidote load

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# mise
(( $+commands[mise] )) && eval "$(mise activate zsh)"
