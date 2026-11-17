<#
  Exporta una imagen PNG de cada diagrama de un proyecto Enterprise Architect.
  Solo sirve para revisar visualmente el resultado; el entregable es el .eapx.

  Uso: powershell -ExecutionPolicy Bypass -File export_previews.ps1 -ProjectFile <ruta.eapx> -OutDir <carpeta>
#>
param(
  [Parameter(Mandatory = $true)][string]$ProjectFile,
  [Parameter(Mandatory = $true)][string]$OutDir
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory $OutDir | Out-Null }

$repo = New-Object -ComObject EA.Repository
try {
  if (-not $repo.OpenFile($ProjectFile)) { throw "No se pudo abrir $ProjectFile" }
  $repo.RefreshModelView(0)
  $pi = $repo.GetProjectInterface()
  $rows = ([xml]$repo.SQLQuery("SELECT Diagram_ID FROM t_diagram")).EADATA.Dataset_0.Data.Row
  foreach ($row in @($rows)) {
    $d = $repo.GetDiagramByID([int]$row.Diagram_ID)
    $name = ($d.Name -split ' ')[0]
    $file = Join-Path $OutDir "$name.png"
    if (Test-Path $file) { Remove-Item $file -Force }
    # La primera exportacion tras abrir el archivo a veces no escribe nada: se reintenta.
    for ($try = 0; $try -lt 4 -and -not (Test-Path $file); $try++) {
      $repo.OpenDiagram($d.DiagramID)
      [void]$pi.PutDiagramImageToFile($d.DiagramGUID, $file, 1)
      $repo.CloseDiagram($d.DiagramID)
      if (-not (Test-Path $file)) { Start-Sleep -Milliseconds 700 }
    }
    if (Test-Path $file) { "OK    $file" } else { "FALLO $($d.Name)" }
  }
} finally {
  $repo.CloseFile()
  $repo.Exit()
  [void][Runtime.InteropServices.Marshal]::ReleaseComObject($repo)
}
