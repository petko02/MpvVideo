#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl3.h>
#import <mpv/client.h>
#import <mpv/opengl_cb.h>

#ifndef MPV_SUB_API_OPENGL_CB
#define MPV_SUB_API_OPENGL_CB 1
#endif

// Forward declare mpv_get_sub_api
extern void *mpv_get_sub_api(mpv_handle *ctx, int sub_api);

@interface MpvGLView : NSOpenGLView {
    mpv_handle *mpv;
    mpv_opengl_cb_context *mpv_gl;
    NSSlider *slider;
    NSButton *playPauseButton;
    NSTimer *timer;
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
        [self prepareUI];
        [self setupMPV];
    }
    return self;
}

- (void)prepareUI {
    slider = [[NSSlider alloc] initWithFrame:NSMakeRect(10, 10, self.bounds.size.width - 20, 20)];
    slider.minValue = 0.0;
    slider.maxValue = 100.0;
    [slider setTarget:self];
    [slider setAction:@selector(sliderMoved:)];
    [self addSubview:slider];

    playPauseButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, 40, 100, 30)];
    [playPauseButton setTitle:@"Play"];
    [playPauseButton setButtonType:NSButtonTypeMomentaryPushIn];
    [playPauseButton setBezelStyle:NSBezelStyleRounded];
    [playPauseButton setTarget:self];
    [playPauseButton setAction:@selector(togglePlayPause)];
    [self addSubview:playPauseButton];
}

- (void)setupMPV {
    mpv = mpv_create();
    mpv_initialize(mpv);

    mpv_gl = (mpv_opengl_cb_context *)mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
    mpv_opengl_cb_init_gl(mpv_gl, NULL, NULL, NULL);

    mpv_opengl_cb_set_update_callback(mpv_gl,
        [](void *ctx) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [(MpvGLView *)ctx setNeedsDisplay:YES];
            });
        },
        (__bridge void *)self
    );

    const char *cmd[] = {"loadfile", "test.mp4", NULL};
    mpv_command_async(mpv, 0, cmd);
    isPlaying = YES;

    timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                             target:self
                                           selector:@selector(updateSlider)
                                           userInfo:nil
                                            repeats:YES];
}

- (void)sliderMoved:(id)sender {
    double percent = [slider doubleValue];
    const char *cmd[] = {"seek", [[NSString stringWithFormat:@"%f", percent] UTF8String], "absolute-percent", NULL};
    mpv_command_async(mpv, 0, cmd);
}

- (void)togglePlayPause {
    isPlaying = !isPlaying;
    const char *cmd[] = {"cycle", "pause", NULL};
    mpv_command_async(mpv, 0, cmd);
    [playPauseButton setTitle:(isPlaying ? @"Pause" : @"Play")];
}

- (void)updateSlider {
    mpv_node node;
    if (mpv_get_property(mpv, "percent-pos", MPV_FORMAT_NODE, &node) >= 0) {
        if (node.format == MPV_FORMAT_DOUBLE)
            [slider setDoubleValue:node.u.double_];
        mpv_free_node_contents(&node);
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    mpv_opengl_cb_draw(mpv_gl, 0, self.bounds.size.width, self.bounds.size.height);
    [[self openGLContext] flushBuffer];
}

@end

void* ListLoad(HWND hwndParent, int fFlags, const char* filename, const void* file) {
    NSRect frame = NSMakeRect(0, 0, 640, 480);
    MpvGLView *view = [[MpvGLView alloc] initWithFrame:frame];
    return (__bridge_retained void *)view;
}
