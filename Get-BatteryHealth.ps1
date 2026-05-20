[CmdletBinding()]
param (
    [ValidateSet('auto', 'manual')]
    [String]$Mode = 'auto',
    [double]$DesignCapacity,
    [double]$FullChargeCapacity
)

function Write-Color {
  [alias('Write-Colour')]
  [CmdletBinding()]
  param (
    [alias ('T')] [String[]]$Text,
    [alias ('C', 'ForegroundColor', 'FGC')] [ConsoleColor[]]$Color = [ConsoleColor]::White,
    [alias ('B', 'BGC')] [ConsoleColor[]]$BackGroundColor = $null,
    [alias ('Indent')][int] $StartTab = 0,
    [int] $LinesBefore = 0,
    [int] $LinesAfter = 0,
    [int] $StartSpaces = 0,
    [alias ('L')] [string] $LogFile = '',
    [Alias('DateFormat', 'TimeFormat')][string] $DateTimeFormat = 'yyyy-MM-dd HH:mm:ss',
    [alias ('LogTimeStamp')][bool] $LogTime = $true,
    [int] $LogRetry = 2,
    [ValidateSet('unknown', 'string', 'unicode', 'bigendianunicode', 'utf8', 'utf7', 'utf32', 'ascii', 'default', 'oem')][string]$Encoding = 'Unicode',
    [switch] $ShowTime,
    [switch] $NoNewLine,
    [switch] $HorizontalCenter,
    [alias('HideConsole')][switch] $NoConsoleOutput
  )
  if (-not $NoConsoleOutput) {
    $DefaultColor = $Color[0]
    if ($null -ne $BackGroundColor -and $BackGroundColor.Count -ne $Color.Count) {
      Write-Error "Colors, BackGroundColors parameters count doesn't match. Terminated."
      return
    }
    if ($LinesBefore -ne 0) { for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host -Object "`n" -NoNewline } } # Add empty line before
    if ($HorizontalCenter) {
      $MessageLength = 0
      foreach ($Value in $Text) {
        $MessageLength += $Value.Length
      }

      $WindowWidth = $Host.UI.RawUI.BufferSize.Width
      $CenterPosition = [Math]::Max(0, $WindowWidth / 2 - [Math]::Floor($MessageLength / 2))

      # Only write spaces to the console if window width is greater than the message length
      if ($WindowWidth -ge $MessageLength) {
        Write-Host ("{0}" -f (' ' * $CenterPosition)) -NoNewline
      }
    } # Center the line horizontally according to the powershell window size
    if ($StartTab -ne 0) { for ($i = 0; $i -lt $StartTab; $i++) { Write-Host -Object "`t" -NoNewline } }  # Add TABS before text
    if ($StartSpaces -ne 0) { for ($i = 0; $i -lt $StartSpaces; $i++) { Write-Host -Object ' ' -NoNewline } }  # Add SPACES before text
    if ($ShowTime) { Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline } # Add Time before output
    if ($Text.Count -ne 0) {
      if ($Color.Count -ge $Text.Count) {
        # the real deal coloring
        if ($null -eq $BackGroundColor) {
          for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -NoNewline }
        } else {
          for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline }
        }
      } else {
        if ($null -eq $BackGroundColor) {
          for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -NoNewline }
          for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -NoNewline }
        } else {
          for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $Color[$i] -BackgroundColor $BackGroundColor[$i] -NoNewline }
          for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host -Object $Text[$i] -ForegroundColor $DefaultColor -BackgroundColor $BackGroundColor[0] -NoNewline }
        }
      }
    }
    if ($NoNewLine -eq $true) { Write-Host -NoNewline } else { Write-Host } # Support for no new line
    if ($LinesAfter -ne 0) { for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host -Object "`n" -NoNewline } }  # Add empty line after
  }
  if ($Text.Count -and $LogFile) {
    # Save to file
    $TextToFile = ""
    for ($i = 0; $i -lt $Text.Length; $i++) {
      $TextToFile += $Text[$i]
    }
    $Saved = $false
    $Retry = 0
    do {
      $Retry++
      try {
        if ($LogTime) {
          "[$([datetime]::Now.ToString($DateTimeFormat))] $TextToFile" | Out-File -FilePath $LogFile -Encoding $Encoding -Append -ErrorAction Stop -WhatIf:$false
        } else {
          "$TextToFile" | Out-File -FilePath $LogFile -Encoding $Encoding -Append -ErrorAction Stop -WhatIf:$false
        }
        $Saved = $true
      } catch {
        if ($Saved -eq $false -and $Retry -eq $LogRetry) {
          Write-Warning "Write-Color - Couldn't write to log file $($_.Exception.Message). Tried ($Retry/$LogRetry))"
        } else {
          Write-Warning "Write-Color - Couldn't write to log file $($_.Exception.Message). Retrying... ($Retry/$LogRetry)"
        }
      }
    } until ($Saved -eq $true -or $Retry -ge $LogRetry)
  }
}

