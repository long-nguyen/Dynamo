// Just handles the runloop

#include <stdio.h>
#include "engine/glutils.h"
#include "shared.h"
#include <SDL/SDL.h>

#ifdef WIN32
	#define _CRT_SECURE_NO_DEPRECATE
	#define _WIN32_LEAN_AND_MEAN
	#include <windows.h>
	#include "engine/windows/gldefs.h"
#endif

// Constants 
#define MSEC_PER_SEC (1000)

// Globals
Renderer_t *gRenderer;
World_t *gWorld;
GameTimer_t gGameTimer;
InputManager_t *gInputManager;
SoundManager_t *gSoundManager;

// Locals
static bool _leftMouseButtonDown, _rightMouseButtonDown;
static Uint32 lastTime;
static bool _shouldExit = false;

// Functions
static void cleanup();

#pragma mark - Drawing


static void windowDidResize(int aWidth, int aHeight)
{
	gRenderer->viewportSize.w = (float)aWidth;
	gRenderer->viewportSize.h = (float)aHeight;

	matrix_stack_pop(gRenderer->projectionMatrixStack);
	matrix_stack_push_item(gRenderer->projectionMatrixStack, mat4_ortho(0.0f, (float)aWidth, 0.0f, (float)aHeight, -1.0f, 1.0f));
}


#pragma mark - Event handling

static Input_type_t _inputTypeForSDLKey(SDLKey aKey)
{
	switch(aKey) {
		case SDLK_LEFT:
			return kInputKey_arrowLeft;
		case SDLK_RIGHT:
			return kInputKey_arrowRight;
		case SDLK_UP:
			return kInputKey_arrowUp;
		case SDLK_DOWN:
			return kInputKey_arrowDown;
		default:
			return -1;
	}
}

static void handleEvent(SDL_Event aEvent)
{
	switch(aEvent.type) {
		case SDL_ACTIVEEVENT:
		{
			if (aEvent.active.gain) {
				// Resume
			}
			else {
				 // Pause
			}
			break;
		}
		case SDL_VIDEORESIZE:
		{
			windowDidResize(aEvent.resize.w, aEvent.resize.h);
		}
		case SDL_KEYDOWN:
		{
			if(aEvent.key.keysym.sym == 'q')
				_shouldExit = true;
			if(aEvent.key.keysym.sym < 127)
				input_beginEvent(gInputManager, kInputKey_ascii, (unsigned char*)&aEvent.key.keysym.sym, NULL);
			else {
				Input_type_t inputType = _inputTypeForSDLKey(aEvent.key.keysym.sym);
				if(inputType != -1)
					input_beginEvent(gInputManager, inputType, NULL, NULL);
			}
			break;
		}
		case SDL_KEYUP:
		{
			if(aEvent.key.keysym.sym < 127)
				input_endEvent(gInputManager, kInputKey_ascii, (unsigned char*)&aEvent.key.keysym.sym);
			else {
				Input_type_t inputType = _inputTypeForSDLKey(aEvent.key.keysym.sym);
				if(inputType == -1) break;
				input_endEvent(gInputManager, inputType, NULL);
			}
			break;
		}
		case SDL_MOUSEMOTION:
		{
			SDL_MouseMotionEvent motion = aEvent.motion;
			vec2_t location = { (float)motion.x, gRenderer->viewportSize.h - (float)motion.y };
			input_postMomentaryEvent(gInputManager, kInputMouse_move, NULL, &location, kInputState_up);

			if(_leftMouseButtonDown)
				input_postMomentaryEvent(gInputManager, kInputMouse_leftDrag, NULL, &location, kInputState_down);
			if(_rightMouseButtonDown)
				input_postMomentaryEvent(gInputManager, kInputMouse_rightDrag, NULL, &location, kInputState_down);
			break;
		}
		case SDL_MOUSEBUTTONDOWN:
		case SDL_MOUSEBUTTONUP:
		{
			SDL_MouseButtonEvent buttonEvent = aEvent.button;
			vec2_t location = { (float)buttonEvent.x, gRenderer->viewportSize.h - (float)buttonEvent.y };

			Input_type_t inputType;
			switch(buttonEvent.button) {
				case SDL_BUTTON_LEFT:
					_leftMouseButtonDown = (buttonEvent.state == SDL_PRESSED);
					inputType = kInputMouse_leftClick;
					break;
				case SDL_BUTTON_RIGHT:
					_rightMouseButtonDown = (buttonEvent.state == SDL_PRESSED);
					inputType = kInputMouse_rightClick;
					break;
				default:
					return;
			}
			input_postMomentaryEvent(gInputManager, inputType, NULL,
									 &location, (buttonEvent.state == SDL_PRESSED) ? kInputState_down : kInputState_up);
			break;
		}
	}
}


