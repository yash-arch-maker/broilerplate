module cdc_event_toggle (
    input  logic clk_a,
    input  logic clk_b,
    input  logic rst_n,

    input  logic event_a,
    output logic event_b
);

    logic event_toggle_a;

    logic sync1_b;
    logic sync2_b;
    logic sync2_b_d;

    // Source domain:
    // Toggle whenever an event occurs.
    always_ff @(posedge clk_a or negedge rst_n) begin
        if (!rst_n)
            event_toggle_a <= 1'b0;
        else if (event_a)
            event_toggle_a <= ~event_toggle_a;
    end

    // Destination-domain synchronizer.
    always_ff @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            sync1_b   <= 1'b0;
            sync2_b   <= 1'b0;
            sync2_b_d <= 1'b0;
        end
        else begin
            sync1_b   <= event_toggle_a;
            sync2_b   <= sync1_b;
            sync2_b_d <= sync2_b;
        end
    end

    // Detect toggle in destination domain.
    assign event_b = sync2_b ^ sync2_b_d;

endmodule
