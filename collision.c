#include "collision.h"
#include <float.h>
#include "engine/various.h"
#include "engine/drawutils.h"
#include "engine/GLMath/GLMath.h"

// Draws a wireframe of the collision world to aid with debugging
static void _collision_drawDebugView(Renderer_t *aRenderer, void *aOwner, double aTimeSinceLastFrame, double aInterpolation);

CollisionWorld_t *collision_createWorld(vec2_t aGravity, vec2_t aSize, float aCellSize)
{
	CollisionWorld_t *out = malloc(sizeof(CollisionWorld_t));
	out->debugRenderable.displayCallback = &_collision_drawDebugView;
	out->debugRenderable.owner = out;
	out->gravity = aGravity;
	out->spatialHash = spatialHash_create(aSize, aCellSize);

	return out;
}

void collision_destroyWorld(CollisionWorld_t *aWorld)
{
	spatialHash_destroy(aWorld->spatialHash);
	free(aWorld);
}

CollisionPolyObject_t *collision_createPolyObject(int aNumberOfEdges, vec2_t *aVertices, float aFriction, float aBounce)
{
	CollisionPolyObject_t *out = malloc(sizeof(CollisionPolyObject_t));
	out->numberOfEdges = aNumberOfEdges;
	out->velocity = kVec2_zero;
	out->frictionCoef = aFriction;
	out->bounceCoef = aBounce;
	out->vertices = malloc(aNumberOfEdges * sizeof(vec2_t));
	memcpy(out->vertices, aVertices, aNumberOfEdges * sizeof(vec2_t));
	out->normals = malloc(aNumberOfEdges * sizeof(vec2_t));

	int currSide = 0;
	vec2_t pointA, pointB;
	float minX, minY, maxX, maxY; // For creating the bounding box
	float totalX = 0.0f, totalY = 0.0f; // For calculating the center of the polygon
	while(collision_getPolyObjectEdges(out, currSide, &pointA, &pointB, NULL)) {
		if(currSide == 0 || minX > pointA.x) minX = pointA.x;
		if(currSide == 0 || minX > pointB.x) minX = pointB.x;
		if(currSide == 0 || minY > pointA.y) minY = pointA.y;
		if(currSide == 0 || minY > pointB.y) minY = pointB.y;
		if(currSide == 0 || maxX < pointA.x) maxX = pointA.x;
		if(currSide == 0 || maxX < pointB.x) maxX = pointB.x;
		if(currSide == 0 || maxY < pointA.y) maxY = pointA.y;
		if(currSide == 0 || maxY < pointB.y) maxY = pointB.y;

		totalX += pointA.x;
		totalY += pointA.y;

		// Calculate the normal vector
		vec2_t aToB = vec2_sub(pointB, pointA);
		out->normals[currSide] = vec2_normalize(vec2_create(-1.0f*aToB.y, aToB.x));

		++currSide;
	}
	out->boundingBox = rect_create(minX, minY, maxX, maxY);
	out->center = vec2_create(totalX/(float)out->numberOfEdges, totalY/(float)out->numberOfEdges);

	// Make the vertices relative to the center
	for(int i = 0; i < out->numberOfEdges; ++i)
		out->vertices[i] = vec2_sub(out->vertices[i], out->center);

	return out;
}

// Sets the center & updates the bounding box
void collision_setPolyObjectCenter(CollisionPolyObject_t *aObject, vec2_t aCenter)
{
	vec2_t delta = vec2_sub(aCenter, aObject->center);
	aObject->boundingBox = rect_translate(aObject->boundingBox, delta);
	aObject->center = aCenter;
}

#pragma mark - Collision detection

bool collision_getPolyObjectEdges(CollisionPolyObject_t *aObject, int aEdgeIndex,
                                  vec2_t *aoPointA, vec2_t *aoPointB, vec2_t *aoNormal)
{
	// Bail for invalid indices
	if(aEdgeIndex < 0 || aEdgeIndex > (aObject->numberOfEdges - 1))
		return false;

	if(aoPointA) *aoPointA = aObject->vertices[aEdgeIndex];
	int indexB = aEdgeIndex+1;
	if(indexB == aObject->numberOfEdges) indexB = 0;
	if(aoPointB) *aoPointB = aObject->vertices[indexB];

	if(aoNormal) *aoNormal = aObject->normals[aEdgeIndex];

	return true;
}

