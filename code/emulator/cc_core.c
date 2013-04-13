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

static struct {
  uint8_t* vram;

  struct {
    uint16_t x;
    uint16_t y;
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

// Used for rendering with SDL.
static struct {
  SDL_Surface* screen;        // The video screen.
  SDL_Surface* vram;          // VRAM with image data.
  SDL_Surface** tile_layers;  // Surfaces for drawing tile layers.
} renderer;

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

  CC_RendererInit();
}

void CC_Cleanup() {
  int i;

  CC_RendererCleanup();

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

void CC_RendererInit() {
  int i;
  uint32_t rmask, gmask, bmask, amask;

  assert(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) == 0);

  renderer.screen =
      SDL_SetVideoMode (SCREEN_WIDTH, SCREEN_HEIGHT, 32, SDL_HWSURFACE);
  assert(renderer.screen);
  rmask = renderer.screen->format->Rmask;
  gmask = renderer.screen->format->Gmask;
  bmask = renderer.screen->format->Bmask;
  amask = renderer.screen->format->Amask;

  renderer.vram = SDL_CreateRGBSurfaceFrom(
      cc.vram,
      TILE_WIDTH,
      VRAM_SIZE / TILE_WIDTH,
      8,              // TODO: make this a #define
      TILE_WIDTH,
      rmask, gmask, bmask, amask);
  assert(renderer.vram);

  renderer.tile_layers = calloc(sizeof(SDL_Surface*), cc.num_tile_layers);
  for (i = 0; i < cc.num_tile_layers; ++i) {
    renderer.tile_layers[i] = SDL_CreateRGBSurface(
        SDL_HWSURFACE | SDL_SRCALPHA | SDL_SRCCOLORKEY,
        TILE_LAYER_WIDTH,
        TILE_LAYER_HEIGHT,
        renderer.screen->format->BitsPerPixel,
        rmask, gmask, bmask, amask);
    assert(renderer.tile_layers[i]);
  }
}

void CC_RendererCleanup() {
  int i;
  for (i = 0; i < cc.num_tile_layers; ++i)
    SDL_FreeSurface(renderer.tile_layers[i]);
  SDL_FreeSurface(renderer.vram);
  SDL_Quit();
}

void CC_RendererDraw() {
  int i;
  SDL_Rect src;
  src.w = TILE_WIDTH;
  src.h = TILE_HEIGHT;
  SDL_Rect dst;

  // Clear the screen.
  SDL_FillRect(renderer.screen, NULL, 0);

  // TODO: implement scrolling and alpha.
  for (i = 0; i < NUM_TILE_LAYERS; ++i) {
    int tile_index = 0;
    if (!cc.tile_layers[i].enabled)
      continue;

    // Set the rendering palette for this layer.
    const CCPalette palette = cc.palettes[cc.tile_layers[i].palette];
    SDL_SetColors(renderer.vram,
                  (SDL_Color*)palette.data,
                  0,
                  NUM_COLORS_PER_PALETTE);

    // Render tiles onto the tile layer surface.
    SDL_Surface* layer = renderer.tile_layers[i];
    for (dst.y = 0; dst.y < TILE_LAYER_HEIGHT; dst.y += TILE_HEIGHT) {
      for (dst.x = 0; dst.x < TILE_LAYER_WIDTH; dst.x += TILE_WIDTH) {
        uint16_t tile_value = cc.tile_layers[i].tiles[tile_index];
        src.x = 0;
        src.y = tile_value * TILE_HEIGHT;
        SDL_BlitSurface(renderer.vram, &src, layer, &dst);
        ++tile_index;
      }
    }

    // Render the tile layer surface onto the screen.
    SDL_Rect screen_dst;
    screen_dst.x = cc.tile_layers[i].x - cc.scroll.x;
    screen_dst.y = cc.tile_layers[i].y - cc.scroll.y;

    // Handle wrap-around.

    // Wrap horizontally.
    if (screen_dst.x + TILE_LAYER_WIDTH < SCREEN_WIDTH) {
      SDL_Rect screen_dst_wrap_x = screen_dst;
      screen_dst_wrap_x.x += TILE_LAYER_WIDTH;
      SDL_BlitSurface(layer, NULL, renderer.screen, &screen_dst_wrap_x);
    }
    // Wrap vertically.
    if (screen_dst.y + TILE_LAYER_HEIGHT < SCREEN_HEIGHT) {
      SDL_Rect screen_dst_wrap_y = screen_dst;
      screen_dst_wrap_y.y += TILE_LAYER_WIDTH;

      // Wrap diagonally.
      if (screen_dst.x + TILE_LAYER_WIDTH < SCREEN_WIDTH) {
        SDL_Rect screen_dst_wrap_xy = screen_dst_wrap_y;
        screen_dst_wrap_xy.x += TILE_LAYER_WIDTH;
        SDL_BlitSurface(layer, NULL, renderer.screen, &screen_dst_wrap_xy);
      }
      SDL_BlitSurface(layer, NULL, renderer.screen, &screen_dst_wrap_y);
    }
    SDL_BlitSurface(layer, NULL, renderer.screen, &screen_dst);
  }
  // TODO: draw sprites.

  SDL_Flip(renderer.screen);
}
