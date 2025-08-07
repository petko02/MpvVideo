// mpvvideo.mm
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import "wlxplugin.h"

NSView *previewView = nil;

// Required entry point: load the plugin window
int DCPCALL ListLoadPluginW(HWND ParentWin, WCHAR* FileToLoad, int ShowFlags) {
    @autoreleasepool {
        if (!FileToLoad) return LISTPLUGIN_ERROR;

        NSView *parent = (__bridge NSView *)ParentWin;

        NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithCharacters:FileToLoad length:wcslen(FileToLoad)]];
        QLPreviewView *qlView = [[QLPreviewView alloc] initWithFrame:parent.bounds style:QLPreviewViewStyleNormal];
        qlView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [qlView setPreviewItem:(id<QLPreviewItem>)fileURL];
        [parent addSubview:qlView];
        previewView = qlView;

        return (int)(__bridge_retained void *)qlView;
    }
}

// Required entry point: unload the plugin
void DCPCALL ListCloseWindowW(HWND ListWin) {
    @autoreleasepool {
        NSView *view = (__bridge_transfer NSView *)ListWin;
        [view removeFromSuperview];
    }
}

// Optional: return supported extensions
void DCPCALL ListGetDetectStringW(WCHAR* DetectString, int maxlen) {
    swprintf(DetectString, maxlen, L"EXT=\"MP4\"|EXT=\"MKV\"|EXT=\"AVI\"|EXT=\"MOV\"|EXT=\"WMV\"");
}
