#!/bin/bash

echo "======================================"
echo " Compilando o controlador de cache..."
echo "======================================"

mkdir -p sim

iverilog -g2012 \
    -o sim/cache_tb.vvp \
    src/cache_controller.sv \
    src/main_memory.sv \
    tb/tb_cache_controller.sv

if [ $? -ne 0 ]; then
    echo ""
    echo "Erro: a compilação falhou."
    exit 1
fi

echo ""
echo "======================================"
echo " Executando a simulação..."
echo "======================================"

vvp sim/cache_tb.vvp

if [ $? -ne 0 ]; then
    echo ""
    echo "Erro: a simulação falhou."
    exit 1
fi

echo ""
echo "======================================"
echo " Simulação finalizada com sucesso."
echo "======================================"
echo ""
echo "Se o arquivo wave.vcd foi gerado, abra com:"
echo "gtkwave sim/wave.vcd"