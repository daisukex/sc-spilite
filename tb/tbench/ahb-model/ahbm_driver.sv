class ahbm_driver extends uvm_driver #(bus_seq_item);
  `uvm_component_utils(ahbm_driver)

  virtual amba_ahb_if vif;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if ( !uvm_config_db#(virtual amba_ahb_if)::get(this, "", "vif", vif) ) begin
      `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    forever begin
      if ( vif.hresetn ) begin
        seq_item_port.get(req);
        @(posedge vif.hclk);
        vif.haddr <= req.addr;
        vif.hwrite <= req.rd0wr1;
        @(posedge vif.hclk);
        if (vif.hwrite)
          vif.hwdata  <= req.wdata;
        @(posedge vif.hclk);
        rsp = new();
        if (!vif.hwrite)
          rsp.rdata <= vif.hrdata;
        rsp.set_id_info(req);
        seq_item_port.put(rsp);
      end
      else
        @(posedge vif.hresetn);
    end
  endtask
endclass
