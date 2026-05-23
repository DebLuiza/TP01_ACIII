# Controlador de Cache - Especificações do Trabalho

Este projeto implementará um **controlador de cache associativa por conjunto 2-way**.

## Parâmetros definidos

- **Endereço:** 8 bits
- **Endereçamento:** por byte
- **Tamanho da palavra:** 32 bits = 4 bytes
- **Número de conjuntos:** 4
- **Associatividade:** 2-way
- **Total de linhas:** 8 linhas
- **Tamanho do bloco:** 1 palavra de 32 bits
- **Política de escrita:** write-back
- **Política de miss de escrita:** write-allocate
- **Substituição:** LRU simples por conjunto
  - `lru[set] = 0` → Way 0 é o menos recentemente usado
  - `lru[set] = 1` → Way 1 é o menos recentemente usado

## Divisão do endereço

Como o endereço possui 8 bits e a palavra possui 32 bits, ou seja, 4 bytes, são necessários 2 bits de offset para selecionar um byte dentro da palavra.

A divisão do endereço é:

- `addr[7:4]` → tag, com 4 bits
- `addr[3:2]` → índice, com 2 bits
- `addr[1:0]` → offset, com 2 bits

Portanto:

- **Tag:** 4 bits
- **Índice:** 2 bits
- **Offset:** 2 bits

Como cada bloco da cache armazena uma palavra inteira de 32 bits, o offset não é usado para selecionar diferentes palavras dentro do bloco. Ele apenas representa o deslocamento em bytes dentro da palavra. Nos acessos à memória principal, o endereço é alinhado usando `2'b00` nos bits menos significativos.

## Organização da cache

- `4 conjuntos x 2 ways = 8 blocos` na cache
- Cada bloco guarda `1 palavra de 32 bits`
- Cada entrada da cache possui:
  - bit `valid`
  - bit `dirty`
  - campo `tag`
  - campo `data`

## Comportamento esperado

- Em uma leitura com hit, o dado é retornado diretamente da cache.
- Em uma leitura com miss, o dado é buscado na memória principal e carregado na cache.
- Em uma escrita com hit, os dados são atualizados na cache e a linha é marcada como dirty.
- Quando uma linha dirty for substituída, deve ocorrer escrita de volta para a memória principal.
- Em miss de escrita, o bloco deve ser carregado para a cache antes da atualização, seguindo a política write-allocate.
- Em cada conjunto, a escolha da vítima para substituição segue LRU simples entre as duas vias.