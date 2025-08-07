#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

static AVPlayerView *playerView = nil;

extern "C" {

void* __attribute__((visibility("default"))) ListLoad(void* ParentWin, int ShowFlags, char* FileToLoad, void* ListerPluginStruct) {
    @autoreleasepool {
        if (!ParentWin || !FileToLoad) return nullptr;

        NSString *filePath = [NSString stringWithUTF8String:FileToLoad];
        NSURL *videoURL = [NSURL fileURLWithPath:filePath];

        NSView *parent = (__bridge NSView *)ParentWin;
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

void __attribute__((visibility("default"))) ListCloseWindow(void* listWin) {
    @autoreleasepool {
        if (listWin) {
            NSView *view = (__bridge_transfer NSView *)listWin;
            [view removeFromSuperview];
        }
        playerView = nil;
    }
}

int __attribute__((visibility("default"))) ListGetDetectString(char* DetectString, int maxlen) {
    snprintf(DetectString, maxlen, "EXT=\"MP4\"|EXT=\"MOV\"|EXT=\"MKV\"|EXT=\"AVI\"|EXT=\"WMV\"");
    return 0;
}

} // extern "C"
