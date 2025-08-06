// mpvvideo.mm
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <stdint.h>

// Stub FILETIME so common.h compiles:
#ifndef _FILETIME_DEFINED
#define _FILETIME_DEFINED
typedef struct { uint32_t dwLowDateTime, dwHighDateTime; } FILETIME;
#endif

#import "common.h"
#import "wlxplugin.h"
#import <mpv/client.h>
#import <mpv/opengl_cb.h>

#ifndef EXTENSIONS_MEDIA
#define EXTENSIONS_MEDIA "*.mp4;*.mkv;*.avi;*.mov;*.webm"
#endif

#pragma mark –– Forward declarations

void updateSeekPosition(void);
void seekSliderMoved(NSSlider*);
void playPausePressed(NSButton*);
static void mpv_update_callback(void *ctx);

#pragma mark –– OpenGL view

@interface MpvGLView : NSOpenGLView
@property (nonatomic, assign) mpv_opengl_cb_context *mpv_gl;
@end
@implementation MpvGLView
- (void)drawRect:(NSRect)dirtyRect {
    if (self.mpv_gl) {
        NSRect r = self.bounds;
        mpv_opengl_cb_draw(self.mpv_gl, 0, (int)r.size.width, (int)r.size.height);
    }
}
- (void)dealloc {
    if (self.mpv_gl) {
        mpv_opengl_cb_uninit_gl(self.mpv_gl);
        self.mpv_gl = NULL;
    }
    [super dealloc];
}
@end

#pragma mark –– Controller bridge

@interface MpvController : NSObject
@end
@implementation MpvController
- (void)sliderChanged:(NSSlider*)s  { seekSliderMoved(s); }
- (void)buttonClicked:(NSButton*)b  { playPausePressed(b); }
- (void)updateSeekTimer:(NSTimer*)t { updateSeekPosition(); }
@end

#pragma mark –– Globals

static mpv_handle            *mpv          = NULL;
static mpv_opengl_cb_context *mpv_gl       = NULL;
static MpvGLView             *glView       = nil;
static NSSlider              *seekSlider   = nil;
static NSButton              *playPauseBtn = nil;
static MpvController         *controller   = nil;

#pragma mark –– C callbacks

void updateSeekPosition() {
    if (!mpv || !seekSlider) return;
    double pos=0, dur=0;
    mpv_get_property(mpv, "time-pos",  MPV_FORMAT_DOUBLE, &pos);
    mpv_get_property(mpv, "duration",  MPV_FORMAT_DOUBLE, &dur);
    if (dur>0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [seekSlider setDoubleValue:(pos/dur)*100.0];
        });
    }
}

void seekSliderMoved(NSSlider *slider) {
    if (!mpv) return;
    double pct=slider.doubleValue, dur=0;
    mpv_get_property(mpv, "duration", MPV_FORMAT_DOUBLE, &dur);
    if (dur>0) {
        double t=(pct/100.0)*dur;
        mpv_set_property(mpv, "time-pos", MPV_FORMAT_DOUBLE, &t);
    }
}

void playPausePressed(NSButton *btn) {
    if (!mpv) return;
    int paused=0;
    mpv_get_property(mpv, "pause", MPV_FORMAT_FLAG, &paused);
    paused = !paused;
    mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, &paused);
    dispatch_async(dispatch_get_main_queue(), ^{
        [btn setTitle:(paused?@"Play":@"Pause")];
    });
}

static void mpv_update_callback(void *ctx) {
    MpvGLView *v = (__bridge MpvGLView*)ctx;
    dispatch_async(dispatch_get_main_queue(), ^{
        [v setNeedsDisplay:YES];
    });
}

#pragma mark –– DCPCALL entry points

HWND DCPCALL ListLoad(HWND parentWin, char* fileToLoad, int showFlags) {
    NSView *hostView = (__bridge NSView*)(void*)parentWin;
    NSRect frame     = hostView.bounds;

    // 1) init mpv
    mpv = mpv_create();
    mpv_initialize(mpv);
    mpv_set_option_string(mpv, "vo", "gpu");

    // 2) opengl-cb sub-API: use literal name
    mpv_gl = mpv_get_sub_api(mpv, "opengl-cb");
    mpv_opengl_cb_init_gl(mpv_gl, NULL, NULL, NULL);
    mpv_opengl_cb_set_update_callback(mpv_gl, mpv_update_callback, (__bridge void*)glView);

    // 3) create GL view
    NSOpenGLPixelFormatAttribute attrs[] = {
      NSOpenGLPFAAccelerated,
      NSOpenGLPFAColorSize,   24,
      NSOpenGLPFADepthSize,    16,
      0
    };
    NSOpenGLPixelFormat *fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    glView = [[MpvGLView alloc] initWithFrame:frame pixelFormat:fmt];
    glView.mpv_gl = mpv_gl;

    // 4) controls
    controller = [[MpvController alloc] init];
    seekSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(10,10,frame.size.width-20,20)];
    seekSlider.minValue = 0; seekSlider.maxValue = 100;
    seekSlider.target = controller; seekSlider.action = @selector(sliderChanged:);
    playPauseBtn = [[NSButton alloc] initWithFrame:NSMakeRect(10,40,80,30)];
    [playPauseBtn setTitle:@"Pause"];
    playPauseBtn.target = controller; playPauseBtn.action = @selector(buttonClicked:);
    [glView addSubview:seekSlider];
    [glView addSubview:playPauseBtn];

    // 5) load file & timer
    const char *cmd[] = {"loadfile", fileToLoad, NULL};
    mpv_command(mpv, cmd);
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:controller
                                   selector:@selector(updateSeekTimer:)
                                   userInfo:nil
                                    repeats:YES];

    // 6) embed view
    [hostView addSubview:glView];
    return (__bridge HWND)glView;
}

void DCPCALL ListCloseWindow(HWND listWin) {
    if (mpv) {
        mpv_terminate_destroy(mpv);
        mpv = NULL;
    }
    if (glView) {
        [glView removeFromSuperview];
        glView = nil;
    }
    controller = nil;
}

void DCPCALL ListGetDetectString(char* DetectString, int maxlen) {
    snprintf(DetectString, maxlen, EXTENSIONS_MEDIA);
}
