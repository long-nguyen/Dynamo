// Utilities for simple drawing

#include "GLMath/GLMath.h"
#include "texture.h"
#include "texture_atlas.h"

#ifndef __DRAWUTILS_H_
#define __DRAWUTILS_H_

// Draws a textured quad on the X/Y plane
extern void draw_quad(vec3_t aCenter, vec2_t aSize, Texture_t *aTexture, TextureRect_t aTextureArea, vec4_t aColor, float aAngle, bool aFlipHorizontal, bool aFlipVertical);
// Draws a specified portion of a texture onto a quad of the same size as the portion sampled
extern void draw_texturePortion(vec3_t aCenter, Texture_t *aTexture, TextureRect_t aTextureArea, float aScale, float aAngle, bool aFlipHorizontal, bool aFlipVertical);
// Draws a texture onto a quad of the same size
extern void draw_texture(vec3_t aCenter, Texture_t *aTexture, float aScale, float aAngle, bool aFlipHorizontal, bool aFlipVertical);
// Draws multiple subtextures at different locations using a texture atlas (In a single draw call, useful for performing
// multiple simple draws, such as when drawing a tiled level)
// aOffsets: an array of [x,y] offsets in the texture atlas (Cast to int)
// aCenterPoints: an array of points to draw the tiles at

// TODO: Actually test this!
extern void draw_textureAtlas(TextureAtlas_t *aAtlas, int aNumberOfTiles, vec2_t *aOffsets, vec2_t *aCenterPoints);
#endif
