interface hax_soc_bind_if #(
  parameter int X_NUM_RS      = 40,
  parameter int X_RFDATA_WIDTH = 32,
  parameter int X_RFREG_WIDTH = 32
) (
  `include "hax_soc_signals.svh"
);

endinterface : hax_soc_bind_if
