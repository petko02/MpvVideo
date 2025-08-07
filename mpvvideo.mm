#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl3.h>
#import <mpv/client.h>
#import <mpv/opengl_cb.h>

@interface MpvGLView : NSOpenGLView {
    mpv_handle *mpv;
    mpv_opengl_cb_context *mpv_gl;
    NSTimer *renderTimer;
}
@end

@implementation MpvGLView

- (instancetype)initWithFrame:(NSRect)frameRect {
    NSOpenGLPixelFormatAttribute attrs[] = {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFAColorSize,   24,
        NSOpenGLPFADepthSize,   16,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion3_2Core,
        0
    };

    NSOpenGLPixelFormat *fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    self = [super initWithFrame:frameRect pixelFormat:fmt];

    if (self) {
        [self prepareMpv];
    }

    return self;
}

- (void)prepareMpv {
    mpv = mpv_create();
    mpv_initialize(mpv);

    mpv_gl = (mpv_opengl_cb_context *)mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
    mpv_opengl_cb_init_gl(mpv_gl, NULL, NULL, NULL);
    mpv_opengl_cb_set_update_callback(mpv_gl, (void (*)(void *))^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setNeedsDisplay:YES];
        });
    }, (__bridge void *)self);

    NSRect bounds = [self bounds];
    NSString *videoPath = @"file:///tmp/sample.mp4"; // Replace as needed
    const char *cmd[] = {"loadfile", [videoPath UTF8String], NULL};
    mpv_command_async(mpv, 0, cmd);

    renderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0
                                                   target:self
                                                 selector:@selector(drawRect:)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    if (mpv_gl) {
        mpv_opengl_cb_draw(mpv_gl, 0, 0, [self bounds].size.width, [self bounds].size.height);
        [[self openGLContext] flushBuffer];
    }
}

- (void)dealloc {
    if (mpv) {
        mpv_terminate_destroy(mpv);
        mpv = NULL;
    }
    renderTimer = nil;
}

@end

void* ListLoad(void* hwndParent, int fFlags, const char* filename, const void* file) {
    NSRect frame = NSMakeRect(0, 0, 800, 600); // Resize dynamically if needed
    MpvGLView *view = [[MpvGLView alloc] initWithFrame:frame];
    return (__bridge_retained void *)view;
}

int ListLoadNext(void* listWin, const char* filename, const void* file) {
    return LISTPLUGIN_ERROR;
}

void ListCloseWindow(void* listWin) {
    if (listWin) {
        NSView *view = (__bridge_transfer NSView *)listWin;
        [view removeFromSuperview];
    }
}
