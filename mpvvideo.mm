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
    return self;
}

- (void)prepareOpenGL {
    [super prepareOpenGL];

    mpv = mpv_create();
    mpv_initialize(mpv);

    mpv_gl = NULL;
    mpv_get_sub_api_fn get_fn = (mpv_get_sub_api_fn)mpv_get_proc_address(mpv, "mpv_get_sub_api");
    if (get_fn) {
        mpv_gl = (mpv_opengl_cb_context *)get_fn(mpv, MPV_SUB_API_OPENGL_CB);
    }

    mpv_opengl_cb_init_gl(mpv_gl, NULL, NULL, NULL);
    mpv_opengl_cb_set_update_callback(mpv_gl, mpv_render_update, (__bridge void *)self);

    renderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0
                                                   target:self
                                                 selector:@selector(redraw)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void)redraw {
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    mpv_opengl_cb_draw(mpv_gl, 0, self.bounds.size.width, self.bounds.size.height);

    [[self openGLContext] flushBuffer];
}

static void mpv_render_update(void *ctx) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [(MpvGLView *)CFBridgingRelease(ctx) setNeedsDisplay:YES];
    });
}

- (void)dealloc {
    if (mpv_gl) {
        mpv_opengl_cb_uninit_gl(mpv_gl);
    }
    if (mpv) {
        mpv_terminate_destroy(mpv);
    }
    [renderTimer invalidate];
}

@end

// WLX plugin entry
void* ListLoad(void* hwndParent, int fFlags, const char* filename, const void* file) {
    NSView *parent = (__bridge NSView *)hwndParent;
    MpvGLView *view = [[MpvGLView alloc] initWithFrame:[parent bounds]];
    [parent addSubview:view];

    const char *cmd[] = {"loadfile", filename, NULL};
    mpv_command_async(view->->mpv, 0, cmd);

    return (__bridge_retained void *)view;
}
