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
//  Module: sc_spil_reg: SPI Lite Register
//-----------------------------------------------------------------------------

module sc_spil_reg
  import screg_pkg::*;
# (
  parameter NUM_CS = 32,
  parameter BUFFER_DEPTH = 1
) (
  // System Interface
  input SYSCLK,
  input SYSRSTB,
  output INTERRUPT,

  // Register Interface
  sc_regbus_if.regif REGBUS,

  // SPI Lite Core Interface
  output [4:0] CSSEL,
  output CSEXTEND,
  output logic TXSTART,
  input SPIBUSY,
  input SPICOMPLETE,
  output BORDER,
  input DATACLK,
  output [31:0] TXDATA,
  input [3:0] TXDPT,
  input [31:0] RXDATA,
  input [3:0] RXDPT,
  input RXVALID,
  output logic [7:0] CLKHIGH,
  output logic [7:0] CLKLOW,
  output [3:0] CSSETUP,
  output [3:0] CSHOLD,
  output [8:0] DWIDTH,
  output CPOL,
  output CPHA
);


// Declaration of base variable for register framework
//------------------------------------------------------
`include "sc_spil_version.vh"
`include "sc_spil_reg_desc.svh"

sc_regbus_t bus;
always_comb begin
  bus.wadr = REGBUS.WADR;
  bus.wtyp = REGBUS.WTYP;
  bus.wenb = REGBUS.WENB;
  bus.wdat = REGBUS.WDAT;
  REGBUS.WWAT = bus.wwat;
  REGBUS.WERR = bus.werr;
  bus.radr = REGBUS.RADR;
  bus.rtyp = REGBUS.RTYP;
  bus.renb = REGBUS.RENB;
  REGBUS.RDAT = bus.rdat;
  REGBUS.RWAT = bus.rwat;
  REGBUS.RERR = bus.rerr;
end

assign bus.wwat = 1'b0;
assign bus.werr = 1'b0;
assign bus.rwat = 1'b0;
assign bus.rerr = 1'b0;


// IP Version/Configuration Register
//--------------------------------------------
IPVER_s IPVER;
IPCONF_s IPCONF;
always_comb begin
  IPVER  = reg_reset(reg_table[get_idx(IPVER_desc, 0)]);
  IPCONF = reg_reset(reg_table[get_idx(IPCONF_desc, 0)]);
end


// Reset Control Register
//--------------------------------------------
logic reg_rst_b;
(* dont_touch = "yes" *) RSTCTRL_s [2:0] RSTCTRL /* synthesis syn_preserve = 1 */;

always_ff @ (posedge SYSCLK) begin
  if (!SYSRSTB)
    RSTCTRL <= reg_reset_tmr(reg_table[get_idx(RSTCTRL_desc, 0)]);
  else
    RSTCTRL <= reg_write_tmr(reg_table[get_idx(RSTCTRL_desc, 0)], bus);
end
RSTCTRL_s rstctrl_data;
assign rstctrl_data = reg_mvote(RSTCTRL);
assign reg_rst_b = ~rstctrl_data.ip_reset;


// Scratch Pad Register
//--------------------------------------------
SCRPAD_s SCRPAD;

always_ff @ (posedge SYSCLK) begin
  if (!reg_rst_b)
    SCRPAD <= reg_reset(reg_table[get_idx(SCRPAD_desc, 0)]);
  else
    SCRPAD <= reg_write(reg_table[get_idx(SCRPAD_desc, 0)], bus);
end


// SPI-Lite Interrupt Status/Enable Register
//--------------------------------------------
INT_s INTSTATS;
INT_s INTENB;

always_ff @ (posedge SYSCLK) begin
  if (!reg_rst_b) begin
    INTSTATS <= reg_reset(reg_table[get_idx(INTST_desc, 0)]);
    INTENB   <= reg_reset(reg_table[get_idx(INTEN_desc, 0)]);
  end
  else begin
    INTSTATS <= reg_write(reg_table[get_idx(INTST_desc, 0)], bus);
    INTENB   <= reg_write(reg_table[get_idx(INTEN_desc, 0)], bus);
    if (SPICOMPLETE)
      INTSTATS.trans_comp <= 1'b1;
  end
end
assign INTERRUPT = |(INTSTATS & INTENB);


// SPI-Lite Transaction Control Register
//--------------------------------------------
TRC_s TRCTRL, rd_TRCTRL;

always_ff @ (posedge SYSCLK) begin
  if (!reg_rst_b)
    TRCTRL <= reg_reset(reg_table[get_idx(TRC_desc, 0)]);
  else begin
    TRCTRL <= reg_write(reg_table[get_idx(TRC_desc, 0)], bus);
    if (TRCTRL.startbusy)
      TRCTRL.startbusy <= 1'b0;
  end
end

assign DWIDTH   = TRCTRL.fmsize;
assign CSEXTEND = TRCTRL.csextend;
assign CSSEL    = TRCTRL.cssel;

always_comb begin
  rd_TRCTRL = TRCTRL;
  rd_TRCTRL.startbusy = SPIBUSY;
end


