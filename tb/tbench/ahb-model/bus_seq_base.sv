virtual class bus_seq_base extends uvm_sequence #(bus_seq_item);
  function new(string name="bus_seq_base");
    super.new(name);
    set_automatic_phase_objection(1);
  endfunction
endclass
