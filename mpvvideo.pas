library MpvVideo;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}

uses
  CocoaAll, MacOSAll, Classes, SysUtils, dynlibs;

const
  LISTPLUGIN_OK = 0;

type
  HWND = Pointer;

type
  TCreateMpvNSView = function(frame: NSRect): NSView; cdecl;
var
  CreateMpvNSView: TCreateMpvNSView;

function ListLoad(ParentWin: HWND; FileToLoad: PChar; ShowFlags: Integer): HWND; cdecl;
type
  TCreateMpvNSView = function(frame: NSRect): NSView; cdecl;
var
  CreateMpvNSView: TCreateMpvNSView;
  libHandle: TLibHandle;
  contentView: NSView;
  frame: NSRect;
  playerView: NSView;
begin
  if ParentWin = nil then
  begin
    Result := nil;
    Exit;
  end;

  libHandle := LoadLibrary('libMpvPlayerView.dylib');
  if libHandle = 0 then
  begin
    writeln('❌ Failed to load libMpvPlayerView.dylib');
    Result := nil;
    Exit;
  end;

  Pointer(CreateMpvNSView) := GetProcAddress(libHandle, 'CreateMpvNSView');
  if not Assigned(CreateMpvNSView) then
  begin
    writeln('❌ Failed to resolve CreateMpvNSView');
    Result := nil;
    Exit;
  end;

  contentView := NSView(ParentWin);
  frame := NSMakeRect(0, 0, contentView.frame.size.width, contentView.frame.size.height);

  playerView := CreateMpvNSView(frame);
  if playerView <> nil then
    contentView.addSubview(playerView);

  Result := ParentWin;
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
