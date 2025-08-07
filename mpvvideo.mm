#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/gl3.h>
#import <dlfcn.h>
#import "mpv/client.h"

// Only needed if wlxplugin.h isn't available
struct ListDefaultParamStruct {
    int size;
    struct {
        int cx;
        int cy;
    } size;
};

// ... your MpvGLView class goes here ...

// === Double Commander Plugin Interface ===
extern "C" void* ListLoad(void* hwndParent, int showFlags, char* fileToLoad, struct ListDefaultParamStruct* lps) {
    @autoreleasepool {
        NSRect frame = NSMakeRect(0, 0, lps ? lps->size.cx : 640, lps ? lps->size.cy : 360);
        MpvGLView *view = [[MpvGLView alloc] initWithFrame:frame];
        if (!view) return NULL;

        NSView *parent = (__bridge NSView *)hwndParent;
        [parent addSubview:view];

        if (fileToLoad) {
            const char *cmd[] = {"loadfile", fileToLoad, NULL};
            mpv_command([view getMPV], cmd);
        }

        return (__bridge_retained void *)view;
    }
}
