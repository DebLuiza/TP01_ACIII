# Controlador de Cache - Especificacoes do Trabalho

Este projeto implementa um controlador de cache set-associative 2-way com memoria principal simulada.

## Parametros definidos

- Endereco: 8 bits (byte-addressed)
- Palavra: 32 bits (4 bytes)
- Numero de conjuntos: 4
- Associatividade: 2-way
- Total de linhas: 8
- Tamanho do bloco: 1 palavra
- Politica de escrita: write-back
- Politica de miss de escrita: write-allocate
- Substituicao: LRU simples por conjunto

## Mapeamento de endereco

- `addr[7:4]`: tag (4 bits)
- `addr[3:2]`: index (2 bits)
- `addr[1:0]`: offset de byte (2 bits)

Como cada bloco guarda uma unica palavra de 32 bits, o offset nao seleciona outra palavra dentro do bloco.
Nos acessos de memoria, o endereco do bloco e alinhado com `2'b00` nos bits menos significativos.

## Estrutura dos modulos

- `src/cache_controller.sv`: FSM da cache, arrays `valid/dirty/tag/data`, politica LRU, write-back e write-allocate.
- `src/main_memory.sv`: memoria de 64 palavras com latencia simulada.
- `src/cache_top.sv`: integra `cache_controller` e `main_memory` em um unico modulo.
- `tb/tb_cache_controller.sv`: testbench do sistema completo usando o `cache_top`.

## FSM do controlador

Estados principais do controlador:

- `IDLE`: aguarda requisicao da CPU.
- `COMPARE_TAG`: detecta hit/miss e escolhe caminho.
- `WRITE_BACK_REQ` / `WRITE_BACK_WAIT`: escreve bloco dirty na memoria antes da substituicao.
- `ALLOCATE_REQ` / `ALLOCATE_WAIT`: requisita e aguarda bloco da memoria (write-allocate em miss de escrita).
- `UPDATE_CACHE`: atualiza linha, bits e dado.
- `RESPOND`: finaliza a transacao para CPU.

A separacao em estados `*_REQ` e `*_WAIT` evita uso indevido de `mem_ready` residual entre operacoes.

## Politica LRU (2-way)

- `lru[set] = 0`: way 0 e a vitima preferida.
- `lru[set] = 1`: way 1 e a vitima preferida.
- Em hit, a way acessada vira a mais recente.
- Em miss, a way escolhida para alocacao/substituicao e travada para a requisicao atual.

## Testes cobertos no testbench

- Miss e hit de leitura.
- Hit de escrita com write-back (linha dirty).
- Miss de escrita com write-allocate.
- Substituicao por LRU no mesmo conjunto.
- Write-back de linha dirty seguido de confirmacao na memoria.

## Como simular

Dentro de `cache-controller/`:

```bash
bash sim/run.sh
```

Ou, no PowerShell com as mesmas etapas:

```powershell
iverilog -g2012 -o sim/cache_tb.vvp src/cache_top.sv src/cache_controller.sv src/main_memory.sv tb/tb_cache_controller.sv
vvp sim/cache_tb.vvp
```
