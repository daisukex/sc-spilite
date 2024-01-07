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
// Space Cubics Standard IP Core
//  AMBA AHB IP
//  Module: AHB Slave Core (sc_ahbip_slave)
//-----------------------------------------------------------------------------

module sc_ahbip_slave # (
  parameter CYCLE_MODE = 0
) (
  // AHB Interface
  input HCLK,
  input HRESETN,
  input HSEL,
  input [31:0] HADDR,
  input [1:0] HTRANS,
  input [2:0] HSIZE,
  input [2:0] HBURST,
  input HWRITE,
  input HREADYIN,
  output HREADYOUT,
  input [31:0] HWDATA,
  output reg [31:0] HRDATA,
  output [1:0] HRESP,

  // Register Interface
  output reg [31:0] REG_WADR,
  output reg [4:0] REG_WTYP,
  output reg [3:0] REG_WENB,
  output reg [31:0] REG_WDAT,
  input REG_WWAT,
  input REG_WERR,

  output reg [31:0] REG_RADR,
  output reg [4:0] REG_RTYP,
  output reg REG_RENB,
  input [31:0] REG_RDAT,
  input REG_RWAT,
  input REG_RERR
);

// AHB Control
// ------------------------------
wire  creq = HSEL & HREADYIN & HREADYOUT & HTRANS != 2'b00;
reg latch_dvalid;
reg latch_wvalid;
reg latch_rvalid;
reg [31:0] latch_addr;
reg [2:0] latch_size;
reg [2:0] latch_burst;
reg [31:0] latch_wdata;

always @ (posedge HCLK) begin
  if (!HRESETN) begin
    latch_addr <= 32'h0000_0000;
    latch_wvalid <= 1'b0;
    latch_rvalid <= 1'b0;
    latch_size <= 3'b000;
    latch_burst <= 3'b000;
  end
  else begin
    if ((REG_RENB & !REG_RWAT) | (|REG_WENB & !REG_WWAT)) begin
      latch_wvalid <= 1'b0;
      latch_rvalid <= 1'b0;
    end
    if (creq) begin
      latch_addr <= HADDR;
      latch_size <= HSIZE;
      latch_burst <= HBURST;
      if (HWRITE)
        latch_wvalid <= 1'b1;
      else
        latch_rvalid <= 1'b1;
    end
  end
end

always @ (posedge HCLK) begin
  if (!HRESETN) begin
    latch_wdata <= 32'h0000_0000;
    latch_dvalid <= 1'b0;
  end
  else if (|REG_WENB & !REG_WWAT) begin
    latch_dvalid <= 1'b0;
  end
  else if (latch_wvalid) begin
    latch_wdata <= HWDATA;
    latch_dvalid <= 1'b1;
  end
end

// Write Channel
// ------------------------------
wire wbyte = (latch_size == 3'b000);
wire whalf = (latch_size == 3'b001);
wire wword = latch_size[1];
wire [3:0] wen;
assign wen[0] = wbyte &  (latch_addr[1:0] == 2'b00)
              | whalf & ~|latch_addr[1:0]
              | wword;
assign wen[1] = wbyte &  (latch_addr[1:0] == 2'b01)
              | whalf &  ~latch_addr[1]
              | wword;
assign wen[2] = wbyte &  (latch_addr[1:0] == 2'b10)
              | whalf &  (latch_addr[1] ^ latch_addr[0])
              | wword;
assign wen[3] = wbyte &  (latch_addr[1:0] == 2'b11)
              | whalf &   latch_addr[1]
              | wword;

always @ (*) begin
  REG_WADR = latch_addr;
  REG_WTYP = btype(latch_burst);
  REG_WENB = 4'h0;
  if (CYCLE_MODE == 0) begin
    if (latch_wvalid) begin
      REG_WENB = wen;
      REG_WDAT = HWDATA;
    end
  end
  else begin
    REG_WDAT = latch_wdata;
    if (latch_dvalid) begin
      REG_WENB = wen;
    end
  end
end

// Read Channel
// ------------------------------
reg rcycle;
always @ (posedge HCLK) begin
  if (!HRESETN)
    rcycle <= 1'b0;
  else begin
    if (rcycle & !REG_RWAT)
      rcycle <= 1'b0;

    if (REG_RENB)
      rcycle <= 1'b1;
  end
end

wire wrrace = CYCLE_MODE == 0 & |REG_WENB & creq & !HWRITE;
reg rwrace_recovery;
always @ (posedge HCLK) begin
  if (!HRESETN)
      rwrace_recovery <= 1'b0;
  else
      rwrace_recovery <= wrrace;
end

always @ (*) begin
  if (CYCLE_MODE == 1 | rwrace_recovery) begin
    REG_RADR = latch_addr;
    REG_RTYP = btype(latch_burst);
    REG_RENB = latch_rvalid;
  end
  else if (CYCLE_MODE == 0 & !wrrace) begin
    REG_RADR = HADDR;
    REG_RTYP = btype(HBURST);
    REG_RENB = creq & !HWRITE;
  end

  if (rcycle)
    HRDATA = REG_RDAT;
  else
    HRDATA = 32'h00000000;
end

// HREADY Control
// ------------------------------
assign HREADYOUT = ~(|REG_WENB & (REG_WWAT | REG_WERR)) &
                   ~(rcycle & (REG_RWAT | REG_RERR)) &
                   ~(CYCLE_MODE == 1 & latch_rvalid & REG_RENB) &
                   ~(rwrace_recovery & latch_rvalid & REG_RENB) &
                   ~(CYCLE_MODE == 1 & latch_wvalid & !(|REG_WENB));

// HRESP Control
// ------------------------------
reg next_hresp;
always @ (posedge HCLK) begin
  if (!HRESETN)
    next_hresp <= 2'b00;
  else if (HREADYOUT & HRESP == 2'b01)
    next_hresp <= 2'b00;
  else if (REG_WERR | REG_RERR)
    next_hresp <= 2'b01;
end
assign HRESP = (REG_WERR | REG_RERR) ? 2'b01: next_hresp;

function [4:0] btype (
  input [2:0] burst
);
begin
  if (burst == 3'b000)
    btype = 5'b00_000;
  else if (burst == 3'b001)
    btype = 5'b01_000;
  else begin
    btype[2:0] = burst[2:1] << 1;
    if (burst[0])
      btype[4:3] = 2'b01;
    else
      btype[4:3] = 2'b10;
  end
end
endfunction

endmodule
