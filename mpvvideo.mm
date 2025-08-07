// mpvvideo.mm
#import <Cocoa/Cocoa.h>
#import "wlxplugin.h"

NSView *previewView = nil;

void* DCPCALL ListLoad(HWND ParentWin, char* FileToLoad, int ShowFlags) {
    @autoreleasepool {
        NSString *path = [NSString stringWithUTF8String:FileToLoad];
        NSURL *url = [NSURL fileURLWithPath:path];
        NSView *parent = (__bridge NSView *)(ParentWin);

        NSTextView *textView = [[NSTextView alloc] initWithFrame:parent.bounds];
        textView.string = [NSString stringWithFormat:@"Preview: %@", [url lastPathComponent]];
        textView.editable = NO;
        textView.drawsBackground = NO;
        textView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

        [parent addSubview:textView];
        previewView = textView;

        return (__bridge_retained void *)textView;
    }
}

void DCPCALL ListCloseWindow(void* ListWin) {
    NSView *view = (__bridge_transfer NSView *)ListWin;
    [view removeFromSuperview];
}

void DCPCALL ListGetDetectString(char* DetectString, int maxlen) {
    snprintf(DetectString, maxlen, "EXT=\"MP4\"|EXT=\"MKV\"|EXT=\"AVI\"|EXT=\"MOV\"|EXT=\"WMV\"");
}
