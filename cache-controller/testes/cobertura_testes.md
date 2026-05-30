# Tabela de Cobertura: Testes vs Requisitos (Secoes 7.1 a 7.5)

Esta tabela mapeia cada teste do testbench (`tb_cache_controller.sv`) ao requisito especificado no enunciado.

## Legenda

| Prefixo   | Secao | Descricao              |
|-----------|-------|------------------------|
| READ      | 7.1   | Testes de Leitura      |
| WRITE     | 7.2   | Testes de Escrita      |
| REPLACE   | 7.3   | Testes de Substituicao |
| CONSIST   | 7.4   | Testes de Consistencia |
| EDGE      | 7.5   | Testes de Casos Limite |

## 7.1 - Testes de Leitura (READ)

| #  | Teste                                           | Requisito Coberto                                       |
|----|-------------------------------------------------|---------------------------------------------------------|
| T1 | Read miss cold (addr 0x10)                      | Miss de leitura com alocacao de bloco                   |
| T2 | Read hit (addr 0x10 novamente)                  | Hit de leitura no mesmo endereco                        |
| T3 | Read miss second way (addr 0x20)                | Miss com uso da segunda via                             |
| T4 | Read hit second way (addr 0x20)                 | Hit na segunda via                                      |
| T5 | Read hit first way still valid (addr 0x10)      | Validacao de tag/valid apos multiplos acessos           |

## 7.2 - Testes de Escrita (WRITE)

| #   | Teste                                           | Requisito Coberto                                       |
|-----|-------------------------------------------------|---------------------------------------------------------|
| T6  | Write hit (addr 0x10)                           | Escrita com hit e atualizacao na cache                  |
| T7  | Read-back confirma write hit (addr 0x10)        | Persistencia do dado escrito em hit                     |
| T8  | Write miss write-allocate (addr 0x30)           | Escrita com miss usando write-allocate                  |
| T9  | Read-back confirma write-allocate (addr 0x30)   | Confirmacao da alocacao e escrita em miss               |
| T10 | Write hit dirty update (addr 0x30)              | Atualizacao de linha dirty com write-back               |

## 7.3 - Testes de Substituicao (REPLACE)

| #   | Teste                                           | Requisito Coberto                                       |
|-----|-------------------------------------------------|---------------------------------------------------------|
| T11 | Fill set1 way0 (addr 0x04)                      | Preenchimento de via 0                                  |
| T12 | Fill set1 way1 (addr 0x14)                      | Preenchimento de via 1                                  |
| T13 | Touch set1 way0 MRU (addr 0x04)                 | Atualizacao de LRU (via acessada vira MRU)              |
| T14 | Evict LRU way1 (addr 0x24)                      | Substituicao conforme politica LRU                      |
| T15 | Confirm 0x14 evicted (miss)                     | Verificacao da vitima escolhida                         |
| T16 | Write set2 way0 dirty (addr 0x08)               | Preparacao de linha dirty para write-back               |
| T17 | Fill set2 way1 (addr 0x18)                      | Preenchimento do set para forcar eviccao                |
| T18 | Touch 0x18 MRU                                  | Reordenacao LRU antes da substituicao                   |
| T19 | Evict dirty 0x08 write-back (addr 0x28)         | Write-back durante substituicao de linha dirty          |
| T20 | Confirm write-back 0x08 from mem                | Confirmacao de dado escrito de volta na memoria         |

## 7.4 - Testes de Consistencia (CONSIST)

| #   | Teste                                           | Requisito Coberto                                       |
|-----|-------------------------------------------------|---------------------------------------------------------|
| T21 | Write addr 0x44                                 | Escrita inicial em endereco novo                        |
| T22 | Read-back addr 0x44                             | Leitura coerente apos escrita                           |
| T23 | Overwrite addr 0x44                             | Sobrescrita no mesmo endereco                           |
| T24 | Read-back overwrite 0x44                        | Confirmacao do ultimo valor escrito                     |
| T25 | Write set3 tag0 (0x0C)                          | Conflito no mesmo indice (set 3) - tag 0               |
| T26 | Write set3 tag1 (0x1C)                          | Conflito no mesmo indice (set 3) - tag 1               |
| T27 | Read set3 tag0 (0x0C)                           | Coexistencia correta de linhas no mesmo set             |
| T28 | Read set3 tag1 (0x1C)                           | Coexistencia correta de linhas no mesmo set             |
| T29 | Write set3 tag2 evicts LRU (0x2C)               | Eviccao por conflito de indice com terceira tag         |
| T30 | Read surviving tag1 (0x1C)                      | Dado sobrevivente apos eviccao permanece consistente    |

## 7.5 - Testes de Casos Limite (EDGE)

| #   | Teste                                           | Requisito Coberto                                       |
|-----|-------------------------------------------------|---------------------------------------------------------|
| T31 | Read addr 0x00 (min)                            | Endereco extremo inferior                               |
| T32 | Read addr 0xFC (max)                            | Endereco extremo superior efetivo (palavra alinhada)    |
| T33 | Read hit addr 0xFC                              | Hit apos alocacao de endereco extremo                   |
| T34 | Read miss after reset (cache invalidated)       | Cache invalida apos reset                               |
| T35 | Read hit after re-fill post-reset               | Re-preenchimento e retorno ao comportamento esperado    |

## Resumo de Cobertura

| Secao | Requisito do Enunciado                           | Coberto? |
|-------|--------------------------------------------------|----------|
| 7.1   | Leitura com miss e hit                           | Sim      |
| 7.1   | Atualizacao de valid/tag                         | Sim      |
| 7.2   | Escrita com hit                                  | Sim      |
| 7.2   | Escrita com miss (write-allocate)                | Sim      |
| 7.2   | Politica write-back (dirty)                      | Sim      |
| 7.3   | Substituicao com LRU                             | Sim      |
| 7.3   | Write-back de linha dirty na eviccao             | Sim      |
| 7.4   | Consistencia em sequencias leitura/escrita       | Sim      |
| 7.4   | Conflitos de indice e sobrevivencia de dados     | Sim      |
| 7.5   | Enderecos extremos                               | Sim      |
| 7.5   | Cache invalida apos reset                        | Sim      |
| 7.5   | Re-fill apos reset                               | Sim      |
