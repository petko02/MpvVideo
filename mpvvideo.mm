#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl3.h>
#import "mpv/client.h"
#import "mpv/opengl_cb.h"

// Patch for missing sub API constant and function declaration
#ifndef MPV_SUB_API_OPENGL_CB
#define MPV_SUB_API_OPENGL_CB 1
extern void *mpv_get_sub_api(mpv_handle *ctx, int sub_api);
#endif

@interface MpvGLView : NSOpenGLView {
    mpv_handle *mpv;
    mpv_opengl_cb_context *mpv_gl;
    NSTimer *renderTimer;
    NSSlider *slider;
    NSButton *playPauseButton;
    BOOL isPlaying;
}

- (mpv_handle *)getMPV;

@end

@implementation MpvGLView

- (instancetype)initWithFrame:(NSRect)frame {
    NSOpenGLPixelFormatAttribute attrs[] = {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFADepthSize, 16,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion3_2Core,
        0
    };
    NSOpenGLPixelFormat *fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    self = [super initWithFrame:frame pixelFormat:fmt];
    if (!self) return nil;

    isPlaying = YES;

    mpv = mpv_create();
    if (!mpv) {
        NSLog(@"Failed to create mpv instance");
        return nil;
    }

    mpv_initialize(mpv);
    mpv_set_option_string(mpv, "terminal", "no");

    // Get OpenGL sub API
    mpv_gl = (mpv_opengl_cb_context *)mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
    if (!mpv_gl) {
        NSLog(@"Failed to get mpv OpenGL CB context");
        return nil;
    }

    [self.openGLContext makeCurrentContext];
    mpv_opengl_cb_init_gl(mpv_gl, NULL, NULL, NULL);

    mpv_opengl_cb_set_update_callback(mpv_gl, &on_mpv_update, (__bridge void *)self);

    const char *cmd[] = {"loadfile", "preview.mp4", NULL};
    mpv_command(mpv, cmd);

    [self setupControls];

    renderTimer = [NSTimer scheduledTimerWithTimeInterval:0.03
                                                   target:self
                                                 selector:@selector(drawView)
                                                 userInfo:nil
                                                  repeats:YES];

    return self;
}

void on_mpv_update(void *ctx) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [(MpvGLView *)CFBridgingRelease(ctx) drawView];
    });
}

- (void)setupControls {
    CGFloat buttonHeight = 30;
    CGFloat padding = 10;
    NSRect bounds = self.bounds;

    slider = [[NSSlider alloc] initWithFrame:NSMakeRect(padding, padding, bounds.size.width - 2 * padding - 60, buttonHeight)];
    [slider setMinValue:0.0];
    [slider setMaxValue:100.0];
    [self addSubview:slider];

    playPauseButton = [[NSButton alloc] initWithFrame:NSMakeRect(bounds.size.width - 50, padding, 40, buttonHeight)];
    [playPauseButton setTitle:@"⏸"];
    [playPauseButton setTarget:self];
    [playPauseButton setAction:@selector(togglePlayPause)];
    [self addSubview:playPauseButton];
}

- (void)togglePlayPause {
    isPlaying = !isPlaying;
    const char *cmd[] = {"cycle", "pause", NULL};
    mpv_command(mpv, cmd);
    [playPauseButton setTitle:(isPlaying ? @"⏸" : @"▶️")];
}

- (void)drawView {
    [self.openGLContext makeCurrentContext];

    NSRect b = [self bounds];
    mpv_opengl_cb_draw(mpv_gl, 0, (int)b.size.width, (int)b.size.height);
    glFlush();
    [self.openGLContext flushBuffer];
}

- (void)dealloc {
    if (renderTimer) {
        [renderTimer invalidate];
        renderTimer = nil;
    }

    if (mpv_gl)
        mpv_opengl_cb_uninit_gl(mpv_gl);
    if (mpv)
        mpv_terminate_destroy(mpv);
}

@end

// === Double Commander Plugin Interface ===

extern "C" {

void* ListLoad(void* hwndParent, int fFlags, const char* filename, const void* file) {
    @autoreleasepool {
        NSRect frame = NSMakeRect(0, 0, 640, 360);
        MpvGLView *view = [[MpvGLView alloc] initWithFrame:frame];

        if (filename) {
            const char *cmd[] = {"loadfile", filename, NULL};
            mpv_command([view getMPV], cmd);
        }

        return (__bridge_retained void *)view;
    }
}

int ListGetDetectString(char *DetectString, int maxlen) {
    snprintf(DetectString, maxlen, "EXT=\"MP4\"|EXT=\"MKV\"|EXT=\"AVI\"|EXT=\"MOV\"|EXT=\"WMV\"");
    return 0;
}

int ListLoadNext(void* listWin, const char* filename, int showFlags) {
    return 0;
}

int ListSearchText(void* listWin, const char* searchString, int searchParameter) {
    return 0;
}

int ListSearchDialog(void* listWin, int findNext) {
    return 0;
}

int ListSendCommand(void* listWin, int command, int parameter) {
    return 0;
}

void ListCloseWindow(void* listWin) {
    @autoreleasepool {
        NSView *view = (__bridge_transfer NSView *)listWin;
        [view removeFromSuperview];
    }
}

}
