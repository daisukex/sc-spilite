class bus_seq_item extends uvm_sequence_item;
  rand bit [31:0] addr;
rand bit [1:0] size;
  rand bit rd0wr1;
  rand bit [31:0] wdata;
  rand bit [31:0] rdata;

  `uvm_object_utils_begin(bus_seq_item)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(rd0wr1, UVM_ALL_ON)
    `uvm_field_int(wdata, UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "bus_seq_item");
    super.new(name);
  endfunction
endclass
