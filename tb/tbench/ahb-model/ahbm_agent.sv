class ahbm_agent extends uvm_agent;
  `uvm_component_utils(ahbm_agent)

  ahbm_driver driver;
  bus_sequencer sequencer;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (get_is_active() == UVM_ACTIVE ) begin
      sequencer = bus_sequencer::type_id::create("sequencer", this);
      driver = ahbm_driver::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    if( get_is_active() == UVM_ACTIVE ) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

endclass
