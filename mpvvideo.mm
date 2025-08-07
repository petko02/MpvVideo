#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

extern "C" {

// Simple WLX plugin interface using QuickLook QLPreviewView

void* ListLoad(void* hwndParent, int showFlags, char* fileToLoad, struct ListDefaultParamStruct* lps) {
    @autoreleasepool {
        // Create QLPreviewView
        NSRect frame = NSMakeRect(0, 0, 640, 480);
        QLPreviewView *previewView = [[QLPreviewView alloc] initWithFrame:frame style:QLPreviewViewStyleNormal];
        [previewView setAutostarts:YES];

        if (fileToLoad) {
            NSURL *url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:fileToLoad]];
            [previewView setPreviewItem:(id<QLPreviewItem>)url];
        }

        // Add to parent view
        if (hwndParent) {
            NSView *parent = (__bridge NSView *)hwndParent;
            [parent addSubview:previewView];
        }

        return (__bridge_retained void *)previewView;
    }
}

int ListLoadNext(void* parentWin, void* pluginWin, const char* fileToLoad, int showFlags) {
    @autoreleasepool {
        if (!fileToLoad || !pluginWin) return LISTPLUGIN_ERROR;

        NSURL *url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:fileToLoad]];
        QLPreviewView *previewView = (__bridge QLPreviewView *)pluginWin;
        [previewView setPreviewItem:(id<QLPreviewItem>)url];
        return LISTPLUGIN_OK;
    }
}

void ListCloseWindow(void* listWin) {
    @autoreleasepool {
        if (listWin) {
            QLPreviewView *previewView = (__bridge_transfer QLPreviewView *)listWin;
            [previewView removeFromSuperview];
        }
    }
}

int ListGetDetectString(char *DetectString, int maxlen) {
    snprintf(DetectString, maxlen, "EXT=\"PDF\"|EXT=\"TXT\"|EXT=\"PNG\"|EXT=\"JPG\"");
    return 0;
}

}
