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

// Video mode definitions.
// The current values are for 640x480 @ 60 MHz.
// See: http://tinyvga.com/vga-timing/640x480@60Hz
// TODO: support other display modes.

`ifndef _VIDEO_MODES_VH_
`define _VIDEO_MODES_VH_

`define VIDEO_MODE_WIDTH        4     // Bit width of video mode value.
`define VIDEO_COUNT_WIDTH      11     // Field width of video scan counters.

// Number of timing parameters for H/V scan (see below).
`define NUM_TIMING_VALUES       9

// Four basic modes.
`define VIDEO_MODE_320x240      0
`define VIDEO_MODE_400x300      1
`define VIDEO_MODE_640x480      2
`define VIDEO_MODE_800x600      3

// VGA timing values, measured in pixel clock cycles.
`define VGA_640X480_60HZ_H_VISIBLE_LENGTH           `VIDEO_COUNT_WIDTH'd640
`define VGA_640X480_60HZ_H_FRONT_LENGTH             `VIDEO_COUNT_WIDTH'd16
`define VGA_640X480_60HZ_H_SYNC_LENGTH              `VIDEO_COUNT_WIDTH'd96
`define VGA_640X480_60HZ_H_BACK_LENGTH              `VIDEO_COUNT_WIDTH'd48
`define VGA_640X480_60HZ_H_SYNC_START               `VIDEO_COUNT_WIDTH'd0
`define VGA_640X480_60HZ_H_BACK_START     \
                             (`VGA_640X480_60HZ_H_SYNC_START + \
                              `VGA_640X480_60HZ_H_SYNC_LENGTH)
`define VGA_640X480_60HZ_H_VISIBLE_START  \
                             (`VGA_640X480_60HZ_H_BACK_START + \
                              `VGA_640X480_60HZ_H_BACK_LENGTH)
`define VGA_640X480_60HZ_H_FRONT_START    \
                             (`VGA_640X480_60HZ_H_VISIBLE_START + \
                              `VGA_640X480_60HZ_H_VISIBLE_LENGTH)
`define VGA_640X480_60HZ_H_TOTAL_LENGTH   \
                             (`VGA_640X480_60HZ_H_VISIBLE_LENGTH + \
                              `VGA_640X480_60HZ_H_FRONT_LENGTH + \
                              `VGA_640X480_60HZ_H_SYNC_LENGTH + \
                              `VGA_640X480_60HZ_H_BACK_LENGTH)

`define VGA_640X480_60HZ_V_VISIBLE_LENGTH           `VIDEO_COUNT_WIDTH'd480
`define VGA_640X480_60HZ_V_FRONT_LENGTH             `VIDEO_COUNT_WIDTH'd10
`define VGA_640X480_60HZ_V_SYNC_LENGTH              `VIDEO_COUNT_WIDTH'd2
`define VGA_640X480_60HZ_V_BACK_LENGTH              `VIDEO_COUNT_WIDTH'd33
`define VGA_640X480_60HZ_V_SYNC_START               `VIDEO_COUNT_WIDTH'd0
`define VGA_640X480_60HZ_V_BACK_START     \
                             (`VGA_640X480_60HZ_V_SYNC_START + \
                              `VGA_640X480_60HZ_V_SYNC_LENGTH)
`define VGA_640X480_60HZ_V_VISIBLE_START  \
                             (`VGA_640X480_60HZ_V_BACK_START + \
                              `VGA_640X480_60HZ_V_BACK_LENGTH)
`define VGA_640X480_60HZ_V_FRONT_START    \
                             (`VGA_640X480_60HZ_V_VISIBLE_START + \
                              `VGA_640X480_60HZ_V_VISIBLE_LENGTH)
`define VGA_640X480_60HZ_V_TOTAL_LENGTH   \
                             (`VGA_640X480_60HZ_V_VISIBLE_LENGTH + \
                              `VGA_640X480_60HZ_V_FRONT_LENGTH + \
                              `VGA_640X480_60HZ_V_SYNC_LENGTH + \
                              `VGA_640X480_60HZ_V_BACK_LENGTH)

`endif  // _VIDEO_MODES_VH_
