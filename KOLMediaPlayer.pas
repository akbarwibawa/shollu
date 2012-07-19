unit KOLMediaPlayer;

//Note: KOL version 2.11 required!
//Compatible with KOL 2.91 !

{++}(*
{$DEFINE _FPC}
{$IFDEF FPC}
  {$IFNDEF DELPHI}
      {$DEFINE F_P}
  {$ENDIF DELPHI}
{$ENDIF FPC}
{$IFDEF F_P}
  {$ASMMODE intel}
  {$GOTO ON}
  {$LONGSTRINGS ON}
  {$IOCHECKS OFF}
  {$MINENUMSIZE 1}
  {$OVERFLOWCHECKS OFF}
  {$RANGECHECKS OFF}
  {$SMARTLINK ON} // !!!
  {$TYPEDADDRESS OFF}
  {$VARSTRINGCHECKS ON}
  {$EXTENDEDSYNTAX ON}
  //{$STACKFRAMES OFF}
{$ENDIF F_P}
*){--}

interface

{$I KOLDEF.INC}
{$I DELPHIDEF.INC}

uses
  Windows, MMSystem, KOL;

{#If not[OBJECTS]}
{#Replace[= object(][= class(]}
{#Replace[@Self][Self]}
{#Replace[@ Self][Self]}

{#SkipBetween[$IFDEF ASM_VERSION][$ELSE ASM_VERSION]}
{#SkipBetween[$IFDEF ASM_noVERSION][$ELSE ASM_VERSION]}
{#Replace[$ENDIF ASM_VERSION][]}

{#End not[OBJECTS]}

{ -- MultiMedia player object -- }

type
  {#If not[OBJECTS]}
  {++}(*TMediaPlayer = class;*){--}
  PMediaPlayer = {-}^{+}TMediaPlayer;

  TMPState = ( mpNotReady, mpStopped, mpPlaying, mpRecording, mpSeeking,
               mpPaused, mpOpen );
  {* Available states of TMediaPlayer. }
  TMPDeviceType = ( mmAutoSelect, mmVCR, mmVideodisc, mmOverlay, mmCDAudio, mmDAT,
                    mmScanner, mmAVIVideo, mmDigitalVideo, mmOther, mmWaveAudio,
                    mmSequencer );
  {* Available device types of TMediaPlayer. }
  TMPTimeFormat = ( tfMilliseconds, tfHMS, tfMSF, tfFrames, tfSMPTE24, tfSMPTE25,
                tfSMPTE30, tfSMPTE30Drop, tfBytes, tfSamples, tfTMSF );
  {* Available time formats, used with properties Length and Position. }
  TMPNotifyValue = (nvSuccessful, nvSuperseded, nvAborted, nvFailure);
  {* Available notification flags, which can be passed to TMediaPlayer.OnNotify
     event handler (if it is set). }
  TMPOnNotify = procedure( Sender: PMediaPlayer; NotifyValue: TMPNotifyValue ) of object;
  {* Event type for TMediaPlayer.OnNotify event. }


  TSoundChannel = ( chLeft, chRight );
  {* Available sound channels. }
  TSoundChannels = set of TSoundChannel;
  {* Set of available sound channels. }

{ ----------------------------------------------------------------------

                         TMediaPlayer object

----------------------------------------------------------------------- }
  TMediaPlayer = object( TObj )
  {* MediaPlayer incapsulation object. Can open and play any supported
     by system multimedia file. (To play wave only, it is possible to
     use functions PlaySound..., which can also play it from memory and
     from resource).
     |<br>
     Please note, that while debugging, You can get application exception
     therefore standalone application is working fine. (Such results took
     place for huge video). )
  }
  private
    FWait: Boolean;
    FDeviceID: Integer;
    FError: Integer;
    FTrack: Integer;
    FDisplay: HWnd;
    FFileName: String;
    FOnNotify: TMPOnNotify;
    FDeviceType: TMPDeviceType;
    FHeight: Integer;
    FWidth: Integer;
    FTimeFormat: TMPTimeFormat;
    FBaseKeyCDAudio: HKey;
    FoldKeyValCDData: DWORD;
    FoldKeyValCDAudio: String;
    FAutoRestore: procedure of object;
    FAudioOff: array[ TSoundChannel ] of Boolean;
    FVideoOff: Boolean;
    FAlias: String;
    function GetErrorMessage: String;
    function GetState: TMPState;
    procedure SetPause(const Value: Boolean);
    procedure SetTrack(Value: Integer);
    function GetCapability( const Index: Integer ): Boolean;
    function GetICapability( const Index: Integer ): Integer;
    procedure SetDisplay(const Value: HWND);
    function GetDisplayRect: TRect;
    function GetDeviceType: TMPDeviceType;
    procedure SetFileName(const Value: String);
    function GetBState( const Index: Integer ): Boolean;
    function GetIState( const Index: Integer ): Integer;
    function GetPosition: Integer;
    procedure SetPosition(Value: Integer);
    function GetTimeFormat: TMPTimeFormat;
    procedure SetTimeFormat(const Value: TMPTimeFormat);
    procedure SetDisplayRect(const Value: TRect);
    function GetPause: Boolean;
    function GetAudioOn(Chn: TSoundChannels): Boolean;
    procedure SetAudioOn(Chn: TSoundChannels; const Value: Boolean);
    function GetVideoOn: Boolean;
    procedure SetVideoOn(const Value: Boolean);
    function DGVGetSpeed: Integer;
    procedure DGVSetSpeed(const Value: Integer);
  protected
  {++}(*public*){--}
    destructor Destroy; {-}virtual;{+}{++}(*override;*){--}
    {* Please remember, that if CDAudio (e.g.) is playing, it is not stop
       playing when TMediaPlayer object destroying unless performing command
       ! Pause := True; }
  {#End not[OBJECTS]}
  public
    property FileName: String read FFileName write SetFileName;
    {* Name of file, containing multimedia, if any (some multimedia devices
       do not require file, corresponding to device rather then file. Such as
       mmCDAudio, mmScanner, etc. Use in that case DeviceType property to
       assign to desired type of multimedia and then open it using Open method).
       When new string is assigned to a FileName, previous media is closed
       and another one is opened automatically. }
    property DeviceType: TMPDeviceType read GetDeviceType write FDeviceType;
    {* Type of multimedia. For opened media, real type is returned. If no
       multimedia (device or file) opened, it is possible to set DeviceType to
       desired type before opening multimedia. Use such way for opening
       devices rather then for opening multimedia, stored in files. }
    property DeviceID: Integer read FDeviceID;
    {* Returns DeviceID, corresponded to opened multimedia (0 is returned
       if no media opened. }
    property TimeFormat: TMPTimeFormat read GetTimeFormat write SetTimeFormat;
    {* Time format, used to set/retrieve information about Length or Position.
       Please note, that not all formats are supported by all multimedia devices.
       Only tfMilliseconds (is set by default) supported by all devices. Following
       table shows what devices are supporting certain time formats:
       |<table>
       |&L=<tr><td>%0</td><td>
       |&E=</td></tr>
       <L tfMilliseconds> All multimedia device types. <E>
       <L tfBytes> mmWaveAudio <E>
       <L tfFrames> mmDigitalVideo <E>
       <L tfHMS (hours, minutes, seconds)> mmVCR (video cassete recorder), mmVideodisc.
          It is necessary to parse retrieved Length or Position or to prepare
          value before assigning it to Position using typecast to THMS. <E>
       <L tfMSF (minutes, seconds, frames)> mmCDAudio, mmVCR. It is necessary to
          parse value retrieved from Length or Position properties or value to
          assign to property Position using typecast to TMSF type. <E>
       <L tfSamples> mmWaveAudio <E>
       <L tfSMPTE24, tfSMPTE25, tfSMPTE30, tfSMPTE30DROP (Society of Motion Picture
          and Television Engineers)> mmVCR, mmSequencer. <E>
       <L tfTMSF (tracks, minutes, seconds, frames)> mmVCR <E>
       |</table> }
    property Position: Integer //index MCI_STATUS_POSITION read GetIState
             read GetPosition write SetPosition;
    {* Current position in milliseconds. Even if device contains several tracks,
       this is the position from starting of first track. To determine position
       in current Track, subtract TrackStartPosition. }
    property Track: Integer read FTrack write SetTrack;
    {* Current track (from 1 to TrackCount). Has no sence, if tracks are not
       supported by opened multimedia device, or no tracks present.  }
    property TrackCount: Integer index MCI_STATUS_NUMBER_OF_TRACKS read GetIState;
    {* Count of tracks for opened multimedia device. If device does not support
       tracks, or tracks not present (e.g. there are no tracks found on CD),
       value 1 is returned by system (but this not a rule to determine if
       tracks are available). }
    property Length: Integer index MCI_STATUS_LENGTH read GetIState;
    {* Length of multimedia in milliseconds. Even if device has tracks,
       this the length of entire multimedia. }
    property Display: HWnd read FDisplay write SetDisplay;
    {* Window to represent animation. It is recommended to create neutral
       control (e.g. label, or paint box, and assign its TControl.Handle to
       this property). Has no sense for multimedia, which HasVideo = False
       (no animation presented). }
    property DisplayRect: TRect read GetDisplayRect write SetDisplayRect;
    {* Rectangle in Display window, where animation is shown while playing
       animation. To restore default value, pass Bottom = Top = 0 and Right =
       Left = 0. }
    property Error: Integer read FError;
    {* Error code. Is set after every operation. If 0, no errors detected. It
       is also possible to retrieve description string for error using
       property ErrorMessage. }
    property ErrorMessage: String read GetErrorMessage;
    {* Brief description of Error. }
    property State: TMPState read GetState;
    {* Current state of multimedia. }
    property Pause: Boolean read GetPause write SetPause;
    {* True, if multimedia currently not playing (or not open). Set this property
       to True to pause playing, and to False to resume. }
    property Wait: Boolean read FWait write FWait;
    {* True, if operations will be performed synchronously (i.e. execution will
       be continued only after completing operation). If Wait is False (default),
       control is returned immediately to application, without waiting of completing
       of operation. It is possible in that case to get notification about finishing
       of previous operation in OnNotify event handler (if any has been set). }

    property TrackStartPosition: Integer index $80000000 or MCI_STATUS_POSITION
             read GetIState;
    {* Returns given track starting position (in units, specisied by TimeFormat
       property. E.g., if TimeFormat is set to (default) tfMilliseconds, in
       milliseconds). }
    property TrackLength: Integer index $80000000 or MCI_STATUS_LENGTH read GetIState;
    {* Returns given track length (in units, specified by TimeFormat property). }
    property OnNotify: TMPOnNotify read FOnNotify write FOnNotify;
    {* Called when asynchronous operation completed. (By default property Wait is
       set to False, so all operations are performed asynchronously, i.e. control
       is returned to application ithout of waiting of completion operation).
       Please note, that syatem can make several notifications while performing
       operation. To determine if operation completed, check State property.
       E.g., to find where playing is finished, check in OnNotify event handler
       if State <> mpPlaying.
       |<br>Though TMediaPlayer works fine with the most of multimedia formats
       (at least it is tested for WAV, MID, RMI, AVI (video and sound), MP3 (soound),
       MPG (video and sound) ),
       there are some problems with getting notifications about finishing MP3
       playing: when OnNotify is called, State returned is mpPlaying yet. For
       that case I can advice to check also playing time and compare it with
       Length of multimedia. }
    property Width: Integer read FWidth;
    {* Default width of video display (for multimedia, having video animation). }
    property Height: Integer read FHeight;
    {* Default height of video display (for multimedia, having video animation). }

    function Open: Boolean;
    {* Call this method to open device, which is not correspondent to file. For
       multimedia, stored in file, Open is called automatically when FileName
       property is changed.
       |<br>
       Multimedia is always trying to be open shareable first. If it is not
       possible, second attempt is made to open multimedia without sharing. }
    property Alias: String read FAlias write FAlias;
    {* Alias for opened device. Must be set before opening (before changing
       FileName). }
    function Play( StartPos, PlayLength: Integer ): Boolean;
    {* Call this method to play multimedia. StartPos is relative to
       starting position of opened multimedia, even if it has tracks. If value
       passed for StartPos is -1, current position is used to start from.
       If -1 passed as PlayLength, multimedia is playing to the end of media.
       Note, that after some operation (including Play) current position is
       moved and it is necessary to pass 0 as StartPos to play multimedia
       from its starting position again. To provide playing the same
       multimedia several times, call:
       ! with MyMediaPlayer do
       !   Play( 0, -1 );
       To Play single track, call:
       ! with MyMediaPlayer do
       ! begin
       !   Track := N; // set track to desired number
       !   Play( TrackStartPosition, TrackLength );
       ! end; }
    procedure Close;
    {* Closes multimedia. Later it can be reopened using Open method. Please
       remember, that if CDAudio (e.g.) is playing, it is not stop playing
       when Close is called. To stop playing, first perform command
       ! Pause := True; }
    procedure Eject;
    {* Ejects media from device. It is possible to check first, if this operation
       is supported by the device - see CanEject. }
    procedure DoorClose;
    {* Backward operation to Eject - inserts media to device. This operation is
       very easy and does not take in consideration if CD data / audio is playing
       automatically when media is inserted. To prevent launching CD player or
       application, defined in autostart.inf file in rootof CD, use Insert method
       instead. }
    procedure DisableAutoPlay;
    {* Be careful when using this method - this affects user settings such as 'Autoplay
       CD audio disk' and 'Autorun CD Data disk'. At least do not forget to restore
       settings later, using RestoreAutoPlay method. When You use Insert method
       to insert CD into device, DisableAutoPlay also is called, but in that case
       restoring is made automatically at least when TMediaPlayer object is
       destroying. }
    procedure RestoreAutoPlay;
    {* Restores settings CD autoplay settings, changed by calling DisableAutoPlay
       method (which must be called earlier to save settings and change it to
       disable CD autoplay feature). It is not necessary to call RestoreAutoPlay
       only in case, when method Insert was used to insert CD into device (but
       calling it restores settings therefore - so it is possible to restore
       settings not only when object TMediaPlayer destroyed, but earlier. }
    procedure Insert;
    {* Does the same as DoorClose, but first disables auto play settings, preventing
       system from running application defined in Autorun.inf (in CD root) or
       launching CD player application. Such settings will be restored at least
       when TMediaPlayer object is destroyed, but it is possible to call
       RestoreAutoPlay earlier (but there is no sence to call it immediately
       after performing Insert method - at least wait several seconds or start
       playing track first). }
    function Save( const aFileName: String ): Boolean;
    {* Saves multimedia to a file. Check first, if this operation is supported
       by device. }
    property Ready: Boolean index MCI_STATUS_READY read GetBState;
    {* True if Device is ready. }
    function StartRecording( FromPos, ToPos: Integer ): Boolean;
    {* Starts recording. If FromPos is passed -1, recording is starting from
       current position. If ToPos is passed -1, recording is continuing up
       to the end of media. }
    function Stop: Boolean;
    {* Stops playing back or recording. }

    property IsCompoundDevice: Boolean index MCI_GETDEVCAPS_COMPOUND_DEVICE read GetCapability;
    {* True, if device is compound. }
    property HasVideo: Boolean index MCI_GETDEVCAPS_HAS_VIDEO read GetCapability;
    {* True, if multimedia has videoanimation. }
    property HasAudio: Boolean index MCI_GETDEVCAPS_HAS_AUDIO read GetCapability;
    {* True, if multimedia contains audio. }
    property CanEject: Boolean index MCI_GETDEVCAPS_CAN_EJECT read GetCapability;
    {* True, if device supports "open door" and "close door" operations. }
    property CanPlay: Boolean index MCI_GETDEVCAPS_CAN_PLAY read GetCapability;
    {* True, if multimedia can be played (some of deviceces are only for recording,
       not for playing). }
    property CanRecord: Boolean index MCI_GETDEVCAPS_CAN_RECORD read GetCapability;
    {* True, if multimedia can be used to record (video or/and audio). }
    property CanSave: Boolean index MCI_GETDEVCAPS_CAN_SAVE read GetCapability;
    {* True, if multimedia device supports saving to a file. }
    property Present: Boolean index MCI_STATUS_MEDIA_PRESENT read GetBState;
    {* True, if CD or videodisc inserted into device. }

    property AudioOn[ Chn: TSoundChannels ]: Boolean read GetAudioOn write SetAudioOn;
    {* Returns True, if given audio channels (both if [chLeft,chRight], any if [])
       are "on". This property also allows to turn desired channels on and off. }
    property VideoOn: Boolean read GetVideoOn write SetVideoOn;
    {* Returns True, if video is "on". Allows to turn video signal on and off. }

    //-- for "CDAudio" only:
    property CDTrackNotAudio: Boolean index $80000000 or MCI_CDA_STATUS_TYPE_TRACK read GetBState;
    {* True, if current Track is not audio. }

    //-- for "digitalvideo":
    property DGV_CanFreeze: Boolean index $4002 {MCI_DGV_GETDEVCAPS_CAN_FREEZE} read GetCapability;
    {* True, if can freeze. }
    property DGV_CanLock: Boolean index $4000 {MCI_DGV_GETDEVCAPS_CAN_LOCK} read GetCapability;
    {* True, if can lock. }
    property DGV_CanReverse: Boolean index $4004 {MCI_DGV_GETDEVCAPS_CAN_REVERSE} read GetCapability;
    {* True, if can reverse playing. }
    property DGV_CanStretchInput: Boolean index $4008 {MCI_DGV_GETDEVCAPS_CAN_STR_IN} read GetCapability;
    {* True, if can stretch input. }
    property DGV_CanStretch: Boolean index $4001 {MCI_DGV_GETDEVCAPS_CAN_STRETCH} read GetCapability;
    {* True, if can stretch output. }
    property DGV_CanTest: Boolean index $4009 {MCI_DGV_GETDEVCAPS_CAN_TEST} read GetCapability;
    {* True, if supports Test. }
    property DGV_HasStill: Boolean index $4005 {MCI_DGV_GETDEVCAPS_HAS_STILL} read GetCapability;
    {* True, if has still images in video. }
    property DGV_MaxWindows: Integer index $4003 {MCI_DGV_GETDEVCAPS_MAX_WINDOWS} read GetICapability;
    {* Returns maximum windows supported. }
    property DGV_MaxRate: Integer index $400A {MCI_DGV_GETDEVCAPS_MAXIMUM_RATE} read GetICapability;
    {* Returns maximum possible rate (frames/sec). }
    property DGV_MinRate: Integer index $400B {MCI_DGV_GETDEVCAPS_MINIMUM_RATE} read GetICapability;
    {* Returns minimum possible rate (frames/sec). }

    property DGV_Speed: Integer read DGVGetSpeed write DGVSetSpeed;
    {* Returns speed of digital video as a ratio between the nominal frame
    rate and the desired frame rate where the nominal frame rate is designated
    as 1000. Half speed is 500 and double speed is 2000. The allowable speed
    range is dependent on the device and possibly the file, too. }

    //-- for AVI only (mmDigitalVideo, AVI-format):
    property AVI_AudioBreaks: Integer index $8003 {MCI_AVI_STATUS_AUDIO_BREAKS} read GetIState;
    {* Returns the number of times that the audio definitely broke up.
       (We count one for every time we're about to write some audio data
       to the driver, and we notice that it's already played all of the
       data we have). }
    property AVI_FramesSkipped: Integer index $8001 {MCI_AVI_STATUS_FRAMES_SKIPPED} read GetIState;
    {* Returns number of frames not drawn during last play.  If this number
       is more than a small fraction of the number of frames that should have
       been displayed, things aren't looking good. }
    property AVI_LastPlaySpeed: Integer index $8002 {MCI_AVI_STATUS_LAST_PLAY_SPEED} read GetIState;
    {* Returns a number representing how well the last AVI play worked.
       A result of 1000 indicates that the AVI sequence took the amount
       of time to play that it should have; a result of 2000, for instance,
       would indicate that a 5-second AVI sequence took 10 seconds to play,
       implying that the audio and video were badly broken up. }


    //-- for "vcr" (video cassete recorder):
    property VCR_ClockIncrementRate: Integer index $401C {MCI_VCR_GETDEVCAPS_CLOCK_INCREMENT_RATE} read GetICapability;
    {* }
    property VCR_CanDetectLength: Boolean index $4001 {MCI_VCR_GETDEVCAPS_CAN_DETECT_LENGTH} read GetCapability;
    {* True, if can detect Length. }
    property VCR_CanFreeze: Boolean index $401B {MCI_VCR_GETDEVCAPS_CAN_FREEZE} read GetCapability;
    {* True, if supports command "freeze". }
    property VCR_CanMonitorSources: Boolean index $4009 {MCI_VCR_GETDEVCAPS_CAN_MONITOR_SOURCES} read GetCapability;
    {* True, if can monitor sources. }
    property VCR_CanPreRoll: Boolean index $4007 {MCI_VCR_GETDEVCAPS_CAN_PREROLL} read GetCapability;
    {* True, if can preroll. }
    property VCR_CanPreview: Boolean index $4008 {MCI_VCR_GETDEVCAPS_CAN_PREVIEW} read GetCapability;
    {* True, if can preview. }
    property VCR_CanReverse: Boolean index $4004 {MCI_VCR_GETDEVCAPS_CAN_REVERSE} read GetCapability;
    {* True, if can play in reverse direction. }
    property VCR_CanTest: Boolean index $4006 {MCI_VCR_GETDEVCAPS_CAN_TEST} read GetCapability;
    {* True, if can test. }
    property VCR_HasClock: Boolean index $4003 {MCI_VCR_GETDEVCAPS_HAS_CLOCK} read GetCapability;
    {* True, if has clock. }
    property VCR_HasTimeCode: Boolean index $400A {MCI_VCR_GETDEVCAPS_HAS_TIMECODE} read GetCapability;
    {* True, if has time code. }
    property VCR_NumberOfMarks: Integer index $4005 {MCI_VCR_GETDEVCAPS_NUMBER_OF_MARKS} read GetICapability;
    {* Returns number of marks. }
    property VCR_SeekAccuracy: Integer index $4002 {MCI_VCR_GETDEVCAPS_SEEK_ACCURACY} read GetICapability;
    {* Returns seek accuracy. }

    //-- for mmWaveAudio:
    property Wave_AvgBytesPerSecond: Integer index $4004 {MCI_WAVE_STATUS_AVGBYTESPERSEC} read GetIState;
    {* Returns current bytes per second used for playing, recording, and saving. }
    property Wave_BitsPerSample: Integer index $4006 {MCI_WAVE_STATUS_BITSPERSAMPLE} read GetIState;
    {* Returns current bits per sample used for playing, recording, and saving PCM formatted data. }
    property Wave_SamplesPerSecond: Integer index $4003 {MCI_WAVE_STATUS_SAMPLESPERSEC} read GetIState;
    {* Returns current samples per second used for playing, recording, and saving. }

    function SendCommand( Cmd, Flags: Integer; Buffer: Pointer ): Integer;
    {* Low level access to a device. To get knoq how to use it, see sources. }

    {$IFNDEF _FPC}
    function asmSendCommand( Flags, Cmd: Integer {;var Buffer in stack} ): Integer;
    {* Assembler version of SendCommand - only for advanced programmers. It
       can be called from assembler only, and last parameter (but without
       first member of the structure, dwCallback) must be placed
       to stack just before calling asmSendCommand. Also, @Self must be
       placed already in EBX, second parameter (Cmd) in EDX, and third (Flags)
       in EAX. This method also retirns error code (0, if success), and
       additionally ZF flag set if success. }
    {$ENDIF}

    {$IFDEF USE_CONSTRUCTORS}
    constructor CreateMediaPlayer( const AFileName: String; AWindow: HWND );
    {$ENDIF USE_CONSTRUCTORS}
  end;


var MediaPlayers: PList;

function NewMediaPlayer( const FileName: String; Window: HWND ): PMediaPlayer;
{* Creates TMediaPlayer instance. If FileName is not empty string, file is opening
   immediately. }

type
  TPlayOption = ( poLoop, poWait, poNoStopAnotherSound, poNotImportant );
  {* Options to play sound. poLoop, when sound is playing back repeatedly until
     PlaySoundStop called. poWait, if sound is playing synchronously (i.e. control
     returns to application after the sound event completed). poNoStopAnotherSound
     means that another sound playing can not be stopped to free resources needed to
     play requested sound. poNotImportant means that if driver busy, function
     will return immediately returning False (with no sound playing). }
  TPlayOptions = set of TPlayOption;
  {* Options, available to play sound from memory or resource or to play standard
     sound event using PlaySoundMemory, PlaySoundResourceID, PlaySoundResourceName,
     PlaySoundEvent. }

function PlaySoundMemory( Memory: Pointer; Options: TPlayOptions ): Boolean;
{* Call it to play sound already stored in memory. (It is possible to preload
   sound from resource (e.g., using Resurce2Stream function) or to load sound from
   file. }
function PlaySoundResourceID( Inst, ResID: Integer; Options: TPlayOptions ): Boolean;
{* Call it to play sound, stored in resource. It is also possible to stop playing
   certain sound, asynchronously playing from a resource, using PlaySoundStopResID.
   |<br>&nbsp;&nbsp;&nbsp;
   In this implementation, sound is played from memory and always with poWait
   option turned on (i.e. synchronously). }
function PlaySoundResourceName( Inst: Integer; const ResName: String; Options: TPlayOptions ): Boolean;
{* Call it to play sound, stored in (named) resource. It is also possible to stop
   playing certain sound, asynchronously playing from a resource, using
   PlaySoundStopResName.
   |<br>&nbsp;&nbsp;&nbsp;
   In this implementation, sound is played from memory and always with poWait
   option turned on (i.e. synchronously). }
function PlaySoundEvent( const EventName: String; Options: TPlayOptions ): Boolean;
{* Call it to play standard event sound. E.g., 'SystemAsterisk', 'SystemExclamation',
   'SystemExit', 'SystemHand', 'SystemQuestion', 'SystemStart' sounds are defined
   for all Win32 implementations. }
function PlaySoundFile( const FileName: String; Options: TPlayOptions ): Boolean;
{* Call it to play waveform audio file. (This also can be done using
   TMediaPlayer, but for wide set of audio and video formats). }
function PlaySoundStop: Boolean;
{* Call it to stop playing sounds, which are yet playing (after calling
   PlaySountXXXXX functions above to play sounds asynchronously). }

function WaveOutChannels( DevID: Integer ): TSoundChannels;
{* Returns available sound output channels for given wave out device. Pass
   -1 (or WAVE_MAPPER) to get channels for wave mapper. If only mono
   output available, [ chLeft ] is returned. }
function WaveOutVolume( DevID: Integer; Chn: TSoundChannel; NewValue: Integer ): Word;
{* Sets volume for given channel. If NewValue = -1 passed, new value is not set.
   Always returns current volume level for a channel (if successful). Volume varies
   in diapason 0..65535. If passed value > 65535, low word of NewValue is used
   to set both chLeft and chRight channels. }


implementation

type
  {++}(*TControl1 = class;*){--}
  PControl1 = {-}^{+}TControl1;
  TControl1 = object( TControl )
  end;

////////////////////////////////////////////////////////////////////////
//
//
//                         M  P  L  A  Y  E  R
//
//
////////////////////////////////////////////////////////////////////////

function WndProcMCINotify( Sender: PControl; var Msg: TMsg; var Rslt: Integer )
                          : Boolean;
begin
  Result := FALSE;
  if Msg.message = MM_MCINOTIFY then
  begin
     if Assigned( FMMNotify ) then
        FMMNotify( Msg );
     Rslt := 0;
     Result := TRUE;
  end;
end;


{ -- TMediaPlayer -- }

{$IFDEF USE_CONSTRUCTORS}
function NewMediaPlayer( const FileName: String; Window: HWND ): PMediaPlayer;
begin
  new( Result, CreateMediaPlayer( FileName, Window ) );
end;
{$ELSE not_USE_CONSTRUCTORS}
{$IFDEF ASM_VERSION}
  function _NewMediaPlayer: PMediaPlayer;
  begin
    New( Result, Create );
  end;
function NewMediaPlayer( const FileName: String; Window: HWND ): PMediaPlayer;
asm
        PUSH     EBX
        PUSH     EDX
        PUSH     EAX
        CALL     _NewMediaPlayer
        XCHG     EBX, EAX
        MOV      ECX, [MediaPlayers]
        INC      ECX
        LOOP     @@ListCreated
        CALL     NewList
        MOV      [MediaPlayers], EAX
        XCHG     ECX, EAX
@@ListCreated:
        XCHG     EAX, ECX
        MOV      EDX, EBX
        CALL     TList.Add
        POP      EDX
        MOV      EAX, EBX
        CALL     TMediaPlayer.SetFileName
        POP      ECX
        MOV      EDX, [EBX].TMediaPlayer.FError
        TEST     EDX, EDX
        JNZ      @@exit

        PUSH     ECX
        MOV      EAX, EBX
        MOV      DL, MCI_GETDEVCAPS_HAS_VIDEO //$3
        CALL     TMediaPlayer.GetCapability
        TEST     AL, AL
        JZ       @@noVideo

        POP      EDX
        PUSH     EDX
        MOV      EAX, EBX
        CALL     TMediaPlayer.SetDisplay
@@noVideo:
        POP      [EBX].TMediaPlayer.FDisplay

@@exit:
        MOV      EDX, offset[WndProcMCINotify]
        MOV      EAX, [Applet]
        CALL     TControl.AttachProc

        XCHG     EAX, EBX
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
function NewMediaPlayer( const FileName: String; Window: HWND ): PMediaPlayer;
begin
  {#If not[OBJECTS]}
  {-}
  New( Result, Create );
  {+}{++}(*Result := PMediaPlayer.Create;*){--}
  {#End not[OBJECTS]}
  if MediaPlayers = nil then
    MediaPlayers := NewList;
  MediaPlayers.Add( Result );
  //Result.FTimeFormat := tfMilliseconds; //by default...
  Result.FileName := FileName;
  if Result.FError <> 0 then
    //MsgOK( 'Error #' + Int2Str( Result.Error ) + ' when opening multimedia:'#13 +
    //       Result.ErrorMessage )
  else
  begin
    if Result.HasVideo then
      Result.Display := Window;
    Result.FDisplay := Window;
  end;
  Applet.AttachProc( WndProcMCINotify );
end;
{$ENDIF ASM_VERSION}
{$ENDIF USE_CONSTRUCTORS}

{$IFDEF ASM_VERSION}
type
    TmmList = object(TList)  end;


procedure MMNotifyProc( var Msg: TMsg );
asm
        PUSH     EBX
        XCHG     EBX, EAX
        PUSH     ESI
        PUSH     EDI
        MOV      EDX, [MediaPlayers]
        TEST     EDX, EDX
        JZ       @@fin
        MOV      ECX, [EDX].TmmList.FCount
        MOV      ESI, [EDX].TmmList.FItems
        MOV      EDI, [EBX].TMsg.lParam
@@loo:
        LODSD
        CMP      [EAX].TMediaPlayer.FDeviceID, EDI
        JNZ      @@nxt

        MOV      ECX, [EAX].TMediaPlayer.fOnNotify.TMethod.Code
        JECXZ    @@fin
        MOV      EDI, ECX
        XCHG     EDX, EAX
        MOV      EAX, [EDX].TMediaPlayer.fOnNotify.TMethod.Data
        MOV      ECX, [EBX].TMsg.wParam
        DEC      ECX
        CALL     EDI
        JMP      @@fin

@@nxt:
        LOOP     @@loo
@@fin:
        POP      EDI
        POP      ESI
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
procedure MMNotifyProc( var Msg: TMsg );
var I: Integer;
    MP: PMediaPlayer;
begin
  if MediaPlayers <> nil then
  for I := 0 to MediaPlayers.Count - 1 do
  begin
    MP := MediaPlayers.Items[ I ];
    if MP.FDeviceID = Msg.lParam then
    begin
      if Assigned( MP.fOnNotify ) then
        MP.FOnNotify( MP, TMPNotifyValue( Msg.wParam - 1 ) );
      break;
    end;
  end;
end;
{$ENDIF ASM_VERSION}

{ TMediaPlayer }

{$IFDEF ASM_VERSION}
procedure TMediaPlayer.Close;
asm
        MOV      ECX, [EAX].FDeviceID
        JECXZ    @@exit
        PUSH     EBX
        XCHG     EBX, EAX
        //PUSH     EAX
        XOR      EAX, EAX
        INC      EAX // EAX = MCI_NOTIFY
        CDQ
        MOV      DX, MCI_CLOSE
        CALL     asmSendCommand
        //TEST     EAX, EAX
        JNZ      @@1
        MOV      [EBX].FDeviceID, EAX
@@1:
        //POP      ECX
        POP      EBX
@@exit:
end;
{$ELSE ASM_VERSION} //Pascal
procedure TMediaPlayer.Close;
var GenParm: TMCI_Generic_Parms;
begin
  if FDeviceID = 0 then Exit;
  GenParm.dwCallback := 0;
  //if SendCommand( MCI_CLOSE, MCI_NOTIFY, @GenParm ) = 0 then
  if SendCommand( MCI_CLOSE, MCI_WAIT, @GenParm ) = 0 then
    FDeviceID := 0;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_noVERSION}
destructor TMediaPlayer.Destroy;
asm
        PUSH     EBX
        MOV      EBX, EAX
        MOV      [EBX].FWait, 1
        XOR      EDX, EDX
        MOV      [EBX].FOnNotify.TMethod.Code, EDX
        CALL     Close
        MOV      EAX, [MediaPlayers]
        PUSH     EAX
        MOV      EDX, EBX
        CALL     TList.IndexOf
        XCHG     EDX, EAX
        POP      EAX
        PUSH     EAX
        PUSH     [EAX].TList.fCount
        CALL     TList.Delete
        POP      ECX
        POP      EAX
        LOOP     @@1
        MOV      [MediaPlayers], ECX
        CALL     TObj.Free
@@1:
        MOV      ECX, [EBX].FAutoRestore.TMethod.Code
        JECXZ    @@2
        MOV      EAX, EBX
        CALL     ECX
@@2:
        LEA      EAX, [EBX].FFileName
        CALL     System.@LStrClr
        LEA      EAX, [EBX].FoldKeyValCDAudio
        CALL     System.@LStrClr
        XCHG     EAX, EBX
        CALL     TObj.Destroy
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
destructor TMediaPlayer.Destroy;
var I: Integer;
begin
  FWait := True;
  FOnNotify := nil;
  I := MediaPlayers.IndexOf( @Self );
  if I >= 0 then
  begin
    Close;
    MediaPlayers.Delete( I );
  end;
  if MediaPlayers.Count = 0 then
  begin
    MediaPlayers.Free;
    MediaPlayers := nil;
  end;
  if Assigned( FAutoRestore ) then
     FAutoRestore;
  FFileName := '';
  FoldKeyValCDAudio := '';
  inherited;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
procedure TMediaPlayer.DoorClose;
asm
        PUSH     EBX
        XCHG     EBX, EAX
        PUSH     ECX  // dwAudio
        PUSH     ECX  // dwTimeFormat
        //PUSH     ECX  // dwCallback
        XOR      EAX, EAX
        MOV      AX, MCI_SET_DOOR_CLOSED or MCI_NOTIFY // $201
        CDQ
        MOV      DX, MCI_SET // $80D
        CALL     asmSendCommand
        //POP      ECX
        POP      ECX
        POP      ECX
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
procedure TMediaPlayer.DoorClose;
var SetParm: TMCI_Set_Parms;
begin
  Assert( (FDeviceID = 0) or CanEject, 'Device not support door close operation' );
  SendCommand( MCI_SET, MCI_SET_DOOR_CLOSED or MCI_NOTIFY, @SetParm );
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
procedure TMediaPlayer.Eject;
asm
        PUSH     EBX
        XCHG     EBX, EAX
        PUSH     ECX  // dwAudio
        PUSH     ECX  // dwTimeFormat
        //PUSH     ECX  // dwCallback
        XOR      EAX, EAX
        MOV      AX, MCI_SET_DOOR_OPEN or MCI_NOTIFY // $101
        CDQ
        MOV      DX, MCI_SET // $80D
        CALL     asmSendCommand
        //POP      ECX
        POP      ECX
        POP      ECX
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
procedure TMediaPlayer.Eject;
var SetParm: TMCI_Set_Parms;
begin
  Assert( (FDeviceID = 0) or CanEject, 'Device not support eject' );
  SendCommand( MCI_SET, MCI_SET_DOOR_OPEN or MCI_NOTIFY, @SetParm );
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.GetCapability( const Index: Integer ): Boolean;
asm
        CALL     GetICapability
        {$IFDEF PARANOIA}
        DB $24, $01
        {$ELSE}
        AND AL, 1
        {$ENDIF}
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.GetCapability( const Index: Integer ): Boolean;
begin
  Result := Boolean( GetICapability( Index ) );
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.GetICapability(const Index: Integer): Integer;
asm
        PUSH     EBX
        XCHG     EBX, EAX
        MOV      EAX, [EBX].FDeviceID
        TEST     EAX, EAX
        JZ       @@exit

        PUSH     EDX // dwItem := Index
        PUSH     ECX // dwReturn
        //PUSH     ECX // dwCallback
        XOR      EAX, EAX
        MOV      AX, MCI_WAIT or MCI_GETDEVCAPS_ITEM // $102
        CDQ
        MOV      DX, MCI_GETDEVCAPS // $80B
        CALL     asmSendCommand
        //POP      ECX // dwCallback
        POP      EDX // dwReturn
        POP      ECX // dwItem
        //TEST     EAX, EAX
        JZ       @@retEDX
        XOR      EDX, EDX
@@retEDX:
        XCHG     EAX, EDX // Result := dwRetirn
@@exit:
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.GetICapability(const Index: Integer): Integer;
var DevCapParm: TMCI_GetDevCaps_Parms;
begin
  Result := 0;
  if FDeviceID <> 0 then
  begin
    DevCapParm.dwItem := Index;
    if SendCommand( MCI_GETDEVCAPS, MCI_WAIT or MCI_GETDEVCAPS_ITEM, @DevCapParm ) = 0 then
      Result := DevCapParm.dwReturn;
  end;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.GetDeviceType: TMPDeviceType;
asm
        XOR      EDX, EDX
        MOV      DL, MCI_GETDEVCAPS_DEVICE_TYPE // $4
        CALL     GetICapability
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.GetDeviceType: TMPDeviceType;
begin
  Result := TMPDeviceType( GetICapability( MCI_GETDEVCAPS_DEVICE_TYPE ) { - 512 } );
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.GetDisplayRect: TRect;
asm
        PUSH     EBX
        XCHG     EBX, EAX
        PUSH     EDI
        MOV      EDI, EDX
        MOV      EAX, MCI_ANIM_WHERE_DESTINATION // $40000
        CDQ
        PUSH     EDX
        PUSH     EDX
        PUSH     EDX
        PUSH     EDX // rc = (0,0,0,0)
        //PUSH     ECX // dwCallback
        MOV      DX, MCI_WHERE or MCI_WAIT // $843
        CALL     asmSendCommand
        //POP      ECX // dwCallback

        JZ       @@success
        MOV      EDI, ESP
@@success:
        POP      [EDI].TRect.Left
        POP      [EDI].TRect.Top
        POP      [EDI].TRect.Right
        POP      [EDI].TRect.Bottom

        POP      EDI
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.GetDisplayRect: TRect;
var RectParms: TMCI_Anim_Rect_Parms;
begin
  Result := MakeRect( 0, 0, 0, 0 );
  //if HasVideo then
    if SendCommand( MCI_WHERE, MCI_ANIM_WHERE_DESTINATION or MCI_WAIT, @RectParms ) = 0 then
      Result := RectParms.rc;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
procedure TMediaPlayer.SetDisplayRect(const Value: TRect);
asm
        PUSH     EBX
        XCHG     EBX, EAX

        MOV      ECX, [EDX].TRect.Right
        OR       ECX, [EDX].TRect.Bottom
        JNZ      @@passValue

        MOV      EAX, [EBX].FHeight
        ADD      EAX, [EDX].TRect.Top
        PUSH     EAX // rc.Bottom
        MOV      EAX, [EBX].FWidth
        ADD      EAX, [EDX].TRect.Left
        PUSH     EAX // rc.Right

        JMP      @@1
@@passValue:
        PUSH     [EDX].TRect.Bottom
        PUSH     [EDX].TRect.Right
@@1:
        PUSH     [EDX].TRect.Top
        PUSH     [EDX].TRect.Left

        //PUSH     ECX // dwCallback
        MOV      EAX, MCI_ANIM_RECT or MCI_ANIM_PUT_DESTINATION or MCI_WAIT
        CDQ
        MOV      DX, MCI_PUT
        CALL     asmSendCommand
        ADD      ESP, 16
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
procedure TMediaPlayer.SetDisplayRect(const Value: TRect);
var RectParms: TMCI_Anim_Rect_Parms;
begin
  if (Value.Bottom = 0) and (Value.Right = 0) then
  begin
    {special case, use default width and height}
    with Value do
      RectParms.rc := MakeRect(Left, Top, Left+FWidth, Top+FHeight);
  end
  else RectParms.rc := Value;
  SendCommand( MCI_PUT, MCI_ANIM_RECT or MCI_ANIM_PUT_DESTINATION or MCI_WAIT,
               @RectParms );
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.GetErrorMessage: String;
asm
        ADD      ESP, -1024
        MOV      ECX, ESP
        PUSH     EDX
        PUSH     1024
        PUSH     ECX
        PUSH     [EAX].FError
        CALL     mciGetErrorString
        POP      EDX // EDX = @Result
        TEST     EAX, EAX
        JNZ      @@1
        POP      ECX
        PUSH     EAX
@@1:
        XCHG     EAX, EDX
        MOV      EDX, ESP
        CALL     System.@LStrFromPChar
        ADD      ESP, 1024
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.GetErrorMessage: String;
var
  ErrMsg: array[0..1023{129 - in win32.hlp, 128 bytes are always sufficient, but...}] of Char;
begin
  if not mciGetErrorString(FError, ErrMsg, SizeOf(ErrMsg)) then
    ErrMsg[ 0 ] := #0;
  Result := ErrMsg;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.GetState: TMPState;
asm
        XOR      EDX, EDX
        MOV      DL, MCI_STATUS_MODE // $4
        CALL     GetIState
        {$IFDEF PARANOIA}
        DB $2C, $0C
        {$ELSE}
        SUB      AL, 12
        {$ENDIF}
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.GetState: TMPState;
begin
  Result := TMPState( GetIState( MCI_STATUS_MODE ) - 524 );
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_noVERSION} //alias
function TMediaPlayer.Open: Boolean;
asm
        MOV      [FMMNotify], offset[MMNotifyProc]
        PUSH     EBX
        PUSH     ESI
        XCHG     EBX, EAX
        MOV      ECX, [EBX].FDeviceID
        TEST     ECX, ECX
        JNZ      @@exit
        PUSH     ECX // lpstrAlias
        PUSH     [EBX].FFileName // lpstrElementName
        MOVZX    EAX, [EBX].FDeviceType
        CDQ
        TEST     EAX, EAX
        MOV      DH, MCI_OPEN_ELEMENT shr 8 // MCI_OPEN_ELEMENT = $200
        JZ       @@all_types
        MOV      DX, MCI_OPEN_TYPE or MCI_OPEN_TYPE_ID
        ADD      AX, 513
@@all_types:
        DEC      EAX
        PUSH     EAX // lpstrDeviceType
        DEC      [EBX].FDeviceID
        XCHG     EAX, EDX
        OR       AX, MCI_NOTIFY or MCI_OPEN_SHAREABLE //$101
        CDQ
        MOV      DX, MCI_OPEN //$803
        MOV      ESI, EAX
        PUSH     EAX // wDeviceID
        CALL     asmSendCommand
        JZ       @@opened
        DEC      [EBX].FDeviceID
        XCHG     EAX, ESI
        AND      AH, $FE // Flag := Flag and not MCI_OPEN_SHAREABLE
        CDQ
        MOV      DX, MCI_OPEN
        CALL     asmSendCommand
@@opened:
        POP      EDX // EDX = wDeviceID
        POP      ECX
        POP      ECX
        POP      ECX
        JNZ      @@exit
        MOV      [EBX].FDeviceID, EDX
        MOV      [EBX].FWidth, EAX
        MOV      [EBX].FHeight, EBX
        MOV      EAX, EBX
        XOR      EDX, EDX
        MOV      DL, MCI_GETDEVCAPS_HAS_VIDEO // $3
        CALL     GetCapability
        TEST     AL, AL
        JZ       @@noDisplay

        MOV      EAX, EBX
        MOV      EDX, [EBX].FDisplay
        CALL     SetDisplay
        ADD      ESP, -16
        MOV      EAX, EBX
        MOV      EDX, ESP
        CALL     GetDisplayRect
        POP      ECX // Left
        POP      EDX // Top
        POP      EAX // Right
        SUB      EAX, ECX
        MOV      [EBX].FWidth, EAX
        POP      EAX // Bottom
        SUB      EAX, EDX
        MOV      [EBX].FHeight, EAX

@@noDisplay:
        XOR      EAX, EAX
        MOV      word ptr [EBX].FAudioOff, AX    
        MOV      EAX, EBX
        MOVZX    EDX, [EBX].FTimeFormat
        CALL     SetTimeFormat

@@exit:
        MOV      EAX, [EBX].FDeviceID
        TEST     EAX, EAX
        SETNZ    AL
        POP      ESI
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.Open: Boolean;
const DevTypes: array [ TMPDeviceType ] of DWORD = ( MCI_ALL_DEVICE_ID,
      MCI_DEVTYPE_VCR, MCI_DEVTYPE_VIDEODISC, MCI_DEVTYPE_OVERLAY,
      MCI_DEVTYPE_CD_AUDIO, MCI_DEVTYPE_DAT, MCI_DEVTYPE_SCANNER,
      MCI_DEVTYPE_ANIMATION, MCI_DEVTYPE_DIGITAL_VIDEO, MCI_DEVTYPE_OTHER,
      MCI_DEVTYPE_WAVEFORM_AUDIO, MCI_DEVTYPE_SEQUENCER );
var
  OpenParm: TMCI_Open_Parms;
  Flag: Integer;
  DisplayR: TRect;
  R: Integer;
begin
  FMMNotify := MMNotifyProc;
  if FDeviceID <> 0 then Result := True { opened already } else
  begin
    ASSERT( (FFileName = '') and (FDeviceType <> mmAutoSelect)
            or FileExists( FFileName ), 'Multimedia file does not exist' );
    ASSERT( not ((FDeviceType in [ mmVideoDisc, mmCDAudio, mmVCR, mmDigitalVideo {more?} ])
               and (FFileName <> '')), 'FileName can not be used with simple multimedia device' );
    FillChar(OpenParm, SizeOf(TMCI_Open_Parms), 0);
    Flag := MCI_OPEN_ELEMENT;
    if FDeviceType <> mmAutoSelect then
    begin
      Flag := MCI_OPEN_TYPE or MCI_OPEN_TYPE_ID;
    end;
    if FAlias <> '' then
    begin
      Flag := Flag or MCI_OPEN_ALIAS;
      OpenParm.lpstrAlias := PChar( FAlias );
    end;
    OpenParm.lpstrDeviceType := Pointer( DevTypes[ FDeviceType ] );
    OpenParm.lpstrElementName := PChar(FFileName);
    FDeviceID := -1;
    R := SendCommand( MCI_OPEN, MCI_NOTIFY or MCI_OPEN_SHAREABLE or Flag, @OpenParm );
    if (R <> 0) then
    begin
      FDeviceID := -1;
      R := SendCommand( MCI_OPEN, MCI_NOTIFY or Flag, @OpenParm );
    end;

    if (R <> 0) then
      Result := False
                else
    begin
      FDeviceID := OpenParm.wDeviceID;
      FWidth := 0;
      FHeight := 0;
      if HasVideo then
      begin
        Display := FDisplay;
        DisplayR := GetDisplayRect;
        FWidth := DisplayR.Right-DisplayR.Left;
        FHeight := DisplayR.Bottom-DisplayR.Top;
      end;
      TimeFormat := FTimeFormat;
      FAudioOff[ chLeft ] := False;
      FAudioOff[ chRight ] := False;
      Result := True;
    end;
  end;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.Play( StartPos, PlayLength: Integer ): Boolean;
asm
        PUSH     EBX
        XCHG     EBX, EAX
        XOR      EAX, EAX
        TEST     ECX, ECX
        JL       @@noTo
        TEST     EDX, EDX
        PUSH     EDX
        JGE      @@startPlusLen
        PUSH     ECX
        CALL     GetPosition
        XCHG     EDX, EAX
        POP      ECX
@@startPlusLen:
        ADD      ECX, EDX
        POP      EDX
        XOR      EAX, EAX
        MOV      AL, MCI_TO // $8
@@noTo:
        PUSH     ECX // dwTo

        TEST     EDX, EDX
        JZ       @@noFrom
        {$IFDEF PARANOIA}
        DB $0C, $04
        {$ELSE}
        OR       AL, MCI_FROM // $4
        {$ENDIF}
@@noFrom:
        PUSH     EDX // dwFrom
        INC      EAX // Flags := Flags or MCI_NOTIFY
        CDQ
        MOV      DX, MCI_PLAY //$806
        CALL     asmSendCommand
        SETZ     AL
        POP      ECX
        POP      ECX
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.Play( StartPos, PlayLength: Integer ): Boolean;
var PlayParm: TMCI_Play_Parms;
    Flags: Integer;
begin
  Flags := 0;
  if StartPos >= 0 then
  begin
    PlayParm.dwFrom := StartPos;
    Flags := MCI_FROM;
  end;
  if PlayLength >= 0 then
  begin
    if StartPos >= 0 then
      PlayParm.dwTo := StartPos + PlayLength
    else
      PlayParm.dwTo := Position + PlayLength;
    Flags := Flags or MCI_TO;
  end;
  Result := SendCommand( MCI_PLAY, Flags or MCI_NOTIFY, @PlayParm ) = 0;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.Save( const aFileName: String ): Boolean;
asm
        PUSH     EBX
        XCHG     EAX, EBX
        PUSH     EDX
        XOR      EAX, EAX
        CDQ
        MOV      AX, MCI_SAVE_FILE or MCI_NOTIFY
        MOV      DX, MCI_SAVE
        CALL     asmSendCommand
        SETZ     AL
        POP      EDX
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.Save( const aFileName: String ): Boolean;
var SaveParm: TMCI_SaveParms;
begin
  //Result := False;
  //if FDeviceID = 0 then Exit;
  SaveParm.lpfilename := PChar( aFileName );
  Result := SendCommand( MCI_SAVE, MCI_NOTIFY or MCI_SAVE_FILE, @SaveParm ) = 0;
end;
{$ENDIF ASM_VERSION}

{$IFNDEF _FPC}
function TMediaPlayer.asmSendCommand(Flags {in EAX}, Cmd {in EDX}: Integer {; var Buf in stack}): Integer;
asm
        POP      ECX
        PUSH     ECX
        PUSH     ECX
        LEA      ECX, [ESP+4]
        PUSH     ECX               // Buffer
        MOV      ECX, [EBX].FDeviceID
        JECXZ    @@error
        {$IFDEF PARANOIA}
        DB $A8, $02
        {$ELSE}
        TEST     AL, MCI_WAIT
        {$ENDIF}
        JNZ      @@1
        {$IFDEF PARANOIA}
        DB $24, $FD
        {$ELSE}
        AND      AL, not MCI_WAIT
        {$ENDIF}
        CMP      [EBX].FWait, 0
        JZ       @@1
        {$IFDEF PARANOIA}
        DB $0C, $02
        {$ELSE}
        OR       AL, MCI_WAIT
        {$ENDIF}
@@1:
        {$IFDEF PARANOIA}
        DB $A8, $02
        {$ELSE}
        TEST     AL, MCI_WAIT
        {$ENDIF}
        JNZ      @@clr_notify
        CMP      [Applet], 0
        JNZ      @@2
@@clr_notify:
        {$IFDEF PARANOIA}
        DB $24, $FE
        {$ELSE}
        AND      AL, not MCI_NOTIFY
        {$ENDIF}
@@2:
        PUSH     EAX               // Flags
        {$IFDEF PARANOIA}
        DB $A8, $01
        {$ELSE}
        TEST     AL, MCI_NOTIFY
        {$ENDIF}
        JZ       @@3

        MOV      EAX, [Applet]
        MOV      EAX, [EAX].TControl1.FHandle
        MOV      [ESP+12], EAX // dwCallback := Applet.FHandle
@@3:
        PUSH     EDX               // Cmd

        INC      ECX
        JZ       @@4
        DEC      ECX
@@4:    PUSH     ECX               // FDeviceID=-1?0:FDeviceID

        CALL     mciSendCommand
        XCHG     ECX, EAX
        INC      ECX
        PUSH     EDX
@@error:
        POP      EDX
        DEC      ECX
        XCHG     EAX, ECX
        MOV      [EBX].FError, EAX
        TEST     EAX, EAX // also return "ZF" if OK (no errors)
        POP      ECX
        POP      EDX
        PUSH     ECX
end;
{$ENDIF _FPC}

{$IFDEF ASM_VERSION}
type
    TmmControl = object(TControl) end;

function TMediaPlayer.SendCommand(Cmd, Flags: Integer; Buffer: Pointer): Integer;
asm
        PUSH     EBX
        XCHG     EBX, EAX
        OR       [EBX].FError, -1
        XCHG     EAX, ECX // EAX=Flags
        MOV      ECX, [EBX].FDeviceID
        JECXZ    @@exit
        PUSH     Buffer // -> Buffer
        {$IFDEF PARANOIA}
        DB $A8, $02
        {$ELSE}
        TEST     AL, MCI_WAIT
        {$ENDIF}
        JNZ      @@1
        {$IFDEF PARANOIA}
        DB $24, $FD
        {$ELSE}
        AND      AL, not MCI_WAIT
        {$ENDIF}
        CMP      [EBX].FWait, 0
        JZ       @@1
        {$IFDEF PARANOIA}
        DB $0C, $02
        {$ELSE}
        OR       AL, MCI_WAIT
        {$ENDIF}
@@1:
        {$IFDEF PARANOIA}
        DB $A8, $02
        {$ELSE}
        TEST     AL, MCI_WAIT
        {$ENDIF}
        JNZ      @@clrNotify
        SUB      [Applet], 0
        JNZ      @@2
@@clrNotify:
        {$IFDEF PARANOIA}
        DB $24, $FE
        {$ELSE}
        AND      AL, not MCI_NOTIFY
        {$ENDIF}
@@2:
        PUSH     EAX // -> Flags
        PUSH     EDX // -> Cmd
        {$IFDEF PARANOIA}
        DB $A8, $01
        {$ELSE}
        TEST     AL, MCI_NOTIFY
        {$ENDIF}
        JZ       @@noNotify
        MOV      EAX, [Applet]
        MOV      EAX, [EAX].TmmControl.FHandle
        MOV      EDX, [Buffer]
        MOV      [EDX], EAX
@@noNotify:
        INC      ECX
        JZ       @@devID
        DEC      ECX
@@devID:
        PUSH     ECX
        CALL     mciSendCommand
        MOV      [EBX].FError, EAX
@@exit:
        MOV      EAX, [EBX].FError
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.SendCommand(Cmd, Flags: Integer; Buffer: Pointer): Integer;
var Parms: PMCI_Generic_Parms;
begin
  FError := -1;
  if FDeviceID <> 0 then
  begin
    if not LongBool( Flags and MCI_WAIT ) then
    begin
      Flags := Flags and not MCI_WAIT;
      if FWait then
        Flags := Flags or MCI_WAIT;
    end;
    if LongBool( Flags and MCI_WAIT ) or not Assigned( Applet ) then
      Flags := Flags and not MCI_NOTIFY;
    Parms := Buffer;
    //Parms.dwCallback := Applet.FHandle;
    if LongBool( Flags and (MCI_NOTIFY {or MCI_WAIT})) then
    begin
      {if FDisplay <> 0 then
        Parms.dwCallback := FDisplay
      else}
        Parms.dwCallback := {$IFDEF FPC} Applet.Handle
                            {$ELSE DELPHI} PControl1( Applet ).FHandle;
                            {$ENDIF}
                         // MakeLong( Applet.FHandle, 0 );
    end;
    if FDeviceID = -1 then
      FDeviceID := 0;
    FError := mciSendCommand( FDeviceID, Cmd, Flags, Integer(Buffer) );
  end;
  Result := FError;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
procedure TMediaPlayer.SetDisplay(const Value: HWND);
asm
        PUSH     EBX
        XCHG     EBX, EAX
        PUSH     EDX
        MOV      EAX, MCI_WAIT or MCI_ANIM_WINDOW_HWND
        CDQ
        MOV      DX, MCI_WINDOW //$841
        CALL     asmSendCommand
        POP      EDX
        JNZ      @@exit
        MOV      [EBX].FDisplay, EDX
@@exit:
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
procedure TMediaPlayer.SetDisplay(const Value: HWND);
var AniWndParm: TMCI_Anim_Window_Parms;
begin
  FDisplay := Value;
  if Value <> 0 then
    AniWndParm.Wnd := Value
  else
    AniWndParm.Wnd := 0;
  if SendCommand( MCI_WINDOW, MCI_WAIT or MCI_ANIM_WINDOW_HWND, @AniWndParm ) <> 0 then
    FDisplay := 0;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
procedure TMediaPlayer.SetPause(const Value: Boolean);
asm
        PUSH     EBX
        XCHG     EBX, EAX
        XOR      EAX, EAX
        INC      EAX
        DEC      DL
        CDQ
        MOV      DX, MCI_PAUSE
        JZ       @@pause
        MOV      DL, MCI_RESUME and $FF
@@pause:
        CALL     asmSendCommand
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
procedure TMediaPlayer.SetPause(const Value: Boolean);
var Cmd: Integer;
    GenParm: TMCI_Generic_Parms;
begin
  if Value then
    Cmd := MCI_PAUSE
  else
    Cmd := MCI_RESUME;
  SendCommand( Cmd, MCI_NOTIFY, @GenParm );
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
procedure TMediaPlayer.SetPosition(Value: Integer);
asm
        PUSH     EBX
        XCHG     EBX, EAX
        PUSH     EDX
        XOR      EAX, EAX
        CDQ
        MOV      AL, MCI_NOTIFY or MCI_TO //$9
        MOV      DX, MCI_SEEK
        CALL     asmSendCommand
        POP      EDX
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
procedure TMediaPlayer.SetPosition(Value: Integer);
var SeekParm: TMCI_Seek_Parms;
begin
  SeekParm.dwTo := Value;
  SendCommand( MCI_SEEK, MCI_NOTIFY or MCI_TO, @SeekParm );
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
procedure TMediaPlayer.SetTrack(Value: Integer);
asm
        CMP      EDX, [EAX].FTrack
        JZ       @@exit
        PUSH     EAX
        PUSH     EDX
        XOR      EDX, EDX
        MOV      DL, MCI_STATUS_NUMBER_OF_TRACKS // $3
        CALL     GetIState
        POP      EDX
        POP      ECX
        CMP      EDX, EAX
        JLE      @@1
        XCHG     EDX, EAX
@@1:
        MOV      [ECX].FTrack, EDX
@@exit:
end;
{$ELSE ASM_VERSION} //Pascal
procedure TMediaPlayer.SetTrack(Value: Integer);
var TC: Integer;
begin
  if FTrack = Value then Exit;
  TC := TrackCount;
  if Value > TC then
    Value := TC;
  FTrack := Value;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
procedure TMediaPlayer.SetFileName(const Value: String);
asm
        PUSHAD
        MOV      EAX, [EAX].FFileName
        CALL     System.@LStrCmp
        POPAD
        JZ       @@1
        PUSHAD
        CALL     Close
        POPAD
@@1:
        PUSHAD
        LEA      EAX, [EAX].FFileName
        CALL     System.@LStrAsg
        POPAD
        TEST     EDX, EDX
        JNZ      Open
end;
{$ELSE ASM_VERSION} //Pascal
procedure TMediaPlayer.SetFileName(const Value: String);
begin
  if FFileName <> Value then
    Close;
  FFileName := Value;
  if Value <> '' then
    Open;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.GetBState( const Index: Integer ): Boolean;
asm
        CALL     GetIState
        {$IFDEF PARANOIA}
        DB $24, $01
        {$ELSE}
        AND      AL, 1
        {$ENDIF}
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.GetBState( const Index: Integer ): Boolean;
begin
  Result := (GetIState( Index ) and 1) = 1;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.GetIState(const Index: Integer): Integer;
asm
        PUSH     EBX
        XCHG     EBX, EAX
        MOV      ECX, [EBX].FTrack
        PUSH     ECX
        PUSH     EDX
        AND      byte ptr [ESP+3], $7F
        XOR      EAX, EAX // flags = 0
        PUSH     EAX
        MOV      AX, MCI_WAIT or MCI_STATUS_ITEM
        TEST     EDX, EDX
        JGE      @@1
        JECXZ    @@1
        {$IFDEF PARANOIA}
        DB $0C, MCI_TRACK
        {$ELSE}
        OR       AL, MCI_TRACK
        {$ENDIF}
@@1:
        CDQ
        MOV      DX, MCI_STATUS
        CALL     asmSendCommand
        POP      EAX
        POP      ECX
        POP      ECX
        JZ       @@2
        XOR      EAX, EAX
@@2:
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.GetIState(const Index: Integer): Integer;
var StatusParm: TMCI_Status_Parms;
    Flags: Integer;
begin
  Flags := 0;
  StatusParm.dwItem := Index and $7FFFFFFF;
  if Index < 0 then
  if FTrack <> 0 then
  begin
    Flags := MCI_TRACK;
    StatusParm.dwTrack := FTrack;
  end;
  Result := 0;
  if SendCommand( MCI_STATUS, MCI_WAIT or MCI_STATUS_ITEM or Flags, @StatusParm ) = 0 then
    Result := StatusParm.dwReturn;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.GetPosition: Integer;
asm
        XOR      EDX, EDX
        MOV      DL, MCI_STATUS_POSITION //$2
        CALL     GetIState
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.GetPosition: Integer;
begin
  Result := GetIState( MCI_STATUS_POSITION );
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.GetTimeFormat: TMPTimeFormat;
asm
        XOR      EDX, EDX
        MOV      DL, MCI_STATUS_TIME_FORMAT // $6
        CALL     GetIState
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.GetTimeFormat: TMPTimeFormat;
begin
  Result := TMPTimeFormat( GetIState( MCI_STATUS_TIME_FORMAT ) );
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
procedure TMediaPlayer.SetTimeFormat(const Value: TMPTimeFormat);
asm
        PUSH     EBX
        XCHG     EBX, EAX
        MOVZX    EDX, DL
        PUSH     EDX
        XCHG     EAX, EDX
        CDQ
        MOV      AX, MCI_SET_TIME_FORMAT or MCI_NOTIFY
        MOV      DX, MCI_SET //$80D
        CALL     asmSendCommand
        POP      EDX
        JNZ      @@exit
        MOV      [EBX].FTimeFormat, DL
@@exit:
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
procedure TMediaPlayer.SetTimeFormat(const Value: TMPTimeFormat);
var SetParm: TMCI_Set_Parms;
begin
  ASSERT( (FDeviceID = 0) or (Value = tfMilliseconds)
          or (Value in [ tfBytes, tfSamples ]) and (DeviceType = mmWaveAudio)
          or (Value = tfFrames) and (DeviceType in [ mmVCR, mmVideoDisc, mmDigitalVideo ])
          or (Value = tfHMS) and (DeviceType in [ mmVCR, mmVideoDisc ])
          or (Value in [ tfMSF, tfTMSF ]) and (DeviceType in [ mmCDAudio, mmVCR ])
          or (Value in [ tfSMPTE24, tfSMPTE25, tfSMPTE30, tfSMPTE30Drop ])
              and (DeviceType in [ mmSequencer, mmVCR ]),
          'Time format not supported by multimedia device' );
  SetParm.dwTimeFormat := Ord( Value );
  if SendCommand( MCI_SET, MCI_NOTIFY or MCI_SET_TIME_FORMAT, @SetParm ) = 0 then
      FTimeFormat := Value;
end;
{$ENDIF ASM_VERSION}

function TMediaPlayer.GetPause: Boolean;
begin
  Result := State <> mpPlaying;
end;

const Key_CD_AutoPlay: PChar = 'AudioCD\Shell';
      Key_CD_AutoRun: PChar = 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer';
      Val_CD_AutoRun: PChar = 'NoDriveTypeAutoRun';

{$IFDEF ASM_VERSION}
procedure TMediaPlayer.Insert;
asm
        PUSH     EAX
        CALL     DisableAutoPlay
        POP      EAX
        MOV      [EAX].FAutoRestore.TMethod.Code, offset[RestoreAutoPlay]
        CALL     DoorClose
end;
{$ELSE ASM_VERSION} //Pascal
procedure TMediaPlayer.Insert;
begin
  DisableAutoPlay;
  FAutoRestore := RestoreAutoPlay;
  DoorClose;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
procedure TMediaPlayer.DisableAutoPlay;
asm
        PUSH     EBX
        XCHG     EBX, EAX
        MOV      EDX, [Key_CD_AutoRun]
        MOV      EAX, HKEY_CURRENT_USER
        CALL     RegKeyOpenWrite
        PUSH     EAX // K1
        MOV      EDX, [Val_CD_AutoRun]
        PUSH     EDX
        CALL     RegKeyGetDw
        POP      EDX
        MOV      [EBX].FOldKeyValCDData, EAX
        {$IFDEF PARANOIA}
        DB $A8, $20
        {$ELSE}
        TEST     AL, $20
        {$ENDIF}
        JNZ      @@1
        {$IFDEF PARANOIA}
        DB $0C, $20
        {$ELSE}
        OR       AL, $20
        {$ENDIF}
        XCHG     ECX, EAX
        POP      EAX
        PUSH     EAX
        CALL     RegKeySetDw
@@1:
        POP      EAX
        CALL     RegKeyClose

        MOV      EAX, HKEY_CURRENT_USER
        MOV      EDX, [Key_CD_AutoPlay]
        PUSH     EAX
        PUSH     EDX
        CALL     RegKeyOpenWrite
        POP      EDX
        POP      ECX
        TEST     EAX, EAX
        JNZ      @@2

        MOV      EAX, HKEY_CLASSES_ROOT
        PUSH     EAX
        CALL     RegKeyOpenWrite
        POP      ECX
@@2:
        MOV      [EBX].FBaseKeyCDAudio, ECX
        PUSH     EAX // K2
        XOR      EDX, EDX
        LEA      ECX, [EBX].FoldKeyValCDAudio
        CALL     RegKeyGetStr
        MOV      ECX, [EBX].FoldKeyValCDAudio
        JECXZ    @@3

        POP      EAX
        PUSH     EAX

        XOR      EDX, EDX
        XOR      ECX, ECX
        CALL     RegKeySetStr
@@3:
        POP      EAX
        CALL     RegKeyClose

        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
procedure TMediaPlayer.DisableAutoPlay;
var K1, K2: HKey;
begin
  K1 := RegKeyOpenWrite( HKEY_CURRENT_USER, Key_CD_AutoRun );
  FoldKeyValCDData := RegKeyGetDw( K1, Val_CD_AutoRun );
  if (FoldKeyValCDData and $20) = 0 then
  begin
    RegKeySetDw( K1, Val_CD_AutoRun, FoldKeyValCDData or $20 );
  end;
  RegKeyClose( K1 );

  FBaseKeyCDAudio := HKEY_CURRENT_USER;
  K2 := RegKeyOpenWrite( FBaseKeyCDAudio, Key_CD_AutoPlay );
  if K2 = 0 then
  begin
    FBaseKeyCDAudio := HKEY_CLASSES_ROOT;
    K2 := RegKeyOpenWrite( FBaseKeyCDAudio, Key_CD_AutoPlay );
  end;
  FoldKeyValCDAudio := RegKeyGetStr( K2, '' );
  if FoldKeyValCDAudio <> '' then
  begin
    RegKeySetStr( K2, '', '' );
  end;
  RegKeyClose( K2 );
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
procedure TMediaPlayer.RestoreAutoPlay;
asm
        PUSH     EBX
        XCHG     EBX, EAX
        XOR      EAX, EAX
        MOV      [EBX].FAutoRestore.TMethod.Code, EAX
        MOV      EAX, [EBX].FoldKeyValCDData
        {$IFDEF PARANOIA}
        DB $A8, $20
        {$ELSE}
        TEST     AL, $20
        {$ENDIF}
        JNZ      @@1

        PUSH     EAX
        MOV      EAX, HKEY_CURRENT_USER
        MOV      EDX, [Key_CD_AutoRun]
        CALL     RegKeyOpenWrite
        POP      ECX
        PUSH     EAX
        MOV      EDX, [Val_CD_AutoRun]
        CALL     RegKeySetDw
        POP      EAX
        CALL     RegKeyClose
@@1:
        MOV      ECX, [EBX].FoldKeyValCDAudio
        JECXZ    @@2

        PUSH     ECX
        MOV      EAX, [EBX].FBaseKeyCDAudio
        MOV      EDX, [Key_CD_AutoPlay]
        CALL     RegKeyOpenWrite
        POP      ECX
        XOR      EDX, EDX
        PUSH     EAX
        CALL     RegKeySetStr
        POP      EAX
        CALL     RegKeyClose
@@2:
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
procedure TMediaPlayer.RestoreAutoPlay;
var K1, K2: HKey;
begin
  FAutoRestore := nil;
  if (FoldKeyValCDData and $20) = 0 then
  begin
    K1 := RegKeyOpenWrite( HKEY_CURRENT_USER, Key_CD_AutoRun );
    RegKeySetDw( K1, Val_CD_AutoRun, FoldKeyValCDData );
    RegKeyClose( K1 );
  end;

  if FoldKeyValCDAudio <> '' then
  begin
    K2 := RegKeyOpenWrite( FBaseKeyCDAudio, Key_CD_AutoPlay );
    RegKeySetStr( K2, '', FoldKeyValCDAudio );
    RegKeyClose( K2 );
  end;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.StartRecording(FromPos, ToPos: Integer): Boolean;
asm
        PUSH     EBX
        XCHG     EBX, EAX
        XOR      EAX, EAX
        INC      EAX // MCI_NOTIFY
        TEST     ECX, ECX
        JL       @@noTo
        {$IFDEF PARANOIA}
        DB $0C, MCI_TO
        {$ELSE}
        OR       AL, MCI_TO
        {$ENDIF}
@@noTo: PUSH     ECX // dwTo
        TEST     EDX, EDX
        JL       @@noFrom
        {$IFDEF PARANOIA}
        DB $0C, MCI_FROM
        {$ELSE}
        OR       AL, MCI_FROM
        {$ENDIF}
@@noFrom: PUSH   EDX
        CDQ
        MOV      DX, MCI_RECORD
        CALL     asmSendCommand
        POP      EDX
        POP      ECX
        SETZ     AL
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.StartRecording(FromPos, ToPos: Integer): Boolean;
var RecordParm: TMCI_Record_Parms;
    Flags: Integer;
begin
  Flags := 0;
  if FromPos >= 0 then
  begin
    RecordParm.dwFrom := FromPos;
    Flags := MCI_FROM;
  end;
  if ToPos >= 0 then
  begin
    RecordParm.dwTo := ToPos;
    Flags := Flags or ToPos;
  end;
  Result := SendCommand( MCI_RECORD, Flags or MCI_NOTIFY, @RecordParm ) = 0;
end;
{$ENDIF ASM_VERSION}

{$IFDEF ASM_VERSION}
function TMediaPlayer.Stop: Boolean;
asm
        PUSH     EBX
        XCHG     EBX, EAX
        XOR      EAX, EAX
        CDQ
        INC      EAX
        MOV      DX, MCI_STOP
        CALL     asmSendCommand
        SETZ     AL
        POP      EBX
end;
{$ELSE ASM_VERSION} //Pascal
function TMediaPlayer.Stop: Boolean;
var GenParm: TMCI_Generic_Parms;
begin
  Result := SendCommand( MCI_STOP, MCI_NOTIFY, @GenParm ) = 0;
end;
{$ENDIF ASM_VERSION}

function TMediaPlayer.GetAudioOn(Chn: TSoundChannels): Boolean;
begin
  if Chn = [ chLeft, chRight ] then
    Result := not FAudioOff[ chLeft ] and not FAudioOff[ chRight ]
  else
  if Chn = [ ] then
    Result := not FAudioOff[ chLeft ] or not FAudioOff[ chRight ]
  else
  begin
    if chLeft in Chn then
      Result := not FAudioOff[ chLeft ]
    else
    //if chRight in Chn then
      Result := not FAudioOff[ chRight ];
  end;
end;

procedure TMediaPlayer.SetAudioOn(Chn: TSoundChannels; const Value: Boolean);
var What: Integer;
    SetParm: TMCI_Set_Parms;
begin
  if Chn = [ chLeft, chRight ] then
    What := MCI_SET_AUDIO_ALL
  else if Chn = [ chLeft ] then
    What := MCI_SET_AUDIO_LEFT
  else if Chn = [ chRight ] then
    What := MCI_SET_AUDIO_RIGHT
  else Exit;
  if chLeft in Chn then
    FAudioOff[ chLeft ] := not Value;
  if chRight in Chn then
    FAudioOff[ chRight ] := not Value;
  SetParm.dwAudio := What;
  if Value then
    What := MCI_SET_ON
  else
    What := MCI_SET_OFF;
  SendCommand( MCI_SET, What or MCI_WAIT or MCI_SET_AUDIO, @SetParm );
end;

function TMediaPlayer.GetVideoOn: Boolean;
begin
  Result := not FVideoOff;
end;

procedure TMediaPlayer.SetVideoOn(const Value: Boolean);
var SetParm: TMCI_Set_Parms;
    What: Integer;
begin
  FVideoOff := not Value;
  if Value then
    What := MCI_SET_ON
  else
    What := MCI_SET_OFF;
  SendCommand( MCI_SET, MCI_WAIT or MCI_SET_VIDEO or What, @SetParm );
end;

function TMediaPlayer.DGVGetSpeed: Integer;
begin
  Result := GetIState( $4003 {MCI_DGV_STATUS_SPEED} );
end;

procedure TMediaPlayer.DGVSetSpeed(const Value: Integer);
type
  TMCI_DGV_Set_Parms = packed record
    dwCallback,
    dwTimeFormat,
    dwAudio,
    dwFileFormat,
    dwSpeed: DWORD;
  end;
var DGVSetParm: TMCI_DGV_Set_Parms;
begin
  DGVSetParm.dwSpeed := Value;
  SendCommand( MCI_SET, MCI_WAIT or $20000 {MCI_DGV_SET_SPEED}, @DGVSetParm );
end;

{ -- PlaySound interafce functions -- }

const PlaySndFlags: array[ TPlayOption ] of Integer = ( SND_LOOP, not SND_ASYNC,
      SND_NOSTOP, SND_NOWAIT );

function PlaySoundMemory( Memory: Pointer; Options: TPlayOptions ): Boolean;
begin
  Result := PlaySound( Memory, hInstance, MakeFlags( @Options, PlaySndFlags )
            or SND_MEMORY or SND_NODEFAULT );
end;

function PlaySoundResourceID( Inst, ResID: Integer; Options: TPlayOptions ): Boolean;
{ This does not work (at least, if resource stored in res-file as RC_DATA.
begin
  Result := PlaySound( Pointer( ResID ), Inst, MakeFlags( @Options, PlaySndFlags )
            or SND_RESOURCE or SND_NODEFAULT );
end;
}
{ This works, but only synchronously.
var MS: PStream;
begin
  MS := NewMemoryStream;
  Resource2Stream( MS, Inst, Pointer( ResID ), RT_RCDATA );
  Result := PlaySoundMemory( MS.Memory, Options + [poWait] );
  MS.Free;
end;
}
{ This works asynchronously as it is set in Options (if needed). }
var Find, Res: THandle;
    Ptr: Pointer;
begin
  Result := False;
  Find := FindResource( Inst, Pointer( ResID ), RT_RCDATA );
  if Find <> 0 then
  begin
    Res := LoadResource( Inst, Find );
    if Res <> 0 then
    begin
      Ptr := LockResource( Res );
      if Ptr <> nil then
      begin
        Result := PlaySoundMemory( Ptr, Options );
      end;
    end;
  end;
end;

function PlaySoundResourceName( Inst: Integer; const ResName: String; Options: TPlayOptions ): Boolean;
var Find, Res: THandle;
    Ptr: Pointer;
begin
  Result := False;
  Find := FindResource( Inst, PChar( ResNAme ), RT_RCDATA );
  if Find <> 0 then
  begin
    Res := LoadResource( Inst, Find );
    if Res <> 0 then
    begin
      Ptr := LockResource( Res );
      if Ptr <> nil then
      begin
        Result := PlaySoundMemory( Ptr, Options );
      end;
    end;
  end;
end;

function PlaySoundEvent( const EventName: String; Options: TPlayOptions ): Boolean;
begin
  Result := PlaySound( PChar( EventName ), 0, MakeFlags( @Options, PlaySndFlags )
            or SND_ALIAS or SND_NODEFAULT );
end;

function PlaySoundFile( const FileName: String; Options: TPlayOptions ): Boolean;
begin
  Result := PlaySound( PChar( FileName ), 0, MakeFlags( @Options, PlaySndFlags )
            or SND_FILENAME or SND_NODEFAULT );
end;

function PlaySoundStop: Boolean;
begin
  Result := PlaySound( nil, 0, SND_PURGE );
end;

function WaveOutChannels( DevID: Integer ): TSoundChannels;
var WC: TWaveOutCaps;
begin
  Result := [ ];
  if waveOutGetDevCaps( DevID, @WC, sizeof( WC ) ) = MMSYSERR_NOERROR then
  begin
    if WC.wChannels = 2 then
      Result := [ chLeft, chRight ]
    else
    if WC.dwSupport = 1 then
      Result := [ chLeft ];
  end;
end;

function WaveOutVolume( DevID: Integer; Chn: TSoundChannel; NewValue: Integer ): Word;
var V, V1: DWORD;
    NV : Integer;
begin
  Result := 0;
  if waveOutGetVolume( DevID, @V ) = MMSYSERR_NOERROR then
  begin
    V1 := V;
    NV := NewValue;
    if Chn = chRight then
    begin
      V1 := V shr 16;
      V := V and $FFFF;
      NewValue := NewValue shl 16;
    end
       else
      V := V and $FFFF0000;
    if NV >= $10000 then
    begin
      NewValue := (NV and $FFFF) or (NV shl 16);
      V := 0;
    end;
    Result := Word( V1 );
    if NV >= 0 then
      waveOutSetVolume( DevID, V or DWORD(NewValue) );
  end;
end;

{$IFDEF USE_CONSTRUCTORS}
constructor TMediaPlayer.CreateMediaPlayer( const AFileName: String;            //
            AWindow: HWND );                                                    //
begin                                                                           //
  Create;                                                                       //
  if MediaPlayers = nil then                                                    //
    MediaPlayers := NewList;                                                    //
  MediaPlayers.Add( @Self );                                                    //
  //FTimeFormat := tfMilliseconds; //by default...                              //
  FileName := AFileName;                                                        //
  if FError <> 0 then                                                           //
    //MsgOK( 'Error #' + Int2Str( Result.Error ) +                              //
    //' when opening multimedia:'#13 +                                          //
    //       Result.ErrorMessage )                                              //
  else                                                                          //
  begin                                                                         //
    if HasVideo then                                                            //
      Display := AWindow;                                                       //
    FDisplay := AWindow;                                                        //
  end;                                                                          //
end;                                                                            //
{$ENDIF}                                                                               //


end.
