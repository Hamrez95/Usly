[CmdletBinding()]
param(
    [ValidateSet("android-apk", "android-aab")]
    [string]$Target = "android-apk",
    [ValidateSet("Debug", "Profile", "Release")]
    [string]$Configuration = "Release",
    [string]$Version = "",
    [string]$OutputDirectory = "",
    [switch]$Clean,
    [switch]$SkipRestore,
    [switch]$NoSign
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$appRoot = Join-Path $repoRoot "apps/mobile"
$pubspec = Join-Path $appRoot "pubspec.yaml"

if (-not (Test-Path $pubspec)) {
    throw "پروژه Flutter در apps/mobile پیدا نشد."
}

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    throw "Flutter در PATH نیست. Flutter stable 3.44.7 را نصب و دوباره اجرا کنید."
}

$versionLine = Select-String -Path $pubspec -Pattern "^version:\s*(.+)$" | Select-Object -First 1
$sourceVersion = if ($versionLine) { $versionLine.Matches[0].Groups[1].Value.Trim() } else { "0.0.0+0" }
$artifactVersion = if ($Version) { $Version } else { ($sourceVersion -replace "\+", "-") }
$artifactRoot = if ($OutputDirectory) { $OutputDirectory } else { Join-Path $repoRoot "artifacts/$artifactVersion" }
$targetRoot = Join-Path $artifactRoot $Target

Push-Location $appRoot
try {
    if (-not (Test-Path (Join-Path $appRoot "android"))) {
        & $flutter.Source create --platforms=android --org com.usly.app --project-name usly .
        if ($LASTEXITCODE -ne 0) { throw "ساخت Android runner شکست خورد." }
    }
    if ($Clean) {
        & $flutter.Source clean
        if ($LASTEXITCODE -ne 0) { throw "flutter clean شکست خورد." }
    }
    if (-not $SkipRestore) {
        & $flutter.Source pub get
        if ($LASTEXITCODE -ne 0) { throw "دریافت dependencyها شکست خورد." }
    }

    $mode = "--$($Configuration.ToLowerInvariant())"
    if ($Target -eq "android-apk") {
        & $flutter.Source build apk $mode
        $builtFile = Join-Path $appRoot "build/app/outputs/flutter-apk/app-$($Configuration.ToLowerInvariant()).apk"
        $extension = "apk"
    } else {
        & $flutter.Source build appbundle $mode
        $builtFile = Join-Path $appRoot "build/app/outputs/bundle/$($Configuration.ToLowerInvariant())/app-$($Configuration.ToLowerInvariant()).aab"
        $extension = "aab"
    }
    if ($LASTEXITCODE -ne 0) { throw "ساخت $Target شکست خورد." }
    if (-not (Test-Path $builtFile)) { throw "فایل خروجی مورد انتظار پیدا نشد: $builtFile" }

    New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
    $artifactName = "Usly-$artifactVersion-$($Configuration.ToLowerInvariant())-$Target.$extension"
    $artifactPath = Join-Path $targetRoot $artifactName
    Copy-Item $builtFile $artifactPath -Force

    $gitCommit = (& git -C $repoRoot rev-parse HEAD).Trim()
    $dirty = -not [string]::IsNullOrWhiteSpace((& git -C $repoRoot status --porcelain))
    $hash = (Get-FileHash -Path $artifactPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $manifest = [ordered]@{
        product = "Usly"
        sourceCommit = $gitCommit
        dirtyWorktree = $dirty
        version = $sourceVersion
        builtAtUtc = [DateTime]::UtcNow.ToString("o")
        flutterVersion = (& $flutter.Source --version --machine | ConvertFrom-Json).frameworkVersion
        target = $Target
        configuration = $Configuration
        signing = if ($NoSign) { "unsigned-requested" } else { "toolchain-default" }
        artifact = [ordered]@{
            path = $artifactPath
            size = (Get-Item $artifactPath).Length
            sha256 = $hash
        }
    }
    $manifestPath = Join-Path $artifactRoot "artifact-manifest.json"
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath -Encoding utf8

    Write-Host "ساخت موفق بود: $artifactPath"
    Write-Host "SHA-256: $hash"
    if ($dirty) { Write-Warning "این build از worktree دارای تغییر ساخته شده و release پایدار نیست." }
}
finally {
    Pop-Location
}
