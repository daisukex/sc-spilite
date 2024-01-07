//-----------------------------------------------------------------------------
// Copyright 2023 Space Cubics, LLC
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
// Space Cubics IP Core Register Package
//-----------------------------------------------------------------------------

`ifndef _SC_IPREG_PKG_SV_
`define _SC_IPREG_PKG_SV_

`timescale 1ps/1ps

package sc_ipreg_pkg;

// Space Cubics Register Parameter
// --------------------------------------------------
typedef struct packed {
  logic [15:0] addr;     // Define the address of this register
  logic [31:0] valid;    // Define whether a register exists or not
                         // Define bit behavior for access
  logic [31:0] write;    // - Write 1 sets the bit to 1, and write 0 clears the bit to 0
  logic [31:0] wset;     // - Write 1 sets the bit to 1, and write 0 has no effect
  logic [31:0] wclr;     // - Write 1 clears the bit to 0, and write 0 has no effect
  logic [31:0] ronly;    // - This bit is read-only. All write access is invalid
  logic [31:0] init;     // Define the initial value of this register
  logic [31:0] cnst;     // This bit is constant
} sc_reg_param;

// Register Address Decode Function
// --------------------------------------------------
function reg_hit;
  input sc_reg_param rp; // register param
  input [31:0] cb;       // compare bit
  input [31:0] ad;       // access address
  input [3:0] en;        // write enable
begin
  reg_hit = en & ((ad & cb) == (rp.addr & cb));
end
endfunction

// Register Read/Write Function
// --------------------------------------------------
function [31:0] reg_wdata;
  input sc_reg_param rp; // register param
  input hit;             // register hit
  input [31:0] rd;       // register data
  input [31:0] wd;       // write data
  input [3:0] en;        // write enable
  integer i;
begin
  // Initialize
  for(i=0; i<32; i=i+1) begin
    if (rp.valid[i] & rp.cnst[i])
      reg_wdata[i] = rp.init[i];
    else if (rp.valid[i] & !rp.ronly[i])
      reg_wdata[i] = rd[i];
    else
      reg_wdata[i] = 1'b0;
  end

  if (hit) begin
    // Write Data
    for(i=0; i<32; i=i+1) begin
      if (rp.valid[i] & !rp.cnst[i] & en[i/8]) begin
        if (rp.write[i])
          reg_wdata[i] = wd[i];
        else if (rp.wset[i] & wd[i])
          reg_wdata[i] = 1'b1;
        else if (rp.wclr[i] & wd[i])
          reg_wdata[i] = 1'b0;
      end
    end
  end
end
endfunction

endpackage
`endif
