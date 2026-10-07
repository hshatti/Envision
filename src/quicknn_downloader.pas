unit quicknn_downloader;

{$ifdef FPC}
{$mode Delphi}
{$endif}
{$Assertions On}

interface

uses
  Classes, SysUtils, StrUtils, nHttp
  {$if not defined(FPC) and defined(MSWINDOWS)}
  , ShellApi
  {$endif}
  ;

const
  BLF_NAME_SPACE                                     = 'black-forest-labs';
  FLUX2_KLEIN_4B_DISTILLED_REPO_NAME                 = 'FLUX.2-klein-4B';    // black-forest-labs
  FLUX2_KLAIN_4B_REPO_PATHS : TArray<string>         = [
                                                             '.',
                                                             'scheduler',
                                                             'text_encoder',
                                                             'tokenizer',
                                                             'transformer',
                                                             'vae'
                                                         ];

  FLUX2_KLEIN_4B_REPO_FILES : TArray<TArray<string>> = [
    ['model_index.json'],
    ['scheduler_config.json'],
    [
      'generation_config.json' ,
      'model-00001-of-00002.safetensors' ,
      'model-00002-of-00002.safetensors' ,
      'model.safetensors.index.json'
    ],
    [
      'added_tokens.json',
      'chat_template.jinja',
      'merges.txt',
      'special_tokens_map.json',
      'tokenizer.json',
      'tokenizer_config.json',
      'vocab.json'
    ],
    [
      'config.json',
      'diffusion_pytorch_model.safetensors'
    ],
    [
      'config.json',
      'diffusion_pytorch_model.safetensors'
    ]
  ];

  TONGYIMAI_NAME_SPACE                                     = 'Tongyi-MAI';
  ZIMAGE_TURBO_REPO_NAME                                   = 'Z-Image-Turbo';
  ZIMAGE_REPO_PATHS : TArray<string>                            = [
                                                                 '.',
                                                                 'scheduler',
                                                                 'text_encoder',
                                                                 'tokenizer',
                                                                 'transformer',
                                                                 'vae'
                                                             ];

  ZIMAGE_TURBO_REPO_FILES : TArray<TArray<string>> = [
    ['model_index.json'],
    ['scheduler_config.json'],
    [
      'generation_config.json' ,
      'model-00001-of-00003.safetensors' ,
      'model-00002-of-00003.safetensors' ,
      'model-00003-of-00003.safetensors' ,
      'model.safetensors.index.json'
    ],
    [
      'merges.txt',
      'tokenizer.json',
      'tokenizer_config.json',
      'vocab.json'
    ],
    [
      'config.json',
      'diffusion_pytorch_model-00001-of-00003.safetensors',
      'diffusion_pytorch_model-00002-of-00003.safetensors',
      'diffusion_pytorch_model-00003-of-00003.safetensors',
      'diffusion_pytorch_model.safetensors.index.json'
    ],
    [
      'config.json',
      'diffusion_pytorch_model.safetensors'
    ]
  ];

type
  { TFLUX4BDownloader }

  { TQNNDownloader }

  TQNNDownloader= record

  const
    HTTP_ROOT       = 'https://huggingface.co/%s/%s/resolve/main/';
    HF_DOWNLOAD_ARG = '?download=true';

  var
    FHttp : TNHttp;
    stage : longint;
    currentFile  : string;
    namespace , repo : string;
    file_names   : TArray<TArray<string>>;
    src_paths    : TArray<string>;
    dst_paths    : TArray<string>;

    //FCanceled : boolean;
    FSubReceived, FSubTotal, FReceived, FTotal:int64;
    OnProgress : procedure (const subProg, subTotal, progress, total:int64) of object;
  private
   procedure OnReceive(sender:TObject; const received, total:int64);
  public
    constructor Create(const aNamespace, aRepository:string; const aSourcePaths:TArray<string>; const aFileSets:TArray<TArray<string>>; const aDestPaths: TArray<string> = nil );
    procedure Free();
    function modelExists(modelPath:string):boolean;
    procedure Cancel();
    procedure download(modelsPath: string = 'models'; srcPath: string='');
  end;

  procedure getOpenBlas();

implementation
uses termesc;

const
  ERROR_CREATE_DIR = 'Cannot create model folder';


procedure MakeDir(const dirName:string);
begin
  if not DirectoryExists(dirName) then
    assert(CreateDir(dirName), ERROR_CREATE_DIR+ ' ['+dirName+']');
end;

{ TFLUX4B }

function getFileSize(const filename: TFileName):int64;
var f:TFileStream;
begin
  f := nil;
  result := 0;
  try
    f := TFilestream.Create(filename, fmOpenRead);
    result := f.Size;
  finally
    freeandnil(f)
  end;
end;

procedure getOpenBlas();
var
    FHttp : TNHttp;
    appPath : string;
begin
  {$ifdef MSWINDOWS}
  AppPath := ExtractFilePath(ParamStr(0));
  assert(not fileExists(appPath+'libopenblas.dll'), 'OpenBLAS already exists, Ignore to continue');
  try
    FHttp := TNHttp.Create;
    FHttp.Download('https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.34/OpenBLAS-0.3.34-x64.zip', AppPath+'OpenBLAS-0.3.34-x64.zip');

  finally
    freeAndNil(FHTTP);
  end;
  unzip(AppPath+'OpenBLAS-0.3.34-x64.zip', 'bin/libopenblas.dll', appPath+'libopenblas.dll')
  {$else}
  {$endif}
