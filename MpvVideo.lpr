library MpvVideo;

{$mode objfpc}{$H+}
{$linklib c}

uses
  SysUtils, wlxplugin, dynlibs, ctypes;

type
  tmpv_handle = Pointer;

var
  mpv_create: function: tmpv_handle; cdecl;
  mpv_initialize: function(mpv: tmpv_handle): cint; cdecl;
  mpv_command: function(mpv: tmpv_handle; args: PPChar): cint; cdecl;
  mpv_destroy: procedure(mpv: tmpv_handle); cdecl;

  mpvLib: TLibHandle;
  mpvInstance: tmpv_handle = nil;

function LoadMPV: Boolean;
begin
  if mpvLib <> NilHandle then Exit(True);
  mpvLib := LoadLibrary('libmpv.dylib');
  if mpvLib = NilHandle then Exit(False);

  Pointer(mpv_create) := GetProcAddress(mpvLib, 'mpv_create');
  Pointer(mpv_initialize) := GetProcAddress(mpvLib, 'mpv_initialize');
  Pointer(mpv_command) := GetProcAddress(mpvLib, 'mpv_command');
  Pointer(mpv_destroy) := GetProcAddress(mpvLib, 'mpv_destroy');

  Result := Assigned(mpv_create) and Assigned(mpv_initialize) and
            Assigned(mpv_command) and Assigned(mpv_destroy);
end;

function InternalListLoad(ParentWin: THandle; FileToLoad: PAnsiChar; ShowFlags: Integer): THandle; cdecl;
var
  args: array[0..1] of PChar;
begin
  if not LoadMPV then Exit(0);

  mpvInstance := mpv_create();
  if mpvInstance = nil then Exit(0);

  if mpv_initialize(mpvInstance) < 0 then
  begin
    mpv_destroy(mpvInstance);
    mpvInstance := nil;
    Exit(0);
  end;

  args[0] := PChar(FileToLoad);
  args[1] := nil;
  mpv_command(mpvInstance, @args[0]);

  Result := ParentWin;
end;

procedure InternalListCloseWindow(ListWin: THandle); cdecl;
begin
  if Assigned(mpvInstance) then
  begin
    mpv_destroy(mpvInstance);
    mpvInstance := nil;
  end;
  if mpvLib <> NilHandle then
  begin
    UnloadLibrary(mpvLib);
    mpvLib := NilHandle;
  end;
end;

function InternalListGetDetectString(DetectString: PAnsiChar; maxlen: Integer): Integer; cdecl;
begin
  StrPLCopy(DetectString,
    'EXT="MP4" | EXT="MKV" | EXT="AVI" | EXT="WMV" | EXT="MOV" | EXT="M4V" | ' +
    'EXT="FLV" | EXT="WEBM" | EXT="MPEG" | EXT="MPG" | EXT="3GP" | EXT="3G2" | ' +
    'EXT="ASF" | EXT="RM" | EXT="VOB" | EXT="DAT" | EXT="MXF" | EXT="F4V" | ' +
    'EXT="TS" | EXT="OGV" | EXT="M2V" | EXT="MPV" | EXT="DIVX" | EXT="XVID" | ' +
    'EXT="MP3" | EXT="WAV" | EXT="FLAC" | EXT="AAC"',
    maxlen);
  Result := 0;
end;

// These are public stubs with proper exported names
function ListLoad(ParentWin: THandle; FileToLoad: PAnsiChar; ShowFlags: Integer): THandle; cdecl; public name 'ListLoad';
begin
  Result := InternalListLoad(ParentWin, FileToLoad, ShowFlags);
end;

procedure ListCloseWindow(ListWin: THandle); cdecl; public name 'ListCloseWindow';
begin
  InternalListCloseWindow(ListWin);
end;

function ListGetDetectString(DetectString: PAnsiChar; maxlen: Integer): Integer; cdecl; public name 'ListGetDetectString';
begin
  Result := InternalListGetDetectString(DetectString, maxlen);
end;

exports
  ListLoad,
  ListCloseWindow,
  ListGetDetectString;

begin
end.
