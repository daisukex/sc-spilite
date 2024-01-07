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
//  Module: SPI Lite Chip Select Decoder (sc_spil_scd)
//-----------------------------------------------------------------------------

module sc_spil_scd # (
  parameter NUM_OF_CS = 32
) (
  input [4:0] CS_SEL,
  input CSB_IN,
  output reg [NUM_OF_CS-1:0] CSB_OUT
);

always @ (*) begin
  CSB_OUT = {NUM_OF_CS{1'b1}};
  CSB_OUT[CS_SEL] = CSB_IN;
end

endmodule
