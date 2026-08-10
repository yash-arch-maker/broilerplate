module cdc_event_handshake (
    input  logic clk_a,
    input  logic clk_b,
    input  logic rst_n,

    input  logic event_a,
    output logic event_b
);

    logic req_a;
    logic ack_b;

    logic ack_a_sync1, ack_a_sync2;
    logic req_b_sync1, req_b_sync2;

    // Source domain
    always_ff @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            req_a <= 1'b0;
        end
        else if (event_a && (ack_a_sync2 == req_a)) begin
            req_a <= ~req_a;
        end
    end

    // Synchronize request into destination.
    always_ff @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            req_b_sync1 <= 1'b0;
            req_b_sync2 <= 1'b0;
        end
        else begin
            req_b_sync1 <= req_a;
            req_b_sync2 <= req_b_sync1;
        end
    end

    // Detect new request and acknowledge it.
    always_ff @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            ack_b   <= 1'b0;
            event_b <= 1'b0;
        end
        else begin
            event_b <= 1'b0;

            if (req_b_sync2 != ack_b) begin
                event_b <= 1'b1;
                ack_b   <= req_b_sync2;
            end
        end
    end

    // Synchronize acknowledgement back.
    always_ff @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            ack_a_sync1 <= 1'b0;
            ack_a_sync2 <= 1'b0;
        end
        else begin
            ack_a_sync1 <= ack_b;
            ack_a_sync2 <= ack_a_sync1;
        end
    end

endmodule
