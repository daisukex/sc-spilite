class spil_test extends uvm_test;
  `uvm_component_utils(spil_test)

  spil_env env;

  function new(string name = "spil_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = spil_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    uvm_top.print_topology();
  endtask: run_phase

endclass
