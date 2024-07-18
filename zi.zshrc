# Created by newuser for 5.9

# eza
# 默认显示 icons： 
# alias ls="eza --icons -color=auto --group-directories-first"
# # 显示文件目录详情
# alias ll="eza --icons --long --header"
# # 显示全部文件目录，包括隐藏文件
# alias la="eza --icons --long --header --all"
# # 显示详情的同时，附带 git 状态信息
# alias lg="eza --icons --long --header --all --git"
# bat
alias cat="bat"
# ps
alias prs="procs"
# 替换 tree 命令
alias tree="eza --tree --icons"

autoload -Uz compinit
compinit

source <(kubectl completion zsh)

eval "$(starship init zsh)"
eval "$(sheldon source)"

# # 额外功能
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey ',' autosuggest-accept

