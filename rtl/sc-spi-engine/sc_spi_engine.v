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
//  SPI Protocol Engine
//  Module: SPI Protocol Engine Top (sc_spi_engine)
//-----------------------------------------------------------------------------

module sc_spi_engine (
  // System Control
  // ------------------------
  input SYSCLK,
  input SRCCLK,
  input SYSRSTB,

  // SPI Signal from Register
  // ------------------------
  input [7:0] CLKDR,
  input [3:0] CSSETUP,
  input [3:0] CSHOLD,
  input [8:0] DWIDTH,
  input CPOL,
  input CPHA,

  input BORDER,
  input TXSTART,
  input CSEXTEND,
  input [31:0] TXDATA,
  output [3:0] TXDPT,
  output [31:0] RXDATA,
  output [3:0] RXDPT,
  output SPIBUSY,
  output SPICOMPLETE,

  // SPI Interface
  // ------------------------
  output CSB,
  output SCLK,
  output MOSI,
  input MISO
);

wire SPICLK;
wire CLK_ENABLE;
wire CLK_ENABLE_SRCCLK;
wire [7:0] CLK_CLKDR;
wire CLK_SPICLK;
wire CLK_SEL;
wire [3:0] SPC_CSSETUP;
wire [3:0] SPC_CSHOLD;
wire [8:0] SPC_DWIDTH;
wire SPC_CPOL;
wire SPC_CPHA;
wire SPC_SPISTART;
wire SPC_SPIBUSY;
wire SPC_SPIBUSY_SYSCLK;
wire SPC_CSEXTEND;
wire SPC_BORDER;
wire [31:0] SPC_TXDATA;
wire SPC_TXDETECT;
wire SPC_TXDETECT_SYSCLK;
wire [31:0] SPC_RXDATA;
wire [31:0] SPC_LRXDATA;
wire SPC_RXVALID;
wire SPC_RXVALID_SYSCLK;

// ----------
// SPI Transfer Controller
// --------------------------------------------------
sc_spi_stc stc (
  // System Control
  .SYSCLK(SYSCLK),
  .SYSRSTB(SYSRSTB),

  // SPI Signal from Register
  .CLKDR(CLKDR),
  .CSSETUP(CSSETUP),
  .CSHOLD(CSHOLD),
  .DWIDTH(DWIDTH),
  .CPOL(CPOL),
  .CPHA(CPHA),

  .TXSTART(TXSTART),
  .CSEXTEND(CSEXTEND),
  .BORDER(BORDER),
  .TXDATA(TXDATA),
  .TXDPT(TXDPT),
  .RXDATA(RXDATA),
  .RXDPT(RXDPT),
  .SPIBUSY(SPIBUSY),
  .SPICOMPLETE(SPICOMPLETE),

  // SPI Signal to SCG
  .CLK_ENABLE(CLK_ENABLE),
  .CLK_CLKDR(CLK_CLKDR),

  // SPI Signal to SPC
  .SPC_CSSETUP(SPC_CSSETUP),
  .SPC_CSHOLD(SPC_CSHOLD),
  .SPC_DWIDTH(SPC_DWIDTH),
  .SPC_CPOL(SPC_CPOL),
  .SPC_CPHA(SPC_CPHA),

  .SPC_SPISTART(SPC_SPISTART),
  .SPC_SPIBUSY(SPC_SPIBUSY_SYSCLK),
  .SPC_CSEXTEND(SPC_CSEXTEND),
  .SPC_BORDER(SPC_BORDER),
  .SPC_TXDATA(SPC_TXDATA),
  .SPC_TXDETECT(SPC_TXDETECT_SYSCLK),
  .SPC_RXDATA(SPC_RXDATA),
  .SPC_LRXDATA(SPC_LRXDATA),
  .SPC_RXVALID(SPC_RXVALID_SYSCLK)
);

// ----------
// SPI Signal Synchronizer
// --------------------------------------------------
sc_spi_sss sss (
  .SYSCLK(SYSCLK),
  .CLKEN(CLK_ENABLE),
  .SPIBUSY_SYSCLK(SPC_SPIBUSY_SYSCLK),
  .TXDETECT_SYSCLK(SPC_TXDETECT_SYSCLK),
  .RXVALID_SYSCLK(SPC_RXVALID_SYSCLK),
  .SRCCLK(SRCCLK),
  .CLKEN_SRCCLK(CLK_ENABLE_SRCCLK),
  .SPIBUSY(SPC_SPIBUSY),
  .TXDETECT(SPC_TXDETECT),
  .RXVALID(SPC_RXVALID)
);

// ----------
// SPI Clock Generator
// --------------------------------------------------
sc_spi_scg scg (
  .SRCCLK(SRCCLK),
  .SYSRSTB(SYSRSTB),
  .CLK_CLKDR(CLK_CLKDR),
  .CLK_MODE({SPC_CPOL, SPC_CPHA}),
  .CLK_ENABLE(CLK_ENABLE_SRCCLK),
  .SPICLK(CLK_SPICLK)
);
assign SPICLK = (!CLK_ENABLE_SRCCLK) ? 1'b0: CLK_SPICLK;

// ----------
// SPI Protocol Controller
// --------------------------------------------------
sc_spi_spc spc (
  // System Control
  .SPICLK(SPICLK),
  .SYSRSTB(SYSRSTB),

  // SPI Wave Parameter
  .CSSETUP(SPC_CSSETUP),
  .CSHOLD(SPC_CSHOLD),
  .DWIDTH(SPC_DWIDTH),
  .CPOL(SPC_CPOL),
  .CPHA(SPC_CPHA),

  // TX/RX Data
  .CSEXTEND(SPC_CSEXTEND),
  .SPISTART(SPC_SPISTART),
  .SPIBUSY(SPC_SPIBUSY),
  .BORDER(SPC_BORDER),
  .TXDATA(SPC_TXDATA),
  .TXDETECT(SPC_TXDETECT),
  .RXDATA(SPC_RXDATA),
  .LRXDATA(SPC_LRXDATA),
  .RXVALID(SPC_RXVALID),

  // SPI Interface
  .CSB(CSB),
  .SCLK(SCLK),
  .MOSI(MOSI),
  .MISO(MISO)
);

endmodule