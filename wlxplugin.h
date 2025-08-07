// wlxplugin.h
#ifndef WLX_PLUGIN_H
#define WLX_PLUGIN_H

#define DCPCALL __attribute__((visibility("default")))

typedef void* HWND;

int DCPCALL ListLoad(HWND ParentWin, char* FileToLoad, int ShowFlags);
void DCPCALL ListCloseWindow(HWND ListWin);
void DCPCALL ListGetDetectString(char* DetectString, int maxlen);

#endif
