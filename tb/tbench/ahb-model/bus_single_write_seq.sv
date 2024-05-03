class bus_single_write_seq extends bus_seq_base;
  `uvm_object_utils(bus_single_write_seq)

  rand bit [31:0] addr;
  rand bit [1:0] size;
  rand bit [31:0] wdata;

  function new(string name = "bus_single_write_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_do_with(req, {
      req.rd0wr1 == 1'b1;
      req.addr   == local::addr;
      req.size   == local::size;
      req.wdata  == local::wdata;
    });
    get_response(rsp);
  endtask

endclass
