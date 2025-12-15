# ============================================================
# QA HARNESS — NEO REPORT VALIDATION (QUEUE V2)
# Runs prompts, waits for responses, checks headings + length
# PowerShell 5.1 safe
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ROOT = Split-Path $PSScriptRoot -Parent
$Q2_ROOT  = Join-Path $ROOT "queue_v2"
$INBOX    = Join-Path $Q2_ROOT "inbox"
$OUTBOX   = Join-Path $Q2_ROOT "outbox"
$QA_FILE  = Join-Path $PSScriptRoot "qa_prompts.json"
$OUT_FILE = Join-Path $PSScriptRoot ("qa_results_{0}.json" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

function Now-UtcIso { ([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) }

function New-MessageId {
    $ts = Get-Date -Format "yyyy
