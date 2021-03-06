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

// DuinoCube memory map definitions.

`ifndef _MEMORY_MAP_VH_
`define _MEMORY_MAP_VH_

// The memory space exposed to a MCU with a 16-bit address space is 32 KB long,
// so it can map to the second half of the 64-KB space, leaving the first half
// for the MCU's memory, registers, peripherals -- both internal and external.

// The 32 KB space is further broken down into two 16 KB pages.  The lower page
// is normally mapped.  The upper page is banked memory, and can map to an
// arbitrarily large internal memory space using a bank value.  The formula is:
//     INT_ADDR = (ADDR - BANK_START) + BANK * 0x4000  if ADDR >= 0x4000 (16 KB)
//     INT_ADDR = ADDR                                 if ADDR < 0x4000
// If BANK = 0, then the second page becomes an alias of the first page.

// All addresses and lengths here are expressed in 16-bit words.  For exmaple,
// an address of 0x800 would correspond to address 0x1000 from the MCU's
// perspective.

// Memory pages and banking
`define MEMORY_PAGE_SIZE       'h2000
`define MEMORY_BANKED_PAGE_BASE (`MEMORY_PAGE_SIZE)
`define INT_ADDR_WIDTH             32  // Arbitrary, but 32 is convenient.
`define PAGE_OFFSET_WIDTH          13  // 8 KB x 16-bits = 16 KB

// Collision table.
`define COLL_ADDR_BASE         'h0100  // Collision data begins at 512 bytes,
`define COLL_ADDR_LENGTH       'h0100  // spanning 512 bytes.

// Palette memory
`define PAL_ADDR_BASE          'h0800  // Palette starts at 4 KB, spans 4 KB.
`define PAL_ADDR_LENGTH        'h0800  // Four palettes, each spanning 1 KB.

`define PAL_ADDR_WIDTH             10
`define NUM_PAL_CHANNELS            3
`define PAL_DATA_WIDTH     `NUM_PAL_CHANNELS * 8

// Sprite register address definitions.
`define NUM_SPRITES               256
`define NUM_SPRITE_REGS            16   // Number of registers for each sprite.

`define SPRITE_ADDR_BASE       'h1000   // Start at 8 KB.
`define SPRITE_ADDR_LENGTH     'h1000   // Extend over 8 KB.
// Note: for some reason, using "(`NUM_SPRITES * `NUM_SPRITE_REGS) doesn't work
// here when NUM_SPRITES=256.  The system still behaves as if NUM_SPRITES=128.
// So the address length is hardcoded instead.

// All sprite X/Y registers are aliased at a different location so they can be
// accessed contiguously.
`define SPRITE_XY_ADDR_BASE    'h0200
`define SPRITE_XY_ADDR_LENGTH  'h0200

// Tile map memory
`define TILEMAP_ADDR_BASE      'h2000
`define TILEMAP_ADDR_LENGTH    'h1000

`define TILEMAP_ADDR_WIDTH         12
`define TILEMAP_DATA_WIDTH         16

// VRAM
`define VRAM_ADDR_BASE         'h4000  // VRAM starts at 32 KB.
`define VRAM_ADDR_LENGTH      'h40000  // VRAM spans 512 KB.

`define VRAM_ADDR_WIDTH            18
`define VRAM_DATA_WIDTH            16

`endif  // _MEMORY_MAP_VH_
