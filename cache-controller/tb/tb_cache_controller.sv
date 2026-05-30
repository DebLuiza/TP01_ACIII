`timescale 1ns/1ps

module tb_cache_controller();

    // ---------------------------------------------------------------
    // Sinais
    // ---------------------------------------------------------------
    logic        clk, reset;
    logic        cpu_read, cpu_write;
    logic [7:0]  cpu_addr;
    logic [31:0] cpu_wdata, cpu_rdata;
    logic        cpu_ready, cache_hit;

    // ---------------------------------------------------------------
    // Contadores de teste
    // ---------------------------------------------------------------
    int pass_count = 0;
    int fail_count = 0;
    int test_num   = 0;

    // ---------------------------------------------------------------
    // DUT
    // ---------------------------------------------------------------
    cache_top uut (
        .clk(clk), .reset(reset),
        .cpu_read(cpu_read), .cpu_write(cpu_write),
        .cpu_addr(cpu_addr), .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata), .cpu_ready(cpu_ready),
        .cache_hit(cache_hit)
    );

    // ---------------------------------------------------------------
    // Clock 10 ns
    // ---------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------------
    // Sinais capturados no momento do cpu_ready
    // ---------------------------------------------------------------
    logic        last_hit;
    logic [31:0] last_rdata;

    // ---------------------------------------------------------------
    // Tasks auxiliares
    // ---------------------------------------------------------------
    task do_read(input logic [7:0] addr);
        @(negedge clk);
        cpu_read  = 1'b1;
        cpu_write = 1'b0;
        cpu_addr  = addr;
        @(posedge clk);  // lança a requisição
        @(negedge clk);
        cpu_read = 1'b0; // desativa após 1 ciclo
        wait (cpu_ready == 1'b1);
        // Captura no mesmo ciclo em que cpu_ready está ativo
        last_hit   = cache_hit;
        last_rdata = cpu_rdata;
        @(negedge clk);
        #10;
    endtask

    task do_write(input logic [7:0] addr, input logic [31:0] wdata);
        @(negedge clk);
        cpu_read  = 1'b0;
        cpu_write = 1'b1;
        cpu_addr  = addr;
        cpu_wdata = wdata;
        @(posedge clk);
        @(negedge clk);
        cpu_write = 1'b0;
        wait (cpu_ready == 1'b1);
        last_hit   = cache_hit;
        last_rdata = cpu_rdata;
        @(negedge clk);
        #10;
    endtask

    task check(input string category, input string desc,
               input logic exp_hit, input logic [31:0] exp_data);
        test_num++;
        if (last_hit !== exp_hit || last_rdata !== exp_data) begin
            $display("[FAIL] %s | T%0d: %s | hit=%b (exp %b) data=0x%08h (exp 0x%08h)",
                     category, test_num, desc, last_hit, exp_hit, last_rdata, exp_data);
            fail_count++;
        end else begin
            $display("[PASS] %s | T%0d: %s | hit=%b data=0x%08h",
                     category, test_num, desc, last_hit, last_rdata);
            pass_count++;
        end
    endtask

    task check_hit_only(input string category, input string desc,
                        input logic exp_hit);
        test_num++;
        if (last_hit !== exp_hit) begin
            $display("[FAIL] %s | T%0d: %s | hit=%b (exp %b)",
                     category, test_num, desc, last_hit, exp_hit);
            fail_count++;
        end else begin
            $display("[PASS] %s | T%0d: %s | hit=%b",
                     category, test_num, desc, last_hit);
            pass_count++;
        end
    endtask

    // ---------------------------------------------------------------
    // Cenarios de teste
    // ---------------------------------------------------------------
    initial begin
        $dumpfile("sim/wave.vcd");
        $dumpvars(0, tb_cache_controller);

        cpu_read = 0; cpu_write = 0; cpu_addr = 0; cpu_wdata = 0;

        // Reset
        reset = 1; #20; reset = 0; #20;

        $display("===========================================================");
        $display(" TESTBENCH - Controlador de Cache 2-way Set-Associative");
        $display("===========================================================");

        // ===========================================================
        // 7.1 - TESTES DE LEITURA (Read Path)
        // ===========================================================
        $display("\n--- [READ] 7.1 Testes de Leitura ---");

        // T1: Read miss - addr 0x10 -> set 0, tag 1 -> mem[4] = 0x1004
        do_read(8'h10);
        check("READ", "Read miss cold (addr 0x10)", 1'b0, 32'h1004);

        // T2: Read hit - mesmo endereco
        do_read(8'h10);
        check("READ", "Read hit (addr 0x10 novamente)", 1'b1, 32'h1004);

        // T3: Read miss - addr 0x20 -> set 0, tag 2 -> mem[8] = 0x1008
        do_read(8'h20);
        check("READ", "Read miss second way (addr 0x20)", 1'b0, 32'h1008);

        // T4: Read hit - addr 0x20 still cached
        do_read(8'h20);
        check("READ", "Read hit second way (addr 0x20)", 1'b1, 32'h1008);

        // T5: Verifica valid e tag atualizados - read hit addr 0x10
        do_read(8'h10);
        check("READ", "Read hit first way still valid (addr 0x10)", 1'b1, 32'h1004);

        // ===========================================================
        // 7.2 - TESTES DE ESCRITA (Write Path)
        // ===========================================================
        $display("\n--- [WRITE] 7.2 Testes de Escrita ---");

        // T6: Write hit - addr 0x10 esta no cache
        do_write(8'h10, 32'hAAAA_0001);
        check("WRITE", "Write hit (addr 0x10)", 1'b1, 32'hAAAA_0001);

        // T7: Read-back confirma escrita (dirty, write-back)
        do_read(8'h10);
        check("WRITE", "Read-back confirma write hit (addr 0x10)", 1'b1, 32'hAAAA_0001);

        // T8: Write miss com write-allocate - addr 0x30 -> set 0, tag 3
        // Set 0 cheio (tag1 dirty, tag2 clean) -> LRU evict tag2 (clean)
        do_write(8'h30, 32'hBBBB_0002);
        check("WRITE", "Write miss write-allocate (addr 0x30)", 1'b0, 32'hBBBB_0002);

        // T9: Read-back confirma write-allocate
        do_read(8'h30);
        check("WRITE", "Read-back confirma write-allocate (addr 0x30)", 1'b1, 32'hBBBB_0002);

        // T10: Valida dirty bit - write em 0x30 e fazer evict forçado depois
        do_write(8'h30, 32'hCCCC_0003);
        check("WRITE", "Write hit dirty update (addr 0x30)", 1'b1, 32'hCCCC_0003);

        // ===========================================================
        // 7.3 - TESTES DE SUBSTITUICAO (Replacement)
        // ===========================================================
        $display("\n--- [REPLACE] 7.3 Testes de Substituicao ---");

        // Usar Set 1 (index bits [3:2] = 01 -> addr[3:2]=01 -> addr 0x04,0x14,0x24...)
        // T11: Fill way 0 set 1
        do_read(8'h04);
        check("REPLACE", "Fill set1 way0 (addr 0x04)", 1'b0, 32'h1001);

        // T12: Fill way 1 set 1
        do_read(8'h14);
        check("REPLACE", "Fill set1 way1 (addr 0x14)", 1'b0, 32'h1005);

        // T13: Access 0x04 to make it MRU (LRU = way1)
        do_read(8'h04);
        check("REPLACE", "Touch set1 way0 MRU (addr 0x04)", 1'b1, 32'h1001);

        // T14: New tag evicts LRU (way1 = addr 0x14)
        do_read(8'h24);
        check("REPLACE", "Evict LRU way1 (addr 0x24)", 1'b0, 32'h1009);

        // T15: Confirm evicted - 0x14 deve dar miss
        do_read(8'h14);
        check_hit_only("REPLACE", "Confirm 0x14 evicted (miss)", 1'b0);

        // T16: Write-back dirty evict - escrever em set2, encher, forcar evict dirty
        do_write(8'h08, 32'hDEAD_0001);
        check("REPLACE", "Write set2 way0 dirty (addr 0x08)", 1'b0, 32'hDEAD_0001);

        do_read(8'h18);
        check("REPLACE", "Fill set2 way1 (addr 0x18)", 1'b0, 32'h1006);

        // Tocar 0x18 para LRU = way0
        do_read(8'h18);
        check("REPLACE", "Touch 0x18 MRU", 1'b1, 32'h1006);

        // Evict 0x08 (dirty) -> deve write-back para memoria
        do_read(8'h28);
        check("REPLACE", "Evict dirty 0x08 write-back (addr 0x28)", 1'b0, 32'h100a);

        // T17: Confirma write-back lendo 0x08 da memoria (deve ter 0xDEAD_0001)
        do_read(8'h08);
        check("REPLACE", "Confirm write-back 0x08 from mem", 1'b0, 32'hDEAD_0001);

        // ===========================================================
        // 7.4 - TESTES DE CONSISTENCIA
        // ===========================================================
        $display("\n--- [CONSIST] 7.4 Testes de Consistencia ---");

        // T18: Sequencia write-read-write-read mesmo endereco
        do_write(8'h44, 32'h1111_1111);
        check("CONSIST", "Write addr 0x44", 1'b0, 32'h1111_1111);

        do_read(8'h44);
        check("CONSIST", "Read-back addr 0x44", 1'b1, 32'h1111_1111);

        do_write(8'h44, 32'h2222_2222);
        check("CONSIST", "Overwrite addr 0x44", 1'b1, 32'h2222_2222);

        do_read(8'h44);
        check("CONSIST", "Read-back overwrite 0x44", 1'b1, 32'h2222_2222);

        // T19: Acessos conflitantes no mesmo indice (set 3)
        // addr com index=11: 0x0C, 0x1C, 0x2C, 0x3C
        do_write(8'h0C, 32'hAAAA_AAAA);
        check_hit_only("CONSIST", "Write set3 tag0 (0x0C)", 1'b0);

        do_write(8'h1C, 32'hBBBB_BBBB);
        check_hit_only("CONSIST", "Write set3 tag1 (0x1C)", 1'b0);

        // Ambos em cache
        do_read(8'h0C);
        check("CONSIST", "Read set3 tag0 (0x0C)", 1'b1, 32'hAAAA_AAAA);

        do_read(8'h1C);
        check("CONSIST", "Read set3 tag1 (0x1C)", 1'b1, 32'hBBBB_BBBB);

        // Conflito: 3o tag evicta LRU
        do_write(8'h2C, 32'hCCCC_CCCC);
        check_hit_only("CONSIST", "Write set3 tag2 evicts LRU (0x2C)", 1'b0);

        // Leitura do sobrevivente
        do_read(8'h1C);
        check("CONSIST", "Read surviving tag1 (0x1C)", 1'b1, 32'hBBBB_BBBB);

        // ===========================================================
        // 7.5 - TESTES DE CASOS LIMITE (Edge Cases)
        // ===========================================================
        $display("\n--- [EDGE] 7.5 Testes de Casos Limite ---");

        // T20: Endereco 0x00 (extremo inferior)
        do_read(8'h00);
        check("EDGE", "Read addr 0x00 (min)", 1'b0, 32'h1000);

        // T21: Endereco 0xFC (extremo superior) -> mem[63]
        do_read(8'hFC);
        check("EDGE", "Read addr 0xFC (max)", 1'b0, 32'h103f);

        // T22: Re-read addr 0xFC hit
        do_read(8'hFC);
        check("EDGE", "Read hit addr 0xFC", 1'b1, 32'h103f);

        // T23: Cache vazia apos reset - testar novo reset
        reset = 1; #20; reset = 0; #20;
        do_read(8'h10);
        check("EDGE", "Read miss after reset (cache invalidated)", 1'b0, 32'h1004);

        // Segundo acesso confirma que voltou ao normal
        do_read(8'h10);
        check("EDGE", "Read hit after re-fill post-reset", 1'b1, 32'h1004);

        // ===========================================================
        // Resumo
        // ===========================================================
        $display("\n===========================================================");
        $display(" RESULTADO FINAL: %0d PASS / %0d FAIL de %0d testes",
                 pass_count, fail_count, test_num);
        if (fail_count == 0)
            $display(" >>> TODOS OS TESTES PASSARAM <<<");
        else
            $display(" >>> EXISTEM FALHAS - VERIFICAR LOG <<<");
        $display("===========================================================");

        $finish;
    end

endmodule
