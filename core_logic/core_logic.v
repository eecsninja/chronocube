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
                 cop_select, cop_sck, cop_mosi, cop_miso,
                 cop_nreset,
                 ram_nss, ram_sck, ram_mosi, ram_miso,
                 usb_nss, sdc_nss, fpga_nss, dev_miso,
                 flash_nss, flash_sck, flash_mosi, flash_miso,
                 fpga_nce, fpga_nconfig
                 );
  // MCU and Coprocessor interfaces, CPLD = slave.
  input mcu_nss, mcu_sck, mcu_mosi;
  output reg mcu_miso;

  input [`DEV_SELECT_WIDTH-1:0] cop_select;
  input cop_sck, cop_mosi;
  output reg cop_miso;
  inout cop_nreset;  // Reset signal to coprocessor.

  // Serial RAM interface, CPLD = master.
  output reg ram_nss, ram_sck, ram_mosi;
  input ram_miso;

  // SPI chip selects for peripheral devices.
  output usb_nss;
  output sdc_nss;
  output fpga_nss;
  input dev_miso;

  // Flash memory interface.
  output flash_nss, flash_sck, flash_mosi;
  input flash_miso;
  output fpga_nce, fpga_nconfig;

  reg bus_mode;
  wire logic_nss = (cop_select != `DEV_SELECT_LOGIC);

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

  // Initial register value is 0.
  initial begin
    mcu_state = 0;
    mcu_counter = 0;
    mcu_command = 0;
    mcu_data = 0;

    cop_state = 0;
    cop_counter = 0;
    cop_status = 0;
    cop_data = 0;
  end

  wire reset = (mcu_state == `MCU_STATE_RESET);

  // Hand RAM bus control over to coprocessor during an RPC operation.
  always @ (*) begin
    if ((mcu_command == `RPC_CMD_NONE) & (cop_status != `RPC_CMD_NONE))
      bus_mode <= `BUS_MODE_COP;
    else
      bus_mode <= `BUS_MODE_MCU;
  end

  // Coprocessor reset logic.
  // Tri-state the reset signal when inactive because there could be other
  // sources driving it low (e.g. a button or a programmer device).
  assign cop_nreset = reset ? 0 : 'bz;

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

  // SPI reset and increment logic for Coprocessor.
  always @ (posedge logic_nss or negedge cop_sck) begin
    // Reset logic.
    if (logic_nss) begin
      // Reset the state when nSS goes low.
      cop_state <= `COP_STATE_OPCODE;
      cop_counter <= 0;
    end else begin
      // Falling edge of SCK means increment to next bit.
      if (cop_counter == `BYTE_WIDTH - 1) begin
        case (cop_state)
        `COP_STATE_OPCODE:
          cop_state <= cop_data;  // The byte that was just read is the opcode
          // TODO: Should it ignore or truncate larger values of |cop_data|?
        `COP_STATE_WRITE_STATUS:
          cop_status <= cop_data;
        endcase
      end
      // Update the counter.  It should wrap around on its own.
      cop_counter <= cop_counter + 1;
    end
  end
  // MCU SPI bus shift register.
  always @ (posedge mcu_sck or posedge reset) begin
    if (reset)
      mcu_data <= 0;
    else if (~mcu_nss)
      mcu_data <= {mcu_data[`BYTE_WIDTH-2:0], mcu_mosi};
  end

  // Coprocessor SPI bus shift register.
  always @ (posedge cop_sck)
    if (~logic_nss)
      cop_data <= {cop_data[`BYTE_WIDTH-2:0], cop_mosi};

  wire ram_enable =
    ((bus_mode == `BUS_MODE_MCU) & (mcu_state == `MCU_STATE_ACCESS_RAM)) |
    ((bus_mode == `BUS_MODE_COP) & (cop_state == `COP_STATE_ACCESS_RAM));

  wire [2:0] mcu_spi = {mcu_nss, mcu_sck, mcu_mosi};
  wire [2:0] cop_spi = {logic_nss, cop_sck, cop_mosi};

  // Shared RAM bus interface.
  always @ (*) begin
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
  always @ (*) begin
    if (mcu_nss) begin
      mcu_miso <= 'bz;
    end else begin
      case (mcu_state)
      `MCU_STATE_READ_STATUS:
        mcu_miso <= cop_status[`BYTE_WIDTH - 1 - mcu_counter];
      `MCU_STATE_ACCESS_RAM:
        mcu_miso <= ram_miso;
      default:
        mcu_miso <= 'bx;
      endcase
    end
  end

  // State machine logic for Coprocessor bus.
  always @ (*) begin
    // If there's an external reset going on, tri-state the MISO line.
    if (reset == 0 & cop_nreset == 0)
      cop_miso <= 'bz;
    else case (cop_select)
    `DEV_SELECT_LOGIC:
      case (cop_state)
      `COP_STATE_READ_COMMAND:
        cop_miso <= mcu_command[`BYTE_WIDTH - 1 - cop_counter];
      `COP_STATE_ACCESS_RAM:
        cop_miso <= ram_miso;
      default:
        cop_miso <= cop_data[`BYTE_WIDTH - 1];
      endcase
    `DEV_SELECT_SDCARD:
      cop_miso <= dev_miso;
    `DEV_SELECT_USB:
      cop_miso <= dev_miso;
    `DEV_SELECT_FPGA:
      cop_miso <= dev_miso;
    `DEV_SELECT_FLASH:
      cop_miso <= flash_miso;
    default:
      cop_miso <= 'bz;
    endcase

  end

  // Coprocessor-to-flash SPI bus interface.
  wire flash_enable = (cop_select == `DEV_SELECT_FLASH);
  assign flash_sck = flash_enable ? cop_sck : 'bz;
  assign flash_mosi = flash_enable ? cop_mosi : 'bz;
  assign flash_nss = flash_enable ? 0 : 'bz;

  // Peripheral device selects.
  assign usb_nss = (cop_select != `DEV_SELECT_USB);
  assign sdc_nss = (cop_select != `DEV_SELECT_SDCARD);
  assign fpga_nss = (cop_select != `DEV_SELECT_FPGA);

  // When writing to flash, set nCE high and nCONFIG low to tri-state the FPGA-
  // flash serial bus. Otherwise, tri-state these signals to avoid interfering
  // with the bus.
  // TODO: Add an external switch to prevent spurious signals from modifying
  // the FPGA configuration flash.
  assign fpga_nce = flash_enable ? 1 : 'bz;
  assign fpga_nconfig = flash_enable ? 0 : 'bz;

endmodule
