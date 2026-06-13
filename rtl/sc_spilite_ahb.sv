//-----------------------------------------------------------------------------
// Copyright 2025-2026 Space Cubics Inc.
// Copyright 2024      Space Cubics, LLC
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
// Space Cubics Open-source Reliable Core Architecture
//  SPI Lite Controller (Single-bit SPI Controller)
//  Module: sc_spilite
//-----------------------------------------------------------------------------

module sc_spilite_ahb # (
  parameter NUM_CS = 32,
  parameter BUFFER_DEPTH = 1
) (
  // AHB Bus Interface
  input HCLK,
  input HRESETN,
  input AHB_S_HSEL,
  input [31:0] AHB_S_HADDR,
  input [1:0] AHB_S_HTRANS,
  input [2:0] AHB_S_HSIZE,
  input [2:0] AHB_S_HBURST,
  input AHB_S_HWRITE,
  input AHB_S_HREADYIN,
  output AHB_S_HREADYOUT,
  input [31:0] AHB_S_HWDATA,
  output [31:0] AHB_S_HRDATA,
  output [1:0] AHB_S_HRESP,

  // Interrupt Signal
  output SPIL_IRQ,

  // SPI Interface
  input SRCCLK,             // SPI Source clock
  output [NUM_CS-1:0] CSB,  // SPI Chip Select (Active Low)
  output SCLK,
  output MOSI,
  input MISO
);

logic DATACLK;

logic [31:0] REG_WADR;
logic [4:0]  REG_WTYP;
logic [3:0]  REG_WENB;
logic [31:0] REG_WDAT;
logic REG_WWAT;
logic REG_WERR;
logic [9:0] reg_wtyp_full;

logic [31:0] REG_RADR;
logic [4:0]  REG_RTYP;
logic REG_RENB;
logic [31:0] REG_RDAT;
logic REG_RWAT;
logic REG_RERR;
logic [9:0] reg_rtyp_full;

logic [4:0] REG_CSSEL;
logic [7:0] REG_CLKHIGH;
logic [7:0] REG_CLKLOW;
logic [3:0] REG_CSSETUP;
logic [3:0] REG_CSHOLD;
logic [8:0] REG_DWIDTH;
logic REG_CPOL;
logic REG_CPHA;
logic REG_BORDER;
logic REG_TXSTART;
logic REG_CSEXTEND;
logic [31:0] REG_TXDATA;
logic [3:0] REG_TXDPT;
logic [31:0] REG_RXDATA;
logic [3:0] REG_RXDPT;
logic REG_RXVALID;
logic REG_SPIBUSY;
logic REG_SPICOMPLETE;

logic CSEXTEND;
logic [5:0] CSSEL;
logic [31:0] TXDATA;
logic TXSTART;
logic [31:0] RXDATA;
logic SPICOMPLETE;
logic SPIBUSY;

// AHB Subordinate
sc_ahbip_subordinate # (
  .CYCLE_MODE(1)
) ahb_s (
  // AHB Interface
  .HCLK(HCLK),
  .HRESETN(HRESETN),
  .HSEL(AHB_S_HSEL),
  .HADDR(AHB_S_HADDR),
  .HTRANS(AHB_S_HTRANS),
  .HSIZE(AHB_S_HSIZE),
  .HBURST(AHB_S_HBURST),
  .HWRITE(AHB_S_HWRITE),
  .HREADYIN(AHB_S_HREADYIN),
  .HREADYOUT(AHB_S_HREADYOUT),
  .HWDATA(AHB_S_HWDATA),
  .HRDATA(AHB_S_HRDATA),
  .HRESP(AHB_S_HRESP),

  // Register Interface
  .REG_WADR(REG_WADR),
  .REG_WTYP(REG_WTYP),
  .REG_WENB(REG_WENB),
  .REG_WDAT(REG_WDAT),
  .REG_WWAT(REG_WWAT),
  .REG_WERR(REG_WERR),
  .REG_RADR(REG_RADR),
  .REG_RTYP(REG_RTYP),
  .REG_RENB(REG_RENB),
  .REG_RDAT(REG_RDAT),
  .REG_RWAT(REG_RWAT),
  .REG_RERR(REG_RERR)
);
assign reg_wtyp_full = {5'h0, REG_WTYP};
assign reg_rtyp_full = {5'h0, REG_RTYP};

sc_spil_reg # (
  .NUM_CS(NUM_CS),
  .BUFFER_DEPTH(BUFFER_DEPTH)
) spil_reg (
  // System Interface
  .SYSCLK(HCLK),
  .SYSRSTB(HRESETN),
  .INTERRUPT(SPIL_IRQ),

  // Register Interface
  .REG_WADR(REG_WADR),
  .REG_WTYP(reg_wtyp_full),
  .REG_WENB(REG_WENB),
  .REG_WDAT(REG_WDAT),
  .REG_WWAT(REG_WWAT),
  .REG_WERR(REG_WERR),
  .REG_RADR(REG_RADR),
  .REG_RTYP(reg_rtyp_full),
  .REG_RENB(REG_RENB),
  .REG_RDAT(REG_RDAT),
  .REG_RWAT(REG_RWAT),
  .REG_RERR(REG_RERR),

  // SPI Lite Core Interface
  .CSSEL(REG_CSSEL),
  .CSEXTEND(REG_CSEXTEND),
  .TXSTART(REG_TXSTART),
  .SPIBUSY(REG_SPIBUSY),
  .SPICOMPLETE(REG_SPICOMPLETE),
  .BORDER(REG_BORDER),
  .DATACLK(DATACLK),
  .TXDATA(REG_TXDATA),
  .TXDPT(REG_TXDPT),
  .RXDATA(REG_RXDATA),
  .RXDPT(REG_RXDPT),
  .RXVALID(REG_RXVALID),
  .CLKHIGH(REG_CLKHIGH),
  .CLKLOW(REG_CLKLOW),
  .CSSETUP(REG_CSSETUP),
  .CSHOLD(REG_CSHOLD),
  .DWIDTH(REG_DWIDTH),
  .CPOL(REG_CPOL),
  .CPHA(REG_CPHA)
);

sc_spi_engine # (
  .NUM_CS(NUM_CS)
) spi_engine (
  // System Control
  .SYSCLK(HCLK),
  .SRCCLK(SRCCLK),
  .SYSRSTB(HRESETN),

  // SPI Signal from Register
  .CLKHIGH(REG_CLKHIGH),
  .CLKLOW(REG_CLKLOW),
  .CSSETUP(REG_CSSETUP),
  .CSHOLD(REG_CSHOLD),
  .DWIDTH(REG_DWIDTH),
  .CPOL(REG_CPOL),
  .CPHA(REG_CPHA),
  .BORDER(REG_BORDER),
  .TXSTART(REG_TXSTART),
  .CSEXTEND(REG_CSEXTEND),
  .CSSEL(REG_CSSEL),
  .SPIBUSY(REG_SPIBUSY),
  .SPICOMPLETE(REG_SPICOMPLETE),

  // Data Interface
  .DATACLK(DATACLK),
  .TXDATA(REG_TXDATA),
  .TXDPT(REG_TXDPT),
  .RXDATA(REG_RXDATA),
  .RXDPT(REG_RXDPT),
  .RXVALID(REG_RXVALID),

  // SPI Interface
  .CSB(CSB),
  .SCLK(SCLK),
  .MOSI(MOSI),
  .MISO(MISO)
);

endmodule
