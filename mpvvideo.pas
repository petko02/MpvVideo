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
var
  contentView: NSView;
  frame: NSRect;
  playerView: NSView;
  libHandle: TLibHandle;
begin
  if ParentWin = nil then
  begin
    Result := nil;
    Exit;
  end;

  // Load the dynamic library
  libHandle := LoadLibrary('libMpvPlayerView.dylib');
  if libHandle = 0 then
  begin
    writeln('❌ Failed to load libMpvPlayerView.dylib');
    Result := nil;
    Exit;
  end;

  // Resolve the symbol
  Pointer(CreateMpvNSView) := GetProcAddress(libHandle, 'CreateMpvNSView');
  if not Assigned(CreateMpvNSView) then
  begin
    writeln('❌ Failed to resolve CreateMpvNSView');
    Result := nil;
    Exit;
  end;

  // Get the container view from Double Commander
  contentView := NSView(ParentWin);
  frame := NSMakeRect(0, 0, contentView.frame.size.width, contentView.frame.size.height);

  // Create and embed the video player view
  playerView := CreateMpvNSView(frame);
  if playerView <> nil then
    contentView.addSubview(playerView);

  Result := ParentWin;
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
