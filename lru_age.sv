module lru_age #(
    parameter int WAYS = 4
) (
    input  logic                         clk,
    input  logic                         rst_n,

    input  logic                         access_valid,
    input  logic [$clog2(WAYS)-1:0]      access_way,

    output logic [$clog2(WAYS)-1:0]      lru_way
);

    localparam int AGE_W = (WAYS <= 1) ? 1 : $clog2(WAYS);
    localparam int WAY_W = (WAYS <= 1) ? 1 : $clog2(WAYS);

    logic [AGE_W-1:0] age [WAYS];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < WAYS; i++)
                age[i] <= AGE_W'(i);
        end
        else if (access_valid) begin
            for (int i = 0; i < WAYS; i++) begin
                if (i == access_way) begin
                    age[i] <= '0;
                end
                else if (age[i] < age[access_way]) begin
                    age[i] <= age[i] + 1'b1;
                end
            end
        end
    end

    always_comb begin
        lru_way = '0;

        for (int i = 0; i < WAYS; i++) begin
            if (age[i] == AGE_W'(WAYS-1))
                lru_way = WAY_W'(i);
        end
    end

endmodule
