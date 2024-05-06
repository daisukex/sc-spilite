//-----------------------------------------------------------------------------
// Copyright 2024 Space Cubics, LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------------------

`timescale 1ps/1ps
module tb_top;
`include "uvm_macros.svh"
import uvm_pkg::*;
import sc_uvm_message_pkg::*;
`include "ahbm_models.sv"
`include "spil_env.sv"
`include "spil_test.sv"


parameter HCLK_PERIOD = 10417;

bit hresetn;
bit hclk;
logic hsel;

amba_ahb_if ahbif (.hclk(hclk), .hresetn(hresetn));
assign hsel = (ahbif.haddr[31:16] == 16'h4F00 & ahbif.htrans != 2'b00);

// AHB Clock
initial forever begin
  #(HCLK_PERIOD);
  hclk = ~hclk;
end

initial begin
  hresetn = 0;
  #100000;
  hresetn = 1;
end

sc_spilite # (
  .NUM_OF_CS(32),
  .NUM_OF_BUF(1)
) dut (
  .HCLK(hclk),
  .HRESETN(hresetn),
  .HSEL(hsel),
  .HADDR(ahbif.haddr),
  .HTRANS(ahbif.htrans),
  .HSIZE(ahbif.hsize),
  .HBURST(ahbif.hburst),
  .HWRITE(ahbif.hwrite),
  .HREADYIN(1'b1),
  .HREADYOUT(ahbif.hready),
  .HWDATA(ahbif.hwdata),
  .HRDATA(ahbif.hrdata),
  .HRESP(ahbif.hresp),

  .INTERRUPT(),

  .SRCCLK(),
  .CSB(),
  .SCLK(),
  .MOSI(),
  .MISO()
);

initial begin
  uvm_config_db#(virtual amba_ahb_if)::set(uvm_root::get(), "*.env.ahbm.*", "vif", ahbif);
  run_test();
end

endmodule
