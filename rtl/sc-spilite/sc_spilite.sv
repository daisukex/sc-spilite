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
//  SPI Lite
//  Module: SPI Lite Top (sc_spilite)
//-----------------------------------------------------------------------------

module sc_spilite # (
  parameter NUM_OF_CS = 32,
  parameter NUM_OF_BUF = 1
) (
  // AHB Bus Interface
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
  output [31:0] HRDATA,
  output [1:0] HRESP,

  // Interrupt Signals
  output INTERRUPT,

  // SPI Interface
  input SRCCLK,             // SPI Source clock
  output [NUM_OF_CS-1:0] CSB,  // SPI Chip Select (Active Low)
  output SCLK,
  output MOSI,
  input MISO
);

sc_regbus_if regbus();

logic [31:0] REG_WADR;
logic [4:0]  REG_WTYP;
logic [3:0]  REG_WENB;
logic [31:0] REG_WDAT;
logic REG_WWAT;
logic REG_WERR;

logic [31:0] REG_RADR;
logic [4:0]  REG_RTYP;
logic REG_RENB;
logic [31:0] REG_RDAT;
logic REG_RWAT;
logic REG_RERR;

logic [4:0] REG_CSSEL;
logic [7:0] REG_CLKDR;
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
logic REG_SPIBUSY;
logic REG_SPICOMPLETE;

logic CSEXTEND;
logic [5:0] CSSEL;
logic [31:0] TXDATA;
logic TXSTART;
logic [31:0] RXDATA;
logic SPICOMPLETE;
logic SPIBUSY;
logic CSB_IN;

sc_ahbip_slave # (
  .CYCLE_MODE(1)
) ahb_slave (.*);

assign regbus.WADR = REG_WADR;
assign regbus.WTYP = REG_WTYP;
assign regbus.WENB = REG_WENB;
assign regbus.WDAT = REG_WDAT;
assign REG_WWAT = regbus.WWAT;
assign REG_WERR = regbus.WERR;

assign regbus.RADR = REG_RADR;
assign regbus.RTYP = REG_RTYP;
assign regbus.RENB = REG_RENB;
assign REG_RDAT = regbus.RDAT;
assign REG_RWAT = regbus.RWAT;
assign REG_RERR = regbus.RERR;

sc_spil_reg # (
  .NUM_OF_CS(NUM_OF_CS),
  .NUM_OF_BUF(NUM_OF_BUF)
) spil_reg (
  .*,
  .SYSCLK(HCLK),
  .SYSRSTB(HRESETN),
  .INTERRUPT(INTERRUPT),

  .REGBUS(regbus),

  .CSSEL(REG_CSSEL),
  .CSEXTEND(REG_CSEXTEND),
  .TXSTART(REG_TXSTART),
  .BORDER(REG_BORDER),
  .TXDATA(REG_TXDATA),
  .TXDPT(REG_TXDPT),
  .RXDATA(REG_RXDATA),
  .RXDPT(REG_RXDPT),
  .SPIBUSY(REG_SPIBUSY),
  .SPICOMPLETE(REG_SPICOMPLETE),

  .CLKDR(REG_CLKDR),
  .CSSETUP(REG_CSSETUP),
  .CSHOLD(REG_CSHOLD),
  .DWIDTH(REG_DWIDTH),
  .CPOL(REG_CPOL),
  .CPHA(REG_CPHA)
);

sc_spi_engine spi_engine (
  .SYSCLK(HCLK),
  .SRCCLK(SRCCLK),
  .SYSRSTB(HRESETN),

  .CLKDR(REG_CLKDR),
  .CSSETUP(REG_CSSETUP),
  .CSHOLD(REG_CSHOLD),
  .DWIDTH(REG_DWIDTH),
  .CPOL(REG_CPOL),
  .CPHA(REG_CPHA),

  .TXSTART(REG_TXSTART),
  .CSEXTEND(REG_CSEXTEND),
  .BORDER(REG_BORDER),
  .TXDATA(REG_TXDATA),
  .TXDPT(REG_TXDPT),
  .RXDATA(REG_RXDATA),
  .RXDPT(REG_RXDPT),
  .RXVALID(/*open*/),
  .SPIBUSY(REG_SPIBUSY),
  .SPICOMPLETE(REG_SPICOMPLETE),
  .CSB(CSB_IN),
  .*
);

sc_spil_scd # (
  .NUM_OF_CS(NUM_OF_CS)
) spil_scd (
  .CS_SEL(REG_CSSEL),
  .CSB_IN(CSB_IN),
  .CSB_OUT(CSB)
);

endmodule
