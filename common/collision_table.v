// Copyright (C) 2013 Simon Que
//
// This file is part of ChronoCube.
//
// ChronoCube is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ChronoCube is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with ChronoCube.  If not, see <http://www.gnu.org/licenses/>.

// Table containing collision detection results.

`include "collision.vh"

`define MPU_DATA_WIDTH      16

module CollisionTable(clk, reset,
                      write_collision, table_index, table_value,
                      wr, be, addr, data_in, data_out);

  input clk;                                  // System clock.
  input reset;                                // System reset.

  // Interface to write collision info.
  // TODO: consider registering these inputs to improve timing.
  input write_collision;                      // Enable writing to table.
  input [`COLL_ADDR_WIDTH-1:0] table_index;   // Index of table entry.
  input [`COLL_DATA_WIDTH-1:0] table_value;   // Value to write to table.

  // Interface for reading from collision table.
  input wr;                                   // Write enable.
  input [1:0] be;                             // Byte enable.
  input [`COLL_ADDR_WIDTH-1:0] addr;          // Address bus.
  input [`MPU_DATA_WIDTH-1:0] data_in;        // Data to write.
  output [`MPU_DATA_WIDTH-1:0] data_out;      // Data that was read.

  // Determine what data is being read.
  assign data_out = table_select ? table_data_out :
                    (reg_select  ? status_regs[reg_addr] : 0);

  // Select the collision status registers.
  wire reg_select = (addr >= `COLL_REGS_BASE) &
                    (addr < `COLL_REGS_BASE + `NUM_COLL_STATUS_REGS);
  wire [`COLL_ADDR_WIDTH-1:0] reg_addr = addr - `COLL_REGS_BASE;
  wire reg_reset = reset | (wr & (addr == `COLL_REGS_CLEAR));

  // Per-sprite collision status registers.
  reg [`MPU_DATA_WIDTH-1:0] status_regs[`NUM_COLL_STATUS_REGS-1:0];
  genvar i;
  generate
    for (i = 0; i < `NUM_COLL_STATUS_REGS; i = i + 1) begin : REGS
      always @ (posedge reg_reset or posedge clk) begin
        if (reg_reset)
          status_regs[i] <= 0;
        else if (write_collision & table_index / `MPU_DATA_WIDTH == i)
          status_regs[i][table_index % `MPU_DATA_WIDTH] <= 1;
      end
    end
  endgenerate

  // Select the collision lookup table.
  wire table_select = (addr >= `COLL_TABLE_BASE) &
                      (addr < `COLL_TABLE_BASE + `COLL_TABLE_SIZE);
  wire [`MPU_DATA_WIDTH-1:0] table_data_out;

  // Table containing list of actual collisions.
  collision_table_256x16 collision_table(
      .clock(clk),

      // Convert byte to word.
      .wren_a(write_collision),
      .byteena_a(table_index[0] ? 'b10 : 'b01),
      .address_a(table_index / 2),
      .data_a({table_value[`BYTE_WIDTH-1:0], table_value[`BYTE_WIDTH-1:0]}),

      .wren_b(0),   // MPU-side interface is read-only.
      .address_b(addr - `COLL_TABLE_BASE),
      .q_b(table_data_out));

endmodule
