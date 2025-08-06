// mpvvideo.c

#ifndef __OBJC__
typedef int BOOL;
#endif

#include "common.h"
#include "wlxplugin.h"

#include <mpv/client.h>
#include <mpv/opengl_cb.h>

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

static mpv_handle *mpv = NULL;
static mpv_opengl_cb_context *mpv_gl = NULL;
static NSView *containerView = NULL;
static NSButton *playPauseBtn = NULL;
static NSSlider *seekSlider = NULL;
static NSTimer *seekTimer = NULL;

void updateSeekPosition() {
    if (!mpv) return;

    double pos = 0;
    mpv_get_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &pos);

    double duration = 0;
    mpv_get_property(mpv, "duration", MPV_FORMAT_DOUBLE, &duration);

    if (duration > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [seekSlider setDoubleValue:(pos / duration) * 100.0];
        });
    }
}

void seekSliderMoved(NSSlider *slider) {
    if (!mpv) return;

    double percent = [slider doubleValue];
    double duration = 0;
    mpv_get_property(mpv, "duration", MPV_FORMAT_DOUBLE, &duration);

    if (duration > 0) {
        double new_time = (percent / 100.0) * duration;
        mpv_set_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &new_time);
    }
}

void playPausePressed(NSButton *sender) {
    if (!mpv) return;

    const char *pauseProp = "pause";
    int paused = 0;
    mpv_get_property(mpv, pauseProp, MPV_FORMAT_FLAG, &paused);

    paused = !paused;
    mpv_set_property(mpv, pauseProp, MPV_FORMAT_FLAG, &paused);

    [sender setTitle:(paused ? @"Play" : @"Pause")];
}

HWND DCPCALL ListLoad(HWND parentWin, char* fileToLoad, int showFlags) {
    NSView *parent = (__bridge NSView *)(void *)parentWin;

    NSRect frame = [parent bounds];
    containerView = [[NSView alloc] initWithFrame:frame];

    // Seek Slider
    seekSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(10, 10, frame.size.width - 20, 20)];
    [seekSlider setMinValue:0.0];
    [seekSlider setMaxValue:100.0];
    [seekSlider setTarget:NSApp];
    [seekSlider setAction:@selector(sliderChanged:)];
    [containerView addSubview:seekSlider];

    // Play/Pause Button
    playPauseBtn = [[NSButton alloc] initWithFrame:NSMakeRect(10, 40, 80, 30)];
    [playPauseBtn setTitle:@"Pause"];
    [playPauseBtn setTarget:NSApp];
    [playPauseBtn setAction:@selector(buttonClicked:)];
    [containerView addSubview:playPauseBtn];

    // mpv setup
    mpv = mpv_create();
    mpv_initialize(mpv);

    mpv_gl = mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
    if (!mpv_gl) return (__bridge HWND)containerView;

    mpv_opengl_cb_set_update_callback(mpv_gl, NULL, NULL); // We don't use the callback yet
    mpv_set_option_string(mpv, "vo", "libmpv");

    const char *cmd[] = {"loadfile", fileToLoad, NULL};
    mpv_command(mpv, cmd);

    // Timer to update seek
    seekTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:[NSApp delegate]
                                                selector:@selector(updateSeekPosition)
                                                userInfo:nil
                                                 repeats:YES];

    return (__bridge HWND)containerView;
}

void DCPCALL ListCloseWindow(HWND listWin) {
    if (seekTimer) {
        [seekTimer invalidate];
        seekTimer = nil;
    }

    if (mpv) {
        mpv_terminate_destroy(mpv);
        mpv = NULL;
    }

    if (containerView) {
        [containerView removeFromSuperview];
        containerView = nil;
    }
}

void DCPCALL ListGetDetectString(char* DetectString, int maxlen) {
    snprintf(DetectString, maxlen, EXTENSIONS_MEDIA);
}
