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

// ChronoCube emulator layer code.

#include "cc_tile_layer.h"

#include <string.h>

#include "cc_internal.h"

void CC_TileLayer_SetData(uint8_t index, void* data, uint32_t size) {
  memcpy(CC_GetTileLayer(index)->tiles, data, size);
}

void CC_TileLayer_SetDataAt(uint8_t index,
                           uint16_t value,
                           uint32_t x,
                           uint32_t y) {
  CC_TileLayer* layer = CC_GetTileLayer(index);
  layer->tiles[x + layer->w * y] = value;
}

void CC_TileLayer_SetOffset(uint8_t index, uint16_t x, uint16_t y) {
  CC_TileLayer* layer = CC_GetTileLayer(index);
  layer->x = x;
  layer->y = y;
}

void CC_TileLayer_SetEnabled(uint8_t index, uint8_t enabled) {
  CC_GetTileLayer(index)->enabled = enabled;
}

void CC_TileLayer_EnableNopTile(uint8_t index, uint8_t enabled) {
  CC_GetTileLayer(index)->enable_nop = enabled;
}

void CC_TileLayer_SetNopValue(uint8_t index, uint16_t nop_value) {
  CC_GetTileLayer(index)->nop_value = nop_value;
}

void CC_TileLayer_EnableAlpha(uint8_t index, uint8_t enabled) {
  CC_GetTileLayer(index)->enable_alpha = enabled;
}

void CC_TileLayer_SetAlpha(uint8_t index, uint8_t alpha) {
  CC_GetTileLayer(index)->alpha = alpha;
}

void CC_TileLayer_SetPalette(uint8_t index, uint8_t palette_index) {
  CC_GetTileLayer(index)->palette = palette_index;
}
