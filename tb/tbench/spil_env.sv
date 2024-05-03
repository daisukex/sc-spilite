class spil_env extends uvm_env;
  `uvm_component_utils(spil_env)

  ahbm_agent ahbm;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ahbm = ahbm_agent::type_id::create("ahbm_agent", this);
  endfunction

endclass
