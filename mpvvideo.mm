#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl3.h>
#import <dlfcn.h>
#import "mpv/client.h"

// Define WLX return codes
#define LISTPLUGIN_OK      0
#define LISTPLUGIN_ERROR   1

@interface MpvGLView : NSOpenGLView {
    mpv_handle *mpv;
    mpv_opengl_cb_context *mpv_gl;
    NSTimer *renderTimer;
    NSButton *playPauseButton;
    BOOL isPlaying;
}
@end

@implementation MpvGLView

- (instancetype)initWithFrame:(NSRect)frame file:(NSString *)filepath {
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
    const char *args[] = {"loadfile", filepath.UTF8String, NULL};
    mpv_command(mpv, args);

    playPauseButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, 10, 60, 30)];
    playPauseButton.title = @"⏸";
    playPauseButton.target = self;
    playPauseButton.action = @selector(togglePlayPause);
    [self addSubview:playPauseButton];

    renderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30
                                                   target:self
                                                 selector:@selector(drawView)
                                                 userInfo:nil
                                                  repeats:YES];
    return self;
}

- (void)togglePlayPause {
    isPlaying = !isPlaying;
    const char *cmd[] = {"cycle", "pause", NULL};
    mpv_command(mpv, cmd);
    playPauseButton.title = isPlaying ? @"⏸" : @"▶️";
}

- (void)drawView {
    [self.openGLContext makeCurrentContext];
    mpv_render_context_render(mpv_opengl_cb_context *ctx, 0, 0, self.bounds.size.width, self.bounds.size.height);
    [self.openGLContext flushBuffer];
}

- (void)dealloc {
    [renderTimer invalidate];
    if (mpv) mpv_terminate_destroy(mpv);
    [super dealloc];
}

@end

extern "C" {

// Structure passed from Double Commander
struct ListDefaultParamStruct {
    int size;
    struct { int cx; int cy; } size_struct;
};

void* ListLoad(void* hwndParent, int showFlags, char* fileToLoad, struct ListDefaultParamStruct* lps) {
    @autoreleasepool {
        if (!fileToLoad || !hwndParent) return nullptr;

        NSView *parent = (__bridge NSView *)hwndParent;
        NSRect frame = NSMakeRect(0, 0,
            lps ? lps->size_struct.cx : 640,
            lps ? lps->size_struct.cy : 360);

        MpvGLView *view = [[MpvGLView alloc] initWithFrame:frame file:[NSString stringWithUTF8String:fileToLoad]];
        if (!view) return nullptr;

        [parent addSubview:view];
        return (__bridge_retained void *)view;
    }
}

int ListLoadNext(void* parentWin, void* pluginWin, char* fileToLoad, int showFlags) {
    return LISTPLUGIN_OK;
}

void ListCloseWindow(void* pluginWin) {
    @autoreleasepool {
        NSView *view = (__bridge_transfer NSView *)pluginWin;
        [view removeFromSuperview];
    }
}

void ListGetDetectString(char* detectString, int maxlen) {
    snprintf(detectString, maxlen, "EXT=\"MP4\"|EXT=\"MKV\"|EXT=\"AVI\"|EXT=\"MOV\"");
}

}
