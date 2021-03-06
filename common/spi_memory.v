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


// SPI memory interface.

`include "spi_memory.vh"

module SPIMemory(_select, sck, mosi, miso,
                 addr, data_out, data_in, rd, wr,
                 );

  // SPI interface.
  input _select, sck, mosi;
  output miso;

  // Memory interface.
  output [`SPI_MEM_ADDR_WIDTH-1:0] addr;
  input [`SPI_MEM_DATA_WIDTH-1:0] data_in;
  output [`SPI_MEM_DATA_WIDTH-1:0] data_out;
  output rd, wr;

  reg [`BYTE_COUNTER_WIDTH-1:0] spi_counter;
  reg [`BYTE_WIDTH-1:0] spi_data;

  // Upper and lower address bytes.
  reg [`BYTE_WIDTH-1:0] spi_addr_0;
  reg [`BYTE_WIDTH-1:0] spi_addr_1;

  // Read in data from MOSI.
  always @ (posedge sck)
    if (~_select)
      spi_data <= {spi_data[`BYTE_WIDTH-2:0], mosi};

  // Read at the start of a byte, before the rising edge of SCK.
  assign rd = (spi_counter == 0) & (spi_state == `SPI_MEM_STATE_DATA_READ);
  // Write at the end of a byte.
  assign wr = (spi_counter == `BYTE_WIDTH-1) &
              (spi_state == `SPI_MEM_STATE_DATA_WRITE);

  // Connect memory address and data buses.
  assign addr = {spi_addr_1, spi_addr_0};
  assign data_out = spi_data;

  // Register for reading data in.
  reg [`SPI_MEM_DATA_WIDTH-1:0] read_data;
  always @ (posedge sck)  // Store the old data at the start of a new byte.
    if (spi_counter == 0)
      read_data <= data_in;

  // Clock out data to MISO.
  assign miso = (spi_counter == 0) ? data_in[`BYTE_WIDTH - 1]
                                   : read_data[`BYTE_WIDTH - 1 - spi_counter];

  // SPI memory interface state machine.
  reg [`SPI_MEM_STATE_WIDTH-1:0] spi_state;
  // Previous state is used to detect transition from address to data bytes.
  reg [`SPI_MEM_STATE_WIDTH-1:0] spi_prev_state;

  // This bit indicates that the current operation is a write operation.
  reg write_op;

  always @ (posedge _select or negedge sck) begin
    // Reset logic.
    if (_select) begin
      // Reset the state when nSS goes low.
      spi_state <= `SPI_MEM_STATE_ADDR_H;
      spi_prev_state <= `SPI_MEM_STATE_ADDR_H;
      spi_counter <= 1'b0;
      write_op <= 0;
    end else begin
      // Falling edge of SCK means increment to next bit.
      if (spi_counter == `BYTE_WIDTH - 1) begin
        case (spi_state)
        `SPI_MEM_STATE_ADDR_H:
          begin
            spi_state <= `SPI_MEM_STATE_ADDR_L;
            // Mask out the highest bit, which indicates read or write.
            spi_addr_1 <= {1'b0, spi_data[`BYTE_WIDTH-2:0]};
            write_op <= spi_data[`BYTE_WIDTH-1];
          end
        `SPI_MEM_STATE_ADDR_L:
          begin
            spi_state <= write_op ? `SPI_MEM_STATE_DATA_WRITE
                                  : `SPI_MEM_STATE_DATA_READ;
            spi_addr_0 <= spi_data;
          end
        `SPI_MEM_STATE_DATA_READ:
          begin
            // Increment the address after writing a byte.  Be sure to mask out
            // the highest bit.
            spi_addr_0 <= spi_addr_0 + 1'b1;
            if (spi_addr_0 == {`BYTE_WIDTH{1'b1}})
              spi_addr_1 <= (spi_addr_1 + 1'b1) & {(`BYTE_WIDTH-1){1'b1}};
          end
        endcase

        // Save the previous state.
        spi_prev_state <= spi_state;
      end else if (spi_counter == 0 & spi_state == `SPI_MEM_STATE_DATA_WRITE &
                   spi_prev_state == spi_state) begin
        // Increment the address after writing a byte.  Be sure to mask out
        // the highest bit.
        spi_addr_0 <= spi_addr_0 + 1'b1;
        if (spi_addr_0 == {`BYTE_WIDTH{1'b1}})
          spi_addr_1 <= (spi_addr_1 + 1'b1) & {(`BYTE_WIDTH-1){1'b1}};
      end
      // Update the counter.  It should wrap around on its own.
      spi_counter <= spi_counter + 1'b1;
    end
  end

endmodule
