#!/bin/bash

# Inicialización de variables
MODE="auto"
DESIGN_CAPACITY=0
FULL_CHARGE_CAPACITY=0

# Códigos de colores ANSI
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para mostrar el modo de uso
show_usage() {
    echo -e "${CYAN}\n MODO DE USO:${NC}"
    echo -e "${GRAY} ==========================================================================${NC}"
    echo -e "${WHITE} Modo Automático (Recomendado):${NC}"
    echo -e "${YELLOW}   ./battery-health.sh --mode auto${NC}"
    echo -e "${GRAY}   (Extrae los datos de la batería usando el sistema nativo de Linux /sys)\n${NC}"
    echo -e "${WHITE} Modo Manual:${NC}"
    echo -e "${YELLOW}   ./battery-health.sh --mode manual --design 53015 --full 43243${NC}"
    echo -e "${GRAY} ==========================================================================\n${NC}"
}

# Procesamiento de argumentos
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --mode) MODE="$2"; shift ;;
        --design) DESIGN_CAPACITY="$2"; shift ;;
        --full) FULL_CHARGE_CAPACITY="$2"; shift ;;
        *) show_usage; exit 1 ;;
    esac
    shift
done

if [ -z "$MODE" ] || [[ "$MODE" != "auto" && "$MODE" != "manual" ]]; then
    show_usage
    exit 1
fi

get_battery_health() {
    awk "BEGIN {print ($1 / $2) * 100}"
}

if [ "$MODE" == "auto" ]; then
    # 1. Intento Estándar de Linux: Leer el sistema de archivos /sys
    if [ -d "/sys/class/power_supply/BAT0" ]; then
        # Algunos kernels exponen 'energy_design'/'energy_full' y otros 'charge_design'/'charge_full'
        if [ -f "/sys/class/power_supply/BAT0/energy_design" ]; then
            DESIGN_CAPACITY=$(cat /sys/class/power_supply/BAT0/energy_design)
            FULL_CHARGE_CAPACITY=$(cat /sys/class/power_supply/BAT0/energy_full)
        elif [ -f "/sys/class/power_supply/BAT0/charge_design" ]; then
            DESIGN_CAPACITY=$(cat /sys/class/power_supply/BAT0/charge_design)
            FULL_CHARGE_CAPACITY=$(cat /sys/class/power_supply/BAT0/charge_full)
        fi

        # /sys suele entregar los valores en µWh o µAh, los convertimos a mWh dividiendo por 1000
        if [ "$DESIGN_CAPACITY" -gt 0 ]; then
            DESIGN_CAPACITY=$((DESIGN_CAPACITY / 1000))
            FULL_CHARGE_CAPACITY=$((FULL_CHARGE_CAPACITY / 1000))
        fi
    fi

    # 2. Fallback para WSL: Si /sys está vacío, detectamos si es WSL y consultamos mediante la herramienta nativa upower o proc
    if [ "$DESIGN_CAPACITY" -eq 0 ] && grep -qi "microsoft" /proc/version 2>/dev/null; then
        # Como WSL no expone la batería a Linux, nos vemos obligados a consultar al host a través del comando rápido de PowerShell nativo
        # Esto evita generar HTML temporales pesados y emula el comportamiento de una herramienta de sistema de Linux
        POWERSHELL_CMD="Get-CimInstance -Namespace root/WMI -ClassName BatteryStaticData | Select-Object -Property DesignedCapacity; Get-CimInstance -Namespace root/WMI -ClassName BatteryFullChargeStatus | Select-Object -Property FullChargeCapacity"

        DATA=$(powershell.exe -NoProfile -Command "$POWERSHELL_CMD" 2>/dev/null)
        if [ ! -z "$DATA" ]; then
            # Limpiamos y extraemos las capacidades directamente desde el flujo de texto de salida
            DESIGN_CAPACITY=$(echo "$DATA" | awk '/DesignedCapacity/ {print $2}' | tr -d '\r[:space:]')
            FULL_CHARGE_CAPACITY=$(echo "$DATA" | awk '/FullChargeCapacity/ {print $2}' | tr -d '\r[:space:]')
        fi
    fi

    if [ -z "$DESIGN_CAPACITY" ] || [ -z "$FULL_CHARGE_CAPACITY" ] || [ "$DESIGN_CAPACITY" -eq 0 ] || [ "$FULL_CHARGE_CAPACITY" -eq 0 ]; then
        echo -e "${RED}Error: No se pudieron obtener de forma automática las capacidades desde Linux /sys o WSL.${NC}" >&2
        exit 1
    fi

elif [ "$MODE" == "manual" ]; then
    if [ -z "$DESIGN_CAPACITY" ] || [ -z "$FULL_CHARGE_CAPACITY" ] || [ "$DESIGN_CAPACITY" -eq 0 ] || [ "$FULL_CHARGE_CAPACITY" -eq 0 ]; then
        echo -e "${RED}Error: En modo 'manual' debes proporcionar --design y --full.${NC}" >&2
        exit 1
    fi
fi

BATTERY_HEALTH=$(get_battery_health "$FULL_CHARGE_CAPACITY" "$DESIGN_CAPACITY")

# Lógica condicional de colores basada en el umbral numérico
if (( $(echo "$BATTERY_HEALTH >= 80" | bc -l) )); then
    HEALTH_COLOR=$GREEN
elif (( $(echo "$BATTERY_HEALTH >= 50" | bc -l) )); then
    HEALTH_COLOR=$YELLOW
else
    HEALTH_COLOR=$RED
fi

HEALTH_FORMATTED=$(printf "%.2f" "$BATTERY_HEALTH")
LINE="=================================="

echo -e "${CYAN}${LINE}${NC}"
echo -e "${GRAY} DESIGN CAPACITY:       ${YELLOW}${DESIGN_CAPACITY}${GRAY} mWh${NC}"
echo -e "${GRAY} FULL CHARGE CAPACITY:  ${YELLOW}${FULL_CHARGE_CAPACITY}${GRAY} mWh${NC}"
echo -e "${GRAY} BATTERY HEALTH STATUS: ${HEALTH_COLOR}${HEALTH_FORMATTED}%${NC}"
echo -e "${CYAN}${LINE}${NC}"
