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
//  SPI Lite
//  Module: SPI Lite Register (sc_spil_reg)
//-----------------------------------------------------------------------------

module sc_spil_reg 
  import sc_ipreg_pkg::*;
  import sc_spil_pkg::*;
# (
  parameter NUM_OF_CS = 32,
  parameter NUM_OF_BUF = 1
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

`include "sc_spil_version.vh"

localparam CS_WIDTH = (NUM_OF_CS <= 1) ? 1: $clog2(NUM_OF_CS);
localparam ADDR_DECODE_BITS = 32'h0000_0FFC;
localparam BUF_LINE = (NUM_OF_BUF == 0) ? 1: (NUM_OF_BUF >= 16) ? 16: NUM_OF_BUF;

genvar i;

// ----
// SPI Lite Transaction Control Register
// --------------------------------------------------
logic hit_w_strc, hit_r_strc;
assign hit_w_strc = reg_hit(SPL_TRC_p, ADDR_DECODE_BITS, REGBUS.WADR, |REGBUS.WENB);
assign hit_r_strc = reg_hit(SPL_TRC_p, ADDR_DECODE_BITS, REGBUS.RADR,  REGBUS.RENB);
SPL_TRC_s strc;
SPL_TRC_s rd_strc;

// Register
always @ (posedge SYSCLK) begin
  if (!SYSRSTB)
    strc <= SPL_TRC_p.init;
  else begin
    strc <= reg_wdata(SPL_TRC_p, hit_w_strc, strc, REGBUS.WDAT, REGBUS.WENB);
    if (SPIBUSY)
      strc.STARTBUSY <= 1'b0;
  end
end

always @ (*) begin
  rd_strc = strc;
  rd_strc.CSSEL = CSSEL;
  rd_strc.STARTBUSY = SPIBUSY;
end

assign DWIDTH = strc.FMSIZE;
assign CSEXTEND = strc.CSEXTEND;
assign CSSEL = {{(5-CS_WIDTH){1'b0}}, strc.CSSEL[CS_WIDTH-1:0]};

// ----
// SPI Lite Transaction Format Register
// --------------------------------------------------
logic hit_w_strf, hit_r_strf;
assign hit_w_strf = reg_hit(SPL_TRF_p, ADDR_DECODE_BITS, REGBUS.WADR, |REGBUS.WENB);
assign hit_r_strf = reg_hit(SPL_TRF_p, ADDR_DECODE_BITS, REGBUS.RADR,  REGBUS.RENB);
SPL_TRF_s strf;

// Register
always @ (posedge SYSCLK) begin
  if (!SYSRSTB)
    strf <= SPL_TRF_p.init;
  else
    strf <= reg_wdata(SPL_TRF_p, hit_w_strf, strf, REGBUS.WDAT, REGBUS.WENB);
end

assign CSHOLD = strf.CSHOLD;
assign CSSETUP = strf.CSSETUP;
assign CPHA = strf.CPHA;
assign CPOL = strf.CPOL;

logic [7:0] divrate;
assign divrate = (strf.CLKDR < 2) ? 2: strf.CLKDR;
always @ (*) begin
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

// ----
// SPI Lite Interrupt Status Register
// --------------------------------------------------
logic hit_w_sist, hit_r_sist;
assign hit_w_sist = reg_hit(SPL_IST_p, ADDR_DECODE_BITS, REGBUS.WADR, |REGBUS.WENB);
assign hit_r_sist = reg_hit(SPL_IST_p, ADDR_DECODE_BITS, REGBUS.RADR,  REGBUS.RENB);
SPL_IST_s sist;

// Register
always @ (posedge SYSCLK) begin
  if (!SYSRSTB)
    sist <= SPL_IST_p.init;
  else begin
    if (SPICOMPLETE)
      sist.COMPST <= 1'b1;
    else
      sist <= reg_wdata(SPL_IST_p, hit_w_sist, sist, REGBUS.WDAT, REGBUS.WENB);
  end
end

// ----
// SPI Lite Interrupt Enable Register
// --------------------------------------------------
logic hit_w_sien, hit_r_sien;
assign hit_w_sien = reg_hit(SPL_IEN_p, ADDR_DECODE_BITS, REGBUS.WADR, |REGBUS.WENB);
assign hit_r_sien = reg_hit(SPL_IEN_p, ADDR_DECODE_BITS, REGBUS.RADR,  REGBUS.RENB);
SPL_IEN_s sien;

// Register
always @ (posedge SYSCLK) begin
  if (!SYSRSTB)
    sien <= SPL_IEN_p.init;
  else
    sien <= reg_wdata(SPL_IEN_p, hit_w_sien, sien, REGBUS.WDAT, REGBUS.WENB);
end
assign INTERRUPT = |(sien & sist);

// ----
// SPI Lite TXD Register
// --------------------------------------------------
logic [BUF_LINE-1:0] hit_w_stxd, hit_r_stxd;
SPL_TXD_s stxd [BUF_LINE-1:0];
SPL_TXD_s rd_stxd;
for (i=0; i<BUF_LINE; i=i+1) begin
  assign hit_w_stxd[i] = reg_hit_buf(SPL_TXD_p, i, ADDR_DECODE_BITS, REGBUS.WADR, |REGBUS.WENB);
  assign hit_r_stxd[i] = reg_hit_buf(SPL_TXD_p, i, ADDR_DECODE_BITS, REGBUS.RADR,  REGBUS.RENB);

  // Register
  always @ (posedge SYSCLK) begin
    if (!SYSRSTB)
      stxd[i] <= SPL_TXD_p.init;
    else
      stxd[i] <= reg_wdata(SPL_TXD_p, hit_w_stxd[i], stxd[i], REGBUS.WDAT, REGBUS.WENB);
  end
end
assign TXDATA = stxd[TXDPT];

// ----
// SPI Lite RXD Register
// --------------------------------------------------
logic [BUF_LINE-1:0] hit_r_srxd;
SPL_RXD_s srxd [BUF_LINE-1:0];
SPL_RXD_s rd_srxd;

for (i=0; i<BUF_LINE; i=i+1)
  assign hit_r_srxd[i] = reg_hit_buf(SPL_RXD_p, i, ADDR_DECODE_BITS, REGBUS.RADR, REGBUS.RENB);

// Register
always @ (posedge DATACLK or negedge SYSRSTB) begin
  integer bf;
  if (!SYSRSTB)
    for (bf=0; bf<BUF_LINE; bf=bf+1)
      srxd[bf]  <= 0;
  else if (RXVALID)
    srxd[RXDPT] <= RXDATA;
end

// ----
// SPI-Lite Operation Mode Register
// --------------------------------------------------
logic hit_w_sopm, hit_r_sopm;
assign hit_w_sopm = reg_hit(SPL_OPM_p, ADDR_DECODE_BITS, REGBUS.WADR, |REGBUS.WENB);
assign hit_r_sopm = reg_hit(SPL_OPM_p, ADDR_DECODE_BITS, REGBUS.RADR,  REGBUS.RENB);
SPL_OPM_s sopm;

// Register
always @ (posedge SYSCLK) begin
  if (!SYSRSTB)
    sopm <= SPL_OPM_p.init;
  else
    sopm <= reg_wdata(SPL_OPM_p, hit_w_sopm, sopm, REGBUS.WDAT, REGBUS.WENB);
end
assign BORDER = sopm.BORDER;

// SPI Transaction Start
always @ (posedge SYSCLK) begin
  if (!SYSRSTB)
    TXSTART <= 1'b0;
  else begin
    if (TXSTART & SPIBUSY)
      TXSTART <= 1'b0;
    else if (!sopm.TXSTM & strc.STARTBUSY)
      TXSTART <= 1'b1;
    else if (sopm.TXSTM & hit_w_stxd)
      TXSTART <= 1'b1;
  end
end

// ----
// SPI-Lite Configuration Register
// --------------------------------------------------
logic hit_r_scfg;
assign hit_r_scfg = reg_hit(SPL_CFG_p, ADDR_DECODE_BITS, REGBUS.RADR, REGBUS.RENB);
SPL_CFG_s scfg;
assign scfg.NOCS = NUM_OF_CS;
assign scfg.NOBUF = BUF_LINE;

// ----
// SPI Lite Version Register
// --------------------------------------------------
logic hit_r_sver;
assign hit_r_sver = reg_hit(SPL_VER_p, ADDR_DECODE_BITS, REGBUS.RADR, REGBUS.RENB);
SPL_VER_s sver;
assign sver.MAJOR_VER = MAJVER_VAL;
assign sver.MINOR_VER = MINVER_VAL;
assign sver.PATCH_VER = PATVER_VAL;

// ----
// Register Read Control
//-----------------------------------------------
always @ (posedge SYSCLK) begin
  if (!SYSRSTB)
    REGBUS.RDAT <= 32'h0000_0000;
  else begin
    if (hit_r_strc)        REGBUS.RDAT <= rd_strc;
    else if (hit_r_strf)   REGBUS.RDAT <= strf;
    else if (hit_r_sist)   REGBUS.RDAT <= sist;
    else if (hit_r_sien)   REGBUS.RDAT <= sien;
    else if (|hit_r_stxd)  REGBUS.RDAT <= rd_stxd;
    else if (|hit_r_srxd)  REGBUS.RDAT <= rd_srxd;
    else if (hit_r_sopm)   REGBUS.RDAT <= sopm;
    else if (hit_r_scfg)   REGBUS.RDAT <= scfg;
    else if (hit_r_sver)   REGBUS.RDAT <= sver;
    else                   REGBUS.RDAT <= 32'h0000_0000;
  end
end

always @ (*) begin
  integer bf;
  rd_stxd = 0;
  rd_srxd = 0;
  for (bf=0; bf<BUF_LINE; bf=bf+1) begin
    if (hit_r_stxd[bf])
      rd_stxd = stxd[bf];
    if (hit_r_srxd[bf])
      rd_srxd = srxd[bf];
  end
end

assign REGBUS.WWAT = 1'b0;
assign REGBUS.WERR = 1'b0;

assign REGBUS.RWAT = 1'b0;
assign REGBUS.RERR = 1'b0;

endmodule