#pragma mark - Initialization

static void cleanup()
{
	debug_log("Quitting...");
	soundManager_destroy(gSoundManager);
	world_destroy(gWorld);
	renderer_destroy(gRenderer);
	input_destroyManager(gInputManager);
	draw_cleanup();
	SDL_Quit();
}


static SDL_Surface *_sdlSurface;

int main(int argc, char **argv)
{
	vec2_t viewport = { 800.0f, 600.0f };

	// Initialize graphics
	if(SDL_Init(SDL_INIT_VIDEO) < 0) {
		debug_log("Couldn't initialize SDL");
		return 1;
	}
	atexit(&cleanup);

	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
	SDL_GL_SetAttribute(SDL_GL_SWAP_CONTROL, 1); // VSync
	_sdlSurface = SDL_SetVideoMode(viewport.w, viewport.h, 0, SDL_OPENGL);
	if(!_sdlSurface) {
		debug_log("Couldn't initialize SDL surface");
		return 1;
	}
	#ifdef GL_GLEXT_PROTOTYPES
		loadGLExtensions(); // Load GL on windows
	#endif

	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glDisable(GL_DEPTH_TEST);
	glLineWidth(2.0);
	glEnable(GL_LINE_SMOOTH);
	glEnable(GL_POINT_SMOOTH);
	glEnable(GL_POLYGON_SMOOTH);
	glHint(GL_LINE_SMOOTH_HINT,GL_NICEST);
	glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
	glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);

	gSoundManager = soundManager_create();
	//Sound_t *testSound = sound_load("audio/test.ogg");
	//sound_play(testSound);

	gRenderer = renderer_create(viewport, kVec3_zero);
	draw_init(gRenderer);

	gGameTimer.desiredInterval = 1.0/(double)DESIRED_FPS;
	gGameTimer.elapsed = 0.0;
	gGameTimer.timeSinceLastUpdate = 0.0;

	gInputManager = input_createManager();

	gWorld = world_init();

	// Enter the runloop
	windowDidResize((int)viewport.w, (int)viewport.h);
	while(!_shouldExit) {
		SDL_Event event;
		while (SDL_PollEvent(&event)) {
			handleEvent(event);
		}

		double delta = 0.0;
		Uint32 currentTime = SDL_GetTicks();
		if(lastTime > 0) {
			Uint32 deltaMsec = currentTime - lastTime;
			delta = (double)deltaMsec / (double)MSEC_PER_SEC;
			gameTimer_update(&gGameTimer, delta);
		}
		lastTime = currentTime;

		// Update the game state as many times as we need to catch up
		for(int i = 0; (i < MAX_FRAMESKIP) && !gameTimer_reachedNextUpdate(&gGameTimer); ++i) {
			input_postActiveEvents(gInputManager);
			world_update(gWorld, delta);
			gameTimer_finishedUpdate(&gGameTimer);
		}
		
		renderer_display(gRenderer, gGameTimer.timeSinceLastUpdate, gameTimer_interpolationSinceLastUpdate(&gGameTimer));		
		SDL_GL_SwapBuffers();
	}

	return 0;
}
