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
    vif.haddr <= 32'h0;
    vif.hwrite <= 1'b0;
    vif.htrans <= 2'b0;
    vif.hsize <= 3'b0;
    vif.hburst <= 3'h0;
    forever begin
      if ( vif.hresetn ) begin
        seq_item_port.get_next_item(req);
        @(posedge vif.hclk);

        // Address Phase
        vif.haddr <= req.addr;
        vif.hwrite <= req.rd0wr1;
        vif.htrans <= 2'b10;
        vif.hsize <= req.size;
        vif.hburst <= 3'h000;
        do
          @(posedge vif.hclk);
        while(!vif.hready);

        // Data Phase
        vif.htrans <= 2'b00;
        if (vif.hwrite)
          vif.hwdata  <= req.wdata;
        do
          @(posedge vif.hclk);
        while(!vif.hready);

        rsp = new();
        rsp.set_id_info(req);
        if (!vif.hwrite)
          rsp.rdata = vif.hrdata;
        seq_item_port.item_done(rsp);
      end
      else
        @(posedge vif.hresetn);
    end
  endtask
endclass
