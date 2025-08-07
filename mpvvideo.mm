#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl3.h>
#import <dlfcn.h>
#import "mpv/client.h"

#define MPV_SUB_API_OPENGL_CB 1

typedef struct mpv_opengl_cb_context mpv_opengl_cb_context;

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

// Manual function pointers
void *(*mpv_get_sub_api_fn)(mpv_handle *, int) = NULL;
int (*mpv_opengl_cb_init_gl_fn)(mpv_opengl_cb_context *, void *, void *, void *) = NULL;
void (*mpv_opengl_cb_uninit_gl_fn)(mpv_opengl_cb_context *) = NULL;
void (*mpv_opengl_cb_set_update_callback_fn)(mpv_opengl_cb_context *, void (*)(void *), void *) = NULL;
int (*mpv_opengl_cb_draw_fn)(mpv_opengl_cb_context *, int, int, int) = NULL;

+ (void)initialize {
    void *handle = dlopen(NULL, RTLD_LAZY | RTLD_LOCAL);
    if (handle) {
        mpv_get_sub_api_fn = (void *(*)(mpv_handle *, int))dlsym(handle, "mpv_get_sub_api");
        mpv_opengl_cb_init_gl_fn = (int (*)(mpv_opengl_cb_context *, void *, void *, void *))dlsym(handle, "mpv_opengl_cb_init_gl");
        mpv_opengl_cb_uninit_gl_fn = (void (*)(mpv_opengl_cb_context *))dlsym(handle, "mpv_opengl_cb_uninit_gl");
        mpv_opengl_cb_set_update_callback_fn = (void (*)(mpv_opengl_cb_context *, void (*)(void *), void *))dlsym(handle, "mpv_opengl_cb_set_update_callback");
        mpv_opengl_cb_draw_fn = (int (*)(mpv_opengl_cb_context *, int, int, int))dlsym(handle, "mpv_opengl_cb_draw");
    }
}

- (mpv_handle *)getMPV {
    return mpv;
}

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
    if (!mpv) return nil;

    mpv_initialize(mpv);
    mpv_set_option_string(mpv, "terminal", "no");

    if (!mpv_get_sub_api_fn) return nil;

    mpv_gl = (mpv_opengl_cb_context *)mpv_get_sub_api_fn(mpv, MPV_SUB_API_OPENGL_CB);
    if (!mpv_gl) return nil;

    [self.openGLContext makeCurrentContext];
    mpv_opengl_cb_init_gl_fn(mpv_gl, NULL, NULL, NULL);
    mpv_opengl_cb_set_update_callback_fn(mpv_gl, &on_mpv_update, (__bridge void *)self);

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
        MpvGLView *view = (__bridge MpvGLView *)ctx;
        [view drawView];
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
    mpv_opengl_cb_draw_fn(mpv_gl, 0, (int)b.size.width, (int)b.size.height);
    glFlush();
    [self.openGLContext flushBuffer];
}

- (void)dealloc {
    if (renderTimer) {
        [renderTimer invalidate];
        renderTimer = nil;
    }

    if (mpv_gl)
        mpv_opengl_cb_uninit_gl_fn(mpv_gl);
    if (mpv)
        mpv_terminate_destroy(mpv);
}

@end

// === Double Commander Plugin Interface ===

struct ListDefaultParamStruct {
    int size;
    struct {
        int cx;
        int cy;
    } size_struct;
};

extern "C" void* ListLoad(void* hwndParent, int showFlags, char* fileToLoad, struct ListDefaultParamStruct* lps) {
    @autoreleasepool {
        NSRect frame = NSMakeRect(0, 0, lps ? lps->size_struct.cx : 640, lps ? lps->size_struct.cy : 360);
        MpvGLView *view = [[MpvGLView alloc] initWithFrame:frame];
        if (!view) return nullptr;

        NSView *parent = (__bridge NSView *)hwndParent;
        [parent addSubview:view];

        if (fileToLoad) {
            const char *cmd[] = {"loadfile", fileToLoad, NULL};
            mpv_command([view getMPV], cmd);
        }

        return (__bridge_retained void *)view;
    }
}

extern "C" int ListGetDetectString(char *DetectString, int maxlen) {
    snprintf(DetectString, maxlen, "EXT="MP4"|EXT="MKV"|EXT="AVI"|EXT="MOV"|EXT="WMV"");
    return 0;
}

extern "C" int ListLoadNext(void* listWin, const char* filename, int showFlags) { return 0; }
extern "C" int ListSearchText(void* listWin, const char* searchString, int searchParameter) { return 0; }
extern "C" int ListSearchDialog(void* listWin, int findNext) { return 0; }
extern "C" int ListSendCommand(void* listWin, int command, int parameter) { return 0; }

extern "C" void ListCloseWindow(void* listWin) {
    @autoreleasepool {
        NSView *view = (__bridge_transfer NSView *)listWin;
        [view removeFromSuperview];
    }
}
