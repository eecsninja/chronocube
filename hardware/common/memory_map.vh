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

// ChronoCube memory map definitions.

`ifndef _MEMORY_MAP_VH_
`define _MEMORY_MAP_VH_


// Palette memory
`define PAL_ADDR_BASE          'h0800
`define PAL_ADDR_LENGTH           512

`define PAL_ADDR_WIDTH             10
`define NUM_PAL_CHANNELS            3
`define PAL_DATA_WIDTH     `NUM_PAL_CHANNELS * 8

// Tile map memory
`define TILEMAP_ADDR_BASE      'h2000
`define TILEMAP_ADDR_LENGTH    'h1000

`define TILEMAP_ADDR_WIDTH         12
`define TILEMAP_DATA_WIDTH         16

// VRAM
`define VRAM_ADDR_BASE         'h4000
`define VRAM_ADDR_LENGTH       'h2000

`define VRAM_ADDR_WIDTH            13
`define VRAM_DATA_WIDTH            16

`endif  // _MEMORY_MAP_VH_