// Returns the distance along the ray to the intersection point with the given line
float _collision_intersectLine(vec2_t aRayOrigin, vec2_t aRayDirection, vec2_t aLineOrigin, vec2_t aLineNormal)
{
	float numer = vec2_dot(vec2_sub(aLineOrigin, aRayOrigin), aLineNormal);
	float denom = vec2_dot(aRayDirection, aLineNormal);

	return numer/denom;
}

vec2_t _collision_closestPointOnLineSeg(vec2_t aQueryPoint, vec2_t aPointA, vec2_t aPointB)
{
	vec2_t lineSegVec = vec2_sub(aPointB, aPointA);
	vec2_t lineDir = vec2_normalize(lineSegVec);
	float lineLen = vec2_mag(lineSegVec);
	vec2_t c = vec2_sub(aQueryPoint, aPointA);
	float t = vec2_dot(lineDir, c);

	if(t <= 0.0f) return aPointA;
	else if(t >= lineLen) return aPointB;

	return vec2_add(aPointA, vec2_scalarMul(lineDir, t));
}

// X component: min, Y component: max
vec2_t _collision_projectPolyShape(CollisionPolyObject_t *aInputObject, vec2_t aLineNormal)
{
	float min = vec2_dot(aLineNormal, vec2_add(aInputObject->center, aInputObject->vertices[0]));
	float max = min;
	int side = 1;
	vec2_t point;
	float p;
	while(collision_getPolyObjectEdges(aInputObject, side++, &point, NULL, NULL)) {
		p = vec2_dot(vec2_add(aInputObject->center, point), aLineNormal);
		min = MIN(min, p);
		max = MAX(max, p);
	}
	vec2_t out = { min, max };
	return out;
}

float _collision_overlapOfProjections(vec2_t aLeft, vec2_t aRight)
{
	if(aLeft.y > aRight.y)
		return aRight.y - aLeft.x;
	else
		return aLeft.y - aLeft.x;
}
bool _collision_doProjectionsOverlap(vec2_t aLeft, vec2_t aRight)
{
	float total = MAX(aLeft.y, aLeft.y) - MIN(aLeft.x, aRight.x);
	float leftLength = aLeft.y - aLeft.x;
	float rightLength = aRight.y - aRight.x;
	
	return total <= (leftLength+rightLength);
}

