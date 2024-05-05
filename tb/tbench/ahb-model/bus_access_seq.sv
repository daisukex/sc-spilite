class bus_access_seq extends bus_seq_base;
  `uvm_object_utils(bus_access_seq)

  bus_single_write_seq write_seq;
  bus_single_read_seq read_seq;

  function new(string name = "bus_access_seq");
    super.new(name);
  endfunction

  virtual task body();
    comp32( .addr(32'h4F000004), .expd(32'h00080001));
    write32(.addr(32'h4F000004), .data(32'h00020304));
    comp32( .addr(32'h4F000004), .expd(32'h00020304));
  endtask

  task write32 (
    input bit [31:0] addr,
    input bit [31:0] data
  );
    `uvm_do_with(write_seq, {
      write_seq.addr   == local::addr;
      write_seq.size   == 2'h2;
      write_seq.wdata  == local::data;
    })
  endtask

  task read32 (
    input bit [31:0] addr,
    output bit [31:0] data
  );
    `uvm_do_with(read_seq, {
      read_seq.addr   == local::addr;
      read_seq.size   == 2'h2;
    })
    data = read_seq.rdata;
  endtask

  task comp32 (
    input bit [31:0] addr,
    input bit [31:0] expd
  );
    bit [31:0] rdata;
    read32 (.addr(addr), .data(rdata));
    if (rdata == expd)
      `uvm_info("ahbm", "Data Compare OK", UVM_LOW)
    else
      `uvm_error("ahbm", "Data Compare Error")
  endtask

endclass
