# QA HARNESS — sends prompts via Queue v2 and validates required report sections
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ROOT = "C:\ai_control\NEO_Stack"
$QA_PROMPTS = Join-Path $ROOT "tests\qa\qa_prompts.json"
$INBOX  = Join-Path $ROOT "queue_v2\inbox"
$OUTBOX = Join-Path $ROOT "queue_v2\outbox"
$RESULTS = Join-Path $ROOT "tests\qa\qa_results.json"

function Now-UtcIso { return ([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) }

function New-MessageId {
    $ts = Get-Date -Format "yyyyMMdd_HHmmss_fff"
    $rand = -join ((65..90) + (48..57) | Get-Random -Count 6 | ForEach-Object {[char]$_})
    return ("QA_{0}_{1}" -f $ts, $rand)
}

function Write-Inbox([string]$payload) {
    $id = New-MessageId
    $obj = @{ id=$id; ts_utc=(Now-UtcIso); type="qa_prompt"; payload=$payload }
    $path = Join-Path $INBOX ("{0}.json" -f $id)
    $obj | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8
    return $id
}

function Wait-Response([string]$id, [int]$TimeoutSec=1200) {
    $dir = Join-Path $OUTBOX $id
    $resp = Join-Path $dir "response.txt"
    $start = Get-Date
    while ($true) {
        Start-Sleep -Milliseconds 250
        if ((Get-Date) - $start -gt [TimeSpan]::FromSeconds($TimeoutSec)) { return $null }
        if (Test-Path $resp) { return (Get-Content $resp -Raw) }
    }
}

function Contains-Section([string]$text, [string]$sectionName) {
    # simple robust check: presence of the phrase
    return ($text -match [regex]::Escape($sectionName))
}

$cfg = (Get-Content $QA_PROMPTS -Raw) | ConvertFrom-Json
$required = @($cfg.required_report_sections)
$prompts = @($cfg.prompts)

$results = @()
foreach ($p in $prompts) {
    $promptText = [string]$p.prompt
    $wrapped = @"
[NEO_OUTPUT_MODE:REPORT]
Produce ONE single multi-page report in one response. No questions.
$promptText
"@

    $id = Write-Inbox $wrapped
    Write-Host ("QA running {0} → id={1}" -f [string]$p.id, $id) -ForegroundColor Cyan

    $resp = Wait-Response $id 1200
    if (-not $resp) {
        $results += @{
            prompt_id = [string]$p.id
            msg_id = $id
            pass = $false
            reason = "timeout"
            checked_utc = (Now-UtcIso)
        }
        continue
    }

    $missing = @()
    foreach ($sec in $required) {
        if (-not (Contains-Section $resp ([string]$sec))) { $missing += [string]$sec }
    }

    $pass = ($missing.Count -eq 0)
    $results += @{
        prompt_id = [string]$p.id
        msg_id = $id
        pass = $pass
        missing_sections = $missing
        checked_utc = (Now-UtcIso)
    }
}

@{
    version="1.0"
    generated_utc=(Now-UtcIso)
    results=$results
} | ConvertTo-Json -Depth 10 | Set-Content $RESULTS -Encoding UTF8

Write-Host ("QA complete → {0}" -f $RESULTS) -ForegroundColor Green
