// A quick&dirty TMX map loader
//
// Doesn't support external tilesets
// Tilesets are assumed to only have a single image
// Ignores the transparency color of images (We use the alpha channel)
//
// And probably some other parts. I only implemented what my project required.
// IMPORTANT: Requires you to save your maps with the data layer as XML (Settable in the preference window)

#ifndef _TMXMAP_H_
#define _TMXMAP_H_

#include "object.h"
#include "renderer.h"
#include "texture_atlas.h"
#include <stdbool.h>

typedef enum _TMXMap_orientation {
	kTMXMap_orthogonal,
	kTMXMap_isometric
} TMXMap_orientation;

typedef struct _TMXProperty {
	char *name;
	char *value;
} TMXProperty_t;

typedef struct _TMXTileset {
	int firstTileGid;
	int imageWidth, imageHeight;
	int tileWidth, tileHeight;
	int spacing;
	int margin;
	char *imagePath;
} TMXTileset_t;

typedef struct _TMXTile {
	TMXTileset_t *tileset;
	int id;
	bool flippedVertically;
	bool flippedHorizontally;
} TMXTile_t;

typedef struct _TMXLayer {
	char *name;
	float opacity;
	bool isVisible;
	int numberOfTiles;
	TMXTile_t *tiles;
	int numberOfProperties;
	TMXProperty_t *properties; // Default NULL
} TMXLayer_t;

typedef struct _TMXObject {
	char *name;
	char *type;
	int x, y; // in pixels
	int width, height; // in pixels
	TMXTile_t tile; // Default -1
	int numberOfProperties;
	TMXProperty_t *properties; // Default NULL
} TMXObject_t;

typedef struct _TMXObjectGroup {
	char *name;
	int numberOfObjects;
	TMXObject_t *objects;
	int numberOfProperties;
	TMXProperty_t *properties; // Default NULL
} TMXObjectGroup_t;

extern Class_t Class_TMXMap;
typedef struct _TMXMap {
	OBJ_GUTS
	TMXMap_orientation orientation;
	int width, height; // Dimensions in tiles
	int tileWidth, tileHeight; // Dimensions of tiles in pixels
	
	int numberOfLayers;
	TMXLayer_t *layers;
	int numberOfTilesets;
	TMXTileset_t *tilesets;
	int numberOfObjectGroups;
	TMXObjectGroup_t *objectGroups;
	int numberOfProperties;
	TMXProperty_t *properties;
} TMXMap_t;

extern Class_t Class_TMXLayerRenderable;
// A renderable that manages a vbo for drawing a layer
typedef struct _TMXLayerRenderable {
    OBJ_GUTS
    RENDERABLE_GUTS
    TMXLayer_t *layer;
    TMXMap_t *map; // Reference required so that we can retain it
    TextureAtlas_t *atlas;
    GLuint posVBO, texCoordVBO, indexVBO;
    int indexCount;
} TMXLayerRenderable_t;

extern TMXMap_t *tmx_readMapFile(const char *aFilename);

// Lookup helpers
extern const char *tmx_mapGetPropertyNamed(TMXMap_t *aMap, const char *aPropertyName);
extern TMXLayer_t *tmx_mapGetLayerNamed(TMXMap_t *aMap, const char *aLayerName);
extern TMXObjectGroup_t *tmx_mapGetObjectGroupNamed(TMXMap_t *aMap, const char *aGroupName);
extern TMXObject_t *tmx_objGroupGetObjectNamed(TMXObjectGroup_t *aGroup, const char *aObjName);

// Note: only supports one tileset per layer, uses the tileset set for the first tile which has one.
extern TMXLayerRenderable_t *tmx_createRenderableForLayer(TMXMap_t *aMap, unsigned int aLayerIdx);
#endif
