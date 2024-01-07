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
//  SPI Lite
//  Module: SPI Lite Register Constant Parameters
//-----------------------------------------------------------------------------

// ----
// SPI Lite Transaction Control Register
// --------------------------------------------------

// CS Select
parameter [4:0] CSSEL_INIT_VALUE    = 5'h00;
parameter [4:0] CSSEL_CONST_BITS    = 5'h00;

// CS Extend
parameter       CSEXTEND_INIT_VALUE = 1'b0;
parameter       CSEXTEND_CONST_BITS = 1'b0;

// Frame Size
parameter [4:0] FMSIZE_INIT_VALUE   = 5'h00;
parameter [4:0] FMSIZE_CONST_BITS   = 5'h00;

// ----
// SPI Lite Transaction Format Register
// --------------------------------------------------

// Clock Divider
parameter [7:0] CLKDR_INIT_VALUE    = 8'h01;
parameter [7:0] CLKDR_CONST_BITS    = 8'h00;

// SPI Clock Polarity
parameter       CPOL_INIT_VALUE     = 1'b0;
parameter       CPOL_CONST_BITS     = 1'b0;

// SPI Clock Phase
parameter       CPHA_INIT_VALUE     = 1'b0;
parameter       CPHA_CONST_BITS     = 1'b0;

// SPI CS Setup
parameter [3:0] CSSETUP_INIT_VALUE  = 4'h1;
parameter [3:0] CSSETUP_CONST_BITS  = 4'h0;

// SPI CS Hold
parameter [3:0] CSHOLD_INIT_VALUE   = 4'h1;
parameter [3:0] CSHOLD_CONST_BITS   = 4'h0;

