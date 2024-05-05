class spil_test extends uvm_test;
  `uvm_component_utils(spil_test)

  spil_env env;

  function new(string name = "spil_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = spil_env::type_id::create("env", this);
    uvm_config_db#(uvm_object_wrapper)::set(this,
      "env.ahbm.sequencer.run_phase", "default_sequence",
      bus_access_seq::type_id::get());
  endfunction

  task run_phase(uvm_phase phase);
    uvm_top.print_topology();
  endtask

endclass
