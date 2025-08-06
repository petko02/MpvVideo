#include "wlxplugin.h"
#include <Cocoa/Cocoa.h>
#include <mpv/client.h>
#include <mpv/opengl_cb.h>

#ifndef __OBJC__
typedef int BOOL;
#endif

static mpv_handle *mpv = NULL;
static mpv_opengl_cb_context *mpv_gl = NULL;
static NSView *videoView = nil;

HWND DCPCALL ListLoad(HWND ParentWin, char* FileToLoad, int ShowFlags) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSView *parentView = (NSView *)ParentWin;
    videoView = [[NSView alloc] initWithFrame:[parentView bounds]];
    [videoView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [parentView addSubview:videoView];

    mpv = mpv_create();
    if (!mpv) return (HWND)videoView;

    mpv_set_option_string(mpv, "vo", "libmpv");
    mpv_initialize(mpv);

    mpv_gl = mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
    if (!mpv_gl) return (HWND)videoView;

    NSOpenGLContext *glContext = [[NSOpenGLContext alloc] initWithFormat:[NSOpenGLPixelFormat alloc]
                                                             shareContext:nil];
    [videoView setWantsLayer:YES];
    [videoView.layer setContentsScale:[[NSScreen mainScreen] backingScaleFactor]];

    mpv_opengl_cb_init_gl(mpv_gl, NULL, NULL, NULL);

    const char *cmd[] = {"loadfile", FileToLoad, NULL};
    mpv_command(mpv, cmd);

    [pool drain];
    return (HWND)videoView;
}

void DCPCALL ListCloseWindow(HWND ListWin) {
    if (mpv_gl) {
        mpv_opengl_cb_uninit_gl(mpv_gl);
        mpv_gl = NULL;
    }
    if (mpv) {
        mpv_terminate_destroy(mpv);
        mpv = NULL;
    }
    if (videoView) {
        [videoView removeFromSuperview];
        [videoView release];
        videoView = nil;
    }
}

void DCPCALL ListGetDetectString(char* DetectString, int maxlen) {
    const char *detect =
        "EXT=\"MP4\" | EXT=\"M4V\" | EXT=\"MKV\" | EXT=\"AVI\" | EXT=\"MOV\" | "
        "EXT=\"WMV\" | EXT=\"FLV\" | EXT=\"WEBM\" | EXT=\"MPG\" | EXT=\"MPEG\" | "
        "EXT=\"3GP\" | EXT=\"TS\" | EXT=\"OGV\" | EXT=\"VOB\" | EXT=\"ASF\"";
    strncpy(DetectString, detect, maxlen - 1);
    DetectString[maxlen - 1] = '\0';
}
