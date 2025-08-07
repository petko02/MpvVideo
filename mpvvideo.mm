#import <Cocoa/Cocoa.h>

extern "C" {

// Handle to the embedded view
void* ListLoad(void* hwndParent, int showFlags, char* fileToLoad, void* lps) {
    @autoreleasepool {
        // Convert parent window handle to NSView
        NSView *parent = (__bridge NSView *)hwndParent;

        // Create a simple black view
        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 640, 360)];
        [view setWantsLayer:YES];
        view.layer.backgroundColor = [[NSColor blackColor] CGColor];

        // Add it to the Double Commander panel
        [parent addSubview:view];

        // Return the view as plugin handle
        return (__bridge_retained void *)view;
    }
}

int ListLoadNext(void* hwndParent, void* pluginWin, char* fileToLoad, int showFlags) {
    return 0; // no-op
}

void ListCloseWindow(void* pluginWin) {
    @autoreleasepool {
        NSView *view = (__bridge_transfer NSView *)pluginWin;
        [view removeFromSuperview];
    }
}

void ListGetDetectString(char* detectString, int maxlen) {
    snprintf(detectString, maxlen, "EXT=\"MP4\"");
}

void ListSetDefaultParams(void* dps) {
    // Optional init logic
}

}
