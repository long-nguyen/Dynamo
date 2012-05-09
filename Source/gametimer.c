#include "gametimer.h"
#include "util.h"

Class_t Class_GameTimer = {
	"GameTimer",
	sizeof(GameTimer_t),
	NULL
};

GameTimer_t *gameTimer_create(GLMFloat aFps, GameTimer_updateCallback_t aUpdateCallback)
{
	GameTimer_t *out = obj_create_autoreleased(&Class_GameTimer);
	out->desiredInterval = 1.0/(aFps > 0.0 ? aFps : 60.0);
	out->updateCallback = aUpdateCallback;

	return out;
}

extern void gameTimer_step(GameTimer_t *aTimer, GLMFloat aElapsed)
{
	GLMFloat delta = aElapsed - aTimer->elapsed;
	aTimer->timeSinceLastUpdate = MAX(0.0, aTimer->timeSinceLastUpdate+delta);
	aTimer->elapsed = aElapsed;
	for(; aTimer->timeSinceLastUpdate > aTimer->desiredInterval; aTimer->timeSinceLastUpdate -= aTimer->desiredInterval) {
		if(aTimer->updateCallback)
			aTimer->updateCallback(aTimer);
		++aTimer->ticks;
	}
}

GLMFloat gameTimer_interpolationSinceLastUpdate(GameTimer_t *aTimer)
{
	return aTimer->timeSinceLastUpdate / aTimer->desiredInterval;
}
