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
//  Module: SPI Lite Register Package
//-----------------------------------------------------------------------------

`ifndef _SC_SPI_LITE_PKG_SV_
`define _SC_SPI_LITE_PKG_SV_

`timescale 1ps/1ps

package sc_spil_pkg;

import sc_ipreg_pkg::*;

`include "sc_spil_reg_const_param.vh"

// ----
// SPI-Lite Transaction Control Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [31:25] reserved3;                             // Reserved
  logic [8:0] FMSIZE;                                  // SPI Frame Size
  logic CSEXTEND;                                      // SPI CS Extend Mode
  logic [14:13] reserved2;                             // Reserved
  logic [4:0] CSSEL;                                   // SPI CS Select
  logic [7:1] reserved1;                               // Reserved
  logic STARTBUSY;                                     // SPI START and Busy
} SPL_TRC_s;

const SPL_TRC_s SPL_TCR_INIT_VALUE = {11'h0, FMSIZE_INIT_VALUE, CSEXTEND_INIT_VALUE, 2'h0, CSSEL_INIT_VALUE, 7'h0, 1'b0};
const SPL_TRC_s SPL_TCR_CONST_BITS = {11'h0, FMSIZE_CONST_BITS, CSEXTEND_CONST_BITS, 2'h0, CSSEL_CONST_BITS, 7'h0, 1'b0};

// Register Parameter
const sc_reg_param SPL_TRC_p = {16'h0000,              // Base addres
                                32'h01FF_9F01,         // Valid
                                32'h01FF_9F00,         // Write
                                32'h0000_0001,         // Write set
                                32'h0000_0000,         // Write clear
                                32'h0000_0000,         // Read only
                                SPL_TCR_INIT_VALUE,    // Initial Value
                                SPL_TCR_CONST_BITS};   // Constant

// ----
// SPI-Lite Transaction Format Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [31:24] reserved2;                             // Reserved
  logic [3:0] CSHOLD;                                  // SPI CS Hold
  logic [3:0] CSSETUP;                                 // SPI CS Setup
  logic [15:10] reserved1;                             // Reserved
  logic CPHA;                                          // SPI Clock Phase
  logic CPOL;                                          // SPI Clock Polarity
  logic [7:0] CLKDR;                                   // SPI Clock Divide Rate
} SPL_TRF_s;

