class bus_single_read_seq extends bus_seq_base;
  `uvm_object_utils(bus_single_read_seq)

  rand bit [31:0] addr;
  rand bit [1:0] size;
  bit [31:0] rdata;

  function new(string name = "bus_single_read_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_do_with(req, {
      req.rd0wr1 == 1'b0;
      req.addr   == local::addr;
      req.size   == local::size;
    });
    get_response(rsp);
    rdata = rsp.rdata;
    $display("[%t] addr: 0x%h data: 0x%h", $time, addr, rdata);
  endtask

endclass
