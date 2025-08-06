#include "wlxplugin.h"
#include <Cocoa/Cocoa.h>
#include <mpv/client.h>
#include <mpv/opengl_cb.h>

static mpv_handle *mpv = NULL;
static mpv_opengl_cb_context *mpv_gl = NULL;
static NSView *videoView = nil;

intptr_t DCPCALL ListLoad(HWND ParentWin, char* FileToLoad, int ShowFlags)
{
    NSView *parent = (__bridge NSView*)ParentWin;

    videoView = [[NSView alloc] initWithFrame:parent.bounds];
    [videoView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [parent addSubview:videoView];

    mpv = mpv_create();
    if (!mpv) return 0;

    mpv_initialize(mpv);

    mpv_set_option_string(mpv, "vo", "libmpv");
    mpv_gl = mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);

    NSOpenGLPixelFormatAttribute attrs[] = {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFADoubleBuffer,
        0
    };
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    NSOpenGLContext *glContext = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
    [glContext setView:videoView];
    [glContext makeCurrentContext];

    mpv_opengl_cb_init_gl(mpv_gl, NULL, NULL, NULL);

    const char *cmd[] = {"loadfile", FileToLoad, NULL};
    mpv_command_async(mpv, 0, cmd);

    return (intptr_t)videoView;
}

void DCPCALL ListCloseWindow(HWND ListWin)
{
    if (mpv_gl) {
        mpv_opengl_cb_uninit_gl(mpv_gl);
        mpv_gl = NULL;
    }
    if (mpv) {
        mpv_terminate_destroy(mpv);
        mpv = NULL;
    }
    if (videoView) {
        [videoView removeFromSuperview];
        videoView = nil;
    }
}

void DCPCALL ListGetDetectString(char* DetectString, int maxlen)
{
    snprintf(DetectString, maxlen,
             "EXT=\"AVI\"|EXT=\"MP4\"|EXT=\"MKV\"|EXT=\"MOV\"|EXT=\"WMV\"|EXT=\"FLV\"|EXT=\"WEBM\"|EXT=\"M4V\"|EXT=\"MPEG\"|EXT=\"MPG\"");
}
