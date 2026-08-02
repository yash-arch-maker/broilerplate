module dual_stage_skid_buffer #(
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
  logic skid_valid, pipe_accept, next_ready;
  assign next_ready = ~o_valid | i_ready;
  assign pipe_accept = (i_valid | skid_valid) & next_ready;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      o_valid <= '0;
      skid_valid <= '0;
      skid_data  <= '0;
      o_data  <= '0;
      o_ready <= '0;
    end
    else begin
      o_ready <= next_ready;
      if (pipe_accept)begin
        o_valid <= 1'b1;
        if (skid_valid) begin
          o_data <= skid_data;
          skdi_valid <= '0;
        end
        else begin
          o_data <= i_data;
        end
      end
      else begin
        if (i_ready) begin
          o_valid <= '0;
        end
        else if (o_valid) begin
          skid_valid <= 1'b1;
          skid_data <= i_data;
        end
      end
    end
  end
endmodule
