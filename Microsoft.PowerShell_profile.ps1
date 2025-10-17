# ==============================
# PowerShell Profile 配置
# ==============================

# ------------------------------
# Starship Prompt
# ------------------------------
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# ------------------------------
# Terminal Icons
# ------------------------------
if (Get-Module -ListAvailable -Name "Terminal-Icons") {
    Import-Module Terminal-Icons
}

# ------------------------------
# posh-git 支持（Git 补全） 在fzf 之前加载
# ------------------------------
if (Get-Module -ListAvailable -Name "posh-git") {
    Import-Module posh-git
}

# fzf 模块（如果已安装）
if (Get-Module -ListAvailable -Name "PSFzf") {
    Import-Module PSFzf
    # 启用别名
    Enable-PsFzfAliases

    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    Set-PSReadLineKeyHandler -Chord 'Alt+Tab' -ScriptBlock { Invoke-FzfTabCompletion }
}

# 历史记录
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -MaximumHistoryCount 5000


# 加载补全脚本
$completionPath = Join-Path (Split-Path $PROFILE) "Completions"
if (Test-Path $completionPath) {
    Get-ChildItem $completionPath | ForEach-Object { . $_.FullName }
}

# PowerToys CommandNotFound
if (Get-Module -ListAvailable -Name "Microsoft.WinGet.CommandNotFound") {
    Import-Module -Name Microsoft.WinGet.CommandNotFound
}
