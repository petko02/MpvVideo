library MpvVideo;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}

uses
  CocoaAll, MacOSAll, Classes, SysUtils;

const
  LISTPLUGIN_OK = 0;

type
  HWND = Pointer;

function CreateMpvNSView(frame: NSRect): NSView; cdecl; external 'libMpvPlayerView.dylib';

function ListLoad(ParentWin: HWND; FileToLoad: PChar; ShowFlags: Integer): HWND; cdecl;
var
  contentView: NSView;
  playerView: NSView;
  frame: NSRect;
begin
  if ParentWin = nil then
  begin
    Result := nil;
    Exit;
  end;

  contentView := NSView(ParentWin); // Cast pointer to NSView
  frame := NSMakeRect(0, 0, contentView.frame.size.width, contentView.frame.size.height);

  playerView := CreateMpvNSView(frame);
  if Assigned(playerView) then
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
