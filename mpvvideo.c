#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gtk/gtk.h>
#include <mpv/client.h>
#include "wlxplugin.h"

static mpv_handle *mpv = NULL;
static GtkWidget *window = NULL;
static GtkWidget *widget = NULL;

HWND DCPCALL ListLoad(HWND ParentWin, char *FileToLoad, int ShowFlags) {
    gtk_init(0, NULL);

    // Create a GTK window to embed in DC
    window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), "MpvViewer");
    gtk_widget_set_size_request(window, 800, 600);
    gtk_widget_realize(window);
    gtk_widget_show_all(window);

    // Init MPV
    mpv = mpv_create();
    if (!mpv) return 0;

    mpv_set_option_string(mpv, "vo", "libmpv");
    mpv_initialize(mpv);

    mpv_set_option_string(mpv, "wid", g_strdup_printf("%lu", (unsigned long)GDK_WINDOW_XID(gtk_widget_get_window(window))));

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

int DCPCALL ListGetDetectString(char *DetectString, int maxlen) {
    strncpy(DetectString, "EXT=\"MP4\"|EXT=\"MKV\"|EXT=\"AVI\"|EXT=\"WMV\"|EXT=\"MOV\"|EXT=\"WEBM\"|EXT=\"FLV\"|EXT=\"M4V\"|EXT=\"MPG\"|EXT=\"MPEG\"|EXT=\"3GP\"", maxlen - 1);
    return TRUE;
}
