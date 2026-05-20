# Battery Status Script

Script para obtener el estado de la bateria de tu laptop

## Modo de uso

1. PowerShell (Windows)

### Ejecución

```powershell
# Modo Auto
.\Get-BatteryHealth -Mode auto

# Modo Manual
.\Get-BatteryHealth.ps1 -Mode manual -DesignCapacity 53015 -FullChargeCapacity 43243
```

2. Bash (Macos/Linux)

### Ejecución 

```bash
chmod +x ./battery-health.sh && ./battery-health.sh
```

3. Node o Deno o Bun

Primero deberas tener instalado cualquiera de estos entornos de ejecucion

- [Node](https://nodejs.org/es/download)

Alternativa instalacion node usando winget 

```powershell
winget install OpenJS.NodeJS
```

- [Bun](https://bun.com/docs/installation)

Alternativa instalacion node usando winget 

```powershell
winget install Oven-sh.Bun
```

### Ejecución 

```javascript
// con node 
node ./batteryHealth.js --mode auto
// con bun
bunx ./batteryHealth.js --mode auto

// con node mode manual
node ./batteryHealth.js --mode manual --design 53015 --full 43243
// con bun mode manual
bunx ./batteryHealth.js --mode manual --design 53015 --full 43243
```

4. Python

Paso anterior a ejecutar [Instalar Python](https://python.org/downloads/)

### Ejecución

```python
py ./battery_health.py
```