# Si el parámetro viene completamente vacío, mostramos cómo usarlo y salimos
if ([String]::IsNullOrEmpty($Mode)) {
    Write-Color "`n MODO DE USO:" -Color Cyan
    Write-Color " ==========================================================================" -Color Gray
    Write-Color " Modo Automático (Recomendado):" -Color White
    Write-Color "    .\Get-BatteryHealth.ps1 -Mode auto" -Color Yellow
    Write-Color "    (Genera el reporte interno y extrae los datos de tu PC actual)`n" -Color Gray
    Write-Color " Modo Manual:" -Color White
    Write-Color "    .\Get-BatteryHealth.ps1 -Mode manual -DesignCapacity 53015 -FullChargeCapacity 43243" -Color Yellow
    Write-Color " ==========================================================================`n" -Color Gray
    return
}

# Definición de la función utilitaria
function Get-BatteryHealth {
    param (
        [double]$FullChargeCapacity,
        [double]$DesignCapacity
    )

    # Cálculo del porcentaje de salud
    return ($FullChargeCapacity / $DesignCapacity) * 100
}

# Procesamiento según el modo seleccionado
switch ($Mode)
{
    'auto' {
        # Generamos un reporte temporal silencioso para extraer los datos reales
        $tempReport = "$env:TEMP\batteryreport.html"
        powercfg /batteryreport /output $tempReport | Out-Null

        if (Test-Path $tempReport) {
            # Leemos el archivo asegurando codificación UTF8 para evitar problemas de caracteres
            $html = Get-Content $tempReport -Raw -Encoding UTF8

            # Regex específica para la estructura: <td><span class="label">DESIGN CAPACITY</span></td><td>XX.XXX mWh
            if ($html -match 'DESIGN CAPACITY<\/span><\/td><td>([\d.,\s]+)mWh') {
                # Limpiamos puntos, comas y espacios antes de castear a número entero/double
                $DesignCapacity = [double]($Matches[1] -replace '[\s.,]', '')
            }

            # Regex específica para la estructura: <td><span class="label">FULL CHARGE CAPACITY</span></td><td>XX.XXX mWh
            if ($html -match 'FULL CHARGE CAPACITY<\/span><\/td><td>([\d.,\s]+)mWh') {
                $FullChargeCapacity = [double]($Matches[1] -replace '[\s.,]', '')
            }

            # Limpiamos el archivo temporal
            Remove-Item $tempReport -Force
        }

        if (-not $DesignCapacity -or -not $FullChargeCapacity) {
            Write-Error "No se pudieron obtener de forma automática las capacidades de la batería."
            return
        }
    }

    'manual' {
        # Validamos que el usuario haya pasado los parámetros requeridos para este modo
        if (-not $DesignCapacity -or -not $FullChargeCapacity) {
            Write-Error "En modo 'manual' debes proporcionar -DesignCapacity y -FullChargeCapacity."
            return
        }
    }
}

# Computamos el porcentaje de la salud de la batería
$batteryHealth = Get-BatteryHealth -FullChargeCapacity $FullChargeCapacity -designCapacity $DesignCapacity
$batteryHealth = [math]::Round($batteryHealth, 2)

# Condicional para determinar el color según el estado de salud de la batería
if ($batteryHealth -ge 80) {
    $healthColor = 'Green'
} elseif ($batteryHealth -ge 50) {
    $healthColor = 'Yellow'
} else {
    $healthColor = 'Red'
}

$line = "=================================="

# Resultado unificado y formateado a dos decimales empleando Write-Color
Write-Color $line -Color Cyan
Write-Color " DESIGN CAPACITY: ", "$DesignCapacity", "mWh" -Color Gray, Yellow, Gray
Write-Color " FULL CHARGE CAPACITY: ", "$FullChargeCapacity", "mWh" -Color Gray, Yellow, Gray
Write-Color " BATTERY HEALTH STATUS: ", "$batteryHealth%" -Color Gray, $healthColor
Write-Color $line -Color Cyan
