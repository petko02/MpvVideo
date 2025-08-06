#include <Cocoa/Cocoa.h>
#include <mpv/client.h>
#include <mpv/opengl_cb.h>
#include "wlxplugin.h"

#ifndef __OBJC__
typedef int BOOL;
#endif

static mpv_handle *mpv = NULL;
static mpv_opengl_cb_context *mpv_gl = NULL;
static NSView *videoView = nil;
static NSSlider *seekSlider = nil;
static NSButton *playPauseButton = nil;
static BOOL isPaused = NO;

@interface MPVView : NSOpenGLView
@end

@implementation MPVView
- (void)drawRect:(NSRect)dirtyRect {
    if (mpv_gl) {
        mpv_opengl_cb_draw(mpv_gl, 0, self.bounds.size.width, -self.bounds.size.height);
    }
}
@end

static void on_mpv_render_update(void *ctx) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [videoView setNeedsDisplay:YES];
    });
}

static void togglePlayPause(id sender) {
    isPaused = !isPaused;
    mpv_command_string(mpv, isPaused ? "set pause yes" : "set pause no");
    [playPauseButton setTitle:(isPaused ? @"▶️" : @"⏸️")];
}

static void seekPosition(id sender) {
    double pos = [seekSlider doubleValue];
    char cmd[64];
    snprintf(cmd, sizeof(cmd), "seek %f absolute", pos);
    mpv_command_string(mpv, cmd);
}

HWND DCPCALL ListLoad(HWND ParentWin, char* FileToLoad, int ShowFlags) {
    if (!mpv) {
        mpv = mpv_create();
        mpv_initialize(mpv);
    }

    NSRect rect = NSMakeRect(0, 0, 400, 300);
    videoView = [[MPVView alloc] initWithFrame:rect];

    NSOpenGLContext *glContext = [videoView openGLContext];
    mpv_gl = mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
    mpv_opengl_cb_init_gl(mpv_gl, NULL, NULL);
    mpv_opengl_cb_set_update_callback(mpv_gl, on_mpv_render_update, NULL);

    const char *cmd[] = {"loadfile", FileToLoad, NULL};
    mpv_command(mpv, cmd);

    // Play/Pause button
    playPauseButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, 10, 50, 24)];
    [playPauseButton setTitle:@"⏸️"];
    [playPauseButton setTarget:NSApp];
    [playPauseButton setAction:@selector(togglePlayPause:)];
    [videoView addSubview:playPauseButton];

    // Seek slider
    seekSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(70, 10, 300, 24)];
    [seekSlider setMinValue:0];
    [seekSlider setMaxValue:100];
    [seekSlider setTarget:NSApp];
    [seekSlider setAction:@selector(seekPosition:)];
    [videoView addSubview:seekSlider];

    return (HWND)videoView;
}

void DCPCALL ListCloseWindow(HWND ListWin) {
    if (mpv) {
        mpv_terminate_destroy(mpv);
        mpv = NULL;
    }
}

void DCPCALL ListGetDetectString(char* DetectString, int maxlen) {
    snprintf(DetectString, maxlen,
             "EXT=\"MP4\" | EXT=\"MKV\" | EXT=\"AVI\" | EXT=\"MOV\" | EXT=\"WMV\" | EXT=\"M4V\" | EXT=\"FLV\"");
}
