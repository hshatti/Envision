//{$apptype console}
unit mainUnit;
{$ifdef FPC}
  {$mode Delphi}
  {$modeswitch advancedrecords}
  {$modeswitch typehelpers}
{$endif}
{$pointermath on}
{$assertions on}
{$H+}

interface

uses
  Classes, SysUtils, Types, LCLType, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, ComCtrls, Spin, ExtDlgs, Menus, quicknn_transformers,
  quicknn_common, quicknn_vae, quicknn_flux, quicknn_zimage, quicknn_downloader, LMessages;

type

  { TGeneratThread }

  TGenerateThread = class(TThread)
    flux : TQNNFlux;
    zi   : TQNNZImage;
    procedure Execute; override;
    procedure DoTerminate; override;

  end;

  { THSPoint }

  THSPoint = record
    class operator implicit(const val:integer):THSPoint;
    class operator implicit(const val:THSPoint):integer;
    class operator implicit(const val:TArray<integer>):THSPoint;
    case boolean of
      false : (x, y : integer);
      true : (arr : array[0..1] of integer);
  end;

  { THSRect }

  THSRect = record
  private
    function getheight: integer;
    function getwidth: integer;
    procedure Setheight(AValue: integer);
    procedure Setwidth(AValue: integer);
  public
    class operator Implicit(const val:integer):THSRect;
    class operator Implicit(const val:THSRect):Integer;
    class operator Implicit(const val:TArray<integer>):THSRect;
    function centroid():THSPoint;
    function inflate(const val : integer):THSRect;
    function deflate(const val : integer):THSRect;

    property width : integer read getwidth write Setwidth;
    property height : integer read getheight write Setheight;
    case byte of
      0  : (left, top, right, bottom : integer);
      1  : (arr : array[0..3] of integer);
      2  : (points : array[0..1] of THSPoint);
  end;



  THSGradientType = (gtLinear, gtSquare, gtRadial);

  { THSColor }

  THSColor = record
    gradientType : THSGradientType;
    color : TRGBAQuad;
    colors : TArray<TRGBAQuad>;
    angle : integer;
    class operator Implicit(const val:TColor):THSColor;
    class operator Implicit(const val:THSColor):TColor;
  end;

  { THSBorder }

  THSBorder = record
    width : THSRect;
    radius:THSRect;
    colors : THSColor;
    class operator implicit(const val:string):THSBorder;
    class operator implicit(const val:integer):THSBorder;
    class operator implicit(const val:TColor):THSBorder;

  end;

  { TCanvasHelper }

  TCanvasHelper = type helper for TCanvas
    procedure GradientRoundRect(const aRect, aRadius:TRect; const colors: TArray<TColor>; const angle:integer = 0);
  end;

  { THSLookAndFeel }

  THSLookAndFeel = class(TComponent)
  private
    procedure SetBackground(AValue: THSColor);
    procedure SetBorder(AValue: THSBorder);
    procedure SetPadding(AValue: THSRect);
  public
    FBackground : THSColor;
    FBorder : THSBorder;
    FPadding : THSRect;
    FOnChange : TNotifyEvent;
    //procedure Paint; override;
    property Background:THSColor read FBackground write SetBackground;
    property Border : THSBorder read FBorder write SetBorder;
    property Padding:THSRect read FPadding write SetPadding;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  { THSSpin }

  THSSpin = class(TCustomControl)
  const BTN_WIDTH = 20;
  type
    TBtn=class(TCustomControl)
      published
        Property OnMouseEnter;
        Property OnMouseLeave;
        Property OnMouseDown;
        Property OnMouseUp;
    end;
  var
    FLookAndFeel: THSLookAndFeel;
    upBtn, downBtn : TBtn;
    FEdit : TCustomEdit;
    procedure FOnEditKeyDown(Sender:TObject; var key:word; shift:TShiftState);
  private
    FOnChange : TNotifyEvent;
    FbtnColor: THSColor;
    FMaxValue: int64;
    FMinValue: int64;
    procedure FOnEditChange(Sender:TObject);
    procedure upClick(sender:TObject);
    procedure downClick(sender:TObject);
    function getValue: int64;
    procedure SetbtnColor(AValue: THSColor);
    procedure SetMaxValue(AValue: int64);
    procedure SetMinValue(AValue: int64);
    procedure SetValue(AValue: int64);
    procedure EraseBackground(DC: HDC); override;
    procedure btnOnPaint(sender:TObject);
    procedure btnEnter(sender:TObject);
    procedure btnLeave(sender:TObject);
    procedure FOnMouseWheel(sender:TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  public
    constructor Create(AOwner:TComponent);override;
    procedure Paint; override;
    destructor Destroy; override;
    property MinValue:int64 read FMinValue write SetMinValue;
    property MaxValue:int64 read FMaxValue write SetMaxValue;
    property Value : int64 read getValue write setValue;
    property btnColor:THSColor read FbtnColor write SetbtnColor;
  protected
    procedure SetColor(Value: TColor); override;
  end;

  { THSEdit }

  THSEdit = class(TCustomControl)
  const BTN_WIDTH = 20;
  type
    TBtn=class(TCustomControl)
      published
        Property OnMouseEnter;
        Property OnMouseLeave;
        Property OnMouseDown;
        Property OnMouseUp;
    end;
  private
    FbtnColor: THSColor;
    FLookAndFeel : THSLookAndFeel;
    FItemIndex: integer;
    FItems: TStrings;
    FText: string;
    FEdit : TCustomEdit;
    FBtn: TBtn;
    FList :TCustomListBox;
    FOnChange : TNotifyEvent;
    FParentOrigWindowProc : TWndMethod;
    procedure FOnBtnPaint(Sender:TObject);
    procedure FOnItemsChange(Sender:TObject);
    procedure FOnListSelectionChange(Sender:TObject;user:boolean);
    procedure FOnListClick(sender:TObject);
    procedure FOnListKeyDown(sender:TObject; var key:word; shift:TShiftState);
    procedure FOnEditChange(Sender:TObject);
    procedure FOnEditKeyDown(sender:TObject; var key:word; shift:TShiftState);
    procedure FOnEditExit(Sender:TObject);
    procedure FOnListExit(Sender:TObject);
    procedure FBtnEnter(Sender:TObject);
    procedure FBtnLeave(Sender:TObject);
    procedure FBtnClick(Sender:TObject);
    procedure FOnListBoxSetVisible(Sender:TObject);
    function GetText: string;
    procedure SetbtnColor(AValue: THSColor);
    procedure SetItemIndex(AValue: integer);
    procedure SetItems(AValue: TStrings);
    procedure SetText(AValue: string);
    // gets the left and top reltive to the top most form
    function getLocation():TRect;
    procedure FParentWindowProc(var msg:TLMessage);
  protected
    procedure SetParent(NewParent: TWinControl); override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure SetColor(Value: TColor); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure paint;override;
    procedure EraseBackground(DC: HDC); override;
    destructor Destroy; override;
    procedure FOnItemChange(Sender:TObject);
    property btnColor : THSColor read FbtnColor write SetbtnColor;
  published
    property ItemIndex:integer read FItemIndex write SetItemIndex;
    property Text : string read GetText write SetText;
    property Items:TStrings read FItems write SetItems;

  end;


  THSProgressStyle = (psNormal, psMarquee, psStrips, psPulse, psPie, psDonut);

  { THSProgressBar }

  THSProgressBar = class(TGraphicControl)
    procedure paint;                         override;
  private
    FBarColor: TColor;
    FBarShowText: boolean;
    FMax: integer;
    //FMin: integer;
    FOrientation: TProgressBarOrientation;
    FPosition: integer;
    FStep: integer;
    FStyle: THSProgressStyle;
    procedure SetBarColor(AValue: TColor);
    procedure SetBarShowText(AValue: boolean);
    procedure SetMax(AValue: integer);
    //procedure SetMin(AValue: integer);
    procedure SetOrientation(AValue: TProgressBarOrientation);
    procedure SetPosition(AValue: integer);
    procedure SetStep(AValue: integer);
    procedure SetStyle(AValue: THSProgressStyle);
    procedure TextChanged(); override;
  public
    procedure StepIt();
    constructor Create(AOwner:TComponent);   override;
    destructor Destroy();                    override;
  published
    //property Min:integer read FMin write SetMin;
    property Max:integer read FMax write SetMax;
    property Position:integer read FPosition write SetPosition;
    property Step:integer read FStep write SetStep;
    property Orientation : TProgressBarOrientation read FOrientation write SetOrientation;
    property Style : THSProgressStyle read FStyle write SetStyle;
    property BarShowText: boolean read FBarShowText write SetBarShowText;
    property BarColor : TColor read FBarColor write SetBarColor;

  end;

  { TMainForm }

  TMainForm = class(TForm)
    btnGenerate: TSpeedButton;
    btnImg2Img: TSpeedButton;
    btnLoadPic1: TLabel;
    btnTxt2Img: TSpeedButton;
    cmbImgRes: TComboBox;
    cmbModels: TComboBox;
    cmbSchedular: TComboBox;
    edtCFG: TEdit;
    edtPowerAlpha: TEdit;
    edtSeed: TEdit;
    Image1: TImage;
    Image2: TImage;
    ImageList1: TImageList;
    Label1: TLabel;
    btnLoadPic: TLabel;
    Label10: TLabel;
    lblDownload: TLabel;
    lblMore: TLabel;
    lblSetAsRef: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    dlgImage: TOpenPictureDialog;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    memoPrompt: TMemo;
    memoNegPrompt: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    mnuDLOpenBLAS: TMenuItem;
    mnuDL1: TMenuItem;
    mnuDL2: TMenuItem;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel1: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    pnlDL: TPanel;
    pnlPrompt: TPanel;
    pnlNegative: TPanel;
    PopupMenu1: TPopupMenu;
    Separator1: TMenuItem;
    Separator2: TMenuItem;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    spnSteps: TSpinEdit;
    prog, subDL, totalDL :THSProgressBar;
    Timer1: TTimer;
    procedure btnGenerateClick(Sender: TObject);
    procedure btnLoadPic1Click(Sender: TObject);
    procedure btnTxt2ImgClick(Sender: TObject);
    procedure btnImg2ImgClick(Sender: TObject);
    procedure cmbModelsDropDown(Sender: TObject);
    procedure edtCFGChange(Sender: TObject);
    procedure edtCFGMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure btnLoadPicClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnLoadPicMouseEnter(Sender: TObject);
    procedure btnLoadPicMouseLeave(Sender: TObject);
    procedure Image1DblClick(Sender: TObject);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
      );
    procedure Label10Click(Sender: TObject);
    procedure lblMoreClick(Sender: TObject);
    procedure lblMoreMouseEnter(Sender: TObject);
    procedure lblMoreMouseLeave(Sender: TObject);
    procedure lblSetAsRefClick(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure mnuDL1Click(Sender: TObject);
    procedure mnuDL2Click(Sender: TObject);
    procedure mnuDLOpenBLASClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure checkExistingModels;
    procedure OnDownload(const subReceived, subTotal, received, total:int64);
    procedure OnIdle(Sender :TObject; var done:boolean);
    procedure OnIdleEnd(Sender :TObject);
    procedure loop(data:IntPtr); // for testing! do not use

  public
    modeledit1, imgRes, schedularEdit1:THSEdit;
    stepsSpn, powerSpn, cfgSpn : THSSpin;
    generateThread : TGenerateThread
  end;

var
  MainForm: TMainForm;
  gotImage:boolean = false;
  gotImage2:boolean = false;
  lastGenerated : string = '';

  procedure QNNImageToBitmap(const img:TQNNImage; var bmp: graphics.TBitmap);
  const DL_Symbols : array of rawbytestring = ['   ', '  .', ' ..', '...', '.. ', '.  '];
implementation
uses
  math
  , unitAbout
{$ifdef MSWINDOWS}
  , windows
  , DwmApi
{$endif};

{$R *.lfm}

{$ifdef MSWINDOWS}

function IsWindows10OrGreater(BuildNumber: Integer): Boolean;
begin
  Result := (Win32MajorVersion >= 10) and (Win32BuildNumber >= BuildNumber);
end;

procedure SetDarkModeTitleBar(AForm: TForm; Active: longbool);
const
  DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1 = 19;
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
  DWMWA_REDIRECTIONBITMAP_ALPHA = 39;
  DWMWA_BORDER_MARGINS = 40;
  DWMWA_SYSTEMBACKDROP_TYPE = 38;


  DWMSBT_AUTO = 0;
  DWMSBT_NONE = 1;
  DWMSBT_MAINWINDOW = 2;
  DWMSBT_TRANSIENTWINDOW = 3;
  DWMSBT_TABBEDWINDOW = 4;
var attr : longword;
begin

  Attr := DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1;
  if IsWindows10OrGreater(18985) then Attr := DWMWA_USE_IMMERSIVE_DARK_MODE;

  DwmSetWindowAttribute(AForm.Handle, Attr, @Active, SizeOf(Active));

  if not IsWindows10OrGreater(18985) then exit;
  Attr:= $884422;
  assert(DwmSetWindowAttribute(MainForm.Handle, DWMWA_CAPTION_COLOR, @attr, SizeOf(Active))=S_OK);

  //Attr:= $ffcc88;
  //assert(DwmSetWindowAttribute(MainForm.Handle, DWMWA_TEXT_COLOR, @attr, SizeOf(Active))=S_OK);

  Attr:= $ffcc88;
  assert(DwmSetWindowAttribute(MainForm.Handle, DWMWA_BORDER_COLOR, @attr, SizeOf(Active))=S_OK);

end;
{$endif}

{$if defined(MacOS) or defined(DARWIN)}
const MODELS_DIR:string = '../../../../../models';
{$else}
const MODELS_DIR:string = '../../models';
{$endif}

var AppPath : RawByteString;

{ TGeneratThread }

procedure OnStepCallback(const msg:TSubstepType; const step, steps:longint);
begin
  MainForm.prog.StepIt;
  MainForm.prog.caption := format('%d/%d', [MainForm.Prog.Position, MainForm.Prog.Max]);
  MainForm.generateThread.Synchronize(MainForm.Update);
  //MainForm.Update;
  if MainForm.generateThread.CheckTerminated then
    abort
end;

procedure OnTextStepCallback(const step, steps:longint);
begin
  MainForm.Prog.StepIt;
  MainForm.Prog.caption := format('%d/%d', [MainForm.Prog.Position, MainForm.Prog.Max]);
  MainForm.generateThread.Synchronize(MainForm.Update);
  if MainForm.generateThread.CheckTerminated then
    abort
end;

procedure OnPreviewCallback(const step, steps:longint; const latent:TMemoryBlock);
var
  img:TQNNImage;
  bmp:Graphics.TBitmap;
begin
  img := PVAE(vae_ptr).preview(latent, flux2_latent_rgb_proj, latent.height(), latent.width(), latent.height(), 1, flux2_latent_rgb_bias, 2).resize(128, 128);
  bmp := Graphics.TBitmap.Create;
  QNNImageToBitmap(img, bmp);
  if MainForm.btnTxt2Img.Down then begin
    mainform.Image1.Picture.Graphic:= bmp;
    //MainForm.generateThread.Synchronize(MainForm.Image1.Repaint);
  end;
  if MainForm.btnImg2Img.Down then begin
    mainform.Image2.Picture.Graphic:= bmp;
    //MainForm.generateThread.Synchronize(MainForm.Image2.Repaint);
  end;
  MainForm.generateThread.Synchronize(MainForm.Repaint);
  img.free;
  freeAndNil(bmp)
end;

{ Tools }

function min(const a, b, c:byte):byte;inline;overload;
begin
  if a>b then result := b else result := a;
  if result>c then result := c
end;

function max(const a, b, c:byte):byte;inline;overload;
begin
  if a>b then result := a else result := b;
  if c>result then result := c
end;

function Limit(const V,aMin,aMax:Integer):Integer;
begin
  if V>aMax then
    Result:=aMax
  else if V<aMin then
    Result:=aMin
  else Result:=V

end;

function lerp(const x, start, finish:single):single;overload;
begin
  result := start + x * (finish - start)
end;

function lerp(const x:single;const start, finish:integer):integer;overload;
begin
  result := trunc(start + x * (finish - start))
end;

function ColorBright(const C:TColorRef; const Brightness:Integer):TColorRef; overload;
var
  R, G, B : byte;
begin
  RedGreenBlue(C, R, G, B);
  Result:=RGBToColor(limit(R + Brightness, 0, 255), limit(G + Brightness, 0, 255), limit(B + Brightness, 0, 255))
end;

function ColorBright(const C:TColor; const Brightness:Integer):TColor; overload;
var
  R, G, B : byte;
begin
  RedGreenBlue(ColorToRGB(C), R, G, B);
  Result:=RGBToColor(limit(R + Brightness, 0, 255), limit(G + Brightness, 0, 255), limit(B + Brightness, 0, 255))
end;

procedure rgb2hsl(const rgb:TColorRef; out H:integer; out S, L: byte);overload;
var R, G, B, C, V, Mi: byte;
begin
  R  := rgb and $000000ff;
  G  := (rgb shr 8) and $000000ff;
  B  := (rgb shr 16) and $000000ff;
  V := max(R, G, B);
  Mi := min(R, G, B);
  C  := V - Mi;
  L  := Mi + C div 2;

  if C = 0 then
    H :=0
  else
    if V = R then
      H := 60 * (((G - B) div C) mod 6)
    else if V = B then
      H := 60 * (((B - R) div C) + 2)
    else
      H := 60 * (((R - G) div C) + 4);

  if (L = 0) or (L = $FF) then
    S := 0
  else
    S := 255*(V - L) div min(255 - L, L)
end;

procedure rgb2hsl(const rgb:TColorRef; out H, S, L: byte);overload;
var
  Mi: integer;
  R, G, B, V, C : byte;
begin
  R  := rgb and $000000ff;
  G  := (rgb shr 8) and $000000ff;
  B  := (rgb shr 16) and $000000ff;

  V := max(R, G, B);
  Mi := min(R, G, B);
  C := V - Mi;
  L := Mi + C div 2;

  if C = 0 then begin
    H := 0;
    S := 0;
  end else begin
    S := 255* (V - L) div min(L, 255 - L);
    if V = R then begin
      Mi := 85 * (G - B) div (2*C);
      if Mi < 0 then H := Mi + 255 else H := Mi;
    end else if V = g then
      H := 85 * (B - R) div (2*C) + 85
    else
      H := 85 * (R - G) div (2*C) + 170;
  end;
end;

procedure rgb2hsv(const rgb:TColorRef; out H, S, V: byte);inline;
var R, G, B, C: byte; Mi:integer;
begin
  R  := rgb and $000000ff;
  G  := (rgb shr 8) and $000000ff;
  B  := (rgb shr 16) and $000000ff;
  V := max(R, G, B);
  Mi := min(R, G, B);
  C  := V - Mi;

  if C = 0 then
    H :=0
  else begin
    if V = R then begin
      Mi := 85 * (G - B) div (2*C);
      if Mi < 0 then H := Mi + 255 else H := Mi;
    end else if V = g then
      H := 85 * (B - R) div (2*C) + 85
    else
      H := 85 * (R - G) div (2*C) + 170;
  end;
  if V = 0 then
    S := 0
  else
    S := 255 * C div V
end;


function hsl2rgb(const H, S, L:Byte):TColorRef;
var X, C, m:byte;
begin
  C := (255 - abs(2*L - 255)) * S div 255;
  X := C - 2*C*abs(longint(H mod 85 - 42)) div 85;   // 85 ~= 255 / 3
  m := L - C div 2;
  case trunc(H / 42.5) of
    0 : exit(RGBToColor(C+m, X+m, m));
    1 : exit(RGBToColor(X+m, C+m, m));
    2 : exit(RGBToColor(m  , C+m, X+m));
    3 : exit(RGBToColor(m  , X+m, C+m));
    4 : exit(RGBToColor(X+m, m  , C+m));
    5 : exit(RGBToColor(C+m, m  , X+m));
  end;
end;

function hsv2rgb(const H, S, V:Byte):TColorRef;
var X, C, m:byte;
begin
  C := V * S div 255;
  X := C - 2*C*abs(longint(H mod 85 - 42)) div 85;
  m := V - C;
  case trunc(H / 42.5) of
    0 : exit(RGBToColor(C+m, X+m, m));
    1 : exit(RGBToColor(X+m, C+m, m));
    2 : exit(RGBToColor(m  , C+m, X+m));
    3 : exit(RGBToColor(m  , X+m, C+m));
    4 : exit(RGBToColor(X+m, m  , C+m));
    5 : exit(RGBToColor(C+m, m  , X+m));
  end;
end;


procedure QNNImageToBitmap(const img: TQNNImage; var bmp: Graphics.TBitmap);
type
  TRGB = packed record r, g, b, a:byte end;
  PRGB = ^TRGB;
var
  y, x:longint;
  rgb:PRGB;
begin
    assert(assigned(bmp), 'ERROR [QNNImageToBMP]: target cannot be nil');
    assert(assigned(img.data), 'ERROR [QNNImageToBMP]: source cannot be nil');
    bmp.Clear;
  {$ifdef MSWINDOWS}
    bmp.PixelFormat:=pf32bit;
  {$else}
    bmp.PixelFormat:=pf24bit;
  {$endif}
    bmp.SetSize(img.width, img.height);
    bmp.BeginUpdate();
    for y:=0 to img.Height-1 do begin
      RGB := bmp.ScanLine[y];
      for x :=0 to img.width-1 do begin
        rgb[x].r := img.data[y*img.width*3 + x*3+2];
        rgb[x].g := img.data[y*img.width*3 + x*3+1];
        rgb[x].b := img.data[y*img.width*3 + x*3];
  {$ifdef MSWINDOWS}
        rgb[x].a := 255;
  {$endif}
      end;
    end;
    bmp.EndUpdate();
end;

var
  params:TGenerateParams;
const
  strMeta = 'EnvisionGUI, a (txt2img/img2img) generator example written in Object Pascal (Delphi and FPC)';
procedure TGenerateThread.Execute;
var
  img:TQNNImage;
  fn : TFileName;
  strRes : array of string;
  s:string;
  imWidth, imHeight:longInt;
begin
  strRes := string(MainForm.imgRes.Text).Split(' ');

  assert((length(strRes)=3) and (TryStrToInt(strRes[0], imWidth)) and (TryStrToInt(strRes[2], imHeight)), 'Incorrect image dimensions!');


  with MainForm do begin
    prog.BarShowText:=True;
    params := default(TGenerateParams);
    params.width:=imWidth;
    params.height:=imHeight;
    params.num_steps := stepsSpn.Value;
    params.guidance  := strToFloat(edtCFG.Text);
    params.powerAlpha:= strToFloat(edtPowerAlpha.Text);
    params.schedule  := TQNNSchedule(schedularEdit1.ItemIndex);
    if (trim(edtSeed.Text)='') or (strToInt(edtSeed.text)<=0) then
      params.seed := random(Int64.MaxValue)
    else
      params.seed := strToInt(edtSeed.text);
    str(params.schedule, s);
    if btnTxt2Img.Down then try // txt2Img

      MainForm.generateThread.Synchronize(MainForm.Update);

      substep_callback:=OnStepCallback;
      text_progress_callback:= OnTextStepCallback;
      vae_progress_callback:= OnTextStepCallback;
      prog.position := 0;
      if LowerCase(ModelEdit1.Text).Contains('flux') then begin
        flux := TQNNFlux.load(AppPath+MODELS_DIR+'/'+modeledit1.Text);
        params.model_name := flux.model_name;
        prog.max:= 27 + params.num_steps*(5 + 20 + 2)*(1+ord((not flux.is_distilled) or (params.guidance<>1))) + 17;  // text_encode_steps + steps*transformer_blocks + ve_decoder_steps
        flux.use_mmap:=true;
        img := flux.generate(memoPrompt.Text, memoNegPrompt.Text, params, OnPreviewCallback);
      end;
      if lowerCase(ModelEdit1.Text).Contains('z-image') then begin
        zi := TQNNZImage.load(AppPath+MODELS_DIR+'/'+modeledit1.Text);
        params.model_name := zi.model_name;
        prog.max:= 35 + params.num_steps*(2 + 2 + 44) + 15+100;  // text_encode_steps + steps*transformer_blocks + ve_decoder_step;
        zi.use_mmap:=true;
        img := zi.generate(memoPrompt.Text, params{, OnPreviewCallback});
      end;
      fn := AppPath+FormatDateTime('yyyymmdd_hhnnss', now())+'.png';
      lastGenerated := fn;
      img.saveToFile(fn, 'program', strMeta);
      img.addPngMeta(fn, 'json',
                              '{"model" : "'+params.model_name+'"'+
                              ', "prompt" : "'+StringReplace(memoPrompt.Text, '"', '\"', [rfReplaceAll])+
                              '", "seed" : '+IntToStr(params.seed)+
                              ', "steps" : '+intToStr(params.num_steps)+
                              ', "schedueler" : "'+copy(s, 5)+'"}');
      image1.Picture.LoadFromFile(fn);
      dlgImage.FileName := fn;
      gotImage := true;
    finally
      if flux.transformer.isLoaded() then flux.free();
      if zi.transformer.isLoaded() then zi.free();
      img.free
    end;

    if btnImg2Img.Down then try // img2Img

      MainForm.generateThread.Synchronize(MainForm.Update);

      img := TQNNImage.loadFromFile(dlgImage.FileName);
      substep_callback:=OnStepCallback;
      text_progress_callback:= OnTextStepCallback;
      vae_progress_callback:= OnTextStepCallback;
      flux := TQNNFlux.load(MODELs_DIR+'/'+modeledit1.Text);
      prog.max:= 27 + params.num_steps*(5 + 20 + 2) + 16 + 100;  // text_encode_steps + steps*transformer_blocks + ve_decoder_steps
      prog.position := 0;
      flux.use_mmap:=true;
      params.model_name := flux.model_name;
      img := flux.generate(memoPrompt.Text, memoNegPrompt.Text, params, img, OnPreviewCallback);
      fn := AppPath+FormatDateTime('yyyymmdd_hhnnss', now())+'.png';
      lastGenerated := fn;
      img.saveToFile(fn, 'program', strMeta);
      img.addPngMeta(fn, 'json',
                              '{"model" : "'+params.model_name+'"'+
                              ', "prompt" : "'+StringReplace(memoPrompt.Text, '"', '\"', [rfReplaceAll])+
                              '", "seed" : '+IntToStr(params.seed)+
                              ', "steps" : '+intToStr(params.num_steps)+
                              ', "schedueler" : "'+copy(s, 5)+'"}');

      image2.Picture.LoadFromFile(fn);
      gotImage2 := true;
      lblSetAsRef.Show;
    finally
      flux.free();
      img.free
    end;
  end;
end;

procedure TGenerateThread.DoTerminate;
begin
  with MainForm do begin
    prog.position := 0;
    btnGenerate.Caption := 'Generate';
    btnTxt2Img.Enabled:=True;
    btnImg2Img.Enabled:=True;
    prog.BarShowText:=false;
    generateThread.Synchronize(MainForm.Repaint);
  end;
  inherited DoTerminate;
end;

{ THPoint }

class operator THSPoint.implicit(const val: integer): THSPoint;
begin
  result.x := val;
  result.y := val
end;

class operator THSPoint.implicit(const val: THSPoint): integer;
begin
  result := (val.x+val.y) div 2
end;

class operator THSPoint.implicit(const val: TArray<integer>): THSPoint;
var i: integer;
begin
  for i:=0 to min(high(val), high(result.arr)) do
    result.arr[i] := val[i]
end;

{ THSRect }

function THSRect.getheight: integer;
begin
  result := bottom - top
end;

function THSRect.getwidth: integer;
begin
  result := right - left
end;

procedure THSRect.Setheight(AValue: integer);
begin
  right := left + AValue
end;

procedure THSRect.Setwidth(AValue: integer);
begin
  bottom := top + AValue
end;

class operator THSRect.Implicit(const val: integer): THSRect;
begin
  result.top := val;
  result.right := val;
  result.bottom := val;
  result.left := val;
end;

class operator THSRect.Implicit(const val: THSRect): Integer;
begin
  result := (val.top + val.right + val.bottom + val.left) div 4;
end;

class operator THSRect.Implicit(const val: TArray<integer>): THSRect;
var i: integer;
begin
  for i:=0 to min(high(val), high(result.arr)) do
    result.arr[i] := val[i]
end;

function THSRect.centroid(): THSPoint;
begin
  result.x := (left + right) div 2 ;
  result.y := (top + bottom) div 2
end;

function THSRect.inflate(const val: integer): THSRect;
begin
  result.left := left - val;
  result.top := top - val;
  result.right := right + val;
  result.bottom := bottom + val;
end;

function THSRect.deflate(const val: integer): THSRect;
begin
  if left+val < right - val  then begin
    result.left := left + val;
    result.right := right - val;
  end;
  if top + val < bottom - val  then begin
    result.top := top + val;
    result.bottom := bottom - val;
  end;
end;

{ THSColor }

class operator THSColor.Implicit(const val: TColor): THSColor;
var Ref:TColorRef;
begin
  ref := ColorToRGB(val);
  result.colors := nil;
  result.color.Red := Red(val);
  result.color.Green := green(val);
  result.color.Blue := Blue(val);

end;

class operator THSColor.Implicit(const val: THSColor): TColor;
begin
  result := RGBToColor(val.color.Red, val.color.green, val.color.blue);
end;

{ THSBorder }

class operator THSBorder.implicit(const val: string): THSBorder;
var vals : TArray<string>;
  w:integer;
  c:TColor;
begin
  vals := val.Split(' ');
  if (length(vals)>0) and TryStrToInt(vals[0], w) then result.width := w;
  if (length(vals)>1) and TryStrToInt(vals[1], c) then result.colors := c;
  if (length(vals)>2) and TryStrToInt(vals[2], w) then result.radius := w;

end;

class operator THSBorder.implicit(const val: integer): THSBorder;
begin
  result.width := val
end;

class operator THSBorder.implicit(const val: TColor): THSBorder;
begin
  result.colors := val;
end;

{ TCanvasHelper }

procedure TCanvasHelper.GradientRoundRect(const aRect, aRadius: TRect;
  const colors: TArray<TColor>; const angle: integer);
var x, y, r1, r2, r3, r4:integer;

begin

end;

{ THSLookAndFeel }

procedure THSLookAndFeel.SetBackground(AValue: THSColor);
begin
  //if FBackground=AValue then Exit;
  FBackground:=AValue;
   if assigned(FOnChange) then FOnChange(Self)
end;

procedure THSLookAndFeel.SetBorder(AValue: THSBorder);
begin
  //if FBorder=AValue then Exit;
  FBorder:=AValue;
  if assigned(FOnChange) then FOnChange(Self)
end;

procedure THSLookAndFeel.SetPadding(AValue: THSRect);
begin
  //if FPadding=AValue then Exit;
  FPadding:=AValue;
  if assigned(FOnChange) then FOnChange(Self)
end;

//procedure THSLookAndFeel.Paint;
//var i,j:integer; r, g, b, a:byte;
//begin
//  inherited Paint;
//  if length(background.colors)>1 then
//    case Background.gradientType of
//      gtLinear: with canvas do begin
//
//      end;
//      gtSquare: with canvas do begin
//
//      end;
//      gtRadial: with canvas do begin
//
//      end;
//    end;
//end;

constructor THSLookAndFeel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Border := '1 $808080 16';
  padding := 4;
end;

destructor THSLookAndFeel.Destroy;
begin
  inherited Destroy;
end;

{ THSSpin }

procedure THSSpin.FOnEditKeyDown(Sender: TObject; var key: word;
  shift: TShiftState);
var i:Int64; d:Double;
begin
  case key of
    VK_UP:begin
      if TryStrToInt64(FEdit.Text, i) and (i<FMaxValue) then FEdit.text := intToStr(i+1);
      key := 0
    end;
    VK_DOWN: begin
      if TryStrToInt64(FEdit.Text, i) and (i>FMinValue) then FEdit.text := intToStr(i-1);
      key := 0;
    end;
    VK_0..VK_9: ;
    else
      key := 0
  end;
end;

procedure THSSpin.FOnEditChange(Sender: TObject);
begin
  if assigned(FOnChange) then FOnChange(Sender);
end;

procedure THSSpin.upClick(sender: TObject);
  var i:int64;
begin
  if TryStrToInt64(FEdit.Text, i) and (i<FMaxValue) then FEdit.text := intToStr(i+1);
end;

procedure THSSpin.downClick(sender: TObject);
var i:int64;
begin
  if TryStrToInt64(FEdit.Text, i) and (i>FMinValue) then FEdit.text := intToStr(i-1);
end;

function THSSpin.getValue: int64;
begin
  TryStrToInt64(FEdit.Text, result);
end;

procedure THSSpin.SetbtnColor(AValue: THSColor);
begin
  //if FbtnColor = AValue then Exit;
  FbtnColor:=AValue;
end;

procedure THSSpin.SetMaxValue(AValue: int64);
begin
  if FMaxValue=AValue then Exit;
  FMaxValue:=AValue;
end;

procedure THSSpin.SetMinValue(AValue: int64);
begin
  if FMinValue=AValue then Exit;
  FMinValue:=AValue;
end;

procedure THSSpin.SetValue(AValue: int64);
begin
  assert((AValue>=FMinValue) and (AValue<=FMaxValue), 'Value is out of range!');
  FEdit.Text:=IntToStr(AValue);
end;

procedure THSSpin.EraseBackground(DC: HDC);
begin
  //inherited EraseBackground(DC);
end;

procedure THSSpin.SetColor(Value: TColor);
begin
  inherited SetColor(Value);
  FEdit.Color:= Color;
end;

procedure THSSpin.btnOnPaint(sender: TObject);
var ts:TTextStyle;
begin
  //TCustomControl(Sender).Canvas.Pen.Color:=$808080;
  TCustomControl(Sender).Canvas.Pen.Style:=psClear;
  TCustomControl(Sender).Canvas.Pen.Cosmetic:=false;
  TCustomControl(Sender).Canvas.Pen.Width:=1;
  if TCustomControl(Sender).MouseInClient then
    TCustomControl(Sender).Canvas.Brush.Color:=ColorBright(FbtnColor, 20)
  else
    TCustomControl(Sender).Canvas.Brush.Color:=FBtnColor;
  TCustomControl(Sender).Canvas.RoundRect(TCustomControl(Sender).ClientRect, 8, 8);
  TCustomControl(Sender).Font.Color:=parent.Font.Color;
  with TCustomControl(Sender).Canvas do begin
    ts := TextStyle;
    ts.Alignment:=taCenter;
    ts.Layout:=tlCenter;
    TextStyle:=ts;
    TextRect(TCustomControl(Sender).ClientRect, 0, 0, TCustomControl(Sender).Caption);
  end
end;

procedure THSSpin.btnEnter(sender: TObject);
begin
  FbtnColor :=ColorBright(FbtnColor, 20);
  TBtn(sender).Invalidate
end;

procedure THSSpin.btnLeave(sender: TObject);
begin
  FbtnColor :=ColorBright(FbtnColor, -20);
  TBtn(sender).Invalidate
end;

procedure THSSpin.FOnMouseWheel(sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var i:int64;
begin
  if Wheeldelta>0 then begin
    if TryStrToInt64(FEdit.Text, i) and (i<FMaxValue) then FEdit.text := intToStr(i+1)
  end else
    if TryStrToInt64(FEdit.Text, i) and (i>FMinValue) then FEdit.text := intToStr(i-1);


  if assigned(OnMouseDown) then OnMouseWheel(sender, Shift, WheelDelta, MousePos, Handled);
end;

constructor THSSpin.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 100;
  Height := 10;
  FLookAndFeel := THSLookAndFeel.Create(Self);
  FEdit :=TCustomEdit.Create(Self);
  //FEdit.Parent:=FLookAndFeel;
  FEdit.Parent:=Self;
  //FEdit.Color := Color;
  OnMouseWheel := FOnMouseWheel;
  FEdit.ControlStyle := FEdit.ControlStyle - [TControlStyleType.csOpaque];
  FEdit.BorderStyle:=bsNone;
  FEdit.left := FLookAndFeel.Padding.left;
  FEdit.Top := FLookAndFeel.Padding.top;
  FEdit.Width := Width - FLookAndFeel.Padding.left - FLookAndFeel.Padding.right - BTN_WIDTH;
  FEdit.Height := Height - FLookAndFeel.Padding.top - FLookAndFeel.Padding.bottom - FLookAndFeel.Border.width.bottom;
  height := FLookAndFeel.Padding.top+FLookAndFeel.Padding.bottom + FEdit.Height;
  FEdit.Anchors := [akLeft, akTop, akRight, akbottom];
  FEdit.OnKeyDown:=FOnEditKeyDown;
  FEdit.OnChange:=FOnEditChange;

  FbtnColor := $CC6611;
  //upBtn := TBtn.Create(self);
  //upBtn.Parent := Self;
  //upBtn.SetBounds(width - FLookAndFeel.Padding.right - BTN_WIDTH, FLookAndFeel.Padding.top, BTN_WIDTH, (height - FLookAndFeel.Padding.top - FLookAndFeel.Padding.bottom) div 4);
  //upBtn.Anchors:=[akTop, akRight, akBottom];
  //upBtn.OnPaint:=btnOnPaint;
  //upBtn.OnMouseEnter:=BtnEnter;
  //upBtn.OnMouseLeave:=BtnLeave;
  //upBtn.OnClick:=upClick;
  //upBtn.Font.Size:=Height div 2;
  //upBtn.Caption:='▲';

  //downBtn := TBtn.Create(self);

  //downBtn.Parent := Self;
  //downBtn.SetBounds(width - FLookAndFeel.Padding.right - BTN_WIDTH, height div 2, BTN_WIDTH, height div 2 - FLookAndFeel.Padding.top + 1);
  //downBtn.Anchors:=[akTop, akRight, akBottom];
  //downBtn.OnPaint:=btnOnPaint;
  //downBtn.OnMouseEnter:=BtnEnter;
  //downBtn.OnMouseLeave:=BtnLeave;
  //downBtn.OnClick:=downClick;
  //downBtn.Font.Size:=Height div 2;
  //downBtn.Caption:='▼';
end;

procedure THSSpin.Paint;
var
  r: TRect;
begin
  inherited Paint;
  with canvas do begin
    pen.width   := FLookAndFeel.Border.width;
    pen.Color   := FLookAndFeel.Border.colors;
    pen.Style   := psSolid;
    brush.Style := bsSolid;
    //brush.Color := color;
    Brush.Color := Parent.Color;
    FillRect(ClientRect);
    Brush.Color := Color;
    r := ClientRect;
    //r.Inflate(0, 0 , -2, -2);
    RoundRect(r, FLookAndFeel.Border.radius.left, FLookAndFeel.Border.radius.left);


  end;

end;

destructor THSSpin.Destroy;
begin
  if assigned(upBtn) then freeandnil(upBtn);
  if assigned(downbtn) then downBtn.Free;
  FreeAndNil(FLookAndFeel);
  inherited Destroy;
end;

{ THSEdit }

procedure THSEdit.SetParent(NewParent: TWinControl);
var par :TControl;
begin
  inherited SetParent(NewParent);
  par :=GetTopParent;
  if assigned(par) then begin
    FParentOrigWindowProc := par.WindowProc;
    par.WindowProc := FParentWindowProc;
  end;

end;

procedure THSEdit.FOnBtnPaint(Sender: TObject);
var ts:TTextStyle;
begin
  //FBtn.Canvas.Pen.Color:=$808080;
  FBtn.Canvas.Pen.Style:=psClear;
  FBtn.Canvas.Pen.Cosmetic:=false;
  FBtn.Canvas.Pen.Width:=1;
  //if FBtn.MouseInClient then
  //  FBtn.Canvas.Brush.Color:=ColorBright(FbtnColor, 20)
  //else
  //  FBtn.Canvas.Brush.Color:=FBtnColor;
  //FBtn.Canvas.RoundRect(FBtn.ClientRect, 8, 8);
  FBtn.Font.Color:=parent.Font.Color;
  with TCustomControl(Sender).Canvas do begin
    ts := TextStyle;
    ts.Alignment:=taCenter;
    ts.Layout:=tlCenter;
    TextStyle:=ts;
    TextRect(FBtn.ClientRect, 0, 0, FBtn.Caption);
  end
end;

procedure THSEdit.FOnItemsChange(Sender: TObject);
begin
  FList.Items.Text:=Items.Text;
end;

procedure THSEdit.FOnListSelectionChange(Sender: TObject; user: boolean);
begin
  if FList.ItemIndex>=0 then begin
    if FEdit.Text<>FList.Items[FList.ItemIndex] then
      FEdit.Text := FList.Items[FList.ItemIndex];
  end;
  //FList.Hide
end;

procedure THSEdit.FOnListClick(sender: TObject);
begin
  FList.Hide;
end;

procedure THSEdit.FOnListKeyDown(sender: TObject; var key: word;
  shift: TShiftState);
begin
  case key of
    VK_RETURN:
      FList.Click;
    //VK_UP: if FList.ItemIndex>0 then
    //  FList.ItemIndex := FList.ItemIndex -1;
    //VK_DOWN: if FList.ItemIndex<FList.Items.Count-1 then
    //  FList.ItemIndex := FList.ItemIndex +1;

  end;
end;

procedure THSEdit.FOnEditChange(Sender: TObject);
var i : longint;
begin
  i := FList.items.IndexOf(FEdit.Text);
  if ItemIndex <> i then
    ItemIndex := i;
  if assigned(FOnChange) then FOnChange(Self)
end;

procedure THSEdit.FOnEditKeyDown(sender: TObject; var key: word;
  shift: TShiftState);
begin
  case key of
    VK_RETURN: FList.Click;
    VK_UP:begin
      if FList.ItemIndex>0 then
        FList.ItemIndex := FList.ItemIndex -1;
      key := 0
    end;
    VK_DOWN: begin
      if FList.ItemIndex<FList.Items.Count-1 then
        FList.ItemIndex := FList.ItemIndex +1;
      key := 0;
    end;
    VK_ESCAPE:
      FList.Hide;
  end;
end;

procedure THSEdit.FOnEditExit(Sender: TObject);
begin
  if not FList.Focused then FList.Hide
end;

procedure THSEdit.FOnListExit(Sender: TObject);
begin
  //Flist.Hide
end;

procedure THSEdit.FBtnEnter(Sender: TObject);
begin
  FbtnColor :=ColorBright(FbtnColor, 20);
  FBtn.Invalidate;
end;

procedure THSEdit.FBtnLeave(Sender: TObject);
begin
  FbtnColor :=ColorBright(FbtnColor, -20);
  FBtn.Invalidate
end;

procedure THSEdit.FBtnClick(Sender: TObject);
begin
  //FList.Items.Text := Items.Text;
  FList.Visible := not FList.Visible;
  if FList.Visible and FList.CanSetFocus then begin
    FList.Update;
    //FList.SetFocus();
    FEdit.SetFocus;
  end;

end;

procedure THSEdit.FOnListBoxSetVisible(Sender: TObject);
var
  r:TRect;
begin
  if not Visible then exit;
  FList.Parent := TWinControl(GetTopParent);
  R := getLocation();
  // check if the list top fits in the top most form
  if R.Bottom + FList.Height>FList.parent.ClientRect.Bottom then
    FList.Top:=  FEdit.Top - FList.height + R.Top -1
  else
    FList.Top:=  FEdit.Top + FEdit.height + R.Top;
  FList.Left:= FEdit.Left  + R.Left;

  Flist.Width  := FEdit.Width;
  if FEdit.CanFocus then FEdit.SetFocus;
end;

function THSEdit.GetText: string;
begin
  result := FEdit.Text;
end;

procedure THSEdit.SetbtnColor(AValue: THSColor);
begin
  //if FbtnColor = AValue then Exit;
  FbtnColor:=AValue;
end;

procedure THSEdit.SetItemIndex(AValue: integer);
begin
  if FItemIndex=AValue then Exit;
  FItemIndex:=AValue;
  FList.ItemIndex:=AValue;
end;

procedure THSEdit.SetItems(AValue: TStrings);
begin
  assert(assigned(AValue), 'Items cannot be nil!');
  if FItems=AValue then Exit;
  if assigned(FItems) then FItems.free;
  FItems:=AValue;
end;

procedure THSEdit.SetText(AValue: string);
begin
  FEdit.text := text;
end;

function THSEdit.getLocation(): TRect;
var control:TWinControl;
begin
  result := Default(TRect);
  control:=Self;
  //while control.parent<>nil do begin
  while assigned(control) and not control.InheritsFrom(TCustomForm) do begin
    result.Left := result.Left + control.left;
    result.Top := result.Top + control.Top;
    control := control.parent;
  end;
  result.Width  :=Width;
  result.Height :=Height;
end;

procedure THSEdit.FParentWindowProc(var msg: TLMessage);
begin
  if FList.Visible and
  {$ifdef MSWINDOWS}
   (msg.msg=LM_SETCURSOR) and (TLMSetCursor(msg).MouseMsg=LM_LBUTTONDOWN) then
  {$else}
  (msg.msg=LM_MOUSEENTER) then
  {$endif}
    FList.Hide;
  FParentOrigWindowProc(msg);
end;

procedure THSEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  //params.Style   := params.Style and not (WS_CLIPCHILDREN);
  //Params.ExStyle := Params.ExStyle or WS_EX_LAYERED;
end;

procedure THSEdit.SetColor(Value: TColor);
begin
  inherited SetColor(Value);
  FEdit.Color:= Color; //ColorBright(Value, -20);
  FList.Color:=FEdit.Color;
end;


constructor THSEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Canvas.Brush.Style := bsClear;
  ControlStyle := ControlStyle + [TControlStyleType.csOpaque];
  width := 100;
  FLookAndFeel := THSLookAndFeel.Create(Self);
  //FLookAndFeel.Align:=alClient;
  //FLookAndFeel.Parent := Self;
  //height:=FLookAndFeel.Padding.top + FLookAndFeel.Padding.bottom + Font.Height;
  FItems := TStringList.Create;
  FItemIndex:=-1;
  FEdit :=TCustomEdit.Create(Self);
  //FEdit.Parent:=FLookAndFeel;
  FEdit.Parent:=Self;
  //FEdit.Color := Color;

  FEdit.ControlStyle := FEdit.ControlStyle - [TControlStyleType.csOpaque];
  FEdit.BorderStyle:=bsNone;
  FEdit.SetBounds(FLookAndFeel.Padding.left, FLookAndFeel.Padding.top, Width - FLookAndFeel.Padding.left - FLookAndFeel.Padding.right - BTN_WIDTH, Height - FLookAndFeel.Padding.top - FLookAndFeel.Padding.bottom - FLookAndFeel.Border.width.bottom);
  height := FLookAndFeel.Padding.top+FLookAndFeel.Padding.bottom + FEdit.Height;
  FEdit.Anchors := [akLeft, akTop, akRight, akbottom];
  FEdit.OnKeyDown:=FOnEditKeyDown;
  FEdit.OnChange:=FOnEditChange;
  FEdit.OnExit:=FOnEditExit;
  //FEdit.Alignment:=taVerticalCenter;
  //FEdit.BorderSpacing.InnerBorder:=2;

  FList := TCustomListBox.Create(self);
  FList.BorderStyle := bsSingle;
  FList.BorderWidth := 1;
  //FList.Color := ColorBright(Color, -20);
  //FList.Font.Color:=Font.Color;
  FList.OnSelectionChange:=FOnListSelectionChange;
  FList.OnClick:=FOnListClick;
  FList.OnKeyDown:=FOnListKeyDown;
  FList.AddHandlerOnVisibleChanged(FOnListBoxSetVisible);
  TStringList(FItems).OnChange:=FOnItemsChange;
  FList.Visible := false;
  Flist.Height := 100;
  FbtnColor := $CC6611;
  FBtn  :=TBtn.Create(Self);
  //FBtn.Color := $cc7700;
  FBtn.Parent := Self;
  FBtn.SetBounds(width - FLookAndFeel.Padding.right - BTN_WIDTH, FLookAndFeel.Padding.top, BTN_WIDTH, height - FLookAndFeel.Padding.top - FLookAndFeel.Padding.bottom + 1);
  FBtn.Anchors:=[akTop, akRight, akBottom];
  FBtn.OnPaint:=FOnBtnPaint;
  FBtn.OnMouseEnter:=FBtnEnter;
  FBtn.OnMouseLeave:=FBtnLeave;
  FBtn.OnClick:=FBtnClick;

  FBtn.Caption:='▼';

  //FBtn.SetBounds(width - 16, 2, 16, height - 4);

end;

procedure THSEdit.paint;
var r: TRect;
begin
  inherited paint;
  with canvas do begin
    pen.width   := FLookAndFeel.Border.width;
    pen.Color   := FLookAndFeel.Border.colors;
    pen.Style   := psSolid;
    brush.Style := bsSolid;
    //brush.Color := color;
    Brush.Color := Parent.Color;
    FillRect(ClientRect);
    Brush.Color := Color;
    r := ClientRect;
    //r.Inflate(0, 0 , -2, -2);
    RoundRect(r, FLookAndFeel.Border.radius.left, FLookAndFeel.Border.radius.left);


  end;
end;

procedure THSEdit.EraseBackground(DC: HDC);
begin
  // do not paint background
  //inherited EraseBackground(DC);
end;

destructor THSEdit.Destroy;
begin
  Fedit.free;
  Flist.free;
  Fbtn .free;
  FItems.Free;
  FLookAndFeel.Free;
  inherited Destroy;
end;

procedure THSEdit.FOnItemChange(Sender: TObject);
begin
  FList.Items.Text:=FItems.Text;
end;

{ THSProgressBar }
{$Assertions on}
constructor THSProgressBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  //FMin := 0;
  FMax := 10;
  FStep:= 1;
  FBarColor := $bb6600;
end;

destructor THSProgressBar.Destroy();
begin
  inherited Destroy();
end;

procedure THSProgressBar.paint;
var
  ts:TTextStyle;
begin
  inherited paint;
  with canvas do begin
    Pen.Style := psClear;
    Brush.Style := bsSolid;
    Brush.Color := ColorBright(Color, -$10);
    FillRect(Canvas.ClipRect);

    Brush.Style := bsSolid;
    Brush.Color := FBarColor;
    if FMax>0 then
      case FOrientation of
        pbVertical:
          RoundRect(0, 0, ClientWidth, round(ClientHeight*FPosition/FMax), 4, 4);
        pbHorizontal:
          RoundRect(0, 0, round(ClientWidth*FPosition/FMax), ClientHeight, 4, 4);
        pbTopDown:
          RoundRect(0, round(ClientHeight*FPosition/FMax), ClientWidth, ClientHeight, 4, 4);
        pbRightToLeft:
          RoundRect(round(ClientWidth*FPosition/FMax), 0, ClientWidth, ClientHeight, 4, 4);
      end;
    if BarShowText then begin
      font.assign(self.font);
      brush.Style:=bsClear;
      ts:= TextStyle;
      ts.Alignment := taCenter;
      ts.Layout := tlCenter;
      TextStyle := ts;
      TextRect(ClientRect, 0, 0, Caption);
    end;
  end;
end;

procedure THSProgressBar.SetBarShowText(AValue: boolean);
begin
  if FBarShowText=AValue then Exit;
  FBarShowText:=AValue;
  Invalidate;
end;

procedure THSProgressBar.SetBarColor(AValue: TColor);
begin
  if FBarColor=AValue then Exit;
  FBarColor:=AValue;
  Invalidate;
end;

procedure THSProgressBar.SetMax(AValue: integer);
begin
  if FMax=AValue then Exit;
  FMax:=AValue;
  Invalidate;
end;

//procedure THSProgressBar.SetMin(AValue: integer);
//begin
//  if FMin=AValue then Exit;
//  FMin:=AValue;
//  Invalidate;
//end;

procedure THSProgressBar.SetOrientation(AValue: TProgressBarOrientation);
begin
  if FOrientation=AValue then Exit;
  FOrientation:=AValue;
  Invalidate;
end;

procedure THSProgressBar.SetPosition(AValue: integer);
begin
  if FPosition=AValue then Exit;
  assert({(AValue>=FMin) and} (AValue<=FMax),'[ProgressBar] Position is out of range!');
  FPosition := AValue;
  Invalidate;
  Update;
end;

procedure THSProgressBar.SetStep(AValue: integer);
begin
  if FStep=AValue then Exit;
  FStep:=AValue;
end;

procedure THSProgressBar.SetStyle(AValue: THSProgressStyle);
begin
  if FStyle=AValue then Exit;
  FStyle:=AValue;
  Invalidate;
end;

procedure THSProgressBar.TextChanged();
begin
  inherited TextChanged();
  //if BarShowText then
    Invalidate;
end;

procedure THSProgressBar.StepIt();
begin
  inc(FPosition, FStep);
  Invalidate;
end;

{ TMainForm }

procedure TMainForm.btnTxt2ImgClick(Sender: TObject);
begin
  image2.Hide;
  btnLoadPic.Hide;
end;

procedure TMainForm.btnGenerateClick(Sender: TObject);
begin
  if (modelEdit1.Items.count=0) {or not TFLUX4BDownloader.modelExists(appPath+MODELS_DIR+PathDelim+modelEdit1.Text)} then
    if (MessageDlg('No models found, Would you like to download a recommended one? [FLUX-klein-4B]', mtConfirmation, mbYesNo, 0) = mrYes) then begin
      mnuDL1.Click;
      checkExistingModels;
    end
      else exit;
  if btnTxt2Img.Down then begin
    if (btnGenerate.Caption = 'Generate') then begin
      TControl(btnGenerate).Caption := 'Stop';
      TControl(btnTxt2Img).Enabled:=false;
      TControl(btnImg2Img).Enabled:=false;
      generateThread := TGenerateThread.Create(false);
    end
    else begin
      if not generateThread.Finished then generateThread.Terminate;
      //btnGenerate.Caption := 'Generate';
    end;

  end;
  if btnImg2Img.Down then begin
    if not fileExists(dlgImage.FileName) then begin
      ShowMessage('Load an image 1st.');
      exit
    end;
    if btnGenerate.Caption = 'Generate' then begin
      TControl(btnGenerate).Caption := 'Stop';
      TControl(btnTxt2Img).Enabled:=false;
      TControl(btnImg2Img).Enabled:=false;
      generateThread := TGenerateThread.Create(false);
    end
    else begin
      if not generateThread.Finished then generateThread.Terminate;
      //btnGenerate.Caption := 'Generate';
    end;

  end;

end;

procedure TMainForm.btnLoadPic1Click(Sender: TObject);
var fn: string;
begin
  fn := AppPath+FormatDateTime('yyyymmdd_hhnnss', now())+'.png';

  if not ((btnTxt2Img.Down and gotImage) or (btnImg2Img.Down and gotImage2)) then begin
    ShowMessage('No output image yet!');
    exit
  end;

  if PromptForFileName(fn, '*.png|*.png|*.bmp|*.bmp|*.jpg|*.jpg|*.ico|*.ico|*.*|*.*', 'png', '', '', true) then begin
    if FileExists(fn) then
      if MessageDlg('Overwrite ['+fn+'] ?', mtConfirmation, mbYesNo, 0)<>mrYes then exit;
    if btnTxt2Img.Down then begin
      image1.Picture.SaveToFile(fn);
      if ExtractFileExt(fn)='.png' then begin
        TQNNImage.addPngMeta(fn, 'program', strMeta);
        TQNNImage.addPngMeta(fn, 'json',
                                '{"model" : "'+modeledit1.text+'"'+
                                ', "prompt" : "'+StringReplace(memoPrompt.text, '"', '\"', [rfReplaceAll])+
                                '", "seed" : '+edtSeed.text+
                                ', "steps" : '+stepsSpn.text);

      end;

    end
    else begin
      image2.Picture.SaveToFile(fn);
      if ExtractFileExt(fn)='.png' then begin

        TQNNImage.addPngMeta(fn,'program', strMeta);
        TQNNImage.addPngMeta(fn, 'json',
                              '{"model" : "'+modeledit1.text+'"'+
                              ', "prompt" : "'+StringReplace(memoPrompt.text, '"', '\"', [rfReplaceAll])+
                              '", "seed" : '+edtSeed.text+
                              ', "steps" : '+stepsSpn.text);
      end
    end;
  end;
end;

procedure TMainForm.btnImg2ImgClick(Sender: TObject);
begin
  Image2.Show;
  btnLoadPic.Show;
  image2.width := image2.parent.width div 2
end;

procedure TMainForm.cmbModelsDropDown(Sender: TObject);
begin
  checkExistingModels;
end;

procedure TMainForm.edtCFGChange(Sender: TObject);
var s:Currency;
begin
  if not TryStrToCurr(edtCFG.Text, s) then exit;
  pnlNegative.Visible := StrToFloat(edtCFG.Text) <> 1.0;
  if pnlNegative.Visible then
    pnlNegative.Width := pnlNegative.parent.Width div 2;
end;

procedure TMainForm.edtCFGMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var s:currency;
begin
  if TryStrToCurr(TEdit(sender).text, s) then
    if (s>1) or (WheelDelta>0) then
      TEdit(Sender).Text := CurrToStr(s + (2*ord(WheelDelta>0)-1)*0.1);
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if assigned(generateThread) and not generateThread.Finished then begin
    generateThread.Terminate;
    generateThread.WaitFor;
  end;
end;

const
  FACE_COLOR = $332211;
  FONT_COLOR = $d0c0d0;
  BACK_COLOR = $221100;

procedure TMainForm.FormCreate(Sender: TObject);
var i:TQNNSchedule; s:ansistring;
  j:longint;
begin
  Application.OnIdle := OnIdle;
  Application.OnIdleEnd := OnIdleEnd;
  Color := FACE_COLOR;
  font.Color := FONT_COLOR ;
  panel6.Color := BACK_COLOR;
  for j:=0 to ComponentCount-1 do
    if (Components[j] is TSpeedButton) or (Components[j].InheritsFrom(TButtonControl))then begin
      TSpeedButton(Components[j]).Transparent:=false;
      TSpeedButton(Components[j]).Color := self.Color;
    end else if (Components[j] is TComboBox) or (Components[j] is TEdit) or (Components[j] is TSpinEdit) or (Components[j] is TMemo) then
      TControl(Components[j]).Color:=panel6.Color;


  //DefaultFormatSettings.DecimalSeparator := '.';
  if not DirectoryExists(AppPath + '/../../../Examples') then
    MODELS_DIR := ExtractFileName(MODELS_DIR);
  checkExistingModels;
  //if cmbModels.Items.count>0 then
  //  cmbModels.ItemIndex:=0;
  cmbSchedular.Items.Clear;

  for i := low(TQNNSchedule) to high(TQNNSchedule) do begin
    str(i, s);
    cmbSchedular.Items.add(copy(s,14));
  end;
  if cmbSchedular.items.count>0 then
    cmbSchedular.ItemIndex:=0;


  cmbModels.hide;
  cmbImgRes.hide;
  cmbSchedular.hide;
  spnSteps.hide;

  modelEdit1:= THSEdit.Create(Self);
  modeledit1.Color:=cmbModels.Color;
  modeledit1.Parent:=cmbModels.Parent;
  modelEdit1.SetBounds(cmbModels.Left, cmbModels.Top, cmbModels.Width, cmbModels.Height);
  modelEdit1.Anchors:=[akLeft, akTop];
  modeledit1.Items.Text:=cmbModels.Items.Text;
  if modeledit1.Items.Count>0 then
    modeledit1.ItemIndex:=0;

  imgRes := THSEdit.Create(Self);
  imgRes.Color:= cmbImgRes.Color;
  imgRes.parent := cmbImgRes.parent;
  imgRes.SetBounds(cmbImgRes.Left, cmbImgRes.Top, cmbImgRes.Width, cmbImgRes.Height);
  imgRes.Anchors:=[akRight, akTop];
  imgRes.items.Text := cmbImgRes.items.text;
  if imgRes.Items.Count>1 then
    imgRes.ItemIndex:=1;

  schedularEdit1 := THSEdit.Create(Self);
  schedularEdit1.Color:=cmbSchedular.Color;
  schedularEdit1.parent := cmbSchedular.parent;
  schedularEdit1.SetBounds(cmbSchedular.Left, cmbSchedular.Top, cmbSchedular.Width, cmbSchedular.Height);
  schedularEdit1.Anchors:=[akRight, akTop];
  schedularEdit1.items.Text := cmbSchedular.items.text;
  if schedularEdit1.Items.Count>0 then
    schedularEdit1.ItemIndex:=0;

  stepsSpn := THSSpin.Create(Self);
  stepsSpn.Color := spnSteps.Color;
  stepsSpn.Parent := spnSteps.Parent;
  stepsSpn.SetBounds(spnSteps.left, spnSteps.Top, spnSteps.Width, spnSteps.Height);
  stepsSpn.Anchors:=[akRight, akTop];
  stepsSpn.MaxValue:= spnSteps.MaxValue;
  stepsSpn.MinValue:= spnSteps.MinValue;
  stepsSpn.Value:= spnSteps.Value;
  stepsSpn.FOnChange:= spnSteps.OnChange;

  prog             := THSProgressBar.Create(Self);
  prog.BarShowText :=true;
  prog.parent      := Self;
  prog.height      := 12;
  prog.align       := alBottom;

  totalDL := THSProgressBar.Create(self);
  totalDL.parent := pnlDl;
  totalDL.SetBounds(lblDownload.width+2, 4, 120, 12);
  totalDL.Anchors := [akLeft, akTop, akRight];
  totalDL.position := totalDL.max div 2;
  totalDL.BarShowText:= true;
  //totalDL.Font.Size := totalDL.Font.Size - 4;

  subDL := THSProgressBar.Create(self);
  subDL.parent := pnlDl;
  subDL.SetBounds(lblDownload.width+2, totalDL.Height+8, 120, 12);
  subDL.Anchors :=  [akLeft, akTop, akRight];
  subDL.position := subDL.max div 2;
  //subDl.BorderSpacing.top:=2;
  subDL.BarShowText:= true;
  //subDL.Font.Size := subDL.Font.Size - 4;


  {$ifdef MSWindows}
  SetDarkModeTitleBar(self, true);
  {$endif}
end;

procedure TMainForm.btnLoadPicClick(Sender: TObject);
var
  img:TQNNImage;
  bmp:Graphics.TBitmap;

  i, w, h : longint;
  dims : string;
begin
  dlgImage.FileName:='';
  if not dlgImage.Execute  then exit;
  img := TQNNImage.loadFromFile(dlgImage.FileName);
  if (img.width>QNN_VAE_MAX_DIM) or (img.height>QNN_VAE_MAX_DIM) then
    if MessageDlg(format('One of the image dimensions is above the allowed resolution [%d X %d] > [%d X %d], resize to and proceed?', [img.width, img.height, QNN_VAE_MAX_DIM, QNN_VAE_MAX_DIM]), mtConfirmation, mbYesNo, 0)=mrYes then
      begin
        if img.width>QNN_VAE_MAX_DIM then begin
          w := 1280;
          h := trunc(img.height * w / img.width);
        end;
        if img.height>QNN_VAE_MAX_DIM then begin
          h := 1280;
          w := trunc(img.width * h / img.height);
        end;
        img := img.resize(w, h);
      end else begin
        img.free;
        exit
      end;
  bmp := Graphics.TBitmap.Create;
  QNNImageToBitmap(img, bmp);
  mainform.Image1.Picture.Graphic:= bmp;
  for i:= 1 to 8 do begin
    w := trunc(i*0.25*bmp.width);
    h := trunc(w * bmp.Height / bmp.width);
    if (w>=QNN_VAE_MAX_DIM) or (h>=QNN_VAE_MAX_DIM) then break;
    dims := format('%d X %d', [w, h]);
    if imgRes.Items.IndexOf(dims)<0 then
      imgRes.Items.add(dims);
    if i=1 then imgRes.ItemIndex:=imgRes.Items.IndexOf(dims);
  end;
  MainForm.generateThread.Synchronize(MainForm.Update);
  img.free;
  freeAndNil(bmp)
end;


procedure TMainForm.FormShow(Sender: TObject);
begin
  //modeledit1.parent := self;
  //
end;

procedure TMainForm.btnLoadPicMouseEnter(Sender: TObject);
begin
  TControl(Sender).font.Style := TControl(Sender).font.Style + [fsUnderline]
end;

procedure TMainForm.btnLoadPicMouseLeave(Sender: TObject);
begin
  TControl(Sender).font.Style := TControl(Sender).font.Style - [fsUnderline]
end;

procedure TMainForm.Image1DblClick(Sender: TObject);
begin
  if btnImg2Img.Down then
    btnLoadPicClick(btnLoadPic);
end;

procedure TMainForm.Image1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin

end;

var model:TQNNDownloader;
procedure TMainForm.Label10Click(Sender: TObject);
//var model:TQNNDownloader;
begin
  //model := TQNNDownloader.Create(BLF_NAME_SPACE, FLUX2_KLEIN_4B_DISTILLED_REPO_NAME, FLUX2_KLAIN_4B_REPO_PATHS, FLUX2_KLEIN_4B_REPO_FILES);
  //if Assigned(model.FHttp) then begin
  //  //model.FHttp.FHTTP.Terminate;
  //end;
  //pnlDL.Hide;
end;

procedure TMainForm.lblMoreClick(Sender: TObject);
begin
  PopupMenu1.PopUp(lblMore.ClientOrigin.X, lblMore.ClientOrigin.Y+lblMore.Height);
end;

procedure TMainForm.lblMoreMouseEnter(Sender: TObject);
begin
  lblMore.ParentColor:=false;
  lblMore.Color := BACK_COLOR;
end;

procedure TMainForm.lblMoreMouseLeave(Sender: TObject);
begin
  lblMore.ParentColor:=true;
end;

procedure TMainForm.lblSetAsRefClick(Sender: TObject);
begin
  Image1.Picture.Graphic := Image2.Picture.Graphic;
  dlgImage.FileName := lastGenerated;
end;

procedure TMainForm.MenuItem2Click(Sender: TObject);
begin
  frmAbout.ShowModal;
end;

procedure TMainForm.mnuDL1Click(Sender: TObject);
begin
  try
    model := TQNNDownloader.Create(
      BLF_NAME_SPACE,
      FLUX2_KLEIN_4B_DISTILLED_REPO_NAME,
      FLUX2_KLAIN_4B_REPO_PATHS,
      FLUX2_KLEIN_4B_REPO_FILES
    );
    subDL.Position:=0;
    totalDL.Position:=0;
    pnlDL.Show;
    Application.ProcessMessages;
    model.OnProgress:=OnDownload;
    model.download(appPath+MODELS_DIR);
    model.Free();
  finally
    pnlDL.Hide;
  end;
end;

procedure TMainForm.mnuDL2Click(Sender: TObject);
begin
  try
    model := TQNNDownloader.Create(
      TONGYIMAI_NAME_SPACE,
      ZIMAGE_TURBO_REPO_NAME,
      ZIMAGE_REPO_PATHS,
      ZIMAGE_TURBO_REPO_FILES
    );
    subDL.Position:=0;
    totalDL.Position:=0;
    pnlDL.Show;
    Application.ProcessMessages;
    model.OnProgress:=OnDownload;
    model.download(appPath+MODELS_DIR);
    model.Free();
  finally
    pnlDL.Hide;
  end;

end;

procedure TMainForm.mnuDLOpenBLASClick(Sender: TObject);
begin
  {$if defined(MSWINDOWS)}
  if MessageDlg('Download [Open Basic Linear Algebra]?'#13'This will improve the generation speed by ~X2', mtConfirmation, mbYesNo, 0)<>mrYes then exit;
  getOpenBlas();
  ShowMessage('OpenBLAS installed successfully, re-launch this program.');
  {$elseif defined(DARWIN) or defined(MACOS)}
  ShowMessage('Already using Apple''s native "Accelerate" library, no need for OpenBLAS!');
  {$else}
  ShowMessage('Install OpenBLAS from your package manager, e.g :'#13'"sudo apt install openblas"');
  {$endif}
end;

//const attr: longword = $884422;
procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  //assert(DwmSetWindowAttribute(MainForm.Handle, DWMWA_CAPTION_COLOR, @attr, SizeOf(Active))==S_OK);
  //attr := RGBToColor((red(attr)+20) mod 255, (green(attr)+20) mod 255, (blue(attr)+20) mod 255);
end;

procedure TMainForm.checkExistingModels;
var sr : TSearchRec;
  r:longint;
  path:RawByteString;
begin
  path := AppPath+MODELs_DIR;
  if not DirectoryExists(Path) then
    CreateDir(Path);

  cmbModels.Items.Clear;;
  try
    r := FindFirst(path +'/*', faDirectory, sr);
    while r=0 do begin
      if (sr.name<>'.') and (sr.name<>'..') then cmbModels.Items.Add(sr.Name);
      r := FindNext(sr)            ;
    end;
  finally
    SysUtils.FindClose(sr);
  end;
  if cmbModels.Items.Count>0 then cmbModels.ItemIndex:=0;
  if assigned(modeledit1) then begin
    modeledit1.Items.text := cmbModels.Items.Text;
    modeledit1.ItemIndex:=cmbModels.ItemIndex;
  end;
end;

const i: integer = 0;
procedure TMainForm.OnDownload(const subReceived, subTotal, received, total: int64);
begin
  subDL.Max:=ceil(subTotal / $4FFFFF); // 4MB
  subDL.Position:=subReceived div $4FFFFF;
  i := subDL.Position mod length(DL_Symbols);
  subDL.Caption := DL_Symbols[i];

  totalDL.Max:=Total;
  totalDL.Position:=Received;
  totalDL.Caption:=format('%d/%d', [received, total]);

  Application.ProcessMessages;
end;

const
  up:boolean = false;
  ANIM_STEP = 2;
procedure TMainForm.OnIdle(Sender: TObject; var done: boolean);
begin


end;

procedure TMainForm.OnIdleEnd(Sender: TObject);
begin
  //if Shape1.top> 200 then up := true;
  //if Shape1.top< 100 then up := false;
  //if up then
  //  Shape1.top := Shape1.top-ANIM_STEP
  //else
  //  Shape1.top := Shape1.top+ANIM_STEP;
end;

procedure TMainForm.loop(data: IntPtr);
begin
  sleep(1000)
end;

initialization
  AppPath := ExtractFilePath(ParamStr(0));

end.

