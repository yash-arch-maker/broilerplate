module pairwise_lru #(
    parameter int WAYS = 4
) (
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    access_valid,
    input  logic [$clog2(WAYS)-1:0] access_way,

    output logic [$clog2(WAYS)-1:0] victim_way
);

    localparam int WAY_W   = $clog2(WAYS);
    localparam int LRU_BITS = (WAYS * (WAYS - 1)) / 2;

    logic [LRU_BITS-1:0] lru;

    logic [WAYS-1:0] lru_onehot;

    integer idx;

    // ------------------------------------------------------------
    // Pairwise LRU update
    //
    // lru bit = 1:
    //     first way in the pair is older than second way
    //
    // Stored pairs:
    // (0,1), (0,2), ... (0,W-1),
    // (1,2), (1,3), ...,
    // ...
    // (W-2,W-1)
    // ------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lru <= '0;
        end
        else if (access_valid) begin

            idx = 0;

            for (int i = 0; i < WAYS; i++) begin
                for (int j = i + 1; j < WAYS; j++) begin

                    if (access_way == i)
                        lru[idx] <= 1'b0;

                    else if (access_way == j)
                        lru[idx] <= 1'b1;

                    idx = idx + 1;
                end
            end
        end
    end

    // ------------------------------------------------------------
    // Determine which way is older than EVERY other way.
    // That way is the LRU victim.
    // ------------------------------------------------------------

    always_comb begin

        lru_onehot = '0;

        for (int i = 0; i < WAYS; i++) begin

            logic is_lru;

            is_lru = 1'b1;
            idx = 0;

            for (int j = 0; j < WAYS; j++) begin

                if (i != j) begin

                    if (i < j) begin
                        // Pair is (i,j)
                        // 1 => i is older than j
                        if (!lru[idx])
                            is_lru = 1'b0;
                    end
                    else begin
                        // Pair is (j,i)
                        // 1 => j is older than i
                        if (lru[idx])
                            is_lru = 1'b0;
                    end
                }

                if (j > i)
                    idx = idx + 1;
            end

            lru_onehot[i] = is_lru;
        end
    end

    // ------------------------------------------------------------
    // One-hot -> binary victim way
    // ------------------------------------------------------------

    always_comb begin

        victim_way = '0;

        for (int i = 0; i < WAYS; i++) begin
            if (lru_onehot[i])
                victim_way = WAY_W'(i);
        end

    end

endmodule