// SPI-Lite Transaction Format Register
//--------------------------------------------
TRF_s TRFORMAT;

always_ff @ (posedge SYSCLK) begin
  if (!reg_rst_b)
    TRFORMAT <= reg_reset(reg_table[get_idx(TRF_desc, 0)]);
  else
    TRFORMAT <= reg_write(reg_table[get_idx(TRF_desc, 0)], bus);
end

assign CSHOLD  = TRFORMAT.cshold;
assign CSSETUP = TRFORMAT.cssetup;
assign CPHA    = TRFORMAT.cpha;
assign CPOL    = TRFORMAT.cpol;

logic [7:0] divrate;
assign divrate = (TRFORMAT.clkdr < 2) ? 2: TRFORMAT.clkdr;
always_comb begin
  if ((divrate %2) == 0) begin
    CLKHIGH = divrate/2;
    CLKLOW  = divrate/2;
  end
  else begin
    case ({CPOL, CPHA})
      0, 3: begin
        CLKHIGH = divrate/2;
        CLKLOW  = divrate/2 + 1;
      end
      1, 2: begin
        CLKHIGH = divrate/2 + 1;
        CLKLOW  = divrate/2;
      end
    endcase
  end
end


// SPI-Lite Operation Mode Register
//--------------------------------------------
OPM_s OPMODE;

always_ff @ (posedge SYSCLK) begin
  if (!reg_rst_b)
    OPMODE <= reg_reset(reg_table[get_idx(OPM_desc, 0)]);
  else
    OPMODE <= reg_write(reg_table[get_idx(OPM_desc, 0)], bus);
end
assign BORDER = OPMODE.boder;

// SPI Transaction Start
always @ (posedge SYSCLK) begin
  sc_reg_event_t evt;
  if (!reg_rst_b)
    TXSTART <= 1'b0;
  else begin
    if (TXSTART & SPIBUSY)
      TXSTART <= 1'b0;
    else if (!OPMODE.stmode & TRCTRL.startbusy)
      TXSTART <= 1'b1;
    else if (OPMODE.stmode &
             is_valid_reg_write(reg_table[get_idx(TRC_desc, BUF_LINE -1)], bus, evt))
      TXSTART <= 1'b1;
  end
end


// SPI-Lite Transmit/Receive Data Register
//--------------------------------------------
TRXD_s TXD [BUFFER_DEPTH];
TRXD_s RXD [BUFFER_DEPTH];

always_ff @ (posedge SYSCLK) begin
  for (int i=0; i<BUFFER_DEPTH; i++) begin
    if (!reg_rst_b)
      TXD[i] <= reg_reset(reg_table[get_idx(TXD_desc, i)]);
    else
      TXD[i] <= reg_write(reg_table[get_idx(TXD_desc, i)], bus);
  end
end
assign TXDATA = TXD[TXDPT];

always_ff @ (posedge SYSCLK) begin
  if (!reg_rst_b)
    for (int i=0; i<BUFFER_DEPTH; i++)
      RXD[i] <= reg_reset(reg_table[get_idx(RXD_desc, i)]);
  else if (RXVALID)
    RXD[RXDPT] <= RXDATA;
end


// Register Read Logic
//----------------------------------
always_ff @ (posedge SYSCLK) begin
  sc_reg_event_t re;
  if (!SYSRSTB)
    bus.rdat <= '0;
  else begin
    bus.rdat <= '0;
    for(int i=0; i<(RESERVED_ADDR_SIZE>>2); i++) begin
      if (is_valid_reg_read(reg_table[i], bus, re))
        bus.rdat <= re.data;
    end
  end
end

// Register Table
//--------------------------------------------
always_comb begin                     // Descriptor    Data                Reg ID
  reg_table[get_idx(IPVER_desc, 0)]   = {IPVER_desc,   IPVER,              32'h0};
  reg_table[get_idx(IPCONF_desc, 0)]  = {IPCONF_desc,  IPCONF,             32'h0};
  reg_table[get_idx(RSTCTRL_desc, 0)] = {RSTCTRL_desc, reg_mvote(RSTCTRL), 32'h0};
  reg_table[get_idx(SCRPAD_desc, 0)]  = {SCRPAD_desc,  SCRPAD,             32'h0};
  reg_table[get_idx(INTST_desc, 0)]   = {INTST_desc,   INTSTATS,           32'h0};
  reg_table[get_idx(INTEN_desc, 0)]   = {INTEN_desc,   INTENB,             32'h0};
  reg_table[get_idx(TRC_desc, 0)]     = {TRC_desc,     TRCTRL,             32'h0};
  reg_table[get_idx(TRF_desc, 0)]     = {TRF_desc,     TRFORMAT,           32'h0};
  reg_table[get_idx(OPM_desc, 0)]     = {OPM_desc,     OPMODE,             32'h0};
  for (int i=0; i<BUFFER_DEPTH; i++) begin
    reg_table[get_idx(TXD_desc, 0)]   = {TXD_desc,     TXD[i],             32'h0};
    reg_table[get_idx(RXD_desc, 0)]   = {RXD_desc,     RXD[i],             32'h0};
  end
end

endmodule
