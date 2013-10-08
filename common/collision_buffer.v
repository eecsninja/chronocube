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

// Buffer for collision detection.

`define COLL_ADDR_WIDTH              10
`define COLL_BUFFER_SIZE              (1 << `COLL_ADDR_WIDTH)
`define DATA_WIDTH                    9

module CollisionBuffer(clk,
                       wr_a, addr_a, wr_data_a, rd_data_a,
                       wr_b, addr_b, wr_data_b, rd_data_b);

  input clk;                // System clock.

  // Interface A
  input wr_a;                              // Enable writing to buffer.
  input [`COLL_ADDR_WIDTH-1:0] addr_a;     // Address bus.
  input [`DATA_WIDTH-1:0] wr_data_a;       // Data to write.
  output [`DATA_WIDTH-1:0] rd_data_a;      // Data that was read.

  // Interface B (buffer 1)

  // Data write port.
  input wr_b;                              // Enable writing to buffer.
  input [`COLL_ADDR_WIDTH-1:0] addr_b;     // Address bus.
  input [`DATA_WIDTH-1:0] wr_data_b;       // Data to write.
  output [`DATA_WIDTH-1:0] rd_data_b;      // Data that was read.

  collision_buffer_1Kx9 buffer(.clock(clk),
                               .address_a(addr_a),
                               .address_b(addr_b),
                               .data_a(wr_data_a),
                               .data_b(wr_data_b),
                               .wren_a(wr_a),
                               .wren_b(wr_b),
                               .q_a(rd_data_a),
                               .q_b(rd_data_b));

endmodule
