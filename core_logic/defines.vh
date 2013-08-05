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

// Give RAM SPI bus access to MCU or Coprocessor.
`define BUS_MODE_MCU           1'b0
`define BUS_MODE_COP           1'b1

// The states for MCU SPI access.
`define MCU_STATE_OPCODE          0
`define MCU_STATE_WRITE_COMMAND   1
`define MCU_STATE_READ_STATUS     2
`define MCU_STATE_ACCESS_RAM      3

`define MCU_STATE_WIDTH           2

// MCU opcodes
`define MCU_OP_RESET              0
`define MCU_OP_WRITE_COMMAND      1
`define MCU_OP_READ_STATUS        2
`define MCU_OP_ACCESS_RAM         3

// Coprocessor states
`define COP_STATE_OPCODE          0
`define COP_STATE_READ_COMMAND    1
`define COP_STATE_WRITE_STATUS    2
`define COP_STATE_ACCESS_RAM      3

`define COP_STATE_WIDTH           2

// Coprocessor opcodes
`define COP_OP_RESET              0   // Relinquish control of the RAM SPI bus.
`define COP_OP_READ_COMMAND       1
`define COP_OP_WRITE_STATUS       2
`define COP_OP_ACCESS_RAM         3

`define BYTE_WIDTH                8   // Number of bits per byte.
`define BYTE_COUNTER_WIDTH        3   // Number of bits to count bits per byte.

// For selecting peripheral devices.
`define DEV_SELECT_NONE           0
`define DEV_SELECT_SDCARD         1
`define DEV_SELECT_USB            2
`define DEV_SELECT_FPGA           3
`define DEV_SELECT_FLASH          4

`define DEV_SELECT_WIDTH          3