const SPL_TRF_s SPL_TRF_INIT_VALUE = {8'h0, CSHOLD_INIT_VALUE, CSSETUP_INIT_VALUE,
                                      5'h0, CPHA_INIT_VALUE, CPOL_INIT_VALUE, CLKDR_INIT_VALUE};
const SPL_TRF_s SPL_TRF_CONST_BITS = {8'h0, CSHOLD_CONST_BITS, CSSETUP_CONST_BITS,
                                      5'h0, CPHA_CONST_BITS, CPOL_CONST_BITS, CLKDR_CONST_BITS};

// Register Parameter
const sc_reg_param SPL_TRF_p = {16'h0004,              // Base addres
                                32'h00FF_03FF,         // Valid
                                32'h00FF_03FF,         // Write
                                32'h0000_0000,         // Write set
                                32'h0000_0000,         // Write clear
                                32'h0000_0000,         // Read only
                                SPL_TRF_INIT_VALUE,    // Initial Value
                                SPL_TRF_CONST_BITS};   // Constant

// ----
// SPI-Lite Interrupt Status Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [31:1] reserved1;                              // Reserved
  logic COMPST;                                        // SPI Complite Status
} SPL_IST_s;

// Register Parameter
const sc_reg_param SPL_IST_p = {16'h0010,              // Base addres
                                32'h0000_0001,         // Valid
                                32'h0000_0000,         // Write
                                32'h0000_0000,         // Write set
                                32'h0000_0001,         // Write clear
                                32'h0000_0000,         // Read only
                                32'h0000_0000,         // Initial Value
                                32'h0000_0000};        // Constant

// ----
// SPI-Lite Interrupt Enable Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [31:1] reserved1;                              // Reserved
  logic COMPEN;                                        // SPI Complite Enable
} SPL_IEN_s;

// Register Parameter
const sc_reg_param SPL_IEN_p = {16'h0014,              // Base addres
                                32'h0000_0001,         // Valid
                                32'h0000_0001,         // Write
                                32'h0000_0000,         // Write set
                                32'h0000_0000,         // Write clear
                                32'h0000_0000,         // Read only
                                32'h0000_0000,         // Initial Value
                                32'h0000_0000};        // Constant

// ----
// SPI-Lite TXD Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [31:0] TXD;                                    // Transmit Data
} SPL_TXD_s;

// Register Parameter
const sc_reg_param SPL_TXD_p = {16'h0020,              // Base addres
                                32'hFFFF_FFFF,         // Valid
                                32'hFFFF_FFFF,         // Write
                                32'h0000_0000,         // Write set
                                32'h0000_0000,         // Write clear
                                32'h0000_0000,         // Read only
                                32'h0000_0000,         // Initial Value
                                32'h0000_0000};        // Constant

// ----
// SPI-Lite RXD Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [31:0] RXD;                                    // Receive Data
} SPL_RXD_s;

// Register Parameter
const sc_reg_param SPL_RXD_p = {16'h0060,              // Base addres
                                32'h0000_0000,         // Valid
                                32'h0000_0000,         // Write
                                32'h0000_0000,         // Write set
                                32'h0000_0000,         // Write clear
                                32'hFFFF_FFFF,         // Read only
                                32'h0000_0000,         // Initial Value
                                32'h0000_0000};        // Constant

// ----
// SPI-Lite Operation Mode Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [31:9] reserved2;                              // Reserved
  logic BORDER;                                        // Byte Order
  logic [7:1] reserved1;                               // Reserved
  logic TXSTM;                                         // Transaction Start Mode
} SPL_OPM_s;

// Register Parameter
const sc_reg_param SPL_OPM_p = {16'h00A0,              // Base addres
                                32'h0000_0101,         // Valid
                                32'h0000_0101,         // Write
                                32'h0000_0000,         // Write set
                                32'h0000_0000,         // Write clear
                                32'h0000_0000,         // Read only
                                32'h0000_0001,         // Initial Value
                                32'h0000_0000};        // Constant

// ----
// SPI-Lite Configuration Register
// --------------------------------------------------

// Register Description
typedef struct packed {
  logic [31:5] reserved2;                              // Reserved
  logic [14:12] NOCS;                                  // Number of Chip Select
  logic [7:5] reserved1;                               // Reserved
  logic [4:0] NOBUF;                                   // Number of Buffer
} SPL_CFG_s;

// Register Parameter
const sc_reg_param SPL_CFG_p = {16'h00A4,              // Base addres
                                32'h0000_1F1F,         // Valid
                                32'h0000_0000,         // Write
                                32'h0000_0000,         // Write set
                                32'h0000_0000,         // Write clear
                                32'h0000_1F1F,         // Read only
                                32'hxxxx_xxxx,         // Initial Value
                                32'h0000_0000};        // Constant

// ----
// SPI-Lite Version Register
// --------------------------------------------------

// Register Description
const sc_reg_param SPL_VER_p =  {16'h00F0,             // Base addres
                                 32'h0000_0000,        // Valid
                                 32'h0000_0000,        // Write
                                 32'h0000_0000,        // Write set
                                 32'h0000_0000,        // Write clear
                                 32'hFFFF_FFFF,        // Read only
                                 32'hxxxx_xxxx,        // Initial Value
                                 32'h0000_0000};       // Constant

// Register Parameter
typedef struct packed {
  logic [7:0] MAJOR_VER;                               // Major Version
  logic [7:0] MINOR_VER;                               // Minor Version
  logic [15:0] PATCH_VER;                              // Patch Version
} SPL_VER_s;

// Register Address Decode Function
// --------------------------------------------------
function reg_hit_buf;
  input sc_reg_param rp; // register param
  input [31:0] of;       // offset address
  input [31:0] cb;       // compare bit
  input [31:0] ad;       // access address
  input [3:0] en;        // write enable
begin
  reg_hit_buf = en & ((ad & cb) == ((rp.addr + of * 4'h4) & cb));
end
endfunction

endpackage
`endif
