#define GL_SILENCE_DEPRECATION

#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include <mpv/client.h>
#include <mpv/opengl_cb.h>
#include <OpenGL/gl3.h>
#include <Cocoa/Cocoa.h>
#include "wlxplugin.h"

static mpv_handle *mpv = NULL;
static mpv_opengl_cb_context *mpv_gl = NULL;
static NSOpenGLView *videoView = nil;
static pthread_mutex_t mpv_mutex = PTHREAD_MUTEX_INITIALIZER;

static void *render_loop(void *arg) {
    (void)arg;
    while (1) {
        pthread_mutex_lock(&mpv_mutex);
        if (!mpv_gl) {
            pthread_mutex_unlock(&mpv_mutex);
            break;
        }
        mpv_opengl_cb_draw(mpv_gl, 0, 0, 0);
        pthread_mutex_unlock(&mpv_mutex);
        usleep(16000); // ~60fps
    }
    return NULL;
}

HWND DCPCALL ListLoad(HWND ParentWin, char *FileToLoad, int ShowFlags)
{
    NSView *parentView = (__bridge NSView *)ParentWin;

    // Create NSOpenGLView for rendering
    NSOpenGLPixelFormatAttribute attrs[] = {
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFADoubleBuffer,
        0
    };
    NSOpenGLPixelFormat *pixFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    videoView = [[NSOpenGLView alloc] initWithFrame:[parentView bounds] pixelFormat:pixFormat];
    [videoView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [parentView addSubview:videoView];

    // Init mpv
    mpv = mpv_create();
    if (!mpv) return 0;
    mpv_initialize(mpv);

    // OpenGL context
    NSOpenGLContext *glCtx = [videoView openGLContext];
    [glCtx makeCurrentContext];

    mpv_gl = mpv_get_sub_api(mpv, MPV_SUB_API_OPENGL_CB);
    mpv_opengl_cb_init_gl(mpv_gl, NULL, NULL, NULL);

    const char *cmd[] = {"loadfile", FileToLoad, NULL};
    mpv_command(mpv, cmd);

    pthread_t tid;
    pthread_create(&tid, NULL, render_loop, NULL);
    pthread_detach(tid);

    return (HWND)videoView;
}

void DCPCALL ListCloseWindow(HWND ListWin)
{
    pthread_mutex_lock(&mpv_mutex);
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
    pthread_mutex_unlock(&mpv_mutex);
}

void DCPCALL ListGetDetectString(char *DetectString, int maxlen)
{
    snprintf(DetectString, maxlen - 1,
        "EXT=\"MP4\"|EXT=\"MKV\"|EXT=\"AVI\"|EXT=\"WMV\"|EXT=\"MOV\"|"
        "EXT=\"WEBM\"|EXT=\"FLV\"|EXT=\"M4V\"|EXT=\"MPG\"|EXT=\"MPEG\"|"
        "EXT=\"3GP\"|EXT=\"WAV\"");
}
