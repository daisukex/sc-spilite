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
//  Module: SPI Protocol Controller (sc_spi_spc)
//-----------------------------------------------------------------------------

module sc_spi_spc (
  // System Control
  input SPICLK,
  input SYSRSTB,

  // SPI Wave Parameter
  input [3:0] CSSETUP,       // CSB Setup
  input [3:0] CSHOLD,        // CSB Hold
  input [8:0] DWIDTH,        // Data Width
  input CPOL,                // Clock POLarity
  input CPHA,                // Clock PHAse

  // SPI Control Interface
  input CSEXTEND,            // CS Extend signal
  input SPISTART,            // SPI Transfer Start
  output reg SPIBUSY,        // SPI Busy
  input BORDER,              // SPI Byte Order
  input [31:0] TXDATA,       // SPI Transfer Data
  output [3:0] TXDPT,        // SPI Transfer buffer pointer
  output reg [31:0] RXDATA,  // SPI Receive Data
  output reg RXVALID,        // SPI Receive Data Valid
  output reg [3:0] RXDPT,    // SPI Receive buffer pointer

  // SPI Interface
  output reg CSB,            // SPI Chip Select Signal
  output reg SCLK,           // SPI Clock Signal
  output reg MOSI,           // SPI Master Out, Slave In
  input MISO                 // SPI Master In, Slave Out
);

// ----------
// Internal Signal Declaration
// --------------------------------------------------
reg fvalid;                         // Frame Valid signal
reg [1:0] spist;                    // SPI State
localparam spiIDLE = 0,             // - IDLE State
           spiCSS  = 1,             // - Chip Select Setup State
           spiDATA = 2,             // - Data Transfer State
           spiCSH  = 3;             // - Chip Select Hold State
reg [8:0] fc, fc_rx;                // - SPI Frame Count

// SPI signal
reg clken_r, clken_f;               // SPI Clock Enable
reg cs_r, cs_f;                     // SPI Chip Select 
reg mosi_r, mosi_f;                 // SPI Master Out, Slave In
reg rxdat, rxdat_r, rxdat_f;        // SPI RX Data (1 bit)
reg [31:0] rxdpara;                 // SPI RX Data (Parallel)
wire [4:0] bpos_tx, bpos_rx;        // Bit Position
assign bpos_tx = fc2bit(BORDER, fc, DWIDTH);
assign TXDPT = fc2word(BORDER, fc, DWIDTH);

// ----------
// SPI Transmit State Machine
// --------------------------------------------------
always @ (posedge SPICLK or negedge SYSRSTB) begin
  if (!SYSRSTB) begin
    fc <= 0;
    SPIBUSY <= 1'b0;
    spist <= spiIDLE;
  end
  else begin

    // spiIDLE state
    // ----------------------------------------
    if (spist == spiIDLE) begin
      SPIBUSY <= 1'b0;
      if (SPISTART & !SPIBUSY) begin
        SPIBUSY <= 1'b1;
        fc <= 0;
        if (CSSETUP != 0)
          spist <= spiCSS;
        else
          spist <= spiDATA;
      end
    end

    // spiCSS (Chip Select Setup) state
    // ----------------------------------------
    else if (spist == spiCSS) begin
      if (fc == CSSETUP - 1) begin
        fc <= 0;
        spist <= spiDATA;
      end
      else
        fc <= fc + 1;
    end

    // spiDATA (Data Transfer) state
    // ----------------------------------------
    else if (spist == spiDATA) begin
      if (fc == DWIDTH) begin
        if (CSHOLD != 0) begin
          fc <= 0;
          spist <= spiCSH;
        end
        else
          spist <= spiIDLE;
      end
      else
        fc <= fc + 1;
    end
 
    // spiCSH (Chip Select Hold) state
    // ----------------------------------------
    else if (spist == spiCSH) begin
      if (fc == CSHOLD - 1) begin
        fc <= 0;
        spist <= spiIDLE;
      end
      else
        fc <= fc + 1;
    end
  end
end

