// =============================================================================
// Modulo: cache_controller
// Descricao: Controlador de cache 2-way set-associative com write-back e
//            write-allocate, politica de substituicao LRU.
//            Baseado na Secao 5.12 do livro Computer Organization and Design
//            (RISC-V Edition).
// Parametros: 4 sets, 2 ways, blocos de 1 palavra (32 bits), enderecos de 8 bits.
// =============================================================================
module cache_controller (
    input  logic        clk,
    input  logic        reset,

    // Interface CPU
    input  logic        cpu_read,
    input  logic        cpu_write,
    input  logic [7:0]  cpu_addr,
    input  logic [31:0] cpu_wdata,
    output logic [31:0] cpu_rdata,
    output logic        cpu_ready,
    output logic        cache_hit,

    // Interface Memoria Principal
    output logic        mem_read,
    output logic        mem_write,
    output logic [7:0]  mem_addr,
    output logic [31:0] mem_wdata,
    input  logic [31:0] mem_rdata,
    input  logic        mem_ready
);

    // -------------------------------------------------------------------------
    // Parametros da cache
    // -------------------------------------------------------------------------
    localparam int NUM_SETS   = 4;
    localparam int NUM_WAYS   = 2;
    localparam int DATA_WIDTH = 32;
    localparam int TAG_BITS   = 4;
    localparam int INDEX_BITS = 2;

    // -------------------------------------------------------------------------
    // Decomposicao do endereco (8 bits)
    //   [7:4] = tag    (4 bits)
    //   [3:2] = index  (2 bits)
    //   [1:0] = offset (nao usado - bloco de 1 palavra)
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // FSM - Estados
    // -------------------------------------------------------------------------
    typedef enum logic [2:0] {
        IDLE,
        COMPARE_TAG,
        WRITE_BACK_REQ,
        WRITE_BACK_WAIT,
        ALLOCATE_REQ,
        ALLOCATE_WAIT,
        UPDATE_CACHE,
        RESPOND
    } state_t;

    state_t state, next_state;

    // -------------------------------------------------------------------------
    // Arrays da cache
    // -------------------------------------------------------------------------
    logic                    valid [NUM_SETS][NUM_WAYS];
    logic                    dirty [NUM_SETS][NUM_WAYS];
    logic [TAG_BITS-1:0]     tags  [NUM_SETS][NUM_WAYS];
    logic [DATA_WIDTH-1:0]   data  [NUM_SETS][NUM_WAYS];

    // -------------------------------------------------------------------------
    // LRU - bit por set (0 = way0 e vitima, 1 = way1 e vitima)
    // -------------------------------------------------------------------------
    logic lru [NUM_SETS];

    // -------------------------------------------------------------------------
    // Registradores de requisicao latched
    // -------------------------------------------------------------------------
    logic        actual_hit;
    logic        req_read;
    logic        req_write;
    logic [7:0]  req_addr;
    logic [31:0] req_wdata;

    // Campos extraidos do endereco da requisicao
    logic [TAG_BITS-1:0]   req_tag;
    logic [INDEX_BITS-1:0] req_index;

    assign req_tag   = req_addr[7:4];
    assign req_index = req_addr[3:2];

    // -------------------------------------------------------------------------
    // Logica de hit
    // -------------------------------------------------------------------------
    logic hit_way0, hit_way1;
    logic hit;
    logic hit_way;

    assign hit_way0 = valid[req_index][0] && (tags[req_index][0] == req_tag);
    assign hit_way1 = valid[req_index][1] && (tags[req_index][1] == req_tag);
    assign hit      = hit_way0 || hit_way1;
    assign hit_way  = hit_way1 ? 1'b1 : 1'b0;

    // -------------------------------------------------------------------------
    // Selecao de vitima (LRU / primeira via invalida)
    // -------------------------------------------------------------------------
    logic victim_way;
    logic req_victim_way;

    always_comb begin
        if (!valid[req_index][0])
            victim_way = 1'b0;
        else if (!valid[req_index][1])
            victim_way = 1'b1;
        else
            victim_way = lru[req_index];
    end

    // -------------------------------------------------------------------------
    // FSM - Logica combinacional (next_state + saidas)
    // -------------------------------------------------------------------------
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
                if (cpu_read || cpu_write)
                    next_state = COMPARE_TAG;
            end

            COMPARE_TAG: begin
                if (hit)
                    next_state = RESPOND;
                else if (valid[req_index][victim_way] && dirty[req_index][victim_way])
                    next_state = WRITE_BACK_REQ;
                else
                    next_state = ALLOCATE_REQ;
            end

            WRITE_BACK_REQ: begin
                mem_write = 1'b1;
                mem_addr  = {tags[req_index][req_victim_way], req_index, 2'b00};
                mem_wdata = data[req_index][req_victim_way];
                next_state = WRITE_BACK_WAIT;
            end

            WRITE_BACK_WAIT: begin
                if (mem_ready)
                    next_state = ALLOCATE_REQ;
            end

            ALLOCATE_REQ: begin
                mem_read = 1'b1;
                mem_addr = {req_tag, req_index, 2'b00};
                next_state = ALLOCATE_WAIT;
            end

            ALLOCATE_WAIT: begin
                mem_read = 1'b1;
                mem_addr = {req_tag, req_index, 2'b00};
                if (mem_ready)
                    next_state = UPDATE_CACHE;
            end

            UPDATE_CACHE: begin
                next_state = RESPOND;
            end

            RESPOND: begin
                cpu_ready = 1'b1;
                cache_hit = actual_hit;
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // -------------------------------------------------------------------------
    // FSM - Logica sequencial (registradores e atualizacao de arrays)
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state          <= IDLE;
            cpu_rdata      <= 32'b0;
            req_read       <= 1'b0;
            req_write      <= 1'b0;
            req_addr       <= 8'b0;
            req_wdata      <= 32'b0;
            req_victim_way <= 1'b0;
            actual_hit     <= 1'b0;

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
                        // Leitura com hit: retorna dado da cache
                        if (req_read)
                            cpu_rdata <= data[req_index][hit_way];

                        // Escrita com hit: atualiza cache e marca dirty
                        if (req_write) begin
                            data[req_index][hit_way]  <= req_wdata;
                            dirty[req_index][hit_way] <= 1'b1;
                            cpu_rdata <= req_wdata;
                        end

                        // Atualiza LRU: via acessada vira MRU
                        lru[req_index] <= ~hit_way;
                    end else begin
                        // Miss: salva via vitima para uso nos estados seguintes
                        req_victim_way <= victim_way;
                    end
                end

                UPDATE_CACHE: begin
                    // Atualiza linha da cache com dado da memoria
                    valid[req_index][req_victim_way] <= 1'b1;
                    tags[req_index][req_victim_way]  <= req_tag;

                    if (req_read) begin
                        data[req_index][req_victim_way]  <= mem_rdata;
                        dirty[req_index][req_victim_way] <= 1'b0;
                        cpu_rdata <= mem_rdata;
                    end

                    if (req_write) begin
                        data[req_index][req_victim_way]  <= req_wdata;
                        dirty[req_index][req_victim_way] <= 1'b1;
                        cpu_rdata <= req_wdata;
                    end

                    // Nova linha alocada vira MRU
                    lru[req_index] <= ~req_victim_way;
                end

                default: ;
            endcase
        end
    end

endmodule
