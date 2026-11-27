class hax_soc_base_test extends uvm_test;
  `uvm_component_utils(hax_soc_base_test)

  hax_soc_env env;

  function new(string name = "hax_soc_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info(get_type_name(), "run_phase()", UVM_LOW)
  endtask

  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
  endfunction
endclass : hax_soc_base_test;