// ----------
// RX Data Control
// --------------------------------------------------
assign bpos_rx = fc2bit(BORDER, fc_rx, DWIDTH);
always @ (posedge SPICLK or negedge SYSRSTB) begin
  if (!SYSRSTB) begin
    rxdpara <= 32'h0000_0000;
    fvalid <= 1'b0;
    fc_rx <= 0;
    RXVALID <= 1'b0;
  end
  else begin
    RXVALID <= 1'b0;

    if (fvalid & fc_rx == DWIDTH)
      fvalid <= 1'b0;
    else if (spist == spiDATA)
      fvalid <= 1'b1;

    rxdpara[bpos_rx] <= rxdat;

    if (fvalid) begin
      fc_rx <= fc;
      if ((!BORDER & bpos_rx == 0) | (BORDER & bpos_rx == 24)) begin
        RXDPT <= fc2word(BORDER, fc_rx, DWIDTH);
        RXDATA <= {rxdpara[31:1], rxdat};
        RXVALID <= 1'b1;
      end
    end
  end
end

// ----------
// SPI Signals
// --------------------------------------------------
// Synchronous Riging Clock
always @ (posedge SPICLK or negedge SYSRSTB) begin
  if (!SYSRSTB) begin
    clken_r <= 1'b0;
    cs_r <= 1'b0;
    mosi_r <= 1'b0;
    rxdat_r <= 0;
  end
  else begin

    // Chip Select
    if (spist == spiCSS | spist == spiDATA)
      cs_r <= 1'b1;
    else if (!CSEXTEND & spist == spiIDLE)
      cs_r <= 1'b0;

    // Clock Enable
    clken_r <= (spist == spiDATA);

    // SPI TX/RX Data
    if (spist == spiDATA)
      mosi_r <= TXDATA[bpos_tx];
    else
      mosi_r <= 1'b0;

    // SPI RX Data
    if (clken_f)
      rxdat_r <= MISO;
  end
end

// Synchronous Falling Clock
always @ (negedge SPICLK or negedge SYSRSTB) begin
  if (!SYSRSTB) begin
    clken_f <= 1'b0;
    cs_f <= 1'b0;
    mosi_f <= 1'b0;
    rxdat_f <= 0;
  end
  else begin

    // Chip Select
    if (spist == spiCSS | spist == spiDATA)
      cs_f <= 1'b1;
    else if (!CSEXTEND & spist == spiIDLE)
      cs_f <= 1'b0;

    // Clock Enable
    clken_f <= (spist == spiDATA);

    // SPI TX/RX Data
    if (spist == spiDATA)
      mosi_f <= TXDATA[bpos_tx];
    else
      mosi_f <= 1'b0;

    // SPI RX Data
    if (clken_r)
      rxdat_f <= MISO;
  end
end

always @ (*) begin
  case ({CPOL, CPHA})
    0, 3: begin
      CSB  = ~cs_f;
      SCLK = (clken_f) ? SPICLK: 1'b0;
      MOSI = mosi_f;
      rxdat = rxdat_r;
    end
    default: begin
      CSB  = ~cs_r;
      SCLK = (clken_r) ? SPICLK: 1'b0;
      MOSI = mosi_r;
      rxdat = rxdat_f;
    end
  endcase
end

function [3:0] fc2word;
  input md;
  input [8:0] fc;
  input [8:0] dw;
  reg [8:0] bp;
begin
  if (!md) begin
    bp = $unsigned(dw - fc);
    fc2word = bp[8:5];
  end
  else begin
    fc2word = fc[8:5];
  end
end
endfunction

function [4:0] fc2bit;
  input md;
  input [8:0] fc;
  input [8:0] dw;
  reg [8:0] bp;
begin
  if (!md) begin
    bp = $unsigned(dw - fc);
    fc2bit = bp[4:0];
  end
  else begin
    if (dw[8:3] == fc[8:3])
      fc2bit = {fc[4:3], 3'b000} + (7 - (dw[2:0] - fc[2:0]));
    else
      fc2bit = {fc[4:3], 3'b000} + (7 - fc[2:0]);
  end
end
endfunction

endmodule
