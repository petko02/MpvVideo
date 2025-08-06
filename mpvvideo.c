#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gtk/gtk.h>
#include <mpv/client.h>
#include "wlxplugin.h"

static mpv_handle *mpv = NULL;
static GtkWidget *window = NULL;

HWND DCPCALL ListLoad(HWND ParentWin, char *FileToLoad, int ShowFlags) {
    gtk_init(0, NULL);

    window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), "MpvViewer");
    gtk_widget_set_size_request(window, 800, 600);
    gtk_widget_realize(window);
    gtk_widget_show_all(window);

    mpv = mpv_create();
    if (!mpv) return 0;

    mpv_initialize(mpv);

    const char *cmd[] = { "loadfile", FileToLoad, NULL };
    mpv_command(mpv, cmd);

    return (HWND)window;
}

void DCPCALL ListCloseWindow(HWND ListWin) {
    if (mpv) {
        mpv_terminate_destroy(mpv);
        mpv = NULL;
    }
    if (window) {
        gtk_widget_destroy(window);
        window = NULL;
    }
}

void DCPCALL ListGetDetectString(char *DetectString, int maxlen) {
    strncpy(DetectString, 
        "EXT=\"MP4\"|EXT=\"MKV\"|EXT=\"AVI\"|EXT=\"WMV\"|EXT=\"MOV\"|EXT=\"WEBM\"|"
        "EXT=\"FLV\"|EXT=\"M4V\"|EXT=\"MPG\"|EXT=\"MPEG\"|EXT=\"3GP\"|EXT=\"WAV\"", 
        maxlen - 1);
}
