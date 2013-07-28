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

`include "defines.vh"

module CoreLogic(mcu_nss, mcu_sck, mcu_mosi, mcu_miso,
                 cop_nss, cop_sck, cop_mosi, cop_miso,
                 ram_nss, ram_sck, ram_mosi, ram_miso);
  // MCU and Coprocessor interfaces, CPLD = slave.
  input mcu_nss, mcu_sck, mcu_mosi;
  output reg mcu_miso;

  input cop_nss, cop_sck, cop_mosi;
  output cop_miso;

  // Serial RAM interface, CPLD = master.
  output reg ram_nss, ram_sck, ram_mosi;
  input ram_miso;

  reg bus_mode;

  // SPI access state machine counters.
  reg [`MCU_STATE_WIDTH-1:0] mcu_state;
  reg [`COP_STATE_WIDTH-1:0] cop_state;

  // SPI bit counters.
  reg [`BYTE_COUNTER_WIDTH-1:0] mcu_counter;
  reg [`BYTE_COUNTER_WIDTH-1:0] cop_counter;

  // SPI data registers.
  reg [`BYTE_WIDTH-1:0] mcu_data;
  reg [`BYTE_WIDTH-1:0] cop_data;

  // These store command and status values.
  reg [`BYTE_WIDTH-1:0] mcu_command;
  reg [`BYTE_WIDTH-1:0] cop_status;

  always @ (posedge mcu_nss)
    if (mcu_state == `MCU_STATE_OPCODE & mcu_data == `MCU_OP_RESET) begin
      bus_mode <= `BUS_MODE_MCU;
    end

  // SPI reset and increment logic for MCU.
  always @ (posedge mcu_nss or negedge mcu_sck) begin
    // Reset logic.
    if (mcu_nss) begin
      // Reset the state when nSS goes low.
      mcu_state <= `MCU_STATE_OPCODE;
      mcu_counter <= 0;
    end else begin
      // Falling edge of SCK means increment to next bit.
      if (mcu_counter == `BYTE_WIDTH - 1) begin
        case (mcu_state)
        `MCU_STATE_OPCODE:
          mcu_state <= mcu_data;  // The byte that was just read is the opcode.
          // TODO: Should it ignore or truncate larger values of |mcu_data|?
        `MCU_STATE_WRITE_COMMAND:
          mcu_command <= mcu_data;
        endcase
      end
      // Update the counter.  It should wrap around on its own.
      mcu_counter <= mcu_counter + 1;
    end
  end

  // MCU SPI bus shift register.
  always @ (posedge mcu_sck)
    if (~mcu_nss)
      mcu_data <= {mcu_mosi, mcu_data[`BYTE_WIDTH-1:1]};

  wire ram_enable = (bus_mode == `BUS_MODE_MCU) &
                    (mcu_state == `MCU_STATE_ACCESS_RAM);

  wire [2:0] mcu_spi = {mcu_nss, mcu_sck, mcu_mosi};
  wire [2:0] cop_spi = {cop_nss, cop_sck, cop_mosi};

  // Shared RAM bus interface.
  always @ (bus_mode or ram_enable or mcu_spi or cop_spi) begin
    if (ram_enable) begin
      // If RAM is active, map either the MCU or Coprocessor SPI bus to it.
      if (bus_mode == `BUS_MODE_MCU) begin
        {ram_nss, ram_sck, ram_mosi} <= mcu_spi;
      end else begin
        {ram_nss, ram_sck, ram_mosi} <= cop_spi;
      end
    end else begin
      // RAM bus is inactive.
      ram_nss <= 1'b1;
      ram_sck <= 1'b0;
      ram_mosi <= 1'bx;
    end
  end

  // State machine logic for MCU bus.
  always @ (bus_mode or mcu_state or ram_miso or mcu_data or mcu_counter or
            cop_status) begin
    if (bus_mode == `BUS_MODE_MCU) begin
      case (mcu_state)
      `MCU_STATE_READ_STATUS:
        mcu_miso <= cop_status[mcu_counter];
      `MCU_STATE_ACCESS_RAM:
        mcu_miso <= ram_miso;
      default:
        mcu_miso <= mcu_data[0];
      endcase
    end else begin  // RAM SPI bus is in Coprocessor mode.
      case (mcu_state)
      `MCU_STATE_READ_STATUS:
        mcu_miso <= cop_status[mcu_counter];
      default:
        mcu_miso <= 'bx;
      endcase
    end
  end

endmodule
