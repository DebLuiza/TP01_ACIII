module main_memory (
    input  logic        clk,
    input  logic        reset,

    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [7:0]  mem_addr,
    input  logic [31:0] mem_wdata,

    output logic [31:0] mem_rdata,
    output logic        mem_ready
);

    // Parâmetros da memória

    localparam int MEM_DEPTH = 64; // 64 palavras de 32 bits = 256 bytes
    localparam int LATENCY   = 4;  // latência simulada da memória

    // Array de memória

    logic [31:0] memory_array [0:MEM_DEPTH-1];

    // Registradores internos

    logic [3:0] delay_counter;
    logic       is_processing;

    logic        saved_read;
    logic        saved_write;
    logic [7:0]  saved_addr;
    logic [31:0] saved_wdata;

    logic [5:0] saved_word_index;

    assign saved_word_index = saved_addr[7:2];

    // Comportamento da memória

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_ready     <= 1'b0;
            mem_rdata     <= 32'b0;
            delay_counter <= 4'b0;
            is_processing <= 1'b0;

            saved_read  <= 1'b0;
            saved_write <= 1'b0;
            saved_addr  <= 8'b0;
            saved_wdata <= 32'b0;

            for (int i = 0; i < MEM_DEPTH; i++) begin
                memory_array[i] <= 32'h1000 + i;
            end

        end else begin
            // ready é um pulso de um ciclo
            mem_ready <= 1'b0;

            if (!is_processing) begin
                if (mem_read || mem_write) begin
                    is_processing <= 1'b1;

                    saved_read  <= mem_read;
                    saved_write <= mem_write;
                    saved_addr  <= mem_addr;
                    saved_wdata <= mem_wdata;

                    delay_counter <= LATENCY - 1;
                end
            end else begin
                if (delay_counter > 0) begin
                    delay_counter <= delay_counter - 1;
                end else begin
                    if (saved_read) begin
                        mem_rdata <= memory_array[saved_word_index];
                    end

                    if (saved_write) begin
                        memory_array[saved_word_index] <= saved_wdata;
                    end

                    mem_ready     <= 1'b1;
                    is_processing <= 1'b0;

                    saved_read  <= 1'b0;
                    saved_write <= 1'b0;
                end
            end
        end
    end

endmodule