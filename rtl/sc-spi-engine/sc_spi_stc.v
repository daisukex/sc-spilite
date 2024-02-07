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
//  Module: SPI Transfer Controller (sc_spi_stc)
//-----------------------------------------------------------------------------

module sc_spi_stc (
  // System Control
  input SYSCLK,
  input SYSRSTB,

  // SPI Signal from Register
  // ------------------------
  input [7:0] CLKHIGH,          // Clock High Width
  input [7:0] CLKLOW,           // Clock Low Width
  input [3:0] CSSETUP,          // CSB Setup
  input [3:0] CSHOLD,           // CSB Hold
  input [8:0] DWIDTH,           // Data Width
  input CPOL,                   // Clock POLarity
  input CPHA,                   // Clock PHAse

  input BORDER,
  input TXSTART,
  input CSEXTEND,
  output reg SPIBUSY,
  output reg SPICOMPLETE,

  // SPI Signal to SCG
  // -----------------------
  output reg CLK_ENABLE,
  output reg [7:0] CLK_WIDTH_HIGH,
  output reg [7:0] CLK_WIDTH_LOW,

  // SPI Signal to SPC
  // -----------------------
  output reg [3:0] SPC_CSSETUP, // Latched CSB Setup
  output reg [3:0] SPC_CSHOLD,  // Latched CSB Hold
  output reg [8:0] SPC_DWIDTH,  // Latched Data Width
  output reg SPC_CPOL,          // Latched CPOL
  output reg SPC_CPHA,          // Latched CPHA

  output reg SPC_SPISTART,
  input SPC_SPIBUSY,
  output reg SPC_CSEXTEND,
  output reg SPC_BORDER
);

// ----------
// Internal Signal Declaration
// --------------------------------------------------
reg [2:0] state;
localparam txIDLE  = 0,
           txSETUP = 1,
           txEXEC  = 2,
           txTRANS = 3,
           txEND = 4;

reg clksel;
reg [7:0] clock_count;

// ----------
// SPI Transfer Control
// --------------------------------------------------
always @ (posedge SYSCLK) begin
  if (!SYSRSTB) begin
    SPC_SPISTART <= 1'b0;
    SPIBUSY <= 1'b0;
    SPICOMPLETE <= 1'b0;
    CLK_ENABLE <= 1'b0;
    state <= txIDLE;
  end
  else begin
    // Clear TXSTART
    if (SPC_SPISTART & SPC_SPIBUSY)
      SPC_SPISTART <= 1'b0;

    // txIDLE state
    // ----------------------------------------
    if (state == txIDLE) begin
      if (TXSTART) begin
        SPIBUSY <= 1'b1;
        SPC_CSSETUP <= CSSETUP;
        SPC_CSHOLD <= CSHOLD;
        SPC_DWIDTH <= DWIDTH;
        SPC_CPOL <= CPOL;
        SPC_CPHA <= CPHA;
        SPC_CSEXTEND <= CSEXTEND;
        SPC_BORDER <= BORDER;
        CLK_WIDTH_HIGH <= CLKHIGH;
        CLK_WIDTH_LOW <= CLKLOW;
        state <= txSETUP;
      end
    end

    // txSETUP state
    // ----------------------------------------
    else if (state == txSETUP) begin
      SPC_SPISTART <= 1'b1;
      CLK_ENABLE <= 1'b1;
      state      <= txEXEC;
    end

    // txEXEC state
    // ----------------------------------------
    else if (state == txEXEC) begin
      if (SPC_SPIBUSY)
        state <= txTRANS;
    end

    // txTRANS state
    // ----------------------------------------
    else if (state == txTRANS) begin
      if (!SPC_SPIBUSY) begin
        SPICOMPLETE <= 1'b1;
        state <= txEND;
      end
    end

    // txTRANS state
    // ----------------------------------------
    else if (state == txEND) begin
      if (!SPC_SPIBUSY) begin
        SPIBUSY <= 1'b0;
        CLK_ENABLE <= 1'b0;
        SPICOMPLETE <= 1'b0;
        state <= txIDLE;
      end
    end
  end
end

endmodule
