#!/bin/bash
# Download PicoRV32 core from GitHub

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTL_CORE_DIR="${SCRIPT_DIR}/../rtl/core"

echo "=== Downloading PicoRV32 Core ==="
echo "Target directory: ${RTL_CORE_DIR}"
echo ""

# Create core directory if it doesn't exist
mkdir -p "${RTL_CORE_DIR}"

# Download PicoRV32 from GitHub
PICORV32_URL="https://raw.githubusercontent.com/YosysHQ/picorv32/master/picorv32.v"

echo "Downloading picorv32.v..."
curl -L -o "${RTL_CORE_DIR}/picorv32.v" "${PICORV32_URL}"

if [ -f "${RTL_CORE_DIR}/picorv32.v" ]; then
    echo ""
    echo "✓ PicoRV32 core downloaded successfully!"
    echo "  File: ${RTL_CORE_DIR}/picorv32.v"
    echo "  Size: $(wc -c < ${RTL_CORE_DIR}/picorv32.v) bytes"
else
    echo ""
    echo "✗ Download failed!"
    exit 1
fi
