module single_stage_skid_buffer #(
  parameter DATA_W = 256
) (
  input logic i_clk,
  input logic rst_n,
  
  //Upstream Intrface
  input  logic [DATA_W-1:0] in_data,
  input  logic            i_valid,
  output logic           o_ready,

  //downstream Interface
  input  logic              i_ready,
  output logic [DATA_W-1:0] o_data,
  output logic              o_valid
);
  logic [DATA_W-1:0] skid_data;
  logic skid_valid, next_ready;
  assign o_data = skid_valid ? skid_data : in_data;
  assign o_valid = skid_valid | i_valid;
  assign o_ready = next_ready | ~skid_valid;
  always_ff @(posedge i_clk or negedge rst_n) begin
    if (!rst_n) begin
      skid_data <= '0;
      skid_valid <= '0;
      next_ready <= '0;
    end
    else begin
      next_ready <= i_ready;
      if (skid_valid) begin
        skid_valid <= ~i_ready;
      end
      else begin
        if (i_valid & o_ready & ~i_ready) begin
          skid_valid <= 1'b1;
          skid_data <= in_data;
        end
      end
    end
  end
endmodule
