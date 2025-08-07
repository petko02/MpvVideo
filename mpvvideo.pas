library MpvVideo;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}

uses
  CocoaAll, MacOSAll, Classes, SysUtils, DynLibs;

const
  WLX_VERSION = 1;
  LISTPLUGIN_OK = 0;

type
  TListDefaultParamStruct = record
    size: Integer;
    InterfaceVersionLow: Integer;
    InterfaceVersionHigh: Integer;
    DefaultIniName: PChar;
  end;

  HWND = Pointer; // Just for compatibility; WLX doesn't need a real HWND

function ListLoad(ParentWin: HWND; FileToLoad: PChar; ShowFlags: Integer): HWND; cdecl;
begin
  // Placeholder: We'll embed an NSView here with libmpv playback
  Result := nil;
end;

function ListGetDetectString(DetectString: PChar; maxlen: Integer): Integer; cdecl;
var
  detect: AnsiString;
begin
  detect := 'EXT="MP4" | EXT="MKV" | EXT="AVI" | EXT="MOV" | EXT="WMV"';
  StrLCopy(DetectString, PChar(detect), maxlen - 1);
  Result := LISTPLUGIN_OK;
end;

exports
  ListLoad,
  ListGetDetectString;

begin
end.
