//-----------------------------------------------------------------------------
// Copyright 2025-2026 Space Cubics Inc.
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
//  Module: sc_spil_reg_desc: SPI Lite Register Descriptor
//-----------------------------------------------------------------------------

parameter ADDR_DECODE_MASK = 32'h0000_FFFC;
parameter RESERVED_ADDR_SIZE = (1024);
sc_reg_entry_t [0:(RESERVED_ADDR_SIZE>>2)-1] reg_table = '0;

// IP Version Register
//--------------------------------------------
typedef struct packed {
  logic [7:0]  major_ver;
  logic [7:0]  minor_ver;
  logic [15:0] patch_ver;
} IPVER_s;

// IP Version Value
const IPVER_s IPVER_value = '{major_ver: MAJVER_VAL, minor_ver: MINVER_VAL, patch_ver: PATVER_VAL};

// Register access attributes      WR             W1S            W1C            FIXED
const sc_reg_attr_t IPVER_attr = '{32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};

// Register descriptor
const sc_reg_desc_t IPVER_desc = '{32'h0000_0000,    // ADDR
                                   ADDR_DECODE_MASK, // DMASK
                                   32'h0000_0000,    // OFFSET
                                   IPVER_attr,       // REG ATTR
                                   IPVER_value};     // INIT


// IP Configuration Register
//--------------------------------------------
localparam CS_WIDTH = (NUM_CS <= 1) ? 1: $clog2(NUM_CS);
localparam BUF_LINE = (BUFFER_DEPTH == 0) ? 1: (BUFFER_DEPTH >= 16) ? 16: BUFFER_DEPTH;

typedef struct packed {
  logic [31:11] reserved2; // Reserved
  logic [2:0] num_cs;      // Number of Chip Select
  logic [7:5] reserved1;   // Reserved
  logic [4:0] num_buf;     // Number of Buffer
} IPCONF_s;

const IPCONF_s IPCONF_value = '{num_buf: BUF_LINE, num_cs: NUM_CS, default: '0};

// Register access attributes       WR             W1S            W1C            FIXED
const sc_reg_attr_t IPCONF_attr = '{32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};

// Register descriptor
const sc_reg_desc_t IPCONF_desc = '{32'h0000_0004,    // ADDR
                                    ADDR_DECODE_MASK, // DMASK
                                    32'h0000_0000,    // OFFSET
                                    IPCONF_attr,      // REG ATTR
                                    IPCONF_value};    // INIT


// Reset Control Register
//--------------------------------------------
typedef struct packed {
  logic [31:1] reserved;
  logic ip_reset;
} RSTCTRL_s;

const RSTCTRL_s RSTCTRL_wr = '{ip_reset: '1, default: '0};

// Register access attributes        WR          W1S            W1C            FIXED
const sc_reg_attr_t RSTCTRL_attr = '{RSTCTRL_wr, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};

// Register descriptor
const sc_reg_desc_t RSTCTRL_desc = '{32'h0000_0010,    // ADDR
                                     ADDR_DECODE_MASK, // DMASK
                                     32'h0000_0000,    // OFFSET
                                     RSTCTRL_attr,     // REG ATTR
                                     RSTCTRL_wr};      // INIT


// Scratch Pad Register
//--------------------------------------------
typedef struct packed {
  logic [31:0] scratch_pad;
} SCRPAD_s;

// Register access attributes       WR             W1S            W1C            FIXED
const sc_reg_attr_t SCRPAD_attr = '{32'hFFFF_FFFF, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};

// Register descriptor
const sc_reg_desc_t SCRPAD_desc = '{32'h0000_001C,    // ADDR
                                    ADDR_DECODE_MASK, // DMASK
                                    32'h0000_0000,    // OFFSET
                                    SCRPAD_attr,      // REG ATTR
                                    32'h0000_0000};   // INIT


// SPI-Lite Interrupt Status/Enable Register
//--------------------------------------------
typedef struct packed {
  logic [31:1] reserved1; // Reserved
  logic trans_comp;       // SPI Complite Status
} INT_s;

INT_s INT_present = '{trans_comp: '1, default: '0};

// Interrupt Status
// Register access attributes      WR             W1S            W1C          FIXED
const sc_reg_attr_t INTST_attr = '{32'h0000_0000, 32'h0000_0000, INT_present, 32'h0000_0000};

// Register descriptor
const sc_reg_desc_t INTST_desc = '{32'h0000_0020,    // ADDR
                                   ADDR_DECODE_MASK, // DMASK
                                   32'h0000_0000,    // OFFSET
                                   INTST_attr,       // REG ATTR
                                   32'h0000_0000};   // INIT

// Interrupt Enable
// Register access attributes      WR           W1S            W1C            FIXED
const sc_reg_attr_t INTEN_attr = '{INT_present, 32'h0000_0000, 43'h0000_0000, 32'h0000_0000};

