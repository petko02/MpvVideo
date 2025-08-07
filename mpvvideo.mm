#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl3.h>

extern "C" {
    #include "mpv/client.h"
    #include "mpv/opengl_cb.h"
}

#define MPV_SUB_API_OPENGL_CB 1
#define LISTPLUGIN_ERROR 1

mpv_handle *mpv = NULL;
mpv_opengl_cb_context *mpv_gl = NULL;

@interface MpvGLView : NSOpenGLView {
    NSButton *playPauseButton;
    NSSlider *seekSlider;
    BOOL isPlaying;
}
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
    if (self) {
        [self setupMPV];
        [self setupUI];
    }
    return self;
}

- (void)setupMPV {
    mpv = mpv_create();
    if (!mpv) return;

    mpv_initialize(mpv);

    mpv_gl = (mpv_opengl_cb_context *)mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);

    mpv_opengl_cb_set_update_callback(mpv_gl, mpv_redraw_callback, (__bridge void *)self);
    mpv_opengl_cb_init_gl(mpv_gl, NULL, NULL, NULL);

    const char *cmd[] = {"loadfile", "file.mp4", NULL};
    mpv_command_async(mpv, 0, cmd);
    isPlaying = YES;
}

void mpv_redraw_callback(void *ctx) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSView *view = (__bridge NSView *)ctx;
        [view setNeedsDisplay:YES];
    });
}

- (void)setupUI {
    CGFloat width = self.bounds.size.width;

    // Play/Pause Button
    playPauseButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, 10, 80, 30)];
    [playPauseButton setTitle:@"Pause"];
    [playPauseButton setTarget:self];
    [playPauseButton setAction:@selector(togglePlayPause)];
    [self addSubview:playPauseButton];

    // Seek Bar
    seekSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(100, 15, width - 110, 20)];
    [seekSlider setMinValue:0];
    [seekSlider setMaxValue:100];
    [seekSlider setDoubleValue:0];
    [seekSlider setTarget:self];
    [seekSlider setAction:@selector(seek)];
    [self addSubview:seekSlider];
}

- (void)togglePlayPause {
    const char *cmd_play[] = {"set", "pause", "no", NULL};
    const char *cmd_pause[] = {"set", "pause", "yes", NULL};
    if (isPlaying) {
        mpv_command_async(mpv, 0, cmd_pause);
        [playPauseButton setTitle:@"Play"];
    } else {
        mpv_command_async(mpv, 0, cmd_play);
        [playPauseButton setTitle:@"Pause"];
    }
    isPlaying = !isPlaying;
}

- (void)seek {
    double pos = [seekSlider doubleValue];
    char posStr[32];
    snprintf(posStr, sizeof(posStr), "%f", pos);
    const char *cmd[] = {"seek", posStr, "absolute-percent", NULL};
    mpv_command_async(mpv, 0, cmd);
}

- (void)drawRect:(NSRect)dirtyRect {
    if (mpv_gl) {
        mpv_opengl_cb_draw(mpv_gl, 0, self.bounds.size.width, self.bounds.size.height);
        [[self openGLContext] flushBuffer];
    }
}

@end

// Entry point for Double Commander WLX plugin
extern "C" {

void* ListLoad(void* hwndParent, int fFlags, const char* filename, const void* file) {
    NSRect frame = NSMakeRect(0, 0, 800, 600);
    MpvGLView *view = [[MpvGLView alloc] initWithFrame:frame];
    return (__bridge_retained void *)view;
}

int ListLoadNext(void* /*listWin*/, const char* /*filename*/) {
    return LISTPLUGIN_ERROR;
}

void ListCloseWindow(void* listWin) {
    NSView *view = (__bridge_transfer NSView *)listWin;
    [view removeFromSuperview];
}

}
