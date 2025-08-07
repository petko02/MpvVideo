#import <Cocoa/Cocoa.h>
#import <dlfcn.h>
#import <QuartzCore/CAMetalLayer.h>  // or NSOpenGLView if fallback

typedef struct mpv_handle mpv_handle;
typedef struct mpv_render_context mpv_render_context;
typedef void (*mpv_opengl_cb_draw_cb)(void *ctx);
typedef void (*mpv_render_param);

@interface MpvPlayerView : NSView
@property void *libmpvHandle;
@property mpv_handle *mpv;
@property mpv_render_context *renderCtx;
@property NSTimer *drawTimer;
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
    [self.playPauseButton setTitle:@"Play"];
    [self.playPauseButton setTarget:self];
    [self.playPauseButton setAction:@selector(togglePlayPause:)];
    [self addSubview:self.playPauseButton];

    self.seekSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(100, 10, self.frame.size.width - 110, 20)];
    [self.seekSlider setMinValue:0];
    [self.seekSlider setMaxValue:100];
    [self.seekSlider setTarget:self];
    [self.seekSlider setAction:@selector(seekVideo:)];
    [self addSubview:self.seekSlider];
}

- (void)initMPV {
    self.libmpvHandle = dlopen("./libmpv.dylib", RTLD_NOW);
    if (!self.libmpvHandle) {
        NSLog(@"Failed to load libmpv");
        return;
    }

    mpv_handle* (*mpv_create)() = dlsym(self.libmpvHandle, "mpv_create");
    int (*mpv_initialize)(mpv_handle*) = dlsym(self.libmpvHandle, "mpv_initialize");
    int (*mpv_command)(mpv_handle*, const char*[]) = dlsym(self.libmpvHandle, "mpv_command");

    if (!mpv_create || !mpv_initialize || !mpv_command) {
        NSLog(@"Missing symbols in libmpv");
        return;
    }

    self.mpv = mpv_create();
    mpv_initialize(self.mpv);

    // Load test file
    const char *cmd[] = {"loadfile", "/System/Library/Sounds/Funk.aiff", NULL};
    mpv_command(self.mpv, cmd);

    self.isPlaying = YES;
}

- (void)togglePlayPause:(id)sender {
    const char *cmd[] = { "cycle", "pause", NULL };
    int (*mpv_command)(mpv_handle*, const char*[]) = dlsym(self.libmpvHandle, "mpv_command");
    if (mpv_command) mpv_command(self.mpv, cmd);
    self.isPlaying = !self.isPlaying;
    [self.playPauseButton setTitle:(self.isPlaying ? @"Pause" : @"Play")];
}

- (void)seekVideo:(id)sender {
    double val = [self.seekSlider doubleValue];
    char buf[32];
    snprintf(buf, sizeof(buf), "%f", val);
    const char *cmd[] = {"seek", buf, "absolute-percent", NULL};
    int (*mpv_command)(mpv_handle*, const char*[]) = dlsym(self.libmpvHandle, "mpv_command");
    if (mpv_command) mpv_command(self.mpv, cmd);
}

- (void)dealloc {
    if (self.mpv) {
        int (*mpv_terminate_destroy)(mpv_handle*) = dlsym(self.libmpvHandle, "mpv_terminate_destroy");
        if (mpv_terminate_destroy) mpv_terminate_destroy(self.mpv);
        self.mpv = NULL;
    }
    if (self.libmpvHandle) {
        dlclose(self.libmpvHandle);
        self.libmpvHandle = NULL;
    }
}

@end
