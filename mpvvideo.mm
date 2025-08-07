#import <Cocoa/Cocoa.h>

@interface DummyView : NSView @end
@implementation DummyView
- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor redColor] setFill];
    NSRectFill(dirtyRect);
}
@end

extern "C" void* ListLoad(void* hwndParent, int showFlags, char* fileToLoad, void* lps) {
    NSRect frame = NSMakeRect(0, 0, 640, 360);
    DummyView *view = [[DummyView alloc] initWithFrame:frame];
    return (__bridge_retained void *)view;
}

extern "C" int ListGetDetectString(char *DetectString, int maxlen) {
    snprintf(DetectString, maxlen, "EXT=\"MP4\"|EXT=\"MKV\"");
    return 0;
}

extern "C" int ListLoadNext(void* listWin, const char* filename, int showFlags) { return 0; }
extern "C" int ListSearchText(void* listWin, const char* searchString, int searchParameter) { return 0; }
extern "C" int ListSearchDialog(void* listWin, int findNext) { return 0; }
extern "C" int ListSendCommand(void* listWin, int command, int parameter) { return 0; }

extern "C" void ListCloseWindow(void* listWin) {
    NSView *view = (__bridge_transfer NSView *)listWin;
    [view removeFromSuperview];
}
