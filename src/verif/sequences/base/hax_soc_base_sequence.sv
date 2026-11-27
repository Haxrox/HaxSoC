class hax_soc_base_sequence extends uvm_sequence;

  `uvm_object_utils(hax_soc_base_sequence)

  function new(string name = "hax_soc_base_sequence");
    super.new(name);
  endfunction : new

endclass : hax_soc_base_sequence
