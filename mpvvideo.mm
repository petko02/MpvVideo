// mpvvideo.mm
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#import "common.h"      // from your SDK
#import "wlxplugin.h"   // from your SDK
#import <mpv/client.h>
#import <mpv/opengl_cb.h>

// If your SDK really doesn’t define this, supply your own detect‐string:
#ifndef EXTENSIONS_MEDIA
#define EXTENSIONS_MEDIA "*.mp4;*.mkv;*.avi;*.mov;*.webm"
#endif

// A tiny Obj-C “controller” to bridge slider/button/timer into our C callbacks:
@interface MpvController : NSObject
@end
@implementation MpvController
- (void)sliderChanged:(NSSlider*)s { extern void seekSliderMoved(NSSlider*); seekSliderMoved(s); }
- (void)buttonClicked:(NSButton*)b { extern void playPausePressed(NSButton*); playPausePressed(b); }
- (void)updateSeekTimer:(NSTimer*)t { extern void updateSeekPosition(void); updateSeekPosition(); }
@end

static mpv_handle *mpv = nullptr;
static MpvController *controller = nil;
static NSView       *containerView = nil;

void updateSeekPosition() {
    if (!mpv || !containerView) return;
    double pos = 0, dur = 0;
    mpv_get_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &pos);
    mpv_get_property(mpv, "duration", MPV_FORMAT_DOUBLE, &dur);
    if (dur > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSSlider *slider = [containerView viewWithTag:100];
            [slider setDoubleValue:(pos/dur)*100.0];
        });
    }
}

void seekSliderMoved(NSSlider *slider) {
    if (!mpv) return;
    double pct = slider.doubleValue, dur = 0;
    mpv_get_property(mpv, "duration", MPV_FORMAT_DOUBLE, &dur);
    if (dur > 0) {
        double t = (pct/100.0)*dur;
        mpv_set_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &t);
    }
}

void playPausePressed(NSButton *btn) {
    if (!mpv) return;
    int paused = 0;
    mpv_get_property(mpv, "pause", MPV_FORMAT_FLAG, &paused);
    paused = !paused;
    mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, &paused);
    [btn setTitle:(paused?@"Play":@"Pause")];
}

HWND DCPCALL ListLoad(HWND parentWin, char* fileToLoad, int showFlags) {
    NSView *parent = (__bridge NSView*)(void*)parentWin;
    NSRect frame = [parent bounds];

    // 1) Container + controller
    containerView = [[NSView alloc] initWithFrame:frame];
    controller    = [[MpvController alloc] init];

    // 2) Seek slider
    NSSlider *slider = [[NSSlider alloc] initWithFrame:
                         NSMakeRect(10,10, frame.size.width-20,20)];
    slider.tag      = 100;
    slider.minValue = 0;
    slider.maxValue = 100;
    slider.target   = controller;
    slider.action   = @selector(sliderChanged:);
    [containerView addSubview:slider];

    // 3) Play/Pause button
    NSButton *btn = [[NSButton alloc] initWithFrame:
                      NSMakeRect(10,40,80,30)];
    [btn setTitle:@"Pause"];
    btn.target = controller;
    btn.action = @selector(buttonClicked:);
    [containerView addSubview:btn];

    // 4) mpv init
    mpv = mpv_create();
    mpv_initialize(mpv);
    mpv_set_option_string(mpv, "vo", "libmpv");
    const char *cmd[] = {"loadfile", fileToLoad, NULL};
    mpv_command(mpv, cmd);

    // 5) Timer to update UI
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:controller
                                   selector:@selector(updateSeekTimer:)
                                   userInfo:nil
                                    repeats:YES];

    // 6) embed
    [parent addSubview:containerView];
    return (__bridge HWND)containerView;
}

void DCPCALL ListCloseWindow(HWND listWin) {
    if (mpv) {
        mpv_terminate_destroy(mpv);
        mpv = nullptr;
    }
    if (containerView) {
        [containerView removeFromSuperview];
        containerView = nil;
    }
    controller = nil;
}

void DCPCALL ListGetDetectString(char* DetectString, int maxlen) {
    snprintf(DetectString, maxlen, EXTENSIONS_MEDIA);
}
