// Copyright (c) 2013, Simon Que
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

// A dual-port multiplexed SPI bus interface.

`include "spi_bus.vh"

module SPIBus(
  // Primary SPI bus.
  input main_nss,
  input main_sck,
  input main_mosi,
  output main_miso,

  // Secondary SPI bus.
  input alt_nss,
  input alt_sck,
  input alt_mosi,
  output alt_miso,

  // Output SPI bus.
  output nss,
  output sck,
  output mosi,
  input miso
);

  // For SPI bookkeeping.
  reg [`BYTE_COUNTER_WIDTH-1:0] spi_counter;
  reg [`BYTE_WIDTH-1:0] spi_data;
  reg [`SPI_BUS_STATE_WIDTH-1:0] spi_state;

  // Read in data from MOSI.
  always @ (posedge main_sck)
    if (~main_nss)
      spi_data <= {spi_data[`BYTE_WIDTH-2:0], main_mosi};

  // If this bit is set, the secondary bus is granted access.
  reg alt_bus;

  // Main SPI logic block.
  always @ (posedge main_nss or negedge main_sck) begin
    // Reset logic.
    if (main_nss) begin
      // Reset the state when nSS goes low.
      spi_state <= `SPI_BUS_STATE_NONE;
      spi_counter <= 0;
    end else begin
      // Update the counter.  It should wrap around on its own.
      spi_counter <= spi_counter + 1'b1;

      // Handle SPI clock edge transitions.
      // Falling edge of SCK means increment to next bit.
      if (spi_counter == `BYTE_WIDTH - 1 &&
          spi_state == `SPI_BUS_STATE_NONE) begin
        spi_state <= spi_data;
      end
    end
  end

  // Handle bus select modes.
  // This is done in a separate block from the main SPI logic because there may
  // not be a second byte during which |alt_bus| can be updated on a SCK edge.
  always @ (posedge main_nss) begin
    case (spi_data)
    `SPI_BUS_STATE_MAIN_BUS:
      alt_bus <= 0;
    `SPI_BUS_STATE_ALT_BUS:
      alt_bus <= 1;
    endcase
  end


  wire main_mem_enabled = (spi_state == `SPI_BUS_STATE_MEMORY);

  // Multiplex the two SPI buses.
  assign {nss, sck, mosi} =
      alt_bus ? {alt_nss, alt_sck, alt_mosi}
              : main_mem_enabled ? {main_nss, main_sck, main_mosi}
                                 : {1'b1, 1'b0, 1'bx};

  assign main_miso = ~main_nss ? (~alt_bus & main_mem_enabled & miso) : 'bz;
  assign alt_miso = ~alt_nss ? (alt_bus & miso) : 'bz;

endmodule
