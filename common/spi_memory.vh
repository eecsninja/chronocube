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


// Definitions for SPI memory interface.

`define BYTE_WIDTH                8  // Number of bits per byte.
`define BYTE_COUNTER_WIDTH        3  // Number of bits to count bits per byte.

// SPI memory access states
`define SPI_MEM_STATE_ADDR_H      0  // Clocking in high byte of address.
`define SPI_MEM_STATE_ADDR_L      1  // Clocking in low byte of address.
`define SPI_MEM_STATE_DATA_WRITE  2  // Clocking in byte to be written.
`define SPI_MEM_STATE_DATA_READ   3  // Clocking out byte that was read.

`define SPI_MEM_STATE_WIDTH       2

// Memory address and data bus sizes.
`define SPI_MEM_ADDR_WIDTH        (2 * `BYTE_WIDTH)
`define SPI_MEM_DATA_WIDTH        (`BYTE_WIDTH)
