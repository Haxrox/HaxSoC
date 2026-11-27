module hax_soc_tb;
  /* UVM */
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  /* HaxSoC */
  import hax_soc_tb_pkg::*;

  logic clk;
  logic rst_n;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  hax_soc dut (
    .clk(clk),
    .rst_n(rst_n)
  );

  initial begin
    automatic string dump_file = "";
    if ($value$plusargs("DUMP_FILE=%s", dump_file) || $test$plusargs("DUMP")) begin
      if (dump_file == "") dump_file = "dump.vcd";
      $dumpfile(dump_file);
      $dumpvars(0, hax_soc_tb);
    end
  end

  initial begin
    `uvm_info("hax_soc_tb", "Starting hax_soc_tb", UVM_LOW);
    run_test();

    $finish;
  end
endmodule : hax_soc_tb
