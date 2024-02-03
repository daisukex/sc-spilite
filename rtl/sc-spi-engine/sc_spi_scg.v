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
//  Module: SPI Clock Generator (sc_spi_scg)
//-----------------------------------------------------------------------------

module sc_spi_scg (
  input SRCCLK,
  input SYSRSTB,
  input [7:0] CLK_CLKDR,
  input [1:0] CLK_MODE,
  input CLK_ENABLE,
  (* dont_touch = "yes" *) output reg SPICLK
);

reg [7:0] clock_count;
reg enable_p;

// ----------
// SPI Clock Generator
// --------------------------------------------------
always @ (posedge SRCCLK) begin
  if (!SYSRSTB) begin
    SPICLK <= 1'b0;
    enable_p <= 1'b0;
    clock_count <= 0;
  end
  else begin
    enable_p <= CLK_ENABLE;
    // clock off state
    if (!CLK_ENABLE) begin
      SPICLK <= 1'b0;
      clock_count <= 0;
    end

    // clock start state
    else if (CLK_ENABLE & !enable_p) begin
      SPICLK <= 1'b1;
      clock_count <= 0;
    end

    // clock active state
    else begin
      if (clock_count == CLK_CLKDR -1) begin
        SPICLK <= 1'b1;
        clock_count <= 0;
      end
      else begin
        clock_count <= clock_count + 1;
        if (((CLK_CLKDR %2) == 0) & clock_count == (CLK_CLKDR/2 - 1))
          SPICLK <= 1'b0;
        else if ((CLK_MODE == 1 | CLK_MODE == 2) & clock_count == (CLK_CLKDR/2))
          SPICLK <= 1'b0;
        else if ((CLK_MODE == 0 | CLK_MODE == 3) & clock_count == (CLK_CLKDR/2 - 1))
          SPICLK <= 1'b0;
      end
    end
  end
end

endmodule
