class hax_soc_env extends uvm_env;
  `uvm_component_utils(hax_soc_env)

  function new(string name = "hax_soc_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction : build_phase
endclass : hax_soc_env