bool collision_intersectObjects(CollisionPolyObject_t *aObjectA, CollisionPolyObject_t *aObjectB,
                                float *aoOverlap, vec2_t *aoOverlapAxis)
{
	float overlap = FLT_MAX;
	vec2_t overlapAxis;

	int side = 0;
	vec2_t normal;
	vec2_t projectionA, projectionB;
	float currOverlap;
	while(collision_getPolyObjectEdges(aObjectB, side++, NULL, NULL, &normal)) {
		projectionA = _collision_projectPolyShape(aObjectA, normal);
		projectionB = _collision_projectPolyShape(aObjectB, normal);
		if(!_collision_doProjectionsOverlap(projectionA, projectionB))
			return false;
		
		currOverlap = _collision_overlapOfProjections(projectionA, projectionB);
		if(currOverlap < overlap) {
			overlap = currOverlap;
			overlapAxis = normal;
		}
	}
	side = 0;
	while(collision_getPolyObjectEdges(aObjectA, side++, NULL, NULL, &normal)) {
		projectionA = _collision_projectPolyShape(aObjectA, normal);
		projectionB = _collision_projectPolyShape(aObjectB, normal);
		if(!_collision_doProjectionsOverlap(projectionA, projectionB))
			return false;

		float currOverlap = _collision_overlapOfProjections(projectionA, projectionB);
		if(currOverlap < overlap) {
			overlap = currOverlap;
			overlapAxis = normal;
		}
	}
	if(aoOverlap) *aoOverlap = overlap;
	if(aoOverlapAxis) *aoOverlapAxis = overlapAxis;

	return true;
}
bool collision_step(CollisionWorld_t *aWorld, CollisionPolyObject_t *aInputObject, float aTimeDelta)
{
	vec2_t displacement = vec2_scalarMul(aInputObject->velocity, aTimeDelta);

	float distanceToTravel = vec2_mag(displacement);
	if(distanceToTravel < FLT_EPSILON)
		return false;

	rect_t newBoundingBox = rect_translate(aInputObject->boundingBox, displacement);
	CollisionPolyObject_t **potentialColliders;
	int numberOfPotentialColliders;
	potentialColliders = (CollisionPolyObject_t **)spatialHash_query(aWorld->spatialHash, newBoundingBox, &numberOfPotentialColliders);
	collision_setPolyObjectCenter(aInputObject, vec2_add(aInputObject->center, displacement));
	if(numberOfPotentialColliders == 0)
		return false;

	// A single collider can be present in multiple cells so we must keep track of which ones we have tested already
	Array_t *testedColliders = array_create(numberOfPotentialColliders);

	CollisionPolyObject_t *nearestCollider = NULL;
	float overlap = 0.0f;
	vec2_t overlapAxis;

	// Process each of the possibly colliding polygons
	bool didCollide = false;
	float currOverlap;
	vec2_t currOverlapAxis;
	CollisionPolyObject_t *currentCollider;
	for(int i = 0; i < numberOfPotentialColliders; ++i) {
		currentCollider = potentialColliders[i];
		// Check if we've already tested against this object
		if(array_containsPtr(testedColliders, currentCollider))
			continue;
		array_push(testedColliders, currentCollider);
		
		if(collision_intersectObjects(aInputObject, currentCollider, &currOverlap, &currOverlapAxis)) {
			if(currOverlap > overlap) {
				didCollide = true;
				nearestCollider = currentCollider;
				overlap = currOverlap;
				overlapAxis = currOverlapAxis;
			}
		}
	}
	free(potentialColliders);
	array_destroy(testedColliders);
	if(!didCollide)
		return false;

	// Separate the objects
	collision_setPolyObjectCenter(aInputObject, vec2_add(aInputObject->center, vec2_scalarMul(overlapAxis, overlap)));

	// Apply some physics magic
	float projection = vec2_dot(overlapAxis, displacement);

	float frictionCoef = 1.0f - nearestCollider->frictionCoef;
	float bounceCoef = nearestCollider->bounceCoef;

	// Only apply collision response when heading into the collision (not out)
	if(projection < 0.0f) {
		vec2_t normalVelocity = vec2_scalarMul(overlapAxis, projection);
		vec2_t tangentVelocity = vec2_sub(displacement, normalVelocity);

		vec2_t newVel = vec2_add(vec2_scalarMul(normalVelocity, -bounceCoef), vec2_scalarMul(tangentVelocity, frictionCoef));
		// Convert back to to px/s
		aInputObject->velocity = vec2_scalarDiv(newVel, aTimeDelta);
	}
	return true;
}


