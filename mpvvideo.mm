//
//  mpvvideo.mm
//  WLX plugin for Double Commander (macOS) using mpv embedded playback
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl3.h>
#import <mpv/client.h>
#import <mpv/opengl_cb.h>

#define MPV_SUB_API_OPENGL_CB 1  // Define missing constant if header is incomplete

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
    if (self) {
        mpv = mpv_create();
        mpv_initialize(mpv);
        mpv_gl = (mpv_opengl_cb_context *)mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
        mpv_opengl_cb_init_gl(mpv_gl, NULL, NULL);
        mpv_set_option_string(mpv, "vo", "libmpv");
    }
    return self;
}

- (void)dealloc {
    if (mpv_gl) {
        mpv_opengl_cb_uninit_gl(mpv_gl);
    }
    if (mpv) {
        mpv_terminate_destroy(mpv);
    }
    [super dealloc];
}

@end

extern "C" void* ListLoad(void* hwndParent, int fFlags, const char* filename, const void* file) {
    NSRect frame = NSMakeRect(0, 0, 800, 600);
    MpvGLView *view = [[MpvGLView alloc] initWithFrame:frame];

    const char *args[] = {"loadfile", filename, NULL};
    mpv_command_async(view->->mpv, 0, args);

    return (__bridge_retained void *)view;
}
