// =============================================================================
// Modulo: cache_top
// Descricao: Wrapper que integra cache_controller e main_memory em um unico
//            modulo top-level para simulacao.
// =============================================================================
module cache_top (
    input  logic        clk,
    input  logic        reset,
    input  logic        cpu_read,
    input  logic        cpu_write,
    input  logic [7:0]  cpu_addr,
    input  logic [31:0] cpu_wdata,
    output logic [31:0] cpu_rdata,
    output logic        cpu_ready,
    output logic        cache_hit
);

    // Sinais internos entre cache e memoria
    logic        mem_read;
    logic        mem_write;
    logic [7:0]  mem_addr;
    logic [31:0] mem_wdata;
    logic [31:0] mem_rdata;
    logic        mem_ready;

    cache_controller u_cache_controller (
        .clk(clk), .reset(reset),
        .cpu_read(cpu_read), .cpu_write(cpu_write),
        .cpu_addr(cpu_addr), .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata), .cpu_ready(cpu_ready),
        .cache_hit(cache_hit),
        .mem_read(mem_read), .mem_write(mem_write),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata), .mem_ready(mem_ready)
    );

    main_memory u_main_memory (
        .clk(clk), .reset(reset),
        .mem_read(mem_read), .mem_write(mem_write),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata), .mem_ready(mem_ready)
    );

endmodule