// Register descriptor
const sc_reg_desc_t INTEN_desc = '{32'h0000_0024,    // ADDR
                                   ADDR_DECODE_MASK, // DMASK
                                   32'h0000_0000,    // OFFSET
                                   INTEN_attr,       // REG ATTR
                                   32'h0000_0000};   // INIT


// SPI-Lite Transaction Control Register
//--------------------------------------------
typedef struct packed {
  logic [31:25] reserved3; // Reserved
  logic [8:0] fmsize;      // SPI Frame Size
  logic csextend;          // SPI CS Extend Mode
  logic [14:13] reserved2; // Reserved
  logic [4:0] cssel;       // SPI CS Select
  logic [7:1] reserved1;   // Reserved
  logic startbusy;         // SPI START and Busy
} TRC_s;

const TRC_s TRC_w1s = '{startbusy: '1, default: '0};
const TRC_s TRC_wr  = '{cssel: '1, csextend: '1, fmsize: '1, default: '0};

// Register access attributes    WR       W1S      W1C            FIXED
const sc_reg_attr_t TRC_attr = '{TRC_wr, TRC_w1s, 32'h0000_0000, 32'h0000_0000};

// Register descriptor
const sc_reg_desc_t TRC_desc = '{32'h0000_0100,    // ADDR
                                 ADDR_DECODE_MASK, // DMASK
                                 32'h0000_0000,    // OFFSET
                                 TRC_attr,         // REG ATTR
                                 32'h0000_0000};   // INIT


// SPI-Lite Transaction Format Register
//--------------------------------------------
typedef struct packed {
  logic [31:24] reserved2; // Reserved
  logic [3:0] cshold;      // SPI CS Hold
  logic [3:0] cssetup;     // SPI CS Setup
  logic [15:10] reserved1; // Reserved
  logic cpha;              // SPI Clock Phase
  logic cpol;              // SPI Clock Polarity
  logic [7:0] clkdr;       // SPI Clock Divide Rate
} TRF_s;

const TRF_s TRF_wr   = '{clkdr: '1,   cpol: '1,   cpha: '1,   cssetup: '1,   cshold: '1,   default: '0};
const TRF_s TRF_init = '{clkdr: 8'h1, cpol: 1'b1, cpha: 1'b1, cssetup: 4'h1, cshold: 4'h1, default: '0};

// Register access attributes    WR       W1S            W1C            FIXED
const sc_reg_attr_t TRF_attr = '{TRF_wr, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};

// Register descriptor
const sc_reg_desc_t TRF_desc = '{32'h0000_0104,    // ADDR
                                 ADDR_DECODE_MASK, // DMASK
                                 32'h0000_0000,    // OFFSET
                                 TRF_attr,         // REG ATTR
                                 TRF_init};        // INIT


// SPI-Lite Operation Mode Register
//--------------------------------------------
typedef struct packed {
  logic [31:9] reserved2; // Reserved
  logic boder;            // Byte Order
  logic [7:1] reserved1;  // Reserved
  logic stmode;           // Transaction Start Mode
} OPM_s;

const OPM_s OPM_wr = '{stmode: '1, boder: '1, default: '0};

// Register access attributes    WR      W1S            W1C            FIXED
const sc_reg_attr_t OPM_attr = '{OPM_wr, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};

// Register descriptor
const sc_reg_desc_t OPM_desc = '{32'h0000_0108,    // ADDR
                                ADDR_DECODE_MASK, // DMASK
                                32'h0000_0004,    // OFFSET
                                OPM_attr,         // REG ATTR
                                32'h0000_0000};   // INIT


// SPI-Lite Transmit/Receive Data Register
//--------------------------------------------
typedef struct packed {
  logic [31:0] trxd; // Transmit/Receive Data
} TRXD_s;

const TRXD_s TRXD_wr = '{trxd: '1, default: '0};

// Transmit Data Register
// Register access attributes    WR       W1S            W1C            FIXED
const sc_reg_attr_t TXD_attr = '{TRXD_wr, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};

// Register descriptor
const sc_reg_desc_t TXD_desc = '{32'h0000_0200,    // ADDR
                                 ADDR_DECODE_MASK, // DMASK
                                 32'h0000_0004,    // OFFSET
                                 TXD_attr,         // REG ATTR
                                 32'h0000_0000};   // INIT

// Register access attributes    WR             W1S            W1C            FIXED
const sc_reg_attr_t RXD_attr = '{32'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};

// Register descriptor
const sc_reg_desc_t RXD_desc = '{32'h0000_0300,    // ADDR
                                 ADDR_DECODE_MASK, // DMASK
                                 32'h0000_0004,    // OFFSET
                                 RXD_attr,         // REG ATTR
                                 32'h0000_0000};   // INIT
