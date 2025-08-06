// common.h
#ifndef _COMMON_H
#define _COMMON_H

#ifdef __GNUC__

#include <stdint.h>

#if defined(__WIN32__) || defined(_WIN32) || defined(_WIN64)
  #define DCPCALL __attribute__((stdcall))
#else
  #define DCPCALL
#endif

#define MAX_PATH 260

typedef int32_t LONG;
typedef uint32_t DWORD;
typedef uint16_t WORD;
typedef void *HANDLE;
typedef HANDLE HICON;
typedef HANDLE HBITMAP;
typedef HANDLE HWND;

// Only define BOOL when not compiling as Objective-C/ObjC++
#if !defined(__OBJC__)
typedef int BOOL;
#endif

typedef uint16_t WCHAR;
typedef intptr_t LPARAM;
typedef uintptr_t WPARAM;

#pragma pack(push,1)
typedef struct _RECT {
    LONG left;
    LONG top;
    LONG right;
    LONG bottom;
} RECT;
#pragma pack(pop)

#pragma pack(push,1)
typedef struct _WIN32_FIND_DATAA {
    DWORD    dwFileAttributes;
    FILETIME ftCreationTime;
    FILETIME ftLastAccessTime;
    FILETIME ftLastWriteTime;
    DWORD    nFileSizeHigh;
    DWORD    nFileSizeLow;
    DWORD    dwReserved0;
    DWORD    dwReserved1;
    char     cFileName[MAX_PATH];
    char     cAlternateFileName[14];
} WIN32_FIND_DATAA;
#pragma pack(pop)

#pragma pack(push,1)
typedef struct _WIN32_FIND_DATAW {
    DWORD    dwFileAttributes;
    FILETIME ftCreationTime;
    FILETIME ftLastAccessTime;
    FILETIME ftLastWriteTime;
    DWORD    nFileSizeHigh;
    DWORD    nFileSizeLow;
    DWORD    dwReserved0;
    DWORD    dwReserved1;
    WCHAR    cFileName[MAX_PATH];
    WCHAR    cAlternateFileName[14];
} WIN32_FIND_DATAW;
#pragma pack(pop)

#endif // __GNUC__

#ifndef __GNUC__

#if defined(_WIN32) || defined(_WIN64)
  #define DCPCALL __stdcall
#else
  #define DCPCALL __cdecl
#endif

#endif // !__GNUC__

#endif // _COMMON_H
