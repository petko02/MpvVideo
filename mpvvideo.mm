extern "C" void* ListLoad(void* hwndParent, int showFlags, char* fileToLoad, struct ListDefaultParamStruct* lps) {
    @autoreleasepool {
        // Determine preview size
        NSRect frame = NSMakeRect(0, 0, lps ? lps->size.cx : 640, lps ? lps->size.cy : 360);
        
        // Create embedded OpenGL view
        MpvGLView *view = [[MpvGLView alloc] initWithFrame:frame];
        if (!view) return nullptr;

        // Attach to parent view (required for Double Commander embedding)
        NSView *parent = (__bridge NSView *)hwndParent;
        [parent addSubview:view];

        // Load file (if present)
        if (fileToLoad) {
            const char *cmd[] = {"loadfile", fileToLoad, NULL};
            mpv_command([view getMPV], cmd);
        }

        // Return pointer to the view
        return (__bridge_retained void *)view;
    }
}
