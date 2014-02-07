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
  output reg nss,
  output reg sck,
  output reg mosi,
  input miso
);

  // Each bus is granted access when its select is asserted and the other bus'
  // select is not asserted.
  wire alt_bus_enabled = (alt_nss == 'b0) & (main_nss == 'b1);
  wire main_bus_enabled = (alt_nss == 'b1) & (main_nss == 'b0);

  // Multiplex the two SPI buses.
  // nSS should be allowed to assert only if only one bus is asserting it.
  // This avoids undefined behavior when the main bus interrupts the secondary
  // bus.
  always @ (*) begin
    if (alt_bus_enabled) begin
      nss <= 'b0;
      sck <= alt_sck;
      mosi <= alt_mosi;
    end else if (main_bus_enabled) begin
      nss <= 'b0;
      sck <= main_sck;
      mosi <= main_mosi;
    end else begin
      nss <= 'b1;
      sck <= 0;
      mosi <= 0;
    end
  end

  assign main_miso = (main_nss == 'b0) ? miso : 'bz;
  assign alt_miso = (alt_nss == 'b0) ? miso : 'bz;

endmodule
