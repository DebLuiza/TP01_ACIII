module cache_controller (
    input  logic        clk,
    input  logic        reset,

    input  logic        cpu_read,
    input  logic        cpu_write,
    input  logic [7:0]  cpu_addr,
    input  logic [31:0] cpu_wdata,

    output logic [31:0] cpu_rdata,
    output logic        cpu_ready,
    output logic        cache_hit,

    output logic        mem_read,
    output logic        mem_write,
    output logic [7:0]  mem_addr,
    output logic [31:0] mem_wdata,
    input  logic [31:0] mem_rdata,
    input  logic        mem_ready
);

    localparam int ADDR_WIDTH  = 8;
    localparam int DATA_WIDTH  = 32;

    localparam int NUM_SETS    = 4;
    localparam int NUM_WAYS    = 2;

    localparam int OFFSET_BITS = 2;
    localparam int INDEX_BITS  = 2;
    localparam int TAG_BITS    = 4;

    // Endereço:
    // addr[7:4] = tag
    // addr[3:2] = índice
    // addr[1:0] = offset dentro da palavra

    typedef enum logic [2:0] {
        IDLE,
        COMPARE_TAG,
        WRITE_BACK,
        ALLOCATE,
        UPDATE_CACHE,
        RESPOND
    } state_t;

    state_t state, next_state;

    logic                  valid [NUM_SETS][NUM_WAYS];
    logic                  dirty [NUM_SETS][NUM_WAYS];
    logic [TAG_BITS-1:0]   tags  [NUM_SETS][NUM_WAYS];
    logic [DATA_WIDTH-1:0] data  [NUM_SETS][NUM_WAYS];

    // lru[set] indica a via menos recentemente usada.
    // 0 = Way 0 é vítima preferida
    // 1 = Way 1 é vítima preferida
    logic lru [NUM_SETS];

    // Registradores da requisição atual
    logic        actual_hit;
    logic        req_read;
    logic        req_write;
    logic [7:0]  req_addr;
    logic [31:0] req_wdata;

    logic [TAG_BITS-1:0]   req_tag;
    logic [INDEX_BITS-1:0] req_index;

    assign req_tag   = req_addr[7:4];
    assign req_index = req_addr[3:2];

    logic hit_way0;
    logic hit_way1;
    logic hit;
    logic hit_way;

    assign hit_way0 = valid[req_index][0] && (tags[req_index][0] == req_tag);
    assign hit_way1 = valid[req_index][1] && (tags[req_index][1] == req_tag);
    assign hit      = hit_way0 || hit_way1;
    assign hit_way  = hit_way1 ? 1'b1 : 1'b0;

    logic victim_way;

    always_comb begin
        if (!valid[req_index][0]) begin
            victim_way = 1'b0;
        end else if (!valid[req_index][1]) begin
            victim_way = 1'b1;
        end else begin
            victim_way = lru[req_index];
        end
    end

    // FSM - lógica combinacional

    always_comb begin
        next_state = state;

        cpu_ready = 1'b0;
        cache_hit = 1'b0;

        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_addr  = 8'b0;
        mem_wdata = 32'b0;

        case (state)

            IDLE: begin
                if (cpu_read || cpu_write) begin
                    next_state = COMPARE_TAG;
                end
            end

            COMPARE_TAG: begin
                if (hit) begin
                    next_state = RESPOND;
                end else begin
                    if (valid[req_index][victim_way] && dirty[req_index][victim_way]) begin
                        next_state = WRITE_BACK;
                    end else begin
                        next_state = ALLOCATE;
                    end
                end
            end

            WRITE_BACK: begin
                mem_write = 1'b1;
                mem_addr  = {tags[req_index][victim_way], req_index, 2'b00};
                mem_wdata = data[req_index][victim_way];

                if (mem_ready) begin
                    next_state = ALLOCATE;
                end
            end

            ALLOCATE: begin
                mem_read = 1'b1;
                mem_addr = {req_tag, req_index, 2'b00};

                if (mem_ready) begin
                    next_state = UPDATE_CACHE;
                end
            end
            
            UPDATE_CACHE: begin
                next_state = RESPOND;
            end

            RESPOND: begin
                cpu_ready = 1'b1;
                cache_hit = actual_hit;

                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end

    // FSM - lógica sequencial

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;

            cpu_rdata <= 32'b0;

            req_read  <= 1'b0;
            req_write <= 1'b0;
            req_addr  <= 8'b0;
            req_wdata <= 32'b0;

            actual_hit <= 1'b0;

            for (int i = 0; i < NUM_SETS; i++) begin
                lru[i] <= 1'b0;

                for (int j = 0; j < NUM_WAYS; j++) begin
                    valid[i][j] <= 1'b0;
                    dirty[i][j] <= 1'b0;
                    tags[i][j]  <= {TAG_BITS{1'b0}};
                    data[i][j]  <= {DATA_WIDTH{1'b0}};
                end
            end
        end else begin
            state <= next_state;

            case (state)

                IDLE: begin
                    if (cpu_read || cpu_write) begin
                        req_read  <= cpu_read;
                        req_write <= cpu_write;
                        req_addr  <= cpu_addr;
                        req_wdata <= cpu_wdata;
                    end
                end

                COMPARE_TAG: begin
                    actual_hit <= hit;

                    if (hit) begin
                        if (req_read) begin
                            cpu_rdata <= data[req_index][hit_way];
                        end

                        if (req_write) begin
                            data[req_index][hit_way]  <= req_wdata;
                            dirty[req_index][hit_way] <= 1'b1;
                            cpu_rdata <= req_wdata;
                        end

                        // Se usei Way 0, Way 1 vira menos recente.
                        // Se usei Way 1, Way 0 vira menos recente.
                        lru[req_index] <= ~hit_way;
                    end
                end

                WRITE_BACK: begin
                    // Sinais de escrita na memória são gerados na lógica combinacional.
                end

                ALLOCATE: begin
                    // A leitura da memória é solicitada no bloco combinacional.
                    // A atualização da cache ocorre apenas no estado UPDATE_CACHE,
                    // quando mem_rdata já está estável.
                end

                UPDATE_CACHE: begin
                    valid[req_index][victim_way] <= 1'b1;
                    tags[req_index][victim_way]  <= req_tag;

                    if (req_read) begin
                        data[req_index][victim_way]  <= mem_rdata;
                        dirty[req_index][victim_way] <= 1'b0;
                        cpu_rdata <= mem_rdata;
                    end

                    if (req_write) begin
                        // Write-allocate + write-back:
                        // o bloco foi buscado, mas o valor escrito pela CPU
                        // substitui a palavra carregada.
                        data[req_index][victim_way]  <= req_wdata;
                        dirty[req_index][victim_way] <= 1'b1;
                        cpu_rdata <= req_wdata;
                    end

                    // Atualiza LRU.
                    // A via usada deixa de ser a menos recentemente usada.
                    lru[req_index] <= ~victim_way;
                end

                RESPOND: begin
                    // cpu_ready e cache_hit são combinacionais neste estado.
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule