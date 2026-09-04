param(
    [string]$Installer = "build\installer\Zomboclat-Admin-Panel-Setup.exe"
)

$ErrorActionPreference = "Stop"
$certificate = Get-ChildItem Cert:\CurrentUser\My |
    Where-Object { $_.Subject -eq "CN=Zomboclat Update Signing" -and $_.HasPrivateKey } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1

if (-not $certificate) {
    throw "Zomboclat update signing key was not found in the current user certificate store."
}

$resolvedInstaller = (Resolve-Path -LiteralPath $Installer).Path
$privateKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($certificate)
$signature = $privateKey.SignData(
    [System.IO.File]::ReadAllBytes($resolvedInstaller),
    [System.Security.Cryptography.HashAlgorithmName]::SHA256,
    [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
)
$signaturePath = "$resolvedInstaller.sig"
[System.IO.File]::WriteAllBytes($signaturePath, $signature)
Write-Output $signaturePath
