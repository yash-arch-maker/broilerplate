module dual_stage_skid_buffer_optimized #(
  parameter DATA_W = 256
) (
  input logic i_clk,
  input logic rst_n,
  // Upstream Interface
  input  logic [DATA_W-1:0] in_data,
  input  logic            i_valid,
  output logic            o_ready,
  // Downstream Interface
  input  logic              i_ready,
  output logic [DATA_W-1:0] o_data,
  output logic              o_valid
);

  logic [DATA_W-1:0] data_r, skid_r;
  logic full_r, skid_full_r;

  // Handshake signals for clarity
  logic in_fire, out_fire;

  assign in_fire  = i_valid & o_ready;
  assign out_fire = o_valid & i_ready;

  // Output assignments
  assign o_ready = ~skid_full_r;  // Accept input only if skid has space
  assign o_valid = full_r;        // Main register has valid data
  assign o_data  = data_r;        // Main register output

  always_ff @(posedge i_clk or negedge rst_n) begin
    if (!rst_n) begin
      full_r      <= '0;
      skid_full_r <= '0;
      data_r      <= '0;
      skid_r      <= '0;
    end
    else begin
      // === DRAIN PHASE ===
      // Main register data exits to output
      if (out_fire) begin
        if (skid_full_r) begin
          // Skid has data waiting: promote to main
          data_r      <= skid_r;
          skid_full_r <= '0;
          full_r      <= '1;     // Main remains full
        end else begin
          // No skid data: main becomes empty
          full_r <= '0;
        end
      end

      // === FILL PHASE ===
      // Input data enters main directly if main is empty, OR if main is
      // draining this cycle and skid isn't promoting into it (out_fire
      // guarantees skid_full_r==0 here, since o_ready=~skid_full_r gates
      // in_fire). Without the out_fire term, new data would be shoved
      // into skid while main goes empty this same cycle -> the data
      // becomes invisible (o_valid=0) and the pipe deadlocks permanently,
      // since promotion only happens inside the out_fire branch above,
      // which itself requires o_valid=1.
      if (in_fire) begin
        if (!full_r || (out_fire && !skid_full_r)) begin
          // Main is empty, or vacated this cycle: fill it directly
          data_r <= in_data;
          full_r <= '1;
        end else begin
          // Main is full and not draining: overflow to skid
          skid_r      <= in_data;
          skid_full_r <= '1;
        end
        // If both full: input blocked by o_ready=0, nothing happens
      end
    end
  end

endmodule
