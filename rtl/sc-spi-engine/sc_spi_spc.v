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

module sc_spi_spc # (
  parameter NUM_OF_CS = 32
) (
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
  input [4:0] CSSEL,
  input SPISTART,            // SPI Transfer Start
  output reg SPIBUSY,        // SPI Busy
  input BORDER,              // SPI Byte Order
  input [31:0] TXDATA,       // SPI Transfer Data
  output [3:0] TXDPT,        // SPI Transfer buffer pointer
  output reg [31:0] RXDATA,  // SPI Receive Data
  output reg RXVALID,        // SPI Receive Data Valid
  output reg [3:0] RXDPT,    // SPI Receive buffer pointer

  // SPI Interface
  output reg [NUM_OF_CS-1:0] CSB,
                             // SPI Chip Select Signal
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
reg [NUM_OF_CS-1:0] cs_r, cs_f;     // SPI Chip Select
reg mosi_r, mosi_f;                 // SPI Master Out, Slave In
reg [31:0] swapTXData;              // Swapping TX Data
reg rxdat, rxdat_r, rxdat_f;        // SPI RX Data (1 bit)
reg [31:0] rxdpara;                 // SPI RX Data (Parallel)
wire [4:0] bpos_tx, bpos_rx;        // Bit Position
assign bpos_tx = fc2bit(fc, DWIDTH);
assign TXDPT = fc2word(fc);

// ----------
// Byte Swapping
// --------------------------------------------------
always @ (*) begin
  if (BORDER)
    swapTXData = TXDATA;
  else
    swapTXData = {TXDATA[7:0], TXDATA[15:8], TXDATA[23:16], TXDATA[31:24]};
end

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
assign bpos_rx = fc2bit(fc_rx, DWIDTH);
always @ (posedge SPICLK or negedge SYSRSTB) begin
  if (!SYSRSTB) begin
    rxdpara <= 32'h0000_0000;
    fvalid <= 1'b0;
    fc_rx <= 0;
    RXVALID <= 1'b0;
  end
  else begin
    RXVALID <= 1'b0;

    if (fvalid) begin
      rxdpara[bpos_rx] <= rxdat;
      fc_rx <= fc;
      if (fc_rx == DWIDTH)
        fvalid <= 1'b0;
      if ((!BORDER & bpos_rx == 0) | (BORDER & bpos_rx == 24)) begin
        RXDPT <= fc2word(fc_rx);
        RXDATA <= {rxdpara[31:1], rxdat};
        RXVALID <= 1'b1;
      end
    end
    else if (spist == spiIDLE)
      rxdpara <= 32'h0000_0000;
    else if (spist == spiDATA)
      fvalid <= 1'b1;
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
      cs_r[CSSEL] <= 1'b1;
    else if (!CSEXTEND & spist == spiIDLE)
      cs_r <= 0;

    // Clock Enable
    clken_r <= (spist == spiDATA);

    // SPI TX/RX Data
    if (spist == spiDATA)
      mosi_r <= swapTXData[bpos_tx];
    else
      mosi_r <= 1'b0;

    // SPI RX Data
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
      cs_f[CSSEL] <= 1'b1;
    else if (!CSEXTEND & spist == spiIDLE)
      cs_f <= 1'b0;

    // Clock Enable
    clken_f <= (spist == spiDATA);

    // SPI TX/RX Data
    if (spist == spiDATA)
      mosi_f <= swapTXData[bpos_tx];
    else
      mosi_f <= 1'b0;

    // SPI RX Data
    rxdat_f <= MISO;
  end
end

always @ (*) begin
  case ({CPOL, CPHA})
    0: begin
      CSB  = ~cs_f;
      SCLK = (clken_f) ? SPICLK: 1'b0;
      MOSI = mosi_f;
      rxdat = rxdat_r;
    end
    1: begin
      CSB  = ~cs_r;
      SCLK = (clken_r) ? SPICLK: 1'b0;
      MOSI = mosi_r;
      rxdat = rxdat_f;
    end
    2: begin
      CSB  = ~cs_r;
      SCLK = (clken_r) ? SPICLK: 1'b1;
      MOSI = mosi_r;
      rxdat = rxdat_f;
    end
    default: begin
      CSB  = ~cs_f;
      SCLK = (clken_f) ? SPICLK: 1'b1;
      MOSI = mosi_f;
      rxdat = rxdat_r;
    end
  endcase
end

function [3:0] fc2word;
  input [8:0] fc;
begin
  fc2word = fc[8:5];
end
endfunction

function [4:0] fc2bit;
  input [8:0] fc;
  input [8:0] dw;
begin
  // Last Byte
  if (dw[8:3] == fc[8:3])
    fc2bit = (fc[4:3] * 8) + (dw[2:0] - fc[2:0]);
  else
    fc2bit = (fc[4:3] * 8) + (7 - fc[2:0]);
end
endfunction

endmodule
