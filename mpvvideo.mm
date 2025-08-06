// mpvvideo.mm
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <stdint.h>

// Stub FILETIME so common.h compiles
#ifndef _FILETIME_DEFINED
#define _FILETIME_DEFINED
typedef struct { uint32_t dwLowDateTime, dwHighDateTime; } FILETIME;
#endif

#import "common.h"
#import "wlxplugin.h"
#import <mpv/client.h>
#import <mpv/opengl_cb.h>   // back to the correct path

#ifndef EXTENSIONS_MEDIA
#define EXTENSIONS_MEDIA "*.mp4;*.mkv;*.avi;*.mov;*.webm"
#endif

#pragma mark –– OpenGL view for MPV

@interface MpvGLView : NSOpenGLView
@property (nonatomic, assign) mpv_opengl_cb_context *mpv_gl;
@end
@implementation MpvGLView
- (void)drawRect:(NSRect)dirtyRect {
    if (_mpv_gl) {
        NSRect r = self.bounds;
        mpv_opengl_cb_draw(_mpv_gl, 0, r.size.width, r.size.height);
    }
}
- (void)dealloc {
    if (_mpv_gl) {
        mpv_opengl_cb_uninit_gl(_mpv_gl);
        _mpv_gl = NULL;
    }
}
@end

#pragma mark –– Controller bridge

@interface MpvController : NSObject @end
@implementation MpvController
- (void)sliderChanged:(NSSlider*)s  { extern void seekSliderMoved(NSSlider*); seekSliderMoved(s); }
- (void)buttonClicked:(NSButton*)b  { extern void playPausePressed(NSButton*); playPausePressed(b); }
- (void)updateSeekTimer:(NSTimer*)t { extern void updateSeekPosition(void); updateSeekPosition(); }
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
    if (dur>0) dispatch_async(dispatch_get_main_queue(), ^{
        [seekSlider setDoubleValue:(pos/dur)*100.0];
    });
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
    paused=!paused;
    mpv_set_property(mpv, "pause", MPV_FORMAT_FLAG, &paused);
    dispatch_async(dispatch_get_main_queue(), ^{
        [btn setTitle: paused?@"Play":@"Pause" ];
    });
}

#pragma mark –– DCPCALL

HWND DCPCALL ListLoad(HWND parentWin, char* fileToLoad, int showFlags) {
    NSView *host=(__bridge NSView*)(void*)parentWin;
    NSRect frame=host.bounds;

    mpv = mpv_create(); mpv_initialize(mpv);
    mpv_set_option_string(mpv,"vo","gpu");
    mpv_gl = mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
    mpv_opengl_cb_init_gl(mpv_gl, NULL, NULL, NULL);

    NSOpenGLPixelFormatAttribute attrs[]={ NSOpenGLPFAAccelerated,
        NSOpenGLPFAColorSize,24, NSOpenGLPFADepthSize,16, 0 };
    NSOpenGLPixelFormat *fmt=[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    glView=[[MpvGLView alloc] initWithFrame:frame pixelFormat:fmt];
    glView.mpv_gl=mpv_gl;
    mpv_opengl_cb_set_update_callback(mpv_gl,
        [](void*ctx){
            MpvGLView *v=(__bridge MpvGLView*)ctx;
            dispatch_async(dispatch_get_main_queue(),^{ [v setNeedsDisplay:YES]; });
        }, (__bridge void*)glView);

    controller=[[MpvController alloc]init];
    seekSlider=[[NSSlider alloc]initWithFrame:NSMakeRect(10,10,frame.size.width-20,20)];
    seekSlider.minValue=0; seekSlider.maxValue=100;
    seekSlider.target=controller; seekSlider.action=@selector(sliderChanged:);
    playPauseBtn=[[NSButton alloc]initWithFrame:NSMakeRect(10,40,80,30)];
    [playPauseBtn setTitle:@"Pause"];
    playPauseBtn.target=controller; playPauseBtn.action=@selector(buttonClicked:);

    const char *cmd[]={"loadfile",fileToLoad,NULL};
    mpv_command(mpv,cmd);
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:controller
                                   selector:@selector(updateSeekTimer:)
                                   userInfo:nil repeats:YES];

    [host addSubview:glView];
    [host addSubview:seekSlider];
    [host addSubview:playPauseBtn];
    return (__bridge HWND)glView;
}

void DCPCALL ListCloseWindow(HWND win) {
    if(mpv){ mpv_terminate_destroy(mpv); mpv=NULL; }
    if(glView){ [glView removeFromSuperview]; glView=nil; }
    if(seekSlider){ [seekSlider removeFromSuperview]; seekSlider=nil; }
    if(playPauseBtn){ [playPauseBtn removeFromSuperview]; playPauseBtn=nil; }
    controller=nil;
}

void DCPCALL ListGetDetectString(char *s,int maxlen){
    snprintf(s,maxlen,EXTENSIONS_MEDIA);
}
