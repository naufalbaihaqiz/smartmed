$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCommand) {
    $flutterPath = $flutterCommand.Source
} else {
    $flutterPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'flutter-sdk\bin\flutter.bat'
}
if (-not (Test-Path -LiteralPath $flutterPath)) {
    throw 'Flutter SDK tidak ditemukan. Pasang Flutter dan tambahkan ke PATH.'
}
& $flutterPath pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $flutterPath run -d chrome --web-port 5173 --web-hostname 127.0.0.1
