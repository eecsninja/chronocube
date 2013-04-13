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

// ChronoCube emulator internal definitions.

#ifndef _CC_INTERNAL_H_
#define _CC_INTERNAL_H_

#include <stdint.h>

// Default system definitions.
// TODO: Eventually these will have to be expanded to support various
// configurations.

// Screen resolution.
#define SCREEN_WIDTH                         320
#define SCREEN_HEIGHT                        240

// VRAM size.
#define VRAM_SIZE                    (64 * 1024)

// Palette definitions.
#define NUM_PALETTES                           4
#define NUM_COLORS_PER_PALETTE               256
#define PALETTE_SIZE              (NUM_PALETTES * NUM_COLORS_PER_PALETTE)

// Individual tile size.
#define TILE_WIDTH                            16
#define TILE_HEIGHT                           16

// Tile layer definitions.
#define NUM_TILE_LAYERS                        4
#define TILE_MAP_WIDTH                        32
#define TILE_MAP_HEIGHT                       32
#define TILE_MAP_SIZE             (TILE_MAP_WIDTH * TILE_MAP_HEIGHT)

// Dimensions of a tile layer.
#define TILE_LAYER_WIDTH          (TILE_WIDTH * TILE_MAP_WIDTH)
#define TILE_LAYER_HEIGHT         (TILE_HEIGHT * TILE_MAP_HEIGHT)

// Sprite definitions.
#define NUM_SPRITES                          128

// Emulates a palette.
typedef struct CCPalette_ {
  // Points to an array of entries, packed to 4 bytes.
  union {
    char* data;
    struct {
      uint8_t r, g, b;
      uint8_t padding;
    } *entries;
  };
} CCPalette;

// Emulates a tile layer.
typedef struct CCTileLayer_ {
  uint16_t* tiles;
  uint8_t enabled;
  uint16_t x, y;
  uint16_t w, h;
  uint16_t alpha;
  uint8_t palette;
} CCTileLayer;

// Emulates a sprite.
typedef struct CCSprite_ {
  uint8_t enabled;
  uint16_t x, y;
  uint16_t alpha;
  uint8_t palette;
} CCSprite;

// Get tile layer and sprite by index.
CCTileLayer* CC_GetTileLayer(uint8_t index);
CCSprite* CC_GetSprite(uint16_t index);

#endif  // _CC_INTERNAL_H_
