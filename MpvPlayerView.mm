#import <Cocoa/Cocoa.h>
#import <dlfcn.h>

typedef struct mpv_handle mpv_handle;

@interface MpvPlayerView : NSView
@property void *libmpvHandle;
@property mpv_handle *mpv;
@property NSButton *playPauseButton;
@property NSSlider *seekSlider;
@property BOOL isPlaying;
@end

@implementation MpvPlayerView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        [self setupUI];
        [self initMPV];
    }
    return self;
}

- (void)setupUI {
    self.playPauseButton = [[NSButton alloc] initWithFrame:NSMakeRect(10, 10, 80, 30)];
    [self.playPauseButton setTitle:@"Pause"];
    [self.playPauseButton setTarget:self];
    [self.playPauseButton setAction:@selector(togglePlayPause:)];
    [self addSubview:self.playPauseButton];

    self.seekSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(100, 15, self.frame.size.width - 110, 20)];
    [self.seekSlider setMinValue:0];
    [self.seekSlider setMaxValue:100];
    [self.seekSlider setTarget:self];
    [self.seekSlider setAction:@selector(seekVideo:)];
    [self addSubview:self.seekSlider];
}

- (void)initMPV {
    self.libmpvHandle = dlopen("./libmpv.dylib", RTLD_NOW);
    if (!self.libmpvHandle) {
        NSLog(@"❌ Failed to load libmpv");
        return;
    }

    mpv_handle* (*mpv_create)() = (mpv_handle* (*)())dlsym(self.libmpvHandle, "mpv_create");
    int (*mpv_initialize)(mpv_handle*) = (int (*)(mpv_handle*))dlsym(self.libmpvHandle, "mpv_initialize");
    int (*mpv_command)(mpv_handle*, const char*[]) = (int (*)(mpv_handle*, const char*[]))dlsym(self.libmpvHandle, "mpv_command");

    if (!mpv_create || !mpv_initialize || !mpv_command) {
        NSLog(@"❌ Missing libmpv symbols");
        return;
    }

    self.mpv = mpv_create();
    mpv_initialize(self.mpv);

    // TEMPORARY test audio file (replace later with video file path)
    const char *cmd[] = {"loadfile", "/System/Library/Sounds/Funk.aiff", NULL};
    mpv_command(self.mpv, cmd);

    self.isPlaying = YES;
}

- (void)togglePlayPause:(id)sender {
    const char *cmd[] = { "cycle", "pause", NULL };
    int (*mpv_command)(mpv_handle*, const char*[]) = (int (*)(mpv_handle*, const char*[]))dlsym(self.libmpvHandle, "mpv_command");
    if (mpv_command) mpv_command(self.mpv, cmd);
    self.isPlaying = !self.isPlaying;
    [self.playPauseButton setTitle:(self.isPlaying ? @"Pause" : @"Play")];
}

- (void)seekVideo:(id)sender {
    double val = [self.seekSlider doubleValue];
    char buf[32];
    snprintf(buf, sizeof(buf), "%f", val);
    const char *cmd[] = {"seek", buf, "absolute-percent", NULL};
    int (*mpv_command)(mpv_handle*, const char*[]) = (int (*)(mpv_handle*, const char*[]))dlsym(self.libmpvHandle, "mpv_command");
    if (mpv_command) mpv_command(self.mpv, cmd);
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];
    CGFloat width = self.frame.size.width;
    self.playPauseButton.frame = NSMakeRect(10, 10, 80, 30);
    self.seekSlider.frame = NSMakeRect(100, 15, width - 110, 20);
}

- (void)dealloc {
    if (self.mpv) {
        int (*mpv_terminate_destroy)(mpv_handle*) = (int (*)(mpv_handle*))dlsym(self.libmpvHandle, "mpv_terminate_destroy");
        if (mpv_terminate_destroy) mpv_terminate_destroy(self.mpv);
        self.mpv = NULL;
    }
    if (self.libmpvHandle) {
        dlclose(self.libmpvHandle);
        self.libmpvHandle = NULL;
    }
}

@end

// Expose to Pascal
extern "C" NSView *CreateMpvNSView(CGRect frame) {
    return [[MpvPlayerView alloc] initWithFrame:frame];
}
