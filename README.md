# Controlador de Cache - TP1 ACIII

Implementacao de um controlador de cache em SystemVerilog com:

- Cache 2-way set associative
- 4 conjuntos (8 linhas no total)
- Endereco de 8 bits
- Palavra de 32 bits
- Bloco de 1 palavra
- Politica de escrita: write-back
- Politica de miss de escrita: write-allocate
- Politica de substituicao: LRU simples por conjunto

## Estrutura

```text
cache-controller/
|-- src/
|   |-- cache_controller.sv
|   |-- main_memory.sv
|   `-- cache_top.sv
|-- tb/
|   `-- tb_cache_controller.sv
|-- sim/
|   `-- run.sh
`-- docs/
    `-- log_simulacao.txt
```

## Dependencias (Linux)

Exemplo em Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y iverilog gtkwave
```

Verificacao:

```bash
iverilog -V
vvp -V
```

## Compilacao e simulacao (Linux)

A partir da pasta `cache-controller/`:

```bash
chmod +x sim/run.sh
./sim/run.sh
```

Comandos equivalentes:

```bash
iverilog -g2012 -o sim/cache_tb.vvp \
  src/cache_controller.sv \
  src/main_memory.sv \
  src/cache_top.sv \
  tb/tb_cache_controller.sv

vvp sim/cache_tb.vvp
```

## Salvar log de simulacao

```bash
mkdir -p docs
./sim/run.sh > docs/log_simulacao.txt
```

## Visualizar waveform

O testbench gera `sim/wave.vcd`.

```bash
gtkwave sim/wave.vcd
```

## Testes cobertos

- Leitura: hit e miss
- Escrita: hit e miss (write-allocate)
- Substituicao por LRU
- Write-back de bloco dirty
- Consistencia com conflitos de indice
- Casos limite: cache vazia apos reset, endereco extremo baixo (`8'h00`) e extremo alto (`8'hFF`)
