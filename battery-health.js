#!/usr/bin/env node
// Compatible runtimes: node, bun, deno

import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

/**
 * @file Battery health status analyzer tool.
 * @description Generates windows battery reports or reads inputs manually to print formatted health statistics with threshold coloring.
 */

// Colors utilizando secuencias ANSI
const CYAN = "\x1b[36m";
const WHITE = "\x1b[37m";
const GRAY = "\x1b[90m";
const YELLOW = "\x1b[33m";
const GREEN = "\x1b[32m";
const RED = "\x1b[31m";
const NC = "\x1b[0m";

/**
 * Prints the CLI usage manual instructions to the console.
 *
 * @returns {void}
 */
function showUsage() {
  console.log(`${CYAN}\n MODO DE USO:${NC}`);
  console.log(
    `${GRAY} ==========================================================================${NC}`,
  );
  console.log(`${WHITE} Modo Automático (Recomendado):${NC}`);
  console.log(`${YELLOW}   node batteryHealth.js --mode auto${NC}`);
  console.log(
    `${GRAY}   (Genera el reporte interno y extrae los datos de tu PC actual)\n${NC}`,
  );
  console.log(`${WHITE} Modo Manual:${NC}`);
  console.log(
    `${YELLOW}   node batteryHealth.js --mode manual --design 53015 --full 43243${NC}`,
  );
  console.log(
    `${GRAY} ==========================================================================\n${NC}`,
  );
}

// Mapeo simple de argumentos de terminal
const args = process.argv.slice(2);
const argMap = {};
for (let i = 0; i < args.length; i += 2) {
  argMap[args[i]] = args[i + 1];
}

const mode = argMap["--mode"] || "auto";
let designCapacity = parseFloat(argMap["--design"]) || 0;
let fullChargeCapacity = parseFloat(argMap["--full"]) || 0;

if (mode !== "auto" && mode !== "manual") {
  showUsage();
  process.exit(1);
}

/**
 * Evaluates the proportional remaining integrity of the battery.
 *
 * @param {number} fullCharge - Current maximum charge capacity in mWh.
 * @param {number} design - Original manufacturer capacity in mWh.
 * @returns {number} Percentage representation of overall battery health.
 */
function getBatteryHealth(fullCharge, design) {
  if (design === 0) return 0;
  return (fullCharge / design) * 100;
}

if (mode === "auto") {
  const tempDir = process.env.TEMP || process.env.TMP || "/tmp";
  const tempReport = path.join(tempDir, "batteryreport.html");

  try {
    // Generación silenciosa del reporte html
    execSync(`powercfg /batteryreport /output "${tempReport}"`, {
      stdio: "ignore",
    });

    if (fs.existsSync(tempReport)) {
      const html = fs.readFileSync(tempReport, "utf8");

      const designMatch = html.match(
        /DESIGN CAPACITY<\/span><\/td><td>([\d.,\s]+)mWh/,
      );
      if (designMatch) {
        designCapacity = parseFloat(designMatch[1].replace(/[\s.,]/g, ""));
      }

      const fullMatch = html.match(
        /FULL CHARGE CAPACITY<\/span><\/td><td>([\d.,\s]+)mWh/,
      );
      if (fullMatch) {
        fullChargeCapacity = parseFloat(fullMatch[1].replace(/[\s.,]/g, ""));
      }

      fs.unlinkSync(tempReport);
    }
  } catch (error) {
    // Falla controlada si el entorno no es compatible con powercfg
  }

  if (!designCapacity || !fullChargeCapacity) {
    console.error(
      "Error: No se pudieron obtener de forma automática las capacidades de la batería.",
    );
    process.exit(1);
  }
} else if (mode === "manual") {
  if (!designCapacity || !fullChargeCapacity) {
    console.error(
      "Error: En modo 'manual' debes proporcionar --design y --full.",
    );
    process.exit(1);
  }
}

const batteryHealth = getBatteryHealth(fullChargeCapacity, designCapacity);

let healthColor = RED;
if (batteryHealth >= 80) {
  healthColor = GREEN;
} else if (batteryHealth >= 50) {
  healthColor = YELLOW;
}

const line = "==================================";
console.log(`${CYAN}${line}${NC}`);
console.log(
  `${GRAY} DESIGN CAPACITY: ${YELLOW}${designCapacity}${GRAY}mWh${NC}`,
);
console.log(
  `${GRAY} FULL CHARGE CAPACITY: ${YELLOW}${fullChargeCapacity}${GRAY}mWh${NC}`,
);
console.log(
  `${GRAY} BATTERY HEALTH STATUS: ${healthColor}${batteryHealth.toFixed(2)}%${NC}`,
);
console.log(`${CYAN}${line}${NC}`);
