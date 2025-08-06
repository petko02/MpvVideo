#define _GNU_SOURCE
#include <Cocoa/Cocoa.h>
#include <mpv/client.h>
#include <mpv/opengl_cb.h>
#include "wlxplugin.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

typedef struct {
    NSView *container;
    NSView *videoView;
    NSSlider *seekBar;
    NSButton *playPauseBtn;
    mpv_handle *mpv;
    mpv_opengl_cb_context *mpvGL;
    BOOL isPlaying;
} MPVPanel;

static void *load_mpv_dylib(void) {
    Dl_info info;
    if (dladdr((void*)load_mpv_dylib, &info) == 0) return NULL;

    char dylibPath[1024];
    snprintf(dylibPath, sizeof(dylibPath), "%s/libmpv.dylib", dirname((char*)info.dli_fname));

    return dlopen(dylibPath, RTLD_NOW | RTLD_GLOBAL);
}

static void on_mpv_render(void *ctx) {
    MPVPanel *panel = (MPVPanel *)ctx;
    if (panel->mpvGL) {
        mpv_opengl_cb_draw(panel->mpvGL, 0, panel->container.bounds.size.width,
                           panel->container.bounds.size.height);
        glFlush();
    }
}

HWND DCPCALL ListLoad(HWND ParentWin, char* FileToLoad, int ShowFlags) {
    if (!load_mpv_dylib()) {
        NSLog(@"Failed to load bundled libmpv.dylib");
        return NULL;
    }

    MPVPanel *panel = calloc(1, sizeof(MPVPanel));

    NSView *parent = (__bridge NSView *)ParentWin;
    NSRect bounds = parent.bounds;

    panel->container = [[NSView alloc] initWithFrame:bounds];
    [parent addSubview:panel->container];

    panel->videoView = [[NSView alloc] initWithFrame:NSMakeRect(0, 40, bounds.size.width, bounds.size.height - 40)];
    [panel->container addSubview:panel->videoView];

    panel->seekBar = [[NSSlider alloc] initWithFrame:NSMakeRect(10, 10, bounds.size.width - 100, 20)];
    [panel->container addSubview:panel->seekBar];

    panel->playPauseBtn = [[NSButton alloc] initWithFrame:NSMakeRect(bounds.size.width - 80, 5, 70, 30)];
    [panel->playPauseBtn setTitle:@"Pause"];
    [panel->playPauseBtn setButtonType:NSButtonTypeMomentaryPushIn];
    [panel->container addSubview:panel->playPauseBtn];

    // Initialize mpv
    panel->mpv = mpv_create();
    mpv_set_option_string(panel->mpv, "vo", "libmpv");
    mpv_initialize(panel->mpv);

    panel->mpvGL = mpv_get_sub_api(panel->mpv, MPV_SUB_API_OPENGL_CB);
    mpv_opengl_cb_set_update_callback(panel->mpvGL, on_mpv_render, panel);

    NSOpenGLPixelFormatAttribute attrs[] = { NSOpenGLPFAAccelerated, 0 };
    NSOpenGLPixelFormat *fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    NSOpenGLContext *glCtx = [[NSOpenGLContext alloc] initWithFormat:fmt shareContext:nil];

    mpv_opengl_cb_init_gl(panel->mpvGL, NULL, NULL);
    [glCtx makeCurrentContext];

    const char *cmd[] = { "loadfile", FileToLoad, NULL };
    mpv_command(panel->mpv, cmd);
    panel->isPlaying = YES;

    return (HWND)CFBridgingRetain(panel);
}

void DCPCALL ListCloseWindow(HWND ListWin) {
    MPVPanel *panel = (__bridge_transfer MPVPanel *)ListWin;
    if (!panel) return;

    mpv_opengl_cb_uninit_gl(panel->mpvGL);
    mpv_terminate_destroy(panel->mpv);

    [panel->videoView removeFromSuperview];
    [panel->seekBar removeFromSuperview];
    [panel->playPauseBtn removeFromSuperview];
    [panel->container removeFromSuperview];
    free(panel);
}

void DCPCALL ListGetDetectString(char* DetectString, int maxlen) {
    strncpy(DetectString, "EXT=\"MP4|MKV|AVI|MOV|WMV|FLV|WEBM|MPEG|MPG|3GP|TS\"", maxlen);
}
