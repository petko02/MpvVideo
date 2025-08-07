#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl3.h>
#import <dlfcn.h>
#include <string.h>

#define LISTPLUGIN_OK 0
#define LISTPLUGIN_ERROR 1

typedef void* (__cdecl *mpv_client_api_func)(const char *name);

typedef struct mpv_handle mpv_handle;
typedef struct mpv_render_context mpv_render_context;

typedef int mpv_opengl_cb_get_proc_address_fn(void *ctx, const char *name);
typedef struct mpv_opengl_cb_context mpv_opengl_cb_context;

typedef mpv_render_context* (*mpv_get_sub_api_fn)(void *);
typedef int (*mpv_render_context_set_update_callback_fn)(mpv_render_context*, void(*cb)(void*), void*);
typedef int (*mpv_render_context_update_fn)(mpv_render_context*);
typedef int (*mpv_render_context_render_fn)(mpv_render_context*, void*);

mpv_get_sub_api_fn mpv_get_sub_api;
mpv_render_context_set_update_callback_fn mpv_render_context_set_update_callback;
mpv_render_context_update_fn mpv_render_context_update;
mpv_render_context_render_fn mpv_render_context_render;

@interface MPVView : NSOpenGLView {
  mpv_render_context *mpv_ctx;
}
@end

@implementation MPVView

- (void)drawRect:(NSRect)dirtyRect {
  if (mpv_ctx && mpv_render_context_render) {
    mpv_render_context_render(mpv_ctx, NULL);
  }
}

@end

extern "C" int ListLoadW(const wchar_t* fileToLoad, int showFlags) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  NSRect frame = NSMakeRect(0, 0, 800, 600);
  NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                 styleMask:(NSWindowStyleMaskTitled |
                                                            NSWindowStyleMaskClosable |
                                                            NSWindowStyleMaskResizable)
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
  [window setTitle:@"MpvVideo.wlx"];
  [window makeKeyAndOrderFront:nil];

  MPVView *view = [[MPVView alloc] initWithFrame:frame];
  [window setContentView:view];

  [pool drain];
  return LISTPLUGIN_OK;
}

extern "C" void ListGetDetectString(char* DetectString, int maxlen) {
  snprintf(DetectString, maxlen, "EXT=\"MP4\"|EXT=\"MKV\"|EXT=\"AVI\"|EXT=\"MOV\"|EXT=\"WMV\"");
}
