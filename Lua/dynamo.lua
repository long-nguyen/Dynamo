-- There's a crasher bug in JIT that I haven't figured out a way to work around
--jit.off()

local ffi = require("ffi")
local lib = ffi.C
local gl = require("OpenGL")

local dynamo = setmetatable({}, { __index = lib })

ffi.cdef[[
typedef float GLMFloat;

// ----- Object
typedef void (*Obj_destructor_t)(void *aSelf);
typedef struct {
	long referenceCount;
	Obj_destructor_t destructor;
} _Obj_guts;

typedef void Obj_t;

Obj_t *obj_create_autoreleased(int size, Obj_destructor_t aDestructor);
Obj_t *obj_retain(Obj_t *aObj);
void obj_release(Obj_t *aObj);
Obj_t *obj_autorelease(Obj_t *aObj);

// ----- Linked list
typedef struct _LinkedList LinkedList_t;
typedef struct _LinkedListItem LinkedListItem_t;
struct _LinkedList {
	_Obj_guts _guts;
	LinkedListItem_t *head;
	LinkedListItem_t *tail;
};

struct _LinkedListItem {
	LinkedListItem_t *previous, *next;
	void *value;
};

extern LinkedList_t *llist_create();

extern void llist_pushValue(LinkedList_t *aList, void *aValue);
extern void *llist_popValue(LinkedList_t *aList);
extern bool llist_insertValue(LinkedList_t *aList, void *aValueToInsert, void *aValueToShift);
extern bool llist_deleteValue(LinkedList_t *aList, void *aValue);
void llist_empty(LinkedList_t *aList);

typedef void (*LinkedListApplier_t)(void *aValue);
extern void llist_apply(LinkedList_t *aList, LinkedListApplier_t aApplier); 


// ----- Renderer
typedef struct _Renderer Renderer_t;
typedef void (*RenderableDisplayCallback_t)(Renderer_t *aRenderer, void *aOwner, GLMFloat aTimeSinceLastFrame, GLMFloat aInterpolation);

// For defining an object you wish to have rendered
typedef struct _Renderable {
	_Obj_guts _guts;
    RenderableDisplayCallback_t displayCallback;
} Renderable_t;

// The renderer object
struct _Renderer {
	_Obj_guts _guts;
	GLuint frameBufferId; // The FBO the renderer should draw to
	vec2_t viewportSize;
	vec3_t cameraOffset;
	matrix_stack_t *worldMatrixStack;
	matrix_stack_t *projectionMatrixStack;
	LinkedList_t *renderables; // For internal use only
};

// Renderer creation
extern Renderer_t *renderer_create(vec2_t aViewPortSize, vec3_t aCameraOffset);

// Display
extern void renderer_display(Renderer_t *aRenderer, GLMFloat aTimeSinceLastFrame, GLMFloat aInterpolation);

// Renderable list management
extern void renderer_pushRenderable(Renderer_t *aRenderer, void *aRenderable);
extern void renderer_popRenderable(Renderer_t *aRenderer);
extern bool renderer_insertRenderable(Renderer_t *aRenderer, void *aRenderableToInsert, void *aRenderableToShift);
extern bool renderer_deleteRenderable(Renderer_t *aRenderer, void *aRenderable);

// ----- Scene

typedef struct _Scene {
	_Obj_guts _guts;
	RenderableDisplayCallback_t displayCallback;
	LinkedList_t *renderables;
	mat4_t transform;
} Scene_t;

extern Scene_t *scene_create();

// Scene object list management (Objects need to conform to the layout of Renderable_t)
extern void scene_pushRenderable(Scene_t *aScene, void *aRenderable);
extern void scene_popRenderable(Scene_t *aScene);
extern bool scene_insertRenderable(Scene_t *aScene, void *aRenderableToInsert, void *aRenderableToShift);
extern bool scene_deleteRenderable(Scene_t *aScene, void *aRenderable);

// ----- Game timer
typedef struct _GameTimer GameTimer_t;
typedef void (*GameTimer_updateCallback_t)(GameTimer_t *aTimer);

// All values are in seconds
struct _GameTimer {
	_Obj_guts _guts;
	GLMFloat elapsed;
	GLMFloat timeSinceLastUpdate;
	GLMFloat desiredInterval; // The minimum interval between updates
	GameTimer_updateCallback_t updateCallback;
};

extern GameTimer_t *gameTimer_create(GLMFloat aFps, GameTimer_updateCallback_t aUpdateCallback);

// Updates the timer and calls the update callback as many times as required to progress up until elapsed
extern void gameTimer_step(GameTimer_t *aTimer, GLMFloat elapsed);

extern GLMFloat gameTimer_interpolationSinceLastUpdate(GameTimer_t *aTimer);

// ----- Texture
typedef struct _Texture {
	_Obj_guts _guts;
	GLuint id;
	vec2_t size;
} Texture_t;

// A  structure to specify areas to sample from a texture (in UV coordinates)
typedef union _TextureRect {
	vec4_t v;
	float *f;
	struct {
		vec2_t origin;
		vec2_t size;
	};
	struct {
		float u, v;
		float w, h;
	};
} TextureRect_t;

extern const TextureRect_t kTextureRectEntire;

extern Texture_t *texture_loadFromPng(const char *aPath, bool aRepeatHorizontal, bool aRepeatVertical);
// Generates a UV texture rectangle from pixel coordinates
extern TextureRect_t textureRectangle_createWithPixelCoordinates(Texture_t *aTexture, vec2_t aOrigin, vec2_t aSize);
extern TextureRect_t textureRectangle_createWithSizeInPixels(Texture_t *aTexture, vec2_t aSize);
// Takes UV (0.0-1.0) coordinates
extern TextureRect_t textureRectangle_create(float aX, float aY, float aWidth, float aHeight);

// ----- Texture Atlas
typedef struct _TextureAtlas {
	_Obj_guts _guts;
	vec2_t origin; // The point to consider as (0,0)
	vec2_t size; // The size of each subtexture
	vec2_t margin; // The gap between frames in the texture
	Texture_t *texture;
} TextureAtlas_t;

extern TextureAtlas_t *texAtlas_create(Texture_t *aTexture, vec2_t aOrigin, vec2_t aSize);
// Gets the sampling rectangle for the subtexture at a given offset
extern TextureRect_t texAtlas_getTextureRect(TextureAtlas_t *aAtlas, int x, int y);

// ----- Draw utils
// Rectangles (Origin: bottom left)
union _rect_t {
	float f[4];
	struct { vec2_t o; vec2_t s; };
	struct { vec2_t origin; vec2_t size; };
};
typedef union _rect_t rect_t;

extern void draw_init(Renderer_t *aDefaultRenderer);
extern void draw_cleanup();

extern void draw_quad(vec3_t aCenter, vec2_t aSize, Texture_t *aTexture, TextureRect_t aTextureArea, vec4_t aColor, float aAngle, bool aFlipHorizontal, bool aFlipVertical);

// Draws a specified portion of a texture onto a quad of the same size as the portion sampled
extern void draw_texturePortion(vec3_t aCenter, Texture_t *aTexture, TextureRect_t aTextureArea, float aScale, float aAngle, bool aFlipHorizontal, bool aFlipVertical);

// Draws a texture onto a quad of the same size
extern void draw_texture(vec3_t aCenter, Texture_t *aTexture, float aScale, float aAngle, bool aFlipHorizontal, bool aFlipVertical);

// Draws multiple subtextures at different locations using a texture atlas (In a single draw call, useful for performing
// multiple simple draws, such as when drawing a tiled level)
// aOffsets: an array of [x,y] offsets in the texture atlas (Cast to int)
// aCenterPoints: an array of points to draw the tiles at
extern void draw_textureAtlas(TextureAtlas_t *aAtlas, int aNumberOfTiles, vec2_t *aOffsets, vec2_t *aCenterPoints);

// Generates the vertices used by the above function (use this if you want to store your vertices in a VBO when handling
// larger meshes
extern void draw_textureAtlas_getVertices(TextureAtlas_t *aAtlas, int aNumberOfTiles, vec2_t *aOffsets, vec2_t *aCenterPoints,
	vec2_t **aoVertices, vec2_t **aoTexCoords, int *aoNumberOfVertices, GLuint **aoIndices, int *aoNumberOfIndices);


// Draws an untextured rectangle
extern void draw_rect(rect_t aRect, float aAngle, vec4_t aColor, bool aShouldFill);

// Draws an untextured ellipse
extern void draw_ellipse(vec2_t aCenter, vec2_t aRadii, int aSubdivisions, float aAngle, vec4_t aColor, bool aShouldFill);

// Draws an untextured circle
extern void draw_circle(vec2_t aCenter, float radius, int aSubdivisions, vec4_t aColor, bool aShouldFill);

// Draws an untextured polygon
extern void draw_polygon(int aNumberOfVertices, vec2_t *aVertices, vec4_t aColor, bool aShouldFill);

// Draws a line segment
extern void draw_lineSeg(vec2_t aPointA, vec2_t aPointB, vec4_t aColor);

// ----- Sprite
typedef struct _SpriteAnimation {
	int numberOfFrames;
	int currentFrame;
	bool loops;
} SpriteAnimation_t;

typedef struct _Sprite {
	_Obj_guts _guts;
	RenderableDisplayCallback_t displayCallback;
	TextureAtlas_t *atlas;
	vec3_t location;
	vec2_t size;
	float scale, angle;
	bool flippedHorizontally;
	bool flippedVertically;
	int activeAnimation; // The y offset of the active animation
	SpriteAnimation_t *animations;
} Sprite_t;

extern Sprite_t *sprite_create(vec3_t aLocation, vec2_t aSize, TextureAtlas_t *aAtlas, int aAnimationCapacity);
extern SpriteAnimation_t sprite_createAnimation(int aNumberOfFrames);

extern void sprite_step(Sprite_t *aSprite);

// ----- Background
typedef struct _BackgroundLayer {
	_Obj_guts _guts;
	Texture_t *texture;
	float depth;
} BackgroundLayer_t;

typedef struct _Background {
	_Obj_guts _guts;
	RenderableDisplayCallback_t displayCallback;
	BackgroundLayer_t *layers[4];
	vec2_t offset;
} Background_t;

extern Background_t *background_create();

extern void background_setLayer(Background_t *aBackground, unsigned int aIndex, BackgroundLayer_t *aLayer);
extern BackgroundLayer_t *background_createLayer(Texture_t *aTexture, float aDepth);

// ----- Input
typedef enum {
	kInputKey_arrowLeft,
	kInputKey_arrowRight,
	kInputKey_arrowUp,
	kInputKey_arrowDown,
	kInputKey_ascii,
	kInputMouse_leftClick,
	kInputMouse_rightClick,
	kInputMouse_leftDrag,
	kInputMouse_rightDrag,
	kInputMouse_move,

	// Touch events
	kInputTouch_tap1,
	kInputTouch_tap2,
	kInputTouch_tap3,
	kInputTouch_tap4,
	kInputTouch_tap5,
	kInputTouch_pan1,
	kInputTouch_pan2,
	kInputTouch_pan3,
	kInputTouch_pan4,
	kInputTouch_pan5

} Input_type_t;

typedef enum {
	kInputState_down,
	kInputState_up
} Input_state_t;

typedef struct _InputManager InputManager_t;
typedef struct _InputObserver InputObserver_t;

typedef void (*Input_handler_t)(InputManager_t *aInputManager, InputObserver_t *aInputObserver, vec2_t *aLocation, Input_state_t aState, void *aMetaData);

struct _InputObserver {
	_Obj_guts _guts;
	Input_handler_t handlerCallback;
	Input_type_t type;
	unsigned char code; // Used for ASCII keys
	void *metaData; // Arbitrary pointer for providing context

	Input_state_t lastKnownState;
};
struct _InputManager {
	_Obj_guts _guts;
	LinkedList_t *observers;
	LinkedList_t *activeEvents;
};

extern InputManager_t *input_createManager();
extern InputObserver_t *input_createObserver(Input_type_t aObservedType, Input_handler_t aHandlerCallback, char *aCode, void *aMetaData);

extern void input_addObserver(InputManager_t *aManager, InputObserver_t *aObserver);
extern bool input_removeObserver(InputManager_t *aManager, InputObserver_t *aObserver);


// Called from within the run loop to post an instance of each active event (held keys)
extern void input_postActiveEvents(InputManager_t *aManager);
// Calls any observers for a certain type of input
extern void input_postMomentaryEvent(InputManager_t *aManager, Input_type_t aType, unsigned char *aCode, vec2_t *aLocation, Input_state_t aState);
// Activates an event so it gets posted once per cycle
extern void input_beginEvent(InputManager_t *aManager, Input_type_t aType, unsigned char *aCode, vec2_t *aLocation);
extern void input_endEvent(InputManager_t *aManager, Input_type_t aType, unsigned char *aCode);

// ---- Maps
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

typedef struct _TMXMap {
	_Obj_guts _guts;
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

extern TMXMap_t *tmx_readMapFile(const char *aFilename);

// A renderable that manages a vbo for drawing a layer
typedef struct _TMXLayerRenderable {
	_Obj_guts _guts;
	RenderableDisplayCallback_t displayCallback;
	TMXLayer_t *layer;
	TMXMap_t *map; // Reference required so that we can retain it
	TextureAtlas_t *atlas;
	GLuint posVBO, texCoordVBO, indexVBO;
	int indexCount;
} TMXLayerRenderable_t;

extern TMXLayerRenderable_t *tmx_createRenderableForLayer(TMXMap_t *aMap, unsigned int aLayerIdx);

// Lookup helpers
extern const char *tmx_mapGetPropertyNamed(TMXMap_t *aMap, const char *aPropertyName);
extern TMXLayer_t *tmx_mapGetLayerNamed(TMXMap_t *aMap, const char *aLayerName);
extern TMXObjectGroup_t *tmx_mapGetObjectGroupNamed(TMXMap_t *aMap, const char *aGroupName);
extern TMXObject_t *tmx_objGroupGetObjectNamed(TMXObjectGroup_t *aGroup, const char *aObjName);


extern bool util_pathForResource(const char *name, const char *ext, const char *dir, char *output, int maxLen);
]]

dynamo.kBackground_maxLayers = 4

--
-- Utilities

-- Retains an object and tells the gc to release it when it's no longer referenced
local function _obj_addToGC(obj)
	lib.obj_retain(obj)
	ffi.gc(obj, lib.obj_release)
	return obj
end

function dynamo.pathForResource(name, type, directory)
	type = type or nil
	directory = directory or nil
	local maxLen = 1024
	local strPtr = ffi.new("char[?]", maxLen)
	local exists = lib.util_pathForResource(name, type, directory, strPtr, maxLen)
	if exists then
		return ffi.string(strPtr)
	else
		return nil
	end
end

--
-- Textures
function dynamo.loadTexture(path)
	local tex = lib.texture_loadFromPng(path, false, false)
	if tex == nil then
		print("Couldn't find texture at path", path)
		return nil
	end
	return _obj_addToGC(tex)
end


--
-- Texture atlases
ffi.metatype("TextureAtlas_t", {
	__index = {
		getTextureRect = lib.texAtlas_getTextureRect,
	}
})

function dynamo.createTextureAtlas(texture, origin, size)
	assert(texture)
	local tex = lib.texAtlas_create(texture, origin, size)
	return _obj_addToGC(tex)
end

function dynamo.loadTextureAtlas(path, origin, size)
	local tex = dynamo.loadTexture(path)
	local atlas = dynamo.createTextureAtlas(tex, origin, size)
	return _obj_addToGC(atlas)
end

--
-- Sprites
--
ffi.metatype("Sprite_t", {
	__index = {
		step = lib.sprite_step
	}
})

function dynamo.createSprite(location, size, atlas, animations)
	animations = animations or {}
	local sprite = lib.sprite_create(location, size, atlas, #animations)
	lib.obj_retain(sprite)

	-- Add the animations to the sprite
	for i, animation in pairs(animations) do
		sprite.animations[i-1] = animation
	end

	return _obj_addToGC(sprite)
end

--
-- The Renderer

ffi.metatype("Renderer_t", {
	__index = {
		display = lib.renderer_display,
		pushRenderable = lib.renderer_pushRenderable,
		popRenderable = lib.renderer_popRenderable,
		insertRenderable = lib.renderer_pushRenderable,
		deleteRenderable = lib.renderer_deleteRenderable,
		handleResize = function(self, viewport)
			self.viewportSize = viewport
			self.projectionMatrixStack:pushItem(mat4_ortho(0, viewport.w, viewport.h, 0, -1, 1));
		end
	}
})

local function _createRenderer(viewportSize)
	local renderer = lib.renderer_create(viewportSize, {{0,0,0}})
	return _obj_addToGC(renderer)
end


--
-- Scenes

ffi.metatype("Scene_t", {
	__index = {
		pushRenderable = lib.scene_pushRenderable,
		popRenderable = lib.scene_popRenderable,
		insertRenderable = lib.scene_pushRenderable,
		deleteRenderable = lib.scene_deleteRenderable,
		rotate = function(self, angle)
			self.transform = mat4_rotate(self.transform, angle, 0, 0, 1)
		end,
		scale = function(self, x, y)
			self.transform = mat4_scale(self.transform, x, y, 0)
		end,
		translate = function(self, x, y)
			self.transform = mat4_translate(self.transform, x, y, 0)
		end
	}
})

function dynamo.createScene(renderables, initialTransform)
	objects = objects or {}
	initialTransform = initialTransform or mat4_identity

	local scene = lib.scene_create()
	for i,renderable in pairs(renderables) do
		scene:pushRenderable(renderable)
	end
	scene.transform = initialTransform

	return _obj_addToGC(scene)
end

--
-- Input manager

ffi.metatype("InputManager_t", {
	__index = {
		addObserver = function(self, desc)
			local observer = lib.input_createObserver(desc.type, desc.callback, desc.charCode, desc.metaData)
			lib.input_addObserver(self, observer)
			return _obj_addToGC(observer)
		end,
		removeObserver = lib.input_removeObserver,
		postActiveEvents = lib.input_postActiveEvents,
		postMomentaryEvent = lib.input_postMomentaryEvent,
		beginEvent = lib.input_beginEvent,
		endEvent = lib.input_endEvent
	}
})

local function _createInputManager()
	local inputManager = lib.input_createManager()
	return _obj_addToGC(inputManager)
end


--
-- Game timer

ffi.metatype("GameTimer_t", {
	__index = {
		step = lib.gameTimer_step,
		interpolation = lib.gameTimer_interpolationSinceLastUpdate
	}
})

local function _createTimer(desiredFPS, updateCallback)
	local timer = lib.gameTimer_create(desiredFPS, updateCallback)
	return _obj_addToGC(timer)
end

-- Time function (IOS/MacOS only! for now)
ffi.cdef[[
struct mach_timebase_info {
	uint32_t	numer;
	uint32_t	denom;
};
typedef struct mach_timebase_info *mach_timebase_info_t;
typedef struct mach_timebase_info	mach_timebase_info_data_t;

void mach_timebase_info(mach_timebase_info_t info);
uint64_t mach_absolute_time(void);
]]
local C = ffi.C
function dynamo.globalTime()
	local timebase = ffi.new("mach_timebase_info_data_t[1]")
	C.mach_timebase_info(timebase)
	local absolute = C.mach_absolute_time()
	local nanosec = (absolute * timebase[0].numer) / timebase[0].denom

	return tonumber(nanosec)/1000000000
end

dynamo.startTime = dynamo.globalTime()
function dynamo.time()
    return dynamo.globalTime() - dynamo.startTime
end


function dynamo.renderable(lambda)
	local drawable = ffi.cast("Renderable_t*", lib.obj_create_autoreleased(ffi.sizeof("Renderable_t"), nil))
	drawable.displayCallback = lambda
	return drawable
end


--
-- Maps
ffi.metatype("TMXMap_t", {
	__index = {
		getProperty = lib.tmx_mapGetPropertyNamed,
		getLayer = tmx_mapGetLayerNamed,
		getObjectGroup = tmx_mapGetObjectGroupNamed,
		createLayerRenderable = lib.tmx_createRenderableForLayer
	}
})

ffi.metatype("TMXLayer_t", {
	__index = {
		-- Generates the texture offsets and screen coordinates to draw each tile
		generateAtlasDrawInfo = function(self, map)
			local texOffsets = ffi.new("vec2_t[?]", self.numberOfTiles)
			local screenCoords = ffi.new("vec2_t[?]", self.numberOfTiles)
			
			for y=0, map.height-1 do
				for x=0, map.width-1 do
					local idx = y*map.width + x
					local tile = self.tiles[idx]
					texOffsets[idx] = tile.tileset:texCoordForID(tile.id)
					screenCoords[idx] = vec2(math.floor(map.tileWidth*x + map.tileWidth/2), math.floor(map.tileHeight*y + map.tileHeight/2))
				end
			end
			return screenCoords, texOffsets
		end

	}
})

ffi.metatype("TMXObjectGroup_t", {
	__index = function(self, key)
		return lib.tmx_objGroupGetObjectNamed(self, key)
	end
})

function math.round(num)
	return math.floor(num+0.5)
end

ffi.metatype("TMXTileset_t", {
	__index = {
		loadAtlas = function(self)
			local fullPath = dynamo.pathForResource(self.imagePath)
			assert(fullPath ~= nil)
			local tex = dynamo.loadTexture(fullPath)
			assert(tex ~= nil)
			local atlas = dynamo.createTextureAtlas(tex, vec2(self.margin, self.margin), vec2(self.tileWidth, self.tileHeight))
			atlas.margin = vec2(self.spacing, self.spacing)
			return atlas
		end,
		texCoordForID = function(self, id)
			local tilesPerRow = math.floor((self.imageWidth - self.spacing) / (self.tileWidth + self.spacing))
			local u = id % tilesPerRow
			local rows = math.floor((self.imageHeight - self.spacing) / (self.tileHeight + self.spacing))
			local v = math.floor(id / tilesPerRow)
			return vec2(u,v)
		end
	}
})

dynamo.loadMap = lib.tmx_readMapFile


--
-- Lifecycle/HighLevelInterface functions

dynamo.initialized = false
function dynamo.init(viewport, desiredFPS, updateCallback)
	assert(dynamo.initialized == false)
	dynamo.initialized = true

	dynamo.renderer = _createRenderer(viewport)
	lib.draw_init(dynamo.renderer)
	dynamo.renderer:handleResize(viewport)
	
	dynamo.timer = _createTimer(desiredFPS, updateCallback)
	lib.obj_retain(dynamo.renderer)
	lib.obj_retain(dynamo.timer)

	dynamo.inputManager = _createInputManager()

	return dynamo.renderer, dynamo.timer
end

function dynamo.cleanup()
	-- Release all resources
	dynamo.renderer = nil
	dynamo.timer = nil
	dynamo.inputManager = nil
	lib.draw_cleanup()
end

function dynamo.postTapEvent(finger, isDown, x, y)
	finger = finger or 0
	local pos = vec2(x or 0, y or 0)
	local state = lib.kInputState_up
	if isDown == true then 
		state = lib.kInputState_down
	end
	dynamo.inputManager:postMomentaryEvent(lib.kInputTouch_tap1+finger, nil, pos, state)
end

function dynamo.postPanEvent(finger, isDown, x, y)
	finger = finger or 0
	local pos = vec2(x or 0, y or 0)
	local state = lib.kInputState_up
	if isDown == 1 or isDown == true then
		state = lib.kInputState_down
	end
	dynamo.inputManager:postMomentaryEvent(lib.kInputTouch_pan1+finger, nil, pos, state)
end

function dynamo.cycle()
	dynamo.inputManager:postActiveEvents()
	dynamo.timer:step(dynamo.time())
	dynamo.renderer:display(dynamo.timer.timeSinceLastUpdate, dynamo.timer:interpolation())
end

return dynamo
