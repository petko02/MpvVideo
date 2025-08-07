#import <Cocoa/Cocoa.h>

extern "C" {

// Entry: Load plugin (shows a blank view)
void* ListLoad(void* hwndParent, int showFlags, char* fileToLoad, void* lps) {
    @autoreleasepool {
        // Cast hwndParent to NSView
        NSView *parent = (__bridge NSView *)hwndParent;

        // Create a blank NSView to embed
        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 640, 360)];
        view.wantsLayer = YES;
        view.layer.backgroundColor = [[NSColor blackColor] CGColor];

        // Add to parent
        [parent addSubview:view];

        // Return plugin handle
        return (__bridge_retained void *)view;
    }
}

// Entry: Load next file (no-op)
int ListLoadNext(void* parentWin, void* pluginWin, char* fileToLoad, int showFlags) {
    return 0; // success
}

// Entry: Close and remove view
void ListCloseWindow(void* pluginWin) {
    @autoreleasepool {
        NSView *view = (__bridge_transfer NSView *)pluginWin;
        [view removeFromSuperview];
    }
}

// Entry: Detect supported files
void ListGetDetectString(char* detectString, int maxlen) {
    snprintf(detectString, maxlen, "EXT=\"MP4\"");
}

}
