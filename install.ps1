# Security Headers Core Universal Installer (PowerShell for Windows)
# Usage:
#   irm https://raw.githubusercontent.com/MosaabGalmod/security-headers-core/main/install.ps1 | iex
# or run locally:
#   .\install.ps1 [-Target <antigravity|claude|cursor|all|project>]

param(
    [string]$Target = "all"
)

$BaseUrl = "https://raw.githubusercontent.com/MosaabGalmod/security-headers-core/main"
$LocalDir = $PSScriptRoot

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Security Headers Core: HTTP Security & CSP Agent Skill Setup" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

function Install-SkillFiles([string]$DestDir) {
    New-Item -ItemType Directory -Force -Path "$DestDir\reference" | Out-Null
    $files = @(
        "SKILL.md",
        "reference\csp-deep-dive.md",
        "reference\isolation-and-cookies.md",
        "reference\server-configs.md"
    )
    foreach ($f in $files) {
        $destFile = "$DestDir\$f"
        if ($LocalDir -and (Test-Path "$LocalDir\$f")) {
            Copy-Item -Force "$LocalDir\$f" $destFile
        } else {
            $webUri = "$BaseUrl/" + ($f -replace '\\', '/')
            Invoke-WebRequest -Uri $webUri -OutFile $destFile -UseBasicParsing
        }
    }
}

# 1. Antigravity & Gemini CLI
if ($Target -in @("all", "antigravity", "gemini")) {
    $AgyDir = "$HOME\.gemini\config\skills\security-headers-core"
    Install-SkillFiles $AgyDir
    Write-Host "[OK] Installed to Antigravity / Gemini CLI: $AgyDir" -ForegroundColor Green
}

# 2. Claude Code
if ($Target -in @("all", "claude")) {
    $ClaudeSkillsDir = "$HOME\.claude\skills\security-headers-core"
    Install-SkillFiles $ClaudeSkillsDir
    Write-Host "[OK] Installed to Claude Code Skill: $ClaudeSkillsDir" -ForegroundColor Green
}

# 3. Project rules (Cursor / Windsurf)
if ($Target -in @("all", "project", "cursor")) {
    $RuleDir = ".cursor\rules"
    New-Item -ItemType Directory -Force -Path $RuleDir | Out-Null
    if ($LocalDir -and (Test-Path "$LocalDir\SKILL.md")) {
        Copy-Item -Force "$LocalDir\SKILL.md" "$RuleDir\security-headers-core.mdc"
    } else {
        Invoke-WebRequest -Uri "$BaseUrl/SKILL.md" -OutFile "$RuleDir\security-headers-core.mdc" -UseBasicParsing
    }
    Write-Host "[OK] Generated Cursor rule: $RuleDir\security-headers-core.mdc" -ForegroundColor Green
}

Write-Host "`nSetup complete! security-headers-core is active." -ForegroundColor Green
