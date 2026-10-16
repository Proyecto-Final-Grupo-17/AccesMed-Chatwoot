# Genera .env a partir de .env.example con claves nuevas (Windows).
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File scripts\generar-env.ps1
# 1-instalar.bat lo ejecuta solo si no existe el .env
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot
$plantilla = Join-Path $raiz '.env.example'
$destino = Join-Path $raiz '.env'

if (Test-Path $destino) {
    Write-Host '.env ya existe; no se modifica.'
    exit 0
}

function Nueva-Clave([int]$bytes) {
    $buffer = New-Object byte[] $bytes
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($buffer)
    $rng.Dispose()
    return -join ($buffer | ForEach-Object { $_.ToString('x2') })
}

$valores = [ordered]@{
    'SECRET_KEY_BASE'                              = Nueva-Clave 64
    'ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY'         = Nueva-Clave 16
    'ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY'   = Nueva-Clave 16
    'ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT' = Nueva-Clave 16
    'REDIS_PASSWORD'                               = Nueva-Clave 16
    'POSTGRES_PASSWORD'                            = Nueva-Clave 16
}

$contenido = [System.IO.File]::ReadAllText($plantilla)
foreach ($clave in $valores.Keys) {
    $patron = '(?m)^' + $clave + '=[^\r\n]*'
    $contenido = [regex]::Replace($contenido, $patron, $clave + '=' + $valores[$clave])
}
[System.IO.File]::WriteAllText($destino, $contenido, (New-Object System.Text.UTF8Encoding $false))
Write-Host '.env generado con claves nuevas.'
