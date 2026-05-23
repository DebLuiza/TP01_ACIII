`timescale 1ns/1ps

module tb_cache_controller();

    // Declaração de Sinais
    logic        clk;
    logic        reset;

    // Sinais da CPU -> Cache
    logic        cpu_read;
    logic        cpu_write;
    logic [7:0]  cpu_addr;
    logic [31:0] cpu_wdata;
    logic [31:0] cpu_rdata;
    logic        cpu_ready;
    logic        cache_hit;

    // Sinais da Cache -> Memória Principal
    logic        mem_read;
    logic        mem_write;
    logic [7:0]  mem_addr;
    logic [31:0] mem_wdata;
    logic [31:0] mem_rdata;
    logic        mem_ready;

    // Instanciação dos Módulos (UUT - Unit Under Test)
    cache_controller uut_cache (
        .clk(clk),
        .reset(reset),
        .cpu_read(cpu_read),
        .cpu_write(cpu_write),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .cpu_ready(cpu_ready),
        .cache_hit(cache_hit),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );

    main_memory uut_memory (
        .clk(clk),
        .reset(reset),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );

    // Geração de Clock (Período de 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Tasks para simular as operações da CPU
    
    // Task de Leitura da CPU
    task do_read(input logic [7:0] addr);
        begin
            // Garante inicio de uma nova transacao apenas com ready em 0.
            wait (cpu_ready == 1'b0);
            @(negedge clk);
            cpu_read  = 1'b1;
            cpu_write = 1'b0;
            cpu_addr  = addr;
            
            // Aguarda o controlador sinalizar que o dado está pronto
            wait (cpu_ready == 1'b1);
            cpu_read = 1'b0; // Desce a requisicao imediatamente para evitar duplicacao
            @(posedge clk); // Desce o sinal da requisição
            $display("[%0t] READ  | Addr: 8'h%0h | Data: 32'h%0h | Hit: %b", $time, addr, cpu_rdata, cache_hit);
            #10; // Pausa entre operações
        end
    endtask

    // Task de Escrita da CPU
    task do_write(input logic [7:0] addr, input logic [31:0] data);
        begin
            // Garante inicio de uma nova transacao apenas com ready em 0.
            wait (cpu_ready == 1'b0);
            @(negedge clk);
            cpu_read  = 1'b0;
            cpu_write = 1'b1;
            cpu_addr  = addr;
            cpu_wdata = data;
            
            // Aguarda o controlador sinalizar que a escrita foi concluída
            wait (cpu_ready == 1'b1);
            cpu_write = 1'b0; // Desce a requisicao imediatamente para evitar duplicacao
            @(posedge clk);
            $display("[%0t] WRITE | Addr: 8'h%0h | Data: 32'h%0h | Hit: %b", $time, addr, data, cache_hit);
            #10;
        end
    endtask

    // Cenários de Teste (Estímulos)
    initial begin
        $dumpfile("sim/wave.vcd");
        $dumpvars(0, tb_cache_controller);
        // Inicialização de Sinais
        cpu_read  = 0;
        cpu_write = 0;
        cpu_addr  = 0;
        cpu_wdata = 0;

        // Reset do Sistema
        $display("---------------------------------------------------");
        $display("Iniciando Simulacao - Resetando o Sistema...");
        reset = 1;
        #20;
        reset = 0;
        #20;

        // 7.1 Testes de Leitura (Read Path)

        $display("\n--- TESTE 1: Miss de Leitura (Alocando na Cache) ---");
        // Endereço 8'h10 (Tag: 1, Index: 0, Offset: 0)
        // Como a memória foi inicializada com 32'h1000 + i, e o word_index de 8'h10 é 4, 
        // o valor retornado deve ser 32'h1004. O Hit deve ser 0.
        do_read(8'h10);

        $display("\n--- TESTE 2: Hit de Leitura ---");
        // Lendo o mesmo endereço logo em seguida. Não deve ter delay de memória.
        // O valor deve ser 32'h1004. O Hit deve ser 1.
        do_read(8'h10);

        // 7.2 Testes de Escrita (Write Path)
        $display("\n--- TESTE 3: Hit de Escrita (Write-Back) ---");
        // Vamos alterar o valor do endereço 8'h10. Como ele já está na cache, 
        // deve ser um Hit = 1 e a linha deve ser marcada como dirty.
        do_write(8'h10, 32'hDEADBEEF);

        $display("\n--- TESTE 4: Leitura para confirmar a Escrita ---");
        // Lendo novamente para garantir que a cache entrega o valor modificado.
        // O valor retornado deve ser 32'hDEADBEEF.
        do_read(8'h10);

        $display("\n--- TESTE 5: Miss de Escrita (Write-Allocate) ---");
        // Escrevendo em um endereço que não está na cache: 8'h24 (Index 1)
        // Ele deve buscar o bloco na memória, gravar na cache, alterar o dado para CAFEBABE,
        // marcar como dirty e responder. Hit = 0.
        do_write(8'h24, 32'hCAFEBABE);

        $display("\n--- TESTE 6: Leitura para confirmar Write-Allocate ---");
        // O valor retornado deve ser 32'hCAFEBABE e Hit = 1.
        do_read(8'h24);


        $display("\n--- TESTE 7: Conflito de Indice - Preenchendo Set 2 ---");
        do_read(8'h08); // Miss
        do_read(8'h18); // Miss

        $display("\n--- TESTE 8: Atualizando LRU ---");
        do_read(8'h08); // Hit, agora 0x18 vira o menos recentemente usado

        $display("\n--- TESTE 9: Substituicao LRU no Set 2 ---");
        do_read(8'h28); // Miss, deve substituir 0x18

        $display("\n--- TESTE 10: Confirmando substituicao LRU ---");
        do_read(8'h08); // Esperado: hit, pois 0x08 foi usado recentemente
        do_read(8'h18); // Esperado: miss, pois 0x18 deve ter sido substituído

        $display("\n--- TESTE 11: Write-Back de bloco Dirty ---");

        // 0x0C, 0x1C e 0x2C mapeiam para o set 3.
        do_write(8'h0C, 32'h11111111); // Miss, aloca e marca dirty
        do_read (8'h1C);               // Miss, ocupa a outra via

        // Acessa 0x1C para tornar 0x0C o menos recentemente usado.
        do_read (8'h1C);               // Hit

        // Agora 0x2C força substituicao.
        // Como 0x0C esta dirty, deve ocorrer write-back para memoria.
        do_read (8'h2C);               // Miss, substitui 0x0C com write-back

        $display("\n--- TESTE 12: Verificando se Write-Back atualizou memoria ---");

        // Se o write-back funcionou, ao buscar 0x0C novamente,
        // o valor deve ser 0x11111111, e nao o valor original da memoria.
        do_read(8'h0C); // Esperado: miss com dado 0x11111111
        $finish;
       
    end

endmodule

