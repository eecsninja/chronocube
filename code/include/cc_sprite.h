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

// ChronoCube sprite API.

#ifndef _CC_SPRITE_H_
#define _CC_SPRITE_H_

#include <stdint.h>

// Set the location of the sprite in world space.
void CC_Sprite_SetLocation(uint16_t index, uint16_t x, uint16_t y);

// Set alpha value of sprite.
void CC_Sprite_SetAlpha(uint16_t index, uint8_t alpha);

// Enable or disable a sprite.
void CC_Sprite_SetEnabled(uint16_t index, uint8_t enabled);

// Select a palette to be used by the sprite.
void CC_Sprite_SetPalette(uint16_t index, uint8_t palette_index);

#endif  // _CC_SPRITE_H_
