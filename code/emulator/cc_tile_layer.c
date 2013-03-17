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

void CCTileLayer_SetData(CCTileLayer* layer, void* data, uint32_t size) {
  memcpy(layer->tiles, data, size);
}

void CCTileLayer_SetDataAt(CCTileLayer* layer,
                           uint16_t value,
                           uint32_t x,
                           uint32_t y) {
  layer->tiles[x + layer->w * y] = value;
}

void CCTileLayer_SetOffset(CCTileLayer* layer, uint16_t x, uint16_t y) {
  layer->x = x;
  layer->y = y;
}

void CCTileLayer_SetEnabled(CCTileLayer* layer, uint8_t enabled) {
  layer->enabled = enabled;
}

void CCTileLayer_SetAlpha(CCTileLayer* layer, uint8_t alpha) {
  layer->alpha = alpha;
}

void CCTileLayer_SetPalette(CCTileLayer* layer, uint8_t palette_index) {
  layer->palette = palette_index;
}
