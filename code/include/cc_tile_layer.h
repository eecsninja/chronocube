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

// ChronoCube layer API.

#ifndef _CC_TILE_LAYER_H_
#define _CC_TILE_LAYER_H_

#include <stdint.h>

// TileLayer object forward declarations.
struct CCTileLayer_;
typedef struct CCTileLayer_ CCTileLayer;

// Bulk copy tile map data.
void CCTileLayer_SetData(CCTileLayer* layer, void* data, uint32_t size);

// Set the tile at a location (x, y) in the tile layer.
void CCTileLayer_SetDataAt(CCTileLayer* layer,
                           uint16_t value,
                           uint32_t x,
                           uint32_t y);

// Set translation offset of the tile layer in world space.
void CCTileLayer_SetOffset(CCTileLayer* layer, uint16_t x, uint16_t y);

// Enable or disable a tile layer.
void CCTileLayer_SetEnabled(CCTileLayer* layer, uint8_t enabled);

// Set alpha value for tile layer.
void CCTileLayer_SetAlpha(CCTileLayer* layer, uint8_t alpha);

// Select a palette for tile layer.
void CCTileLayer_SetPalette(CCTileLayer* layer, uint8_t palette_index);

#endif  // _CC_TILE_LAYER_H_
