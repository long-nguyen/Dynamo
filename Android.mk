LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LOCAL_CFLAGS := -I$(LOCAL_PATH)/Dependencies -std=gnu99 -I$(LOCAL_PATH)/Dependencies/png -I$(LOCAL_PATH)/Dependencies/mxml  -g
LOCAL_ARM_MODE := arm
TARGET_PLATFORM := armeabi-v7a
TARGET_ABI := android-8-armeabi

LOCAL_MODULE    := dynamo
LOCAL_SRC_FILES :=\
Source/array.c \
Source/background.c \
Source/drawutils.c \
Source/gametimer.c \
Source/input.c \
Source/linkedlist.c \
Source/object.c \
Source/png_loader.c \
Source/renderer.c \
Source/scene.c \
Source/shader.c \
Source/sprite.c \
Source/texture.c \
Source/texture_atlas.c \
Source/tmx_map.c \
Source/util.c \
Dependencies/GLMath/GLMath.c \
Dependencies/GLMath/GLMathExports.c \
Dependencies/GLMath/GLMathUtilities.c \
Dependencies/mxml/mxml-attr.c \
Dependencies/mxml/mxml-entity.c \
Dependencies/mxml/mxml-file.c \
Dependencies/mxml/mxml-get.c \
Dependencies/mxml/mxml-index.c \
Dependencies/mxml/mxml-node.c \
Dependencies/mxml/mxml-private.c \
Dependencies/mxml/mxml-search.c \
Dependencies/mxml/mxml-set.c \
Dependencies/mxml/mxml-string.c \
Dependencies/png/png.c \
Dependencies/png/pngerror.c \
Dependencies/png/pngget.c \
Dependencies/png/pngmem.c \
Dependencies/png/pngpread.c \
Dependencies/png/pngread.c \
Dependencies/png/pngrio.c \
Dependencies/png/pngrtran.c \
Dependencies/png/pngrutil.c \
Dependencies/png/pngset.c \
Dependencies/png/pngtrans.c \
Dependencies/png/pngwio.c \
Dependencies/png/pngwrite.c \
Dependencies/png/pngwtran.c \
Dependencies/png/pngwutil.c

LIBS+=bps screen EGL GLESv2 freetype
LOCAL_LDLIBS := -lz -llog -ldl -lGLESv2

include $(BUILD_SHARED_LIBRARY)