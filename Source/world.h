// The game world
// Handles the state of the game

#include "engine/background.h"
#include "engine/input.h"
#include "level.h"
#include "collision.h"
#include "menu.h"

#ifndef _WORLD_H_
#define _WORLD_H_

typedef struct _World World_t;

struct _World {
	double time; // Game time in seconds
	long ticks; // Number of game updates since beginning (roughly time/FPS)

	MainMenu_t *menu;

	Level_t *level;

	InputObserver_t *arrowRightObserver;
	InputObserver_t *arrowLeftObserver;
	InputObserver_t *arrowUpObserver;
	InputObserver_t *arrowDownObserver;
};

extern World_t *world_init();
extern void world_destroy(World_t *aWorld);
void world_update(World_t *aWorld, double aTimeDelta);
#endif