end;

procedure TQNNDownloader.OnReceive(sender: TObject; const received, total: int64);
begin
  FSubReceived:=received;
  FSubTotal:=total;
  if assigned(OnProgress) then OnProgress(FSubReceived, FSubTotal, FReceived, FTotal);
end;

constructor TQNNDownloader.Create(const aNamespace, aRepository: string;
  const aSourcePaths: TArray<string>; const aFileSets: TArray<TArray<string>>;
  const aDestPaths: TArray<string>);
begin
  assert(aNamespace<>'', 'Model Downloader : aNamespace must have a value!');
  assert(aRepository<>'', 'Model Downloader : aRepository must have a value!');
  assert(assigned(aSourcePaths), 'Model Downloader : sourcepaths must have a value!');
  assert(length(aFileSets)=length(aSourcePaths), 'Model Downloader : number of file sets to download is either empty or doesn''t match the number of aSourcePaths');


  nameSpace  := aNamespace;
  repo       := aRepository;
  src_paths  := aSourcePaths;
  file_names := aFileSets;
  if assigned(aDestPaths) then
    dst_paths  := aDestPaths
  else
    dst_paths  := copy(aSourcePaths);
end;

procedure TQNNDownloader.Free;
begin
  if assigned(FHTTP) then
    FHTTP.FHTTP.Terminate;

  nameSpace    := '';
  Repo         := '';
  file_names   := nil;
  src_paths    := nil;
  dst_paths    := nil;
end;

function TQNNDownloader.modelExists(modelPath: string): boolean;
var i, j:integer;
begin
  if modelPath<>'' then
    if not (modelPath[length(modelPath)] in ['\','/']) then
      modelPath := modelPath+PathDelim;
  result := true;

  for j:=0 to high(file_names) do
    for i := 0 to high(file_names[j]) do begin
      result := result and FileExists(
        modelPath+
        ifthen((j<length(dst_paths)) and (dst_paths[j]<>''), dst_paths[j], src_paths[j])+
        PathDelim+file_names[j][i]
      );
      if not result then exit;
    end
end;

procedure TQNNDownloader.Cancel();
begin
  {$ifdef FPC}
  if assigned(FHTTP) then begin
    FHTTP.FHTTP.Terminate;
  {$else}

  {$endif}
  end;

end;

procedure TQNNDownloader.download(modelsPath: string; srcPath: string);
var curDir, subDir :string;
    i, j, dsize, fSize : int64;
    //sl : TStringList;
begin
  //sl := TStringList.Create;
  //FCanceled:=false;
  assert(assigned(file_names) and (length(file_names)=length(src_paths)), 'Model Downloader : number of file sets to download is either empty or doesn''t match the number of source paths');
  assert(namespace<>'', 'Model Downloader : no namespace defined!');
  assert(repo<>'', 'Model Downloader : no repository defined!');

  FSubtotal := 0;
  FSubReceived:=0;
  FReceived:=0;
  FTotal := length(src_paths);
  FHttp := TNHttp.Create;
  FHttp.OnReceive:=OnReceive;
  try
    if isConsole then cursorShow(false);
    if modelsPath<>'' then begin
      curDir := modelsPath + PathDelim + repo + PathDelim;
      MakeDir(modelsPath);
    end else begin
      curDir := repo + PathDelim;
    end;
    makeDir(curDir);
    for i:=0 to high(src_paths) do begin
      subDir := ifthen((i<length(dst_paths)) and (dst_paths[i]<>''), dst_paths[i], src_paths[i]);
      MakeDir(curDir + subDir);
    end;
    //if not fileExists(curDir+MODEL_INDEX) then
    //  fhttp.Download('https://huggingface.co/black-forest-labs/FLUX.2-klein-4B/resolve/main/'+MODEL_INDEX+'?download=true', curDir+MODEL_INDEX);

    for j:=0 to high(file_names) do begin
      inc(FReceived);
      for i := 0 to high(file_names[j]) do begin
        if FHTTP.FHTTP.Terminated then abort;
        currentFile := file_names[j][i];
        subDir := ifthen((j<length(dst_paths)) and (dst_paths[j]<>''), dst_paths[j], src_paths[j]);
        if fileExists(curDir + subDir + PathDelim + currentFile) then continue;
        //fSize := getfileSize(curDir+ENCODER_DIR + '/' + currentFile);
        if isConsole then
          writeln('Downloading ... ', file_names[j][i]);
        Fhttp.Download(format(HTTP_ROOT, [namespace, repo]) + subDir + '/' + currentFile + HF_DOWNLOAD_ARG, curDir + subDir + '/' + currentFile);
      end;
    end;

    if assigned(OnProgress) then OnProgress(FSubReceived, FSubTotal, FReceived, FTotal);
  finally
    // this will execute even when abort
    freeAndNil(Fhttp);
    if isConsole then cursorShow(True);
  end;
  //sl.free;

end;


initialization
  //TFLUX4B.download();
  //ExecuteProcess('cmd',[]);
   //ExecuteProcess('powershell', ['-Command', 'Invoke-WebRequest', 'https://huggingface.co/black-forest-labs/FLUX.2-klein-4B/resolve/main/text_encoder/model-00001-of-00002.safetensors?download=true', '-resume', '-OutFile', './model-00001-of-00002.safetensors']);

end.

