module plru #(
    parameter int WAYS = 4
) (
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic                    access_valid,
    input  logic [$clog2(WAYS)-1:0] access_way,

    output logic [$clog2(WAYS)-1:0] victim_way
);

    localparam int WAY_W = $clog2(WAYS);
    localparam int PLRU_BITS = WAYS - 1;

    // ----------------------------------------------------------------
    // PLRU tree
    //
    // bit = 0 : left subtree is LRU
    // bit = 1 : right subtree is LRU
    //
    // For 4 ways:
    //
    //                  [0]
    //                 /   \
    //               [1]   [2]
    //              /  \   /  \
    //             W0  W1 W2  W3
    // ----------------------------------------------------------------

    logic [PLRU_BITS-1:0] plru_bits;

    integer node;

    // ----------------------------------------------------------------
    // Update PLRU state on every cache access
    // ----------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            plru_bits <= '0;
        end
        else if (access_valid) begin

            node = 0;

            for (int level = 0; level < WAY_W; level++) begin

                // If accessed way goes LEFT (0),
                // mark RIGHT as LRU.
                //
                // If accessed way goes RIGHT (1),
                // mark LEFT as LRU.
                plru_bits[node] <= ~access_way[WAY_W-1-level];

                // Move to the child containing access_way.
                if (access_way[WAY_W-1-level] == 1'b0)
                    node = 2 * node + 1;
                else
                    node = 2 * node + 2;

            end
        end
    end

    // ----------------------------------------------------------------
    // Victim selection
    //
    // Follow the tree in the direction indicated by each PLRU bit.
    // ----------------------------------------------------------------

    always_comb begin

        victim_way = '0;
        node = 0;

        for (int level = 0; level < WAY_W; level++) begin

            if (plru_bits[node] == 1'b0) begin
                // Left subtree is LRU
                victim_way[WAY_W-1-level] = 1'b0;
                node = 2 * node + 1;
            end
            else begin
                // Right subtree is LRU
                victim_way[WAY_W-1-level] = 1'b1;
                node = 2 * node + 2;
            end

        end
    end

endmodule
