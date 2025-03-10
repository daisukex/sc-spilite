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
// Space Cubics Standard IP Core
//  SPI Protocol Engine
//  Module: SPI Protocol Engine Top (sc_spi_engine)
//-----------------------------------------------------------------------------

module sc_spi_engine # (
  parameter NUM_OF_CS = 32
) (
  // System Control
  // ------------------------
  input SYSCLK,
  input SRCCLK,
  input SYSRSTB,

  // SPI Signal from Register
  // ------------------------
  input [7:0] CLKHIGH,
  input [7:0] CLKLOW,
  input [3:0] CSSETUP,
  input [3:0] CSHOLD,
  input [8:0] DWIDTH,
  input CPOL,
  input CPHA,

  input BORDER,
  input TXSTART,
  input CSEXTEND,
  input [4:0] CSSEL,
  output SPIBUSY,
  output SPICOMPLETE,

  // Data Interface
  // ------------------------
  output DATACLK,
  input [31:0] TXDATA,
  output [3:0] TXDPT,
  output [31:0] RXDATA,
  output [3:0] RXDPT,
  output RXVALID,

  // SPI Interface
  // ------------------------
  output [NUM_OF_CS-1:0] CSB,
  output SCLK,
  output MOSI,
  input MISO
);

wire SPICLK;
wire CLK_ENABLE;
wire CLK_ENABLE_SRCCLK;
wire [7:0] CLK_WIDTH_HIGH;
wire [7:0] CLK_WIDTH_LOW;
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
wire [4:0] SPC_CSSEL;
wire SPC_BORDER;

// ----------
// SPI Transfer Controller
// --------------------------------------------------
sc_spi_stc stc (
  // System Control
  .SYSCLK(SYSCLK),
  .SYSRSTB(SYSRSTB),

  // SPI Signal from Register
  .CLKHIGH(CLKHIGH),
  .CLKLOW(CLKLOW),
  .CSSETUP(CSSETUP),
  .CSHOLD(CSHOLD),
  .DWIDTH(DWIDTH),
  .CPOL(CPOL),
  .CPHA(CPHA),

  .TXSTART(TXSTART),
  .CSEXTEND(CSEXTEND),
  .CSSEL(CSSEL),
  .BORDER(BORDER),
  .SPIBUSY(SPIBUSY),
  .SPICOMPLETE(SPICOMPLETE),

  // SPI Signal to SCG
  .CLK_ENABLE(CLK_ENABLE),
  .CLK_WIDTH_HIGH(CLK_WIDTH_HIGH),
  .CLK_WIDTH_LOW(CLK_WIDTH_LOW),

  // SPI Signal to SPC
  .SPC_CSSETUP(SPC_CSSETUP),
  .SPC_CSHOLD(SPC_CSHOLD),
  .SPC_DWIDTH(SPC_DWIDTH),
  .SPC_CPOL(SPC_CPOL),
  .SPC_CPHA(SPC_CPHA),

  .SPC_SPISTART(SPC_SPISTART),
  .SPC_SPIBUSY(SPC_SPIBUSY_SYSCLK),
  .SPC_CSEXTEND(SPC_CSEXTEND),
  .SPC_CSSEL(SPC_CSSEL),
  .SPC_BORDER(SPC_BORDER)
);

// ----------
// SPI Signal Synchronizer
// --------------------------------------------------
sc_spi_sss sss (
  .SYSCLK(SYSCLK),
  .CLKEN(CLK_ENABLE),
  .SPIBUSY_SYSCLK(SPC_SPIBUSY_SYSCLK),
  .SRCCLK(SRCCLK),
  .CLKEN_SRCCLK(CLK_ENABLE_SRCCLK),
  .SPIBUSY(SPC_SPIBUSY)
);

// ----------
// SPI Clock Generator
// --------------------------------------------------
sc_spi_scg scg (
  .SRCCLK(SRCCLK),
  .SYSRSTB(SYSRSTB),
  .CLK_WIDTH_HIGH(CLK_WIDTH_HIGH),
  .CLK_WIDTH_LOW(CLK_WIDTH_LOW),
  .CLK_MODE({SPC_CPOL, SPC_CPHA}),
  .CLK_ENABLE(CLK_ENABLE_SRCCLK),
  .SPICLK(SPICLK)
);
assign DATACLK = SPICLK;

// ----------
// SPI Protocol Controller
// --------------------------------------------------
sc_spi_spc # (
  .NUM_OF_CS(NUM_OF_CS)
) spc (
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
  .CSSEL(SPC_CSSEL),
  .SPISTART(SPC_SPISTART),
  .SPIBUSY(SPC_SPIBUSY),
  .BORDER(SPC_BORDER),
  .TXDATA(TXDATA),
  .TXDPT(TXDPT),
  .RXDATA(RXDATA),
  .RXVALID(RXVALID),
  .RXDPT(RXDPT),

  // SPI Interface
  .CSB(CSB),
  .SCLK(SCLK),
  .MOSI(MOSI),
  .MISO(MISO)
);

endmodule
