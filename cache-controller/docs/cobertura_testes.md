# Tabela de Cobertura: Testes vs Requisitos (Secoes 7.1 a 7.5)

Esta tabela mapeia cada teste do testbench (`tb_cache_controller.sv`) ao requisito especificado no enunciado.

## Legenda

| Prefixo   | Secao | Descricao                     |
|-----------|-------|-------------------------------|
| READ      | 7.1   | Testes de Leitura             |
| WRITE     | 7.2   | Testes de Escrita             |
| REPLACE   | 7.3   | Testes de Substituicao        |
| CONSIST   | 7.4   | Testes de Consistencia        |
| EDGE      | 7.5   | Testes de Casos Limite        |

## 7.1 - Testes de Leitura (Read Path)

| #  | Teste                                   | Requisito Coberto                                         |
|----|----------------------------------------|-----------------------------------------------------------|
| T1 | Read miss cold (addr 0x10)             | Cache miss seguido de carregamento da memoria principal   |
| T2 | Read hit (addr 0x10 novamente)         | Acesso com cache hit (dados ja presentes)                 |
| T3 | Read miss second way (addr 0x20)       | Cache miss com alocacao na segunda via                    |
| T4 | Read hit second way (addr 0x20)        | Cache hit na segunda via                                  |
| T5 | Read hit first way still valid (0x10)  | Verificacao de bits valid e tag corretos                  |

## 7.2 - Testes de Escrita (Write Path)

| #   | Teste                                  | Requisito Coberto                                         |
|-----|----------------------------------------|-----------------------------------------------------------|
| T6  | Write hit (addr 0x10)                  | Escrita com hit (atualizacao direta na cache)             |
| T7  | Read-back confirma write hit           | Validacao write-back (dado persiste na cache)             |
| T8  | Write miss write-allocate (addr 0x30)  | Escrita com miss (write-allocate)                         |
| T9  | Read-back confirma write-allocate      | Confirmacao da politica write-allocate                    |
| T10 | Write hit dirty update (addr 0x30)     | Validacao do bit dirty (write-back)                       |

## 7.3 - Testes de Substituicao (Replacement)

| #   | Teste                                  | Requisito Coberto                                         |
|-----|----------------------------------------|-----------------------------------------------------------|
| T11 | Fill set1 way0 (addr 0x04)             | Preenchimento da cache                                    |
| T12 | Fill set1 way1 (addr 0x14)             | Preenchimento completo do set                             |
| T13 | Touch set1 way0 MRU                    | Atualizacao do LRU ao acessar via                         |
| T14 | Evict LRU way1 (addr 0x24)             | Substituicao conforme politica LRU                        |
| T15 | Confirm 0x14 evicted (miss)            | Confirmacao que bloco LRU foi removido                    |
| T16 | Write set2 dirty + evict write-back    | Write-back de bloco dirty durante substituicao            |
| T17 | Confirm write-back from memory         | Verificacao de escrita em memoria em caso de dirty        |

## 7.4 - Testes de Consistencia

| #   | Teste                                  | Requisito Coberto                                         |
|-----|----------------------------------------|-----------------------------------------------------------|
| T18 | Write-Read-Write-Read mesmo endereco   | Sequencias leitura/escrita validando coerencia            |
| T19 | Acessos conflitantes mesmo indice      | Diferentes enderecos mapeiam para mesmo indice (conflito) |
|     | Read set3 tag0 e tag1                  | Acessos repetidos ao mesmo endereco                       |
|     | Write tag2 evicts LRU                  | Conflito de indice com eviction                           |
|     | Read surviving tag1                    | Consistencia do dado sobrevivente                         |

## 7.5 - Testes de Casos Limite (Edge Cases)

| #   | Teste                                  | Requisito Coberto                                         |
|-----|----------------------------------------|-----------------------------------------------------------|
| T20 | Read addr 0x00 (min)                   | Acesso a endereco extremo inferior                        |
| T21 | Read addr 0xFC (max)                   | Acesso a endereco extremo superior                        |
| T22 | Read hit addr 0xFC                     | Hit apos alocacao de endereco extremo                     |
| T23 | Read miss after reset                  | Inicializacao da cache (estado vazio apos reset)          |
|     | Read hit after re-fill post-reset      | Cache completamente invalida apos reset, re-preenchimento |

## Resumo de Cobertura

| Secao | Requisito do Enunciado                              | Coberto? |
|-------|-----------------------------------------------------|----------|
| 7.1   | Cache hit (dados presentes)                         | Sim      |
| 7.1   | Cache miss + carregamento da memoria                | Sim      |
| 7.1   | Atualizacao de bits valid e tag                     | Sim      |
| 7.2   | Escrita com hit                                     | Sim      |
| 7.2   | Escrita com miss (write-allocate)                   | Sim      |
| 7.2   | Politica write-back (bit dirty)                     | Sim      |
| 7.3   | Preenchimento completo e substituicao               | Sim      |
| 7.3   | Politica de substituicao LRU                        | Sim      |
| 7.3   | Write-back de bloco dirty na substituicao           | Sim      |
| 7.4   | Sequencias leitura/escrita coerentes                | Sim      |
| 7.4   | Acessos repetidos ao mesmo endereco                 | Sim      |
| 7.4   | Conflitos de indice (mesmo set, tags diferentes)    | Sim      |
| 7.5   | Enderecos extremos (0x00, 0xFC)                     | Sim      |
| 7.5   | Inicializacao (estado vazio)                        | Sim      |
| 7.5   | Cache completamente invalida (pos-reset)            | Sim      |
