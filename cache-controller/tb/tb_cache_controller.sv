`timescale 1ns/1ps

module tb_cache_controller();

    // Declaracao de sinais
    logic        clk;
    logic        reset;

    // Sinais da CPU -> cache
    logic        cpu_read;
    logic        cpu_write;
    logic [7:0]  cpu_addr;
    logic [31:0] cpu_wdata;
    logic [31:0] cpu_rdata;
    logic        cpu_ready;
    logic        cache_hit;

    // Instanciacao do modulo de topo (cache + memoria)
    cache_top uut_top (
        .clk(clk),
        .reset(reset),
        .cpu_read(cpu_read),
        .cpu_write(cpu_write),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .cpu_ready(cpu_ready),
        .cache_hit(cache_hit)
    );

    // Clock de 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task do_read(input logic [7:0] addr);
        begin
            wait (cpu_ready == 1'b0);
            @(negedge clk);
            cpu_read  = 1'b1;
            cpu_write = 1'b0;
            cpu_addr  = addr;

            wait (cpu_ready == 1'b1);

            $display("[%0t] READ  | Addr: 8'h%0h | Data: 32'h%0h | Hit: %b",
                    $time, addr, cpu_rdata, cache_hit);

            @(negedge clk);
            cpu_read = 1'b0;
            #10;
        end
    endtask

    task do_write(input logic [7:0] addr, input logic [31:0] data);
        begin
            wait (cpu_ready == 1'b0);
            @(negedge clk);
            cpu_read  = 1'b0;
            cpu_write = 1'b1;
            cpu_addr  = addr;
            cpu_wdata = data;

            wait (cpu_ready == 1'b1);
            cpu_write = 1'b0;
            @(posedge clk);
            $display("[%0t] WRITE | Addr: 8'h%0h | Data: 32'h%0h | Hit: %b", $time, addr, data, cache_hit);
            #10;
        end
    endtask

    initial begin
        $dumpfile("sim/wave.vcd");

        // Dumpa o testbench inteiro
        $dumpvars(0, tb_cache_controller);

        // Dumpa explicitamente o módulo top e os módulos internos
        $dumpvars(0, uut_top);
        $dumpvars(0, uut_top.u_cache_controller);
        $dumpvars(0, uut_top.u_main_memory);

        cpu_read  = 0;
        cpu_write = 0;
        cpu_addr  = 0;
        cpu_wdata = 0;

        $display("---------------------------------------------------");
        $display("Iniciando Simulacao - Resetando o Sistema...");
        reset = 1;
        #20;
        reset = 0;
        #20;

        $display("\n--- TESTE 1: Miss de Leitura (Alocando na Cache) ---");
        do_read(8'h10);

        $display("\n--- TESTE 2: Hit de Leitura ---");
        do_read(8'h10);

        $display("\n--- TESTE 3: Hit de Escrita (Write-Back) ---");
        do_write(8'h10, 32'hDEADBEEF);

        $display("\n--- TESTE 4: Leitura para confirmar a Escrita ---");
        do_read(8'h10);

        $display("\n--- TESTE 5: Miss de Escrita (Write-Allocate) ---");
        do_write(8'h24, 32'hCAFEBABE);

        $display("\n--- TESTE 6: Leitura para confirmar Write-Allocate ---");
        do_read(8'h24);

        $display("\n--- TESTE 7: Conflito de Indice - Preenchendo Set 2 ---");
        do_read(8'h08);
        do_read(8'h18);

        $display("\n--- TESTE 8: Atualizando LRU ---");
        do_read(8'h08);

        $display("\n--- TESTE 9: Substituicao LRU no Set 2 ---");
        do_read(8'h28);

        $display("\n--- TESTE 10: Confirmando substituicao LRU ---");
        do_read(8'h08);
        do_read(8'h18);

        $display("\n--- TESTE 11: Write-Back de bloco Dirty ---");
        do_write(8'h0C, 32'h11111111);
        do_read (8'h1C);
        do_read (8'h1C);
        do_read (8'h2C);

        $display("\n--- TESTE 12: Verificando se Write-Back atualizou memoria ---");
        do_read(8'h0C);

        $finish;
    end

endmodule
