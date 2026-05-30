#!/bin/bash
# =============================================================================
# run_all.sh - Script de execução reprodutível do testbench
# Compila, simula e reporta resultado (PASS/FAIL) com exit code apropriado.
# Uso: ./run_all.sh
# =============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

SRC_DIR="src"
TB_DIR="tb"
SIM_DIR="sim"
OUT="$SIM_DIR/cache_tb.vvp"

echo "============================================================"
echo " Controlador de Cache - Simulação Automatizada"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"

# --- Compilação ---
echo ""
echo "[1/3] Compilando..."
mkdir -p "$SIM_DIR"

iverilog -g2012 \
    -o "$OUT" \
    "$SRC_DIR/cache_controller.sv" \
    "$SRC_DIR/main_memory.sv" \
    "$SRC_DIR/cache_top.sv" \
    "$TB_DIR/tb_cache_controller.sv"

echo "      Compilação OK."

# --- Simulação ---
echo ""
echo "[2/3] Executando simulação..."
echo ""

SIM_LOG="$SIM_DIR/sim_output.log"
vvp "$OUT" | tee "$SIM_LOG"

# --- Verificação de resultado ---
echo ""
echo "[3/3] Verificando resultado..."

if grep -q "TODOS OS TESTES PASSARAM" "$SIM_LOG"; then
    echo ""
    echo "============================================================"
    echo " RESULTADO: SUCESSO - Todos os testes passaram."
    echo "============================================================"
    exit 0
else
    echo ""
    echo "============================================================"
    echo " RESULTADO: FALHA - Verifique as linhas [FAIL] no log."
    echo "============================================================"
    exit 1
fi
