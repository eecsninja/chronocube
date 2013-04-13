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

// ChronoCube emulator sprite code.

#include "cc_sprite.h"

#include <assert.h>

#include "cc_internal.h"

void CCSprite_SetLocation(uint16_t index, uint16_t x, uint16_t y) {
  CCSprite* sprite = CC_GetSprite(index);
  sprite->x = x;
  sprite->y = y;
}

void CCSprite_SetAlpha(uint16_t index, uint8_t alpha) {
  CC_GetSprite(index)->alpha = alpha;
}

void CCSprite_SetEnabled(uint16_t index, uint8_t enabled) {
  CC_GetSprite(index)->enabled = enabled;
}

void CCSprite_SetPalette(uint16_t index, uint8_t palette_index) {
  CC_GetSprite(index)->palette = palette_index;
}
