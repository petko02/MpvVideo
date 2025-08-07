#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <QuickLook/QuickLook.h>

extern "C" {

// Simple preview item
@interface SimpleQLItem : NSObject <QLPreviewItem>
@property NSURL *url;
@end

@implementation SimpleQLItem
- (NSURL *)previewItemURL {
    return self.url;
}
@end

// Load plugin
void* ListLoad(void* hwndParent, int showFlags, char* fileToLoad, void* lps) {
    @autoreleasepool {
        if (!fileToLoad) return nullptr;

        NSView *parent = (__bridge NSView *)hwndParent;
        NSRect frame = NSMakeRect(0, 0, 640, 360);

        QLPreviewView *preview = [[QLPreviewView alloc] initWithFrame:frame style:QLPreviewViewStyleNormal];
        preview.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

        SimpleQLItem *item = [SimpleQLItem new];
        item.url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:fileToLoad]];
        [preview setPreviewItem:item];

        [parent addSubview:preview];
        return (__bridge_retained void *)preview;
    }
}

// Load next file
int ListLoadNext(void* parentWin, void* pluginWin, char* fileToLoad, int showFlags) {
    @autoreleasepool {
        if (!fileToLoad || !pluginWin) return 1;

        QLPreviewView *preview = (__bridge QLPreviewView *)pluginWin;
        SimpleQLItem *item = [SimpleQLItem new];
        item.url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:fileToLoad]];
        [preview setPreviewItem:item];

        return 0;
    }
}

// Cleanup
void ListCloseWindow(void* pluginWin) {
    @autoreleasepool {
        QLPreviewView *preview = (__bridge_transfer QLPreviewView *)pluginWin;
        [preview removeFromSuperview];
    }
}

// Set detection string
void ListGetDetectString(char* detectString, int maxlen) {
    snprintf(detectString, maxlen, "EXT=\"PDF\"|EXT=\"JPG\"|EXT=\"PNG\"|EXT=\"TXT\"");
}

}
