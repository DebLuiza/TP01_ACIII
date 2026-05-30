# Controlador de Cache — Trabalho Prático 1 (ACIII)

Implementação de um controlador de cache set-associative 2-way com memória principal simulada, baseado na Seção 5.12 do livro *Computer Organization and Design: The Hardware/Software Interface (RISC-V Edition)*.

## Parâmetros do Projeto

| Parâmetro              | Valor                |
|------------------------|----------------------|
| Endereço               | 8 bits               |
| Palavra                | 32 bits              |
| Número de conjuntos    | 4                    |
| Associatividade        | 2-way                |
| Tamanho do bloco       | 1 palavra            |
| Política de escrita    | Write-back           |
| Política de miss       | Write-allocate       |
| Substituição           | LRU simples por set  |

## Mapeamento de Endereço

```
addr[7:4] = tag   (4 bits)
addr[3:2] = index (2 bits)
addr[1:0] = offset de byte (não usado — bloco de 1 palavra)
```

## Estrutura de Arquivos

```
cache-controller/
├── src/
│   ├── cache_controller.sv   # FSM da cache, arrays, LRU, write-back
│   ├── main_memory.sv        # Memória de 64 palavras, latência 4 ciclos
│   └── cache_top.sv          # Wrapper integrando cache + memória
├── tb/
│   └── tb_cache_controller.sv  # Testbench com auto-verificação
├── sim/
│   └── run.sh                 # Script de compilação e simulação
├── docs/
│   ├── cobertura_testes.md    # Tabela cobertura teste → requisito
│   └── log_simulacao.txt      # Log de saída da simulação
└── run_all.sh                 # Script reprodutível com saída padronizada
```

## Dependências

- **Icarus Verilog** (iverilog) — compilador e simulador
- **GTKWave** (opcional) — visualização de waveforms

### Instalação (Linux - Ubuntu/Debian)

```bash
sudo apt install iverilog gtkwave
```

### Instalação (Windows - MSYS2 MINGW64)

```bash
pacman -S mingw-w64-x86_64-iverilog mingw-w64-x86_64-gtkwave
```

### Instalação (macOS - Homebrew)

```bash
brew install icarus-verilog
```

## Como Executar

Na raiz do projeto (`cache-controller/`):

```bash
chmod +x run_all.sh
./run_all.sh
```

Ou diretamente:

```bash
cd cache-controller
bash sim/run.sh
```

## Como Interpretar os Resultados dos Testes

O testbench executa automaticamente todos os cenários e imprime o resultado de cada teste no terminal.

### Formato de saída

Cada linha de teste segue o padrão:

```
[PASS] CATEGORIA | T<n>: <descricao> | hit=<valor> data=<valor>
[FAIL] CATEGORIA | T<n>: <descricao> | hit=<obtido> (exp <esperado>) data=<obtido> (exp <esperado>)
```

### Categorias

| Prefixo   | Seção | Significado              |
|-----------|-------|--------------------------|
| READ      | 7.1   | Testes de leitura        |
| WRITE     | 7.2   | Testes de escrita        |
| REPLACE   | 7.3   | Testes de substituição   |
| CONSIST   | 7.4   | Testes de consistência   |
| EDGE      | 7.5   | Casos limite             |

### Resumo final

Ao final da simulação, é exibido:

```
RESULTADO FINAL: X PASS / Y FAIL de Z testes
>>> TODOS OS TESTES PASSARAM <<<
```

### Critérios de sucesso/falha

- **Sucesso**: todas as linhas mostram `[PASS]` e o resumo indica `0 FAIL`.
- **Falha**: qualquer linha `[FAIL]` indica divergência entre o comportamento obtido e o esperado. O log mostra exatamente qual teste falhou, o valor de `hit` e `data` obtidos versus esperados.

### Salvando o log

```bash
./run_all.sh 2>&1 | tee docs/log_simulacao.txt
```

### Visualizando waveforms

```bash
gtkwave sim/wave.vcd
```

## FSM do Controlador

| Estado           | Descrição                                          |
|------------------|----------------------------------------------------|
| IDLE             | Aguarda requisição da CPU                          |
| COMPARE_TAG      | Verifica hit/miss e escolhe caminho                |
| WRITE_BACK_REQ   | Inicia escrita de bloco dirty na memória           |
| WRITE_BACK_WAIT  | Aguarda conclusão do write-back                    |
| ALLOCATE_REQ     | Inicia leitura do bloco da memória                 |
| ALLOCATE_WAIT    | Aguarda dado da memória                            |
| UPDATE_CACHE     | Atualiza linha da cache com novo bloco             |
| RESPOND          | Sinaliza cpu_ready e cache_hit para a CPU          |

## Política LRU (2-way)

- `lru[set] = 0` → way 0 é a vítima preferida
- `lru[set] = 1` → way 1 é a vítima preferida
- Em hit: a via acessada se torna MRU (mais recente)
- Em miss: a via LRU é selecionada para alocação/substituição

## Limitações e Próximos Passos

- **Bloco de 1 palavra**: simplificação que reduz complexidade de alinhamento mas não explora localidade espacial. Extensão natural: blocos de 4 palavras com burst.
- **4 sets / 2 ways**: cache pequena para fins didáticos. Escalar para 64+ sets e 4-way é direto.
- **Latência fixa de memória**: memória real teria latência variável. Poderia ser modelada com distribuição aleatória.
- **Sem suporte multi-core**: não há protocolo de coerência (MESI/MOESI).
- **Sem byte-enable**: acessos sempre em palavra completa de 32 bits.
