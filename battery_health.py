#!/usr/bin/env python3
import argparse
import os
import re
import subprocess
import sys

# Definición de códigos de color ANSI
CYAN = "\033[0;36m"
WHITE = "\033[1;37m"
GRAY = "\033[0;37m"
YELLOW = "\033[1;33m"
GREEN = "\033[0;32m"
RED = "\033[0;31m"
NC = "\033[0m"


def show_usage():
    """Prints terminal execution context manual helper."""
    print(f"{CYAN}\n MODO DE USO:{NC}")
    print(f"{GRAY} =========================================================================={NC}")
    print(f"{WHITE} Modo Automático (Recomendado):{NC}")
    print(f"{YELLOW}   python battery_health.py --mode auto{NC}")
    print(f"{GRAY}   (Genera el reporte interno y extrae los datos de tu PC actual)\n{NC}")
    print(f"{WHITE} Modo Manual:{NC}")
    print(f"{YELLOW}   python battery_health.py --mode manual --design 53015 --full 43243{NC}")
    print(f"{GRAY} ==========================================================================\n${NC}")


def get_battery_health(full_charge: float, design: float) -> float:
    """Calculates mathematical battery health ratio."""
    if design == 0:
        return 0.0
    return (full_charge / design) * 100


def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--mode", default="auto", choices=["auto", "manual"])
    parser.add_argument("--design", type=float, default=0.0)
    parser.add_argument("--full", type=float, default=0.0)

    # Captura errores en argumentos para desviar a la guía personalizada
    try:
        args = parser.parse_args()
    except SystemExit:
        show_usage()
        sys.exit(1)

    design_capacity = args.design
    full_charge_capacity = args.full

    if args.mode == "auto":
        temp_dir = os.environ.get("TEMP") or os.environ.get("TMP") or "/tmp"
        temp_report = os.path.join(temp_dir, "batteryreport.html")

        try:
            # Ejecución controlada y redirección silenciosa de flujos
            subprocess.run(
                ["powercfg", "/batteryreport", "/output", temp_report],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=True
            )

            if os.path.exists(temp_report):
                with open(temp_report, "r", encoding="utf-8") as f:
                    html = f.read()

                design_match = re.search(r"DESIGN CAPACITY<\/span><\/td><td>([\d.,\s]+)mWh", html)
                if design_match:
                    design_capacity = float(re.sub(r"[\s.,]", "", design_match.group(1)))

                full_match = re.search(r"FULL CHARGE CAPACITY<\/span><\/td><td>([\d.,\s]+)mWh", html)
                if full_match:
                    full_charge_capacity = float(re.sub(r"[\s.,]", "", full_match.group(1)))

                os.remove(temp_report)
        except Exception:
            pass

        if not design_capacity or not full_charge_capacity:
            print("Error: No se pudieron obtener de forma automática las capacidades de la batería.", file=sys.stderr)
            sys.exit(1)

    elif args.mode == "manual":
        if not design_capacity or not full_charge_capacity:
            print("Error: En modo 'manual' debes proporcionar --design y --full.", file=sys.stderr)
            sys.exit(1)

    battery_health = get_battery_health(full_charge_capacity, design_capacity)

    # Evaluación condicional de salud de la celda de energía
    if battery_health >= 80:
        health_color = GREEN
    elif battery_health >= 50:
        health_color = YELLOW
    else:
        health_color = RED

    line = "=================================="
    print(f"{CYAN}{line}{NC}")
    print(f"{GRAY} DESIGN CAPACITY:       {YELLOW}{design_capacity:g}{GRAY} mWh{NC}")
    print(f"{GRAY} FULL CHARGE CAPACITY:  {YELLOW}{full_charge_capacity:g}{GRAY} mWh{NC}")
    print(f"{GRAY} BATTERY HEALTH STATUS: {health_color}{battery_health:.2f}%{NC}")
    print(f"{CYAN}{line}{NC}")


if __name__ == "__main__":
    main()
