#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl3.h>

// Import mpv headers from mpv subfolder
#import <mpv/client.h>
#import <mpv/opengl_cb.h>

@interface MpvGLView : NSOpenGLView {
    mpv_handle *mpv;
    mpv_opengl_cb_context *mpv_gl;
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
        [self prepareMPV];
    }
    return self;
}

- (void)prepareMPV {
    mpv = mpv_create();
    if (!mpv) {
        NSLog(@"Failed to create mpv instance.");
        return;
    }

    // Initialize mpv and the OpenGL context
    mpv_initialize(mpv);
    mpv_gl = (mpv_opengl_cb_context *)mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
    if (!mpv_gl) {
        NSLog(@"Failed to get mpv OpenGL context.");
        return;
    }

    // Setup rendering callback, etc.
    // You should replace this with actual render loop logic
}

- (void)dealloc {
    if (mpv_gl)
        mpv_opengl_cb_uninit_gl(mpv_gl);
    if (mpv)
        mpv_terminate_destroy(mpv);
}

@end

// Entry point for WLX Plugin
__attribute__((visibility("default")))
void* ListLoad(HWND hwndParent, int fFlags, const char* filename, const void* file) {
    // Basic loader stub
    return NULL;
}

__attribute__((visibility("default")))
int ListGetDetectString(char* DetectString, int maxlen) {
    snprintf(DetectString, maxlen, "EXT=\"MP4\"\nEXT=\"MKV\"\nEXT=\"AVI\"");
    return 0;
}