#pragma mark - Debug drawing
static void _collision_drawDebugView(Renderer_t *aRenderer, void *aOwner, double aTimeSinceLastFrame, double aInterpolation)
{
	CollisionWorld_t *world = (CollisionWorld_t *)aOwner;
	glClear(GL_COLOR_BUFFER_BIT);

	// Draw the cells
	
	vec4_t whiteColor = { 1.0f, 1.0f, 1.0f, 1.0f };
	vec4_t redColor = { 1.0f, 0.0f, 0.0f, 1.0f };
	vec4_t blueColor = { 0.0f, 0.0f, 1.0f, 1.0f };
	vec4_t greenColor = { 0.0f, 1.0f, 0.0f, 1.0f };
	//vec4_t yellowColor = { 1.0f, 0.8f, 0.0f, 1.0f };

	rect_t cellRect = { 0.0f, 0.0f, world->spatialHash->cellSize, world->spatialHash->cellSize };
	SpatialHash_cell_t *currCell;
	CollisionPolyObject_t *currPoly;

	// Draw the grid
	for(int y = 0; y < (int)world->spatialHash->sizeInCells.h; ++y) {
		cellRect.origin.y = y*world->spatialHash->cellSize;
		for(int x = 0; x < (int)world->spatialHash->sizeInCells.w; ++x) {
			cellRect.origin.x = x*world->spatialHash->cellSize;
			draw_rect(cellRect, 0.0f, whiteColor, false);
		}
	}
	for(int y = 0; y < (int)world->spatialHash->sizeInCells.h; ++y) {
		cellRect.origin.y = y*world->spatialHash->cellSize;
		for(int x = 0; x < (int)world->spatialHash->sizeInCells.w; ++x) {
			cellRect.origin.x = x*world->spatialHash->cellSize;
			currCell = world->spatialHash->cells[y*(int)world->spatialHash->sizeInCells.w + x];
			if(currCell == NULL) continue;
			// Redraw populated cells in blue
			if(currCell->objects->count > 0)
				draw_rect(cellRect, 0.0f, blueColor, false);

			// Draw the polyon
			for(int i = 0; i < currCell->objects->count; ++i) {
				currPoly = currCell->objects->items[i];
				draw_circle(currPoly->center, 1.0f, 5.0, greenColor, true);

				matrix_stack_push(aRenderer->worldMatrixStack);
				matrix_stack_translate(aRenderer->worldMatrixStack, currPoly->center.x, currPoly->center.y, 0.0f);
				draw_polygon(currPoly->numberOfEdges, currPoly->vertices, redColor, false);
				// Draw the polygon's edge normals
				int currEdge = 0;
				vec2_t normal;
				vec2_t pointA, pointB;
				while(collision_getPolyObjectEdges(currPoly, currEdge++, &pointA, &pointB, &normal)) {
					draw_circle(pointA, 1.0f, 5.0, greenColor, true);
					// Find the edge midpoint
					vec2_t lineSeg = vec2_scalarDiv(vec2_sub(pointB, pointA), 2.0f);
					lineSeg = vec2_add(pointA, lineSeg);
					normal = vec2_add(lineSeg, vec2_scalarMul(vec2_normalize(normal), 10.0f));
					draw_lineSeg(lineSeg, normal, greenColor);
				}
				matrix_stack_pop(aRenderer->worldMatrixStack);
			}
		}
	}

	// Draw the character
	if(world->character) {
		//draw_rect(world->character->boundingBox, 0.0f, blueColor, false);
		draw_circle(world->character->center, 1.0f, 5.0, greenColor, true);			
		matrix_stack_push(aRenderer->worldMatrixStack);
		matrix_stack_translate(aRenderer->worldMatrixStack, world->character->center.x, world->character->center.y, 0.0f);
		draw_polygon(world->character->numberOfEdges, world->character->vertices, redColor, false);
		// Draw the polygon's edge normals
		int currEdge = 0;
		vec2_t normal;
		vec2_t pointA, pointB;
		while(collision_getPolyObjectEdges(world->character, currEdge++, &pointA, &pointB, &normal)) {
			draw_circle(pointA, 1.0f, 5.0, greenColor, true);
			// Find the edge midpoint
			vec2_t lineSeg = vec2_scalarDiv(vec2_sub(pointB, pointA), 2.0f);
			lineSeg = vec2_add(pointA, lineSeg);
			normal = vec2_add(lineSeg, vec2_scalarMul(vec2_normalize(normal), 10.0f));
			draw_lineSeg(lineSeg, normal, greenColor);
		}
		// Draw the velocity
		draw_lineSeg(kVec2_zero, vec2_scalarDiv(world->character->velocity, 20.0f), greenColor);
		matrix_stack_pop(aRenderer->worldMatrixStack);
	}
}