// Copyright (C) 2013 Simon Que
//
// This file is part of DuinoCube.
//
// DuinoCube is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// DuinoCube is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with DuinoCube.  If not, see <http://www.gnu.org/licenses/>.

// Defines for hardware collision detector.

`define BYTE_WIDTH                    8

// Size of address and data buses.
`define COLL_ADDR_WIDTH               8   // Collision table covers 512 bytes.
`define COLL_DATA_WIDTH               8

// Collision detected registers.
`define COLL_REGS_BASE                0
// Each register is 16 bits, so 16 registers = 256 bits, one bit per sprite /
// collision table entry.
`define NUM_COLL_STATUS_REGS         16

// Writing to the this register clears all the collision detected registers.
// It should come right after those registers.
`define COLL_REGS_CLEAR         `NUM_COLL_STATUS_REGS

`define COLL_TABLE_BASE            'h80   // Collision table is at 256 bytes.
`define COLL_TABLE_SIZE            'h80   // Collision table spans 256 bytes.
