#include "gametimer.h"
#include "various.h"

void gameTimer_update(GameTimer_t *aTimer, double aDelta)
{
	aTimer->elapsed += aDelta;
	aTimer->timeSinceLastUpdate = MAX(0.0, aTimer->timeSinceLastUpdate+aDelta);
}

void gameTimer_finishedFrame(GameTimer_t *aTimer)
{
	aTimer->timeSinceLastUpdate -= aTimer->desiredInterval;	
}

bool gameTimer_reachedNextFrame(GameTimer_t *aTimer)
{
	return !(aTimer->timeSinceLastUpdate >= aTimer->desiredInterval);
}

double gameTimer_interpolationSinceLastFrame(GameTimer_t *aTimer)
{
	return aTimer->timeSinceLastUpdate / aTimer->desiredInterval;
}
