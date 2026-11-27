module hax_soc #(
  parameter bit          X_EXT = 1'b0,
  parameter int unsigned X_NUM_RS = 2,
  parameter int unsigned X_ID_WIDTH = 4,
  parameter int unsigned X_MEM_WIDTH = 32,
  parameter int unsigned X_RDATA_WIDTH = 32,
  parameter int unsigned X_RFREG_WIDTH = 32
) (
  `include "hax_soc_signals.svh"
);
  cv32e40x_if_xif #(
    .X_NUM_RS      (X_NUM_RS),
    .X_ID_WIDTH    (X_ID_WIDTH),
    .X_MEM_WIDTH   (X_MEM_WIDTH)
  ) xif_if ();

  cv32e40x_core #(
    .X_EXT         (X_EXT),
    .X_NUM_RS      (X_NUM_RS),
    .X_ID_WIDTH    (X_ID_WIDTH),
    .X_MEM_WIDTH   (X_MEM_WIDTH)
  ) u_cv32e40x_core (
    .clk_i(clk),
    .rst_ni(rst_n),
    .xif_compressed_if(xif_if),
    .xif_issue_if(xif_if),
    .xif_commit_if(xif_if),
    .xif_mem_if(xif_if),
    .xif_mem_result_if(xif_if),
    .xif_result_if(xif_if)
  );

endmodule : hax_soc
