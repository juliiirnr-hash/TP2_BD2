# =====================================================================
# Unidad 6 - backup_foodstore.ps1
# Respaldo lógico diario de Food Store con verificación y retención.
# =====================================================================

$ErrorActionPreference = 'Stop'

# Configuración de rutas y parámetros
$PgBin   = 'C:\Program Files\PostgreSQL\18\bin'
$PgHost  = 'localhost'
$PgUser  = 'mant_backup'
$Base    = 'food_store_test'
$Destino = "C:\Respaldos\food_store_test"
$LogDir  = "C:\Respaldos\logs"
$Retencion = 14 # Días de retención de respaldos antiguos

# Generación de marcas de tiempo y nombres de archivo
$Fecha   = Get-Date -Format 'yyyyMMdd_HHmm'
$Archivo = Join-Path $Destino "${Base}_${Fecha}.dump"
$Parcial = "$Archivo.parcial"
$LogFile = Join-Path $LogDir "backup_$Fecha.log"

# Asegurar que existan los directorios de destino y logs
New-Item -ItemType Directory -Force -Path $Destino, $LogDir | Out-Null

"[{0}] Inicio de respaldo de la base -> {1}" -f (Get-Date -Format 's'), $Archivo | Out-File $LogFile

try {
    # 1) Respaldo lógico en formato custom (-Fc) con compresión
    & "$PgBin\pg_dump.exe" -h $PgHost -U $PgUser -d $Base -Fc -Z 6 -f $Parcial
    if ($LASTEXITCODE -ne 0) { 
        throw "pg_dump terminó con código de error $LASTEXITCODE" 
    }

    # 2) Verificación mínima: comprobar que el archivo custom sea legible por pg_restore
    & "$PgBin\pg_restore.exe" --list $Parcial | Out-Null
    if ($LASTEXITCODE -ne 0) { 
        throw "El archivo de respaldo no pasó la verificación de lectura con pg_restore" 
    }

    # 3) Renombrado atómico al archivo definitivo y cálculo de huella SHA-256
    Move-Item $Parcial $Archivo
    $Hash = (Get-FileHash $Archivo -Algorithm SHA256).Hash
    $Hash | Set-Content "$Archivo.sha256"

    # 4) Retención: limpiar respaldos y huellas que superen los días configurados
    Get-ChildItem $Destino -File -Filter "${Base}_*.dump*" |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$Retencion) } |
        Remove-Item -Force

    "[{0}] Respaldo exitoso, verificado y retención aplicada. Archivo: {1}" -f (Get-Date -Format 's'), $Archivo | Out-File $LogFile -Append
    exit 0

} catch {
    # Limpieza del archivo parcial en caso de fallo para no dejar basura válida aparente
    if (Test-Path $Parcial) {
        Remove-Item $Parcial -Force
    }
    # Corrección del índice {1} para que tome la variable $_ correctamente
    "[{0}] ERROR: {1}" -f (Get-Date -Format 's'), $_ | Out-File $LogFile -Append
    exit 1
}