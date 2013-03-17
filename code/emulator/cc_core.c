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

// ChronoCube emulator core.

#include "cc_core.h"

#include <assert.h>
#include <SDL/SDL.h>

#include "cc_internal.h"

typedef struct CCPalette_ CCPalette;

static struct {
  uint8_t* vram;

  struct {
    uint8_t x;
    uint8_t y;
  } scroll;

  uint8_t enabled;
  uint8_t blanked;

  CCPalette* palettes;
  uint8_t num_palettes;

  CCTileLayer* tile_layers;
  uint8_t num_tile_layers;

  CCSprite* sprites;
  uint16_t num_sprites;
} cc;

void CC_Init() {
  int i;

  cc.vram = malloc(VRAM_SIZE);

  cc.palettes = calloc(NUM_PALETTES, sizeof(CCPalette));
  cc.num_palettes = NUM_PALETTES;
  for (i = 0; i < NUM_PALETTES; ++i)
    cc.palettes[i].data = calloc(NUM_COLORS_PER_PALETTE, 4);

  cc.tile_layers = calloc(NUM_TILE_LAYERS, sizeof(CCTileLayer));
  cc.num_tile_layers = NUM_TILE_LAYERS;
  for (i = 0; i < NUM_TILE_LAYERS; ++i)
    cc.tile_layers[i].tiles = calloc(TILE_MAP_SIZE, sizeof(uint16_t));

  cc.sprites = calloc(NUM_SPRITES, sizeof(CCSprite));
  cc.num_sprites = NUM_SPRITES;

  cc.enabled = 0;
  cc.blanked = 0;
  cc.scroll.x = 0;
  cc.scroll.y = 0;
}

void CC_Cleanup() {
  int i;

  free(cc.vram);

  for (i = 0; i < NUM_TILE_LAYERS; ++i)
    free(cc.palettes[i].data);
  free(cc.palettes);

  for (i = 0; i < NUM_TILE_LAYERS; ++i)
    free(cc.tile_layers[i].tiles);
  free(cc.tile_layers);

  free(cc.sprites);
}

void CC_SetVramData(uint32_t vram_offset, void* src_data, uint32_t size) {
  assert(vram_offset + size <= VRAM_SIZE);
  memcpy(cc.vram + vram_offset, src_data, size);
}

void CC_SetPaletteData(uint8_t index, void* data, uint16_t size) {
  assert(index < cc.num_palettes);
  assert(size <= PALETTE_SIZE);
  memcpy(cc.palettes[index].data, data, size);
}

void CC_SetPaletteEntry(uint8_t index, uint8_t r, uint8_t g, uint8_t b) {
  assert(index < cc.num_palettes);
  CCPalette* palette = &cc.palettes[index];
  palette->entries[index].r = r;
  palette->entries[index].g = g;
  palette->entries[index].b = b;
}

void CC_SetOutputEnable(uint8_t enabled) {
  cc.enabled = enabled;
}

void CC_SetOutputBlank(uint8_t blanked) {
  cc.blanked = blanked;
}

void CC_SetScrollOffset(uint16_t x, uint16_t y) {
  cc.scroll.x = x;
  cc.scroll.y = y;
}

CCTileLayer* CC_GetTileLayer(uint8_t index) {
  assert(index < cc.num_tile_layers);
  return &cc.tile_layers[index];
}

CCSprite* CC_GetSprite(uint16_t index) {
  assert(index < cc.num_sprites);
  return &cc.sprites[index];
}
