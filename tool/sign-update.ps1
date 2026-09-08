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

# Authenticode-sign the installer FIRST so the bytes are final before the
# update signature (.sig) is computed over the file. Doing it after would
# invalidate the .sig the app verifies.
$signtool = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*\x64\signtool.exe" } |
    Sort-Object FullName -Descending |
    Select-Object -First 1
if ($signtool) {
    & $signtool.FullName sign /sha1 $certificate.Thumbprint /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com $resolvedInstaller | Write-Output
} else {
    Write-Warning "signtool.exe not found; installer has no Authenticode signature."
}

$privateKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($certificate)
$signature = $privateKey.SignData(
    [System.IO.File]::ReadAllBytes($resolvedInstaller),
    [System.Security.Cryptography.HashAlgorithmName]::SHA256,
    [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
)
$signaturePath = "$resolvedInstaller.sig"
[System.IO.File]::WriteAllBytes($signaturePath, $signature)
Write-Output $signaturePath
