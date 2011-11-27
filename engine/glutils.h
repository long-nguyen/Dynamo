#if defined(__APPLE__)
	#include <sys/time.h>
	#include <unistd.h>
	#include <OpenGL/gl.h>
	#include <Opengl/glext.h>
#else
	#define _CRT_SECURE_NO_DEPRECATE
	#define _WIN32_LEAN_AND_MEAN

	#ifdef WIN32
		#include <windows.h>
		#include "engine/windows/gldefs.h"
	#endif
	#include <GL/gl.h>
	#include <GL/glext.h>
#endif

#ifdef DEBUG
#define glError() { \
	GLenum err = glGetError(); \
	while (err != GL_NO_ERROR) { \
		debug_log("glError(0x%04x): %s caught", err, (char *)gluErrorString(err)); \
		err = glGetError(); \
	} \
}
#else
#define glError()
#endif
