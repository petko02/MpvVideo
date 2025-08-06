#include <stdio.h>
#include <string.h>
#include <mpv/client.h>
#include "wlxplugin.h"

static mpv_handle *mpv = NULL;

__attribute__((visibility("default")))
HWND DCPCALL ListLoad(HWND ParentWin, char *FileToLoad, int ShowFlags)
{
    mpv = mpv_create();
    if (!mpv) return 0;

    // Embed video into provided window
    char wid[64];
    snprintf(wid, sizeof(wid), "%p", (void *)ParentWin);
    mpv_set_option_string(mpv, "wid", wid);

    if (mpv_initialize(mpv) < 0) {
        mpv_terminate_destroy(mpv);
        mpv = NULL;
        return 0;
    }

    const char *cmd[] = {"loadfile", FileToLoad, NULL};
    mpv_command(mpv, cmd);

    return ParentWin;
}

__attribute__((visibility("default")))
void DCPCALL ListCloseWindow(HWND ListWin)
{
    if (mpv) {
        mpv_terminate_destroy(mpv);
        mpv = NULL;
    }
}

__attribute__((visibility("default")))
void DCPCALL ListGetDetectString(char *DetectString, int maxlen)
{
    snprintf(DetectString, maxlen - 1,
        "EXT=\"MP4\"|EXT=\"MKV\"|EXT=\"AVI\"|EXT=\"WMV\"|EXT=\"MOV\"|"
        "EXT=\"WEBM\"|EXT=\"FLV\"|EXT=\"M4V\"|EXT=\"MPG\"|EXT=\"MPEG\"|"
        "EXT=\"3GP\"|EXT=\"WAV\"");
}
