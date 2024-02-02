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
  output reg TXDETECT,       // SPI Transfer data detect
  output reg [31:0] RXDATA,  // SPI Receive Data
  output [31:0] LRXDATA,     // SPI Last Receive Data
  output reg RXVALID,        // SPI Receive Data Valid

  // SPI Interface
  output reg CSB,            // SPI Chip Select Signal
  output reg SCLK,           // SPI Clock Signal
  output reg MOSI,           // SPI Master Out, Slave In
  input MISO                 // SPI Master In, Slave Out
);

// ----------
// Internal Signal Declaration
// --------------------------------------------------
reg [1:0] spist;                    // SPI State
localparam spiIDLE = 0,             // - IDLE State
           spiCSS  = 1,             // - Chip Select Setup State
           spiDATA = 2,             // - Data Transfer State
           spiCSH  = 3;             // - Chip Select Hold State
reg [8:0] fc;                       // - SPI Frame Count

// SPI signal
reg [31:0] txd;                     // SPI Transmit data latched by spiclk
reg clken_r, clken_f;               // SPI Clock Enable
reg cs_r, cs_f;                     // SPI Chip Select 
reg mosi_r, mosi_f;                 // SPI Master Out, Slave In
reg [4:0] frxc_r, frxc_f;           // SPI Frame RX Data Count
reg [31:0] rxdat, rxdat_r, rxdat_f; // SPI RX Data
reg rxval, rxval_r, rxval_f;        // SPI RX Valid
wire [4:0] bpos;                    // Bit Position
assign bpos = fc2bit(BORDER, fc, DWIDTH[4:0]);
assign TXDPT = fc2word(BORDER, fc, DWIDTH);

// ----------
// SPI Transmit State Machine
// --------------------------------------------------
always @ (posedge SPICLK or negedge SYSRSTB) begin
  if (!SYSRSTB) begin
    fc <= 0;
    txd <= 8'h0;
    SPIBUSY <= 1'b0;
    TXDETECT <= 1'b0;
    RXVALID <= 1'b0;
    spist <= spiIDLE;
  end
  else begin

    // spiIDLE state
    // ----------------------------------------
    if (spist == spiIDLE) begin
      if (SPISTART & !SPIBUSY) begin
        txd <= TXDATA;
        TXDETECT <= ~TXDETECT;
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
        else begin
          SPIBUSY <= 1'b0;
          spist <= spiIDLE;
        end
      end
      else begin
        fc <= fc + 1;

        // TX Data Control
        if ((!BORDER & bpos == 0) | (BORDER & bpos == 24)) begin
          txd <= TXDATA;
          TXDETECT <= ~TXDETECT;
        end

        // RX Data Control
        if (rxval) begin
          RXDATA <= rxdat;
          RXVALID <= ~RXVALID;
        end
      end
    end
 
    // spiCSH (Chip Select Hold) state
    // ----------------------------------------
    else if (spist == spiCSH) begin
      if (fc == CSHOLD - 1) begin
        fc <= 0;
        SPIBUSY <= 1'b0;
        spist <= spiIDLE;
      end
      else
        fc <= fc + 1;
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
    frxc_r <= 0;
    rxdat_r <= 0;
    rxval_r <= 1'b0;
  end
  else begin
    rxval_r <= 1'b0;

    // Chip Select
    if (spist == spiCSS | spist == spiDATA)
      cs_r <= 1'b1;
    else if (!CSEXTEND & spist == spiIDLE)
      cs_r <= 1'b0;

    // Clock Enable
    clken_r <= (spist == spiDATA);

    // SPI TX/RX Data
    if (spist == spiDATA) begin
      mosi_r <= txd[bpos];
      frxc_r <= fc;
    end
    else
      mosi_r <= 1'b0;

    // SPI RX Data
    if (clken_f) begin
      rxdat_r[bpos] <= MISO;
      if ((!BORDER & bpos == 0) | (BORDER & bpos == 24))
        rxval_r <= 1'b1;
    end
  end
end

// Synchronous Falling Clock
always @ (negedge SPICLK or negedge SYSRSTB) begin
  if (!SYSRSTB) begin
    clken_f <= 1'b0;
    cs_f <= 1'b0;
    mosi_f <= 1'b0;
    frxc_f <= 0;
    rxdat_f <= 0;
  end
  else begin
    rxdat_f <= 0;

    // Chip Select
    if (spist == spiCSS | spist == spiDATA)
      cs_f <= 1'b1;
    else if (!CSEXTEND & spist == spiIDLE)
      cs_f <= 1'b0;

    // Clock Enable
    clken_f <= (spist == spiDATA);

    // SPI TX/RX Data
    if (spist == spiDATA) begin
      mosi_f <= txd[bpos];
      frxc_f <= fc;
    end
    else
      mosi_f <= 1'b0;

    // SPI RX Data
    if (clken_r) begin
      rxdat_f[bpos] <= MISO;
      if ((!BORDER & bpos == 0) | (BORDER & bpos == 24))
        rxval_f <= 1'b1;
    end
  end
end

always @ (*) begin
  case ({CPOL, CPHA})
    0: begin
      CSB  = ~cs_f;
      SCLK = (clken_f) ? SPICLK: 1'b0;
      MOSI = mosi_f;
      rxdat = rxdat_r;
      rxval = rxval_r;
    end
    1: begin
      CSB  = ~cs_r;
      SCLK = (clken_r) ? SPICLK: 1'b0;
      MOSI = mosi_r;
      rxdat = rxdat_f;
      rxval = rxval_f;
    end
    2: begin
      CSB  = ~cs_r;
      SCLK = (clken_r) ? SPICLK: 1'b1;
      MOSI = mosi_r;
      rxdat = rxdat_f;
      rxval = rxval_f;
    end
    default: begin
      CSB  = ~cs_f;
      SCLK = (clken_f) ? SPICLK: 1'b1;
      MOSI = mosi_f;
      rxdat <= rxdat_r;
      rxval <= rxval_r;
    end
  endcase
end
assign LRXDATA = rxdat;

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
