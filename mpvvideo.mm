// mpvvideo.mm
#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import "wlxplugin.h"

NSView *previewView = nil;
AVPlayerView *playerView = nil;

int DCPCALL ListLoad(HWND ParentWin, char* FileToLoad, int ShowFlags)
{
    NSString *path = [NSString stringWithUTF8String:FileToLoad];
    NSURL *url = [NSURL fileURLWithPath:path];

    NSView *parent = (__bridge NSView *)(ParentWin);

    playerView = [[AVPlayerView alloc] initWithFrame:parent.bounds];
    playerView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    playerView.controlsStyle = AVPlayerViewControlsStyleDefault;
    playerView.player = [AVPlayer playerWithURL:url];

    [parent addSubview:playerView];
    previewView = playerView;

    [playerView.player play];

    return (int)(__bridge_retained void *)playerView;
}

void DCPCALL ListCloseWindow(HWND ListWin)
{
    NSView *view = (__bridge_transfer NSView *)ListWin;
    [view removeFromSuperview];
    previewView = nil;
    playerView = nil;
}

void DCPCALL ListGetDetectString(char* DetectString, int maxlen)
{
    snprintf(DetectString, maxlen,
             "EXT=\"MP4\"|EXT=\"MKV\"|EXT=\"AVI\"|EXT=\"MOV\"|EXT=\"WMV\"");
}
