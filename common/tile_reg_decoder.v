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

// ChronoCube tile layer register field decoder.

`include "tile_registers.vh"

module TileRegDecoder(current_layer,
                      reg_values,

                      layer_enabled,
                      enable_8bit,
                      enable_nop,
                      enable_scroll,
                      enable_transp,
                      enable_alpha,
                      enable_color,
                      enable_wrap_x,
                      enable_wrap_y,
                      enable_flip,

                      tile_hsize_enum,
                      tile_vsize_enum,

                      ctrl0,
                      ctrl1,
                      data_offset,
                      nop_value,
                      color_key,
                      offset_x,
                      offset_y);
  input [1:0] current_layer;
  input [`NUM_TOTAL_TILE_REG_BITS-1:0] reg_values;

  wire [`NUM_REG_BITS_PER_TILE_LAYER-1:0]
      reg_values_array[`NUM_TILE_LAYERS-1:0];
  genvar i;
  generate
    for (i = 0; i < `NUM_TILE_LAYERS; i = i + 1) begin: TILE_REG_VALUES
      assign reg_values_array[i] =
          reg_values[(i + 1) * `NUM_REG_BITS_PER_TILE_LAYER - 1:
                          i * `NUM_REG_BITS_PER_TILE_LAYER];
    end
  endgenerate

  wire [`REG_DATA_WIDTH-1:0] regs [`NUM_TILE_REGISTERS-1:0];
  generate
    for (i = 0; i < `NUM_TILE_REGISTERS; i = i + 1) begin: TILE_REGS
      assign regs[i] =
          reg_values_array[current_layer][(i+1)*`REG_DATA_WIDTH-1:
                                               i*`REG_DATA_WIDTH];
    end
  endgenerate

  output layer_enabled ;
  output enable_8bit   ;
  output enable_nop    ;
  output enable_scroll ;
  output enable_transp ;
  output enable_alpha  ;
  output enable_color  ;
  output enable_wrap_x ;
  output enable_wrap_y ;
  output enable_flip   ;

  output [`TILE_HSIZE_WIDTH-1:0] tile_hsize_enum;
  output [`TILE_VSIZE_WIDTH-1:0] tile_vsize_enum;

  output [`REG_DATA_WIDTH-1:0] ctrl0       ;
  output [`REG_DATA_WIDTH-1:0] ctrl1       ;
  output [`REG_DATA_WIDTH-1:0] data_offset ;
  output [`REG_DATA_WIDTH-1:0] nop_value   ;
  output [`REG_DATA_WIDTH-1:0] color_key   ;
  output [`REG_DATA_WIDTH-1:0] offset_x    ;
  output [`REG_DATA_WIDTH-1:0] offset_y    ;

  assign layer_enabled    = regs[`TILE_CTRL0][`TILE_LAYER_ENABLED];
  assign enable_8bit      = regs[`TILE_CTRL0][`TILE_ENABLE_8_BIT];
  assign enable_nop       = regs[`TILE_CTRL0][`TILE_ENABLE_NOP];
  assign enable_scroll    = regs[`TILE_CTRL0][`TILE_ENABLE_SCROLL];
  assign enable_transp    = regs[`TILE_CTRL0][`TILE_ENABLE_TRANSP];
  assign enable_alpha     = regs[`TILE_CTRL0][`TILE_ENABLE_ALPHA];
  assign enable_color     = regs[`TILE_CTRL0][`TILE_ENABLE_COLOR];
  assign enable_wrap_x    = regs[`TILE_CTRL0][`TILE_ENABLE_WRAP_X];
  assign enable_wrap_y    = regs[`TILE_CTRL0][`TILE_ENABLE_WRAP_Y];
  assign enable_flip      = regs[`TILE_CTRL0][`TILE_ENABLE_FLIP];

  assign tile_width_enum    = regs[`TILE_CTRL1][`TILE_HSIZE_1:`TILE_HSIZE_0];
  assign tile_height_enum   = regs[`TILE_CTRL1][`TILE_VSIZE_1:`TILE_VSIZE_0];

  assign ctrl0 = regs[`TILE_CTRL0];
  assign ctrl1 = regs[`TILE_CTRL1];
  assign data_offset = regs[`TILE_DATA_OFFSET];
  assign nop_value = regs[`TILE_NOP_VALUE];
  assign color_key = regs[`TILE_COLOR_KEY];
  assign offset_x = regs[`TILE_OFFSET_X];
  assign offset_y = regs[`TILE_OFFSET_Y];
  
endmodule
