#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

extern "C" {

// Global pointer to the player view so we can clean up
static AVPlayerView *playerView = nil;

// WLX entry point
void* ListLoad(void* hwndParent, int showFlags, char* fileToLoad, void* lps) {
    @autoreleasepool {
        if (!fileToLoad || !hwndParent) return nullptr;

        NSString *filePath = [NSString stringWithUTF8String:fileToLoad];
        NSURL *videoURL = [NSURL fileURLWithPath:filePath];

        NSView *parent = (__bridge NSView *)hwndParent;

        NSRect frame = parent.bounds;
        playerView = [[AVPlayerView alloc] initWithFrame:frame];
        playerView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        playerView.controlsStyle = AVPlayerViewControlsStyleDefault;

        AVPlayer *player = [AVPlayer playerWithURL:videoURL];
        playerView.player = player;

        [parent addSubview:playerView];
        [player play];

        return (__bridge_retained void *)playerView;
    }
}

void ListCloseWindow(void* listWin) {
    @autoreleasepool {
        if (listWin) {
            NSView *view = (__bridge_transfer NSView *)listWin;
            [view removeFromSuperview];
        }
        playerView = nil;
    }
}

int ListGetDetectString(char* DetectString, int maxlen) {
    snprintf(DetectString, maxlen, "EXT=\"MP4\"|EXT=\"MOV\"|EXT=\"MKV\"|EXT=\"AVI\"|EXT=\"WMV\"");
    return 0;
}

}
