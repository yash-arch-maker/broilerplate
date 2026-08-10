module lru_4way (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       access_valid,
    input  logic [1:0] access_way,

    output logic [1:0] victim_way
);

    // 1 means first way is older than second way.
    //
    // [0] : W0 older than W1
    // [1] : W0 older than W2
    // [2] : W0 older than W3
    // [3] : W1 older than W2
    // [4] : W1 older than W3
    // [5] : W2 older than W3

    logic [5:0] lru;

    logic lru0, lru1, lru2, lru3;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lru <= 6'b111110;
        end
        else if (access_valid) begin
            case (access_way)

                2'd0: begin
                    lru[0] <= 1'b0;
                    lru[1] <= 1'b0;
                    lru[2] <= 1'b0;
                end

                2'd1: begin
                    lru[0] <= 1'b1;
                    lru[3] <= 1'b0;
                    lru[4] <= 1'b0;
                end

                2'd2: begin
                    lru[1] <= 1'b1;
                    lru[3] <= 1'b1;
                    lru[5] <= 1'b0;
                end

                2'd3: begin
                    lru[2] <= 1'b1;
                    lru[4] <= 1'b1;
                    lru[5] <= 1'b1;
                end

            endcase
        end
    end

    // A way is LRU if it is older than every other way.

    assign lru0 =  lru[0] &
                   lru[1] &
                   lru[2];

    assign lru1 = ~lru[0] &
                   lru[3] &
                   lru[4];

    assign lru2 = ~lru[1] &
                  ~lru[3] &
                   lru[5];

    assign lru3 = ~lru[2] &
                  ~lru[4] &
                  ~lru[5];

    always_comb begin
        case ({lru3, lru2, lru1, lru0})
            4'b0001: victim_way = 2'd0;
            4'b0010: victim_way = 2'd1;
            4'b0100: victim_way = 2'd2;
            4'b1000: victim_way = 2'd3;
            default: victim_way = 2'd0;
        endcase
    end

endmodule
