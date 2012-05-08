#ifndef _PNGLOADER_H_
#define _PNGLOADER_H_
#include "object.h"

typedef struct {
    OBJ_GUTS
    int height;
    int width;
    bool hasAlpha;
    const unsigned char *data;
#ifdef __APPLE__
    CFDataRef cfData;
#endif
} Png_t;

extern Png_t *png_load(const char *aPath);//, int *oWidth, int *oHeight, bool *oHasAlpha, unsigned char **oData);
#endif
