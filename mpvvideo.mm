#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl3.h>
#import <mpv/client.h>
#import <mpv/opengl_cb.h>

// Declare manually (since not in header)
extern void *mpv_get_sub_api(mpv_handle *ctx, int sub_api);
#define MPV_SUB_API_OPENGL_CB 1

@interface MpvGLView : NSOpenGLView {
    mpv_handle *mpv;
    mpv_opengl_cb_context *mpv_gl;
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
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        0
    };
    NSOpenGLPixelFormat *fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    self = [super initWithFrame:frame pixelFormat:fmt];
    if (self) {
        mpv = mpv_create();
        mpv_initialize(mpv);

        mpv_gl = (mpv_opengl_cb_context *)mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
        mpv_opengl_cb_init_gl(mpv_gl, NULL, NULL, NULL);

        mpv_opengl_cb_set_update_callback(mpv_gl, ^(void *) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setNeedsDisplay:YES];
            });
        }, NULL);

        const char *cmd[] = {"loadfile", "sample.mp4", NULL};
        mpv_command_async(mpv, 0, cmd);

        // Create play/pause button
        playPauseButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, 10, 80, 30)];
        [playPauseButton setTitle:@"Play"];
        [playPauseButton setButtonType:NSButtonTypeMomentaryPushIn];
        [playPauseButton setBezelStyle:NSBezelStyleRounded];
        [playPauseButton setTarget:self];
        [playPauseButton setAction:@selector(togglePlayPause:)];
        [self addSubview:playPauseButton];

        // Create seek bar
        seekSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(100, 10, frame.size.width - 120, 30)];
        [seekSlider setMinValue:0];
        [seekSlider setMaxValue:100];
        [seekSlider setTarget:self];
        [seekSlider setAction:@selector(seek:)];
        [self addSubview:seekSlider];

        isPlaying = YES;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    mpv_opengl_cb_draw(mpv_gl, 0, dirtyRect.size.width, dirtyRect.size.height);
}

- (void)togglePlayPause:(id)sender {
    const char *cmd[] = {"cycle", "pause", NULL};
    mpv_command_async(mpv, 0, cmd);
    isPlaying = !isPlaying;
    [playPauseButton setTitle:(isPlaying ? @"Pause" : @"Play")];
}

- (void)seek:(id)sender {
    double value = [seekSlider doubleValue];
    char time[64];
    snprintf(time, sizeof(time), "%f", value);
    const char *cmd[] = {"seek", time, "absolute", NULL};
    mpv_command_async(mpv, 0, cmd);
}

@end

void* ListLoad(void* hwndParent, int fFlags, const char* filename, const void* file) {
    NSRect frame = NSMakeRect(0, 0, 800, 600);
    MpvGLView *view = [[MpvGLView alloc] initWithFrame:frame];
    return (__bridge_retained void *)view;
}
