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
//  Module: SPI Signal Synchronizer (sc_spi_sss)
//-----------------------------------------------------------------------------

module sc_spi_sss (
  // Sync SYSCLK
  input SYSCLK,
  input CLKEN,
  output reg SPIBUSY_SYSCLK,
  output reg TXDETECT_SYSCLK,
  output reg RXVALID_SYSCLK,

  // Sync SRCCLK
  input SRCCLK,
  output reg CLKEN_SRCCLK,
  input SPIBUSY,
  input TXDETECT,
  input RXVALID
);

// ----------
// Clock enable signal synchronization
// --------------------------------------------------
reg sync_clken;
always @ (posedge SRCCLK) begin
  sync_clken <= CLKEN;
  CLKEN_SRCCLK <= sync_clken;
end

// ----------
// Transmit data detect signal synchronization
// --------------------------------------------------
reg sync_txdetect;
reg [1:0] txdetect_p = 2'b00;
always @ (posedge SYSCLK) begin
  sync_txdetect <= TXDETECT;
  txdetect_p <= {txdetect_p[0], sync_txdetect};
  if (txdetect_p[1] != txdetect_p[0])
    TXDETECT_SYSCLK <= 1'b1;
  else
    TXDETECT_SYSCLK <= 1'b0;
end

// ----------
// Receive data valid signal synchronization
// --------------------------------------------------
reg sync_rxdetect;
reg [1:0] rxdetect_p = 2'b00;
always @ (posedge SYSCLK) begin
  sync_rxdetect <= RXVALID;
  rxdetect_p <= {rxdetect_p[0], sync_rxdetect};
  if (rxdetect_p[1] != rxdetect_p[0])
    RXVALID_SYSCLK <= 1'b1;
  else
    RXVALID_SYSCLK <= 1'b0;
end

// ----------
// SPI busy signal synchronization
// --------------------------------------------------
reg sync_spibusy;
always @ (posedge SYSCLK) begin
  sync_spibusy <= SPIBUSY;
  SPIBUSY_SYSCLK <= sync_spibusy;
end

endmodule
