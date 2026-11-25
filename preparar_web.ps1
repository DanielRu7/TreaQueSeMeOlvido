$ErrorActionPreference = 'Stop'
$release = 'https://github.com/simolus3/drift/releases/download/drift-2.35.4'
$web = Join-Path $PSScriptRoot 'web'

if (-not (Test-Path (Join-Path $web 'index.html'))) {
    throw 'Genera primero la plataforma web con flutter create.'
}

$archivos = @(
    @{
        Origen = 'drift_worker.js'
        Destino = 'drift_worker.dart.js'
        Hash = '48c950cd8e3bc3cddb34816c860e228be8832bef07a297c27e9907c057ff8162'
    },
    @{
        Origen = 'sqlite3.wasm'
        Destino = 'sqlite3.wasm'
        Hash = 'e7451780e78c56ff864fe9317a0fbcd6aeb2e8de3beba7f5efd963202f7ec3d9'
    }
)

foreach ($archivo in $archivos) {
    $destino = Join-Path $web $archivo.Destino
    if ((Test-Path $destino) -and ((Get-FileHash $destino).Hash -eq $archivo.Hash)) {
        continue
    }
    $temporal = [IO.Path]::GetTempFileName()
    try {
        Invoke-WebRequest -UseBasicParsing -Uri "$release/$($archivo.Origen)" -OutFile $temporal
        if ((Get-FileHash $temporal).Hash -ne $archivo.Hash) {
            throw "La suma SHA-256 de $($archivo.Origen) no coincide."
        }
        Copy-Item -LiteralPath $temporal -Destination $destino -Force
    } finally {
        Remove-Item -LiteralPath $temporal
    }
}
