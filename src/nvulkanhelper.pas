unit nVulkanHelper;
{$ifdef fpc}
  {$mode Delphi}
  {$modeswitch advancedrecords}
  {$ifdef CPUX64}
    {$asmmode intel}
  {$endif}
  {$modeSwitch nestedprocvars}
{$endif}
{$C+} // or {$ASSERTIONS ON} override to compile with assertion routine for SAFE_CALL
{$pointermath on}
{$Z4}
{$T+}
interface
uses SysUtils, generics.Collections, math, typinfo, vulkan_api;

{$ifdef FPC}
const
  GL_COMPUTE_SHADER                 = $91B9;

  GL_SHADER_STORAGE_BUFFER = $90D2;
  GL_SHADER_STORAGE_BUFFER_BINDING = $90D3;
  GL_SHADER_STORAGE_BUFFER_START = $90D4;
  GL_SHADER_STORAGE_BUFFER_SIZE = $90D5;

  GL_MAX_COMPUTE_UNIFORM_BLOCKS     = $91BB;
  GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS = $91BC;
  GL_MAX_COMPUTE_IMAGE_UNIFORMS     = $91BD;
  GL_MAX_COMPUTE_SHARED_MEMORY_SIZE = $8262;
  GL_MAX_COMPUTE_UNIFORM_COMPONENTS = $8263;
  GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS = $8264;
  GL_MAX_COMPUTE_ATOMIC_COUNTERS    = $8265;
  GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS = $8266;
  GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS = $90EB;
  GL_MAX_COMPUTE_WORK_GROUP_COUNT   = $91BE;
  GL_MAX_COMPUTE_WORK_GROUP_SIZE    = $91BF;
  GL_COMPUTE_WORK_GROUP_SIZE        = $8267;
  GL_PROGRAM_BINARY_RETRIEVABLE_HINT = $8257 ;
  GL_PROGRAM_BINARY_LENGTH          = $8741 ;

{$endif}
const
  MAX_COMMAND_BUFFER_COUNT = $10;

type
  PHalf = ^half;
  Half = type smallint;

  PBF16 = ^BF16;
  BF16 = type smallint;

  PPF8 = ^PFP8;
  PFP8 = type shortint;

  { TWorkloadSizes }

  TWorkloadSizes = record
    x, y, z : longword;
    class operator Implicit(const a:TArray<longword>):TWorkloadSizes;
  end;

  { TVulkanDevice }

  TVulkanDevice = record
  public
    index                    : longint;
    PhysicalDevice           : VkPhysicalDevice;
    memoryProperties         : VkPhysicalDeviceMemoryProperties;
    deviceIdProperties       : VkPhysicalDeviceIDProperties;
    deviceProperties         : VkPhysicalDeviceProperties2;
    deviceFeatures           : VkPhysicalDeviceFeatures;
    deviceLayerProperties    : TArray<VkLayerProperties>;
    deviceExtProperties      : TArray<VkExtensionProperties>;
    queueIndex               : longint;
    queuePropCount           : longword;
    queueProperties          : TArray<VkQueueFamilyProperties>;
    function getMemoryIndex(const memType:longword; const memPropertyFlags:VkMemoryPropertyFlags): longword;
  end;

  TVulkanPrecision = (
    //floating
    vpUnknowen,
    vpF32,
    vpBf16,
    vpF16,
    vpF8_e5m2,
    vpF8_e4m3,
    vpF4_e2m1,
    vpF4_e3m0,
    vpF64,

    //signed integers
    vpS32,
    vpS16,
    vpS8,
    vpS4,

    //unsigned integers
    vpU32,
    vpU16,
    vpU8,
    vpU4,

    vpBoolean
    //vpE8m0,
  );
const
  VulkanPrecisionBitSizes : array[low(TVulkanPrecision)..high(TVulkanPrecision)] of longint = (
    //floating
    8,
    32,
    16,
    16,
    8,
    8,
    4,
    4,
    64,

    //signed integers
    32,
    16,
    8,
    4,

    //unsigned integers
    32,
    16,
    8,
    4,

    8
    //vpE8m0,
  );

type
  TVulkanMemoryAttr  = (
                       maSource, // memory is a readable
                       maTarget, //memory is writable
                       maStorage, // compute shader
                       maVertex,
                       maIndex,
                       maInDirect,
                       maDevice, // located in device otherwise in the shared (slower)
                       maHostVisible, // mappable
                       maHostCoherent, // instantly reflects updates
                       maHostCached, // memory is cached
                       maPointerMath // device memory is the device ADDRESS BIT not a handle, allowng pointer math
                     );

  TVulkanMemoryAttrs = set of TVulkanMemoryAttr;

  { TVulkanMemory }

  TVulkanMemory = record
    buffer : VkBuffer;
    memory : VkDeviceMemory;
    size : VkDeviceSize;
    offset : longint;
    precision : TVulkanPrecision;
    attributes : TVulkanMemoryAttrs;
    scaler    : TArray<TVulkanMemory>;
    blockSize : int64;
  {$ifdef MSWINDOWS}
    handle : THandle;
  {$else}
    fd : longint;
  {$endif}
    //class operator implicit(const val:pointer):TVulkanMemory;
    class operator initialize({$ifdef FPC}var{$else}out{$endif} mem:TVulkanMemory);
    class operator add(const src:TVulkanMemory; const aOffset:longint):TVulkanMemory  ;
    class operator add(const src:TVulkanMemory; const aOffset:int64):TVulkanMemory  ;
  end;

  {$if not defined(Int4)}
  Int4 = -8..7;
  {$endif}
  TVulkanArgType = (atPointer, atInt4, atInt8, atInt16, atInt32, atInt64, atUInt8, atUInt16, atUInt32, atUInt64, atHalf, atBF16, atFP8, atSingle, atDouble);

  { TVulkanArg }

  TVulkanArg = record
    class operator implicit(const src:pointer ):TVulkanArg;
    class operator implicit(const src:shortint):TVulkanArg;
    class operator implicit(const src:smallint):TVulkanArg;
    class operator implicit(const src:longint ):TVulkanArg;
    class operator implicit(const src:int64   ):TVulkanArg;
    class operator implicit(const src:uint64  ):TVulkanArg;
    class operator implicit(const src:Half    ):TVulkanArg;
    class operator implicit(const src:Single  ):TVulkanArg;
    class operator implicit(const src:double  ):TVulkanArg;
    class operator implicit(const src:TVulkanMemory  ):TVulkanArg;


    class operator implicit(const src:TVulkanArg):pointer ;
    class operator implicit(const src:TVulkanArg):shortint;
    class operator implicit(const src:TVulkanArg):smallint;
    class operator implicit(const src:TVulkanArg):longint ;
    class operator implicit(const src:TVulkanArg):int64   ;
    class operator implicit(const src:TVulkanArg):uint64  ;
    class operator implicit(const src:TVulkanArg):Half    ;
    class operator implicit(const src:TVulkanArg):Single  ;
    class operator implicit(const src:TVulkanArg):double  ;
    class operator initialize({$ifdef fpc}var{$else}out{$endif} src: TVulkanArg);
  public
    //argType : TVulkanArgType;
    //value   : uint64;
    Size      : uint64;
    case argType: TVulkanArgType of
      atPointer :(vPointer: pointer );
      atInt4    :(vInt4   : int4);
      atInt8    :(vInt8   : shortint);
      atInt16   :(vInt16  : smallint);
      atint32   :(vInt32  : longint );
      atInt64   :(vInt64  : int64   );
      atUInt8   :(vUInt8  : Byte);
      atUInt16  :(vUInt16 : Word);
      atUint32  :(vUInt32 : LongWord);
      atUInt64  :(vUInt64 : UInt64  );
      atBF16    :(vBF16   : BF16    );
      atHalf    :(vHalf   : Half    );
      atFP8     :(vPFP8   : PFP8    );
      atSingle  :(vSingle : Single  );
      atDouble  :(vDouble : Double  );
  end;

  { TVulkanPipeline }

  TVulkanPipeline = record
    shaderId           : longword;
    shader             : VkShaderModule;
    device             : VkDevice;
    pipeline           : VkPipeline;
    pipelineLayout     : VkPipelineLayout;
    descPool           : VkDescriptorPool;
    descSet            : VkDescriptorSet;
    descSetLayout      : VkDescriptorSetLayout;
    constantRange      : VkPushConstantRange;
    procedure free();
  end;

  TVulkanCommand = record
    Buffers : array [0..MAX_COMMAND_BUFFER_COUNT-1] of VkCommandBuffer;
    Fences  : array [0..MAX_COMMAND_BUFFER_COUNT-1] of VkFence;
  end;

  TVulkanArgs = TArray<TVulkanArg>;

  const
    VULKAN_ARGS_MAX_BUFFERS_COUNT = $20;
    VULKAN_ARGS_MAX_CONSTANTS_COUNT = $20;

  type
    TKernelHandle = type longint;
  { TVulkanCompute }

  TVulkanCompute = class
  type
    //TVulkanOperations = TDictionary<TNNOperation, TVulkanPipeline>;
    TVulkanConstants = array [0..VULKAN_ARGS_MAX_CONSTANTS_COUNT-1] of longint;
    //TSPIVTDictionary = TDictionary<rawbytestring, TKernelHandle>;
  const
    VK_BUFFER_USAGE_STAGING = longword(VK_BUFFER_USAGE_TRANSFER_DST_BIT)
                            or longword(VK_BUFFER_USAGE_TRANSFER_SRC_BIT)
                            or longword(VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT);

    VK_BUFFER_USAGE_STORAGE = longword(VK_BUFFER_USAGE_TRANSFER_DST_BIT)
                            or longword(VK_BUFFER_USAGE_TRANSFER_SRC_BIT)
                            or longword(VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
                            or longword(VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT)
                            ;

    VK_MEMORY_PROPERTY_STAGING  = longword(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
                                or longword(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
                                //or longword(VK_MEMORY_PROPERTY_HOST_CACHED_BIT)
                                ;

    VK_MEMORY_PROPERTY_STORAGE  = longword(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
                                //or longword(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)
                                //or longword(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
                                ;

  private
    class function loadFile(const fileName: TFileName): RawByteString; static;
    //queueFlags             : TArray<VkQueueFlags>;
    class procedure CreateInstance(const appName:ansistring);   static;
    class procedure DestroyInstance();                          static;
    class function deviceCount():longword;                      static;
    class function CheckInstanceExtension(const aExtensionName:ansistring):boolean;
  private
    device                : VkDevice;
    queue                 : vkQueue;
    cmdPool               : VkCommandPool;
    cmd                   : TVulkanCommand;
  {$ifdef MSWINDOWS}
    vkGetMemoryWin32HandleKHR : PFN_vkGetMemoryWin32HandleKHR;
  {$else}
    vkGetMemoryFdKHR : PFN_vkGetMemoryFdKHR;
  {$endif}


    //shaders               : TArray<VkShaderModule>;

    //Ops                   : TVulkanOperations;

  protected
    vulkanPipelines       : TArray<TVulkanPipeline>;
    CommandBufferStarted  : boolean;
  public
    class var
      instance               : VkInstance;
      availableLayers        : TArray<VkLayerProperties>;
      availableExtensions    : TArray<VkExtensionProperties>;
      vulkanDevices          : TArray<TVulkanDevice>;
  public
    vulkanDevice          : TVulkanDevice;
    supportsInterOp : boolean;
    class function QueryPhysicalDevices(const flags : VkQueueFlags = VkQueueFlags(VK_QUEUE_COMPUTE_BIT)):TArray<TVulkanDevice>;       static;
    constructor Create(const deviceIndex: longint = 0; aExtensions:TArray<pAnsiChar> = nil; const queuePriority: single = 1.0);
    destructor Destroy; override;
    //function CompileSPIRV(const sourcefile:TFileName):RawByteString;
    function CheckExtention(const aExtension:ansistring):boolean;
    function createBuffer(const byteSize:VkDeviceSize ; const usage: vkBufferUsageFlags = VK_BUFFER_USAGE_STORAGE):VkBuffer;
    function allocMem(const buffer:VkBuffer; const memProperty: VkMemoryPropertyFlags = VK_MEMORY_PROPERTY_STORAGE):VkDeviceMemory;  overload;
    // size in bytes
    function createStorageMemory(const size: uint64):TVulkanMemory;
    //size in bytes
    function createStagingMemory(const size: uint64):TVulkanMemory;
    function createMemory(const N: uint64; const aPrecision:TVulkanPrecision; const attr:TVulkanMemoryAttrs = [maSource, maTarget]):TVulkanMemory;
    procedure freeMemory(const mem:TVulkanMemory);
    function mapMemory(const mem:TVulkanMemory; const aOffset:longword=0):pointer;
    procedure unMapMemory(const mem:TVulkanMemory);
    procedure pushToDevice(const aData:pointer; const mem:TVulkanMemory; N:NativeInt=-1);
    procedure pullFromDevice(const aData:pointer; const mem:TVulkanMemory; N:NativeInt=-1);
    procedure copyBuffer(const src, dst: TVulkanMemory);overload;
    // aRegions length must be a multiple of 3 [(srsOffset, dstOffset, dataSize), ...]
    procedure copyBuffer(const src, dst: TVulkanMemory; const aRegions:TArray<VkDeviceSize>);overload;
    function loadShader(const fileNameSpirV: RawByteString):VkShaderModule;
    procedure preparePipeline(const Op: TKernelHandle; const shader: VkShaderModule; const localThreads:TWorkloadSizes); overload;
    procedure preparePipeline(const Op: TKernelHandle; const shader : VkShaderModule ); overload;
    procedure dispatchPipeline(const Op: TkernelHandle; const args: TVulkanArgs; const x:longword; const y:longword = 1; const z:longword =1);
    procedure beginCommadBuffer;
    procedure endCommandBuffer;
    procedure finish;
    //procedure Create
  end;
type
  nfloat = single;
  Pnfloat = ^nfloat;

procedure SAFE_CALL(const res:VkResult); overload;// inline;
function CEIL_DIV(const M, N:longword):longword; inline;

function array_sum(const N:longword; const a:Pnfloat):single; overload;
function array_sum(const a:TArray<nfloat>):single; overload;
function array_max(const N:longword; const a:Pnfloat):nfloat;overload;
function array_max(const a:TArray<nfloat>):nfloat;overload;
function array_min(const N:longword; const a:Pnfloat):nfloat;overload;
function array_min(const a:TArray<nfloat>):nfloat;overload;
procedure array_min_max(const N:longword; const a:pnfloat; const _min, _max: Pnfloat); overload;
procedure array_min_max(const a:TArray<nfloat>; var _min, _max: nfloat);overload;
function array_sum_sqr_diff(const N:longword; const a:Pnfloat; const b:single):single;overload;
function array_sum_sqr_diff(const a:TArray<nfloat>; const b:single):single;overload;
function array_variance(const N:longword; const mean:single; const a:Pnfloat):single; overload;
function array_variance(const N:longword; const a:Pnfloat):single; overload;
function array_variace(const a:TArray<nfloat>):single; overload;
procedure array_rand(const N:longword; const start, finish:nfloat; const a:Pnfloat);overload;
function array_rand(const N:longword; const start:single = -1;const finish:single = 1):TArray<nfloat>;  overload;
procedure array_linSpace(const N:longword; const start, finish:nfloat; const a:Pnfloat);overload;
function array_linSpace(const N:longword; const start:single = -1;const finish:single = 1):TArray<nfloat>;  overload;
procedure array_add(const N:longword; const a, b, c:Pnfloat); overload;
procedure array_add(const a, b, c:TArray<nfloat>);  overload;
procedure array_axpy(const N:longword; const a: nfloat; const x, y:Pnfloat);
procedure array_print(const N:longword; const a:Pnfloat; const decimals: word=2);overload;
procedure array_print(const a:TArray<nfloat>; const decimals: word=2);overload;
procedure array_stat(const N:longword; const a:Pnfloat; const decimals: word=2); overload;
procedure array_stat(const a:TArray<nfloat>; const decimals: word=2); overload;
function array_sum_sqr_diff(const N:longword; const a,b:Pnfloat):single; overload;
function array_sum_sqr_diff(const a,b:TArray<nfloat>):single; overload;
function array_sum_abs_diff(const N:longword; const a,b:Pnfloat):single; overload;
function array_sum_abs_diff(const a,b:TArray<nfloat>):single; overload;
function array_max_abs_diff(const N:longword; const a,b:Pnfloat):single; overload;
function array_max_abs_diff(const a,b:TArray<nfloat>):single; overload;
procedure array_print_diff(const N:longword; const a,b:Pnfloat; const Eps: single=0.000001); overload;
procedure array_print_diff(const a,b:TArray<nfloat>; const Eps: single=0.000001); overload;
procedure array_fma(const N:longword; const a,b :nfloat; const x, y:Pnfloat); overload;
procedure array_gemm_nn(const M,N,K : longword; const ALPHA:single; const A:TArray<nfloat>; const lda:longword; const B:TArray<nfloat>; const ldb:longword; const BETA:single; const C:TArray<nfloat>; const ldc:longword); overload;
procedure array_gemm_tn(const M,N,K : longword; const ALPHA:single; const A:TArray<nfloat>; const lda:longword; const B:TArray<nfloat>; const ldb:longword; const BETA:single; const C:TArray<nfloat>; const ldc:longword); overload;
procedure array_gemm_nt(const M,N,K : longword; const ALPHA:single; const A:TArray<nfloat>; const lda:longword; const B:TArray<nfloat>; const ldb:longword; const BETA:single; const C:TArray<nfloat>; const ldc:longword); overload;


implementation
{$ifdef MSWINDOWS}
uses windows, quicknncpu;
{$endif}

procedure SAFE_CALL(const res:VkResult);
begin
  Assert(res = VK_SUCCESS, 'ERROR : '+intToStr(longint(res)))
end;

function VK_MAKE_API_VERSION(const variant, major, minor, patch: longword): longword;inline;
begin
  result :=((variant shl 29) or (major shl 22) or (minor shl 12) or patch)
end;

function VK_MAKE_VERSION(const major, minor, patch: longword): longword;inline;
begin
  result :=((major shl 22) or (minor shl 12) or patch)
end;

function CHECK_NAME(const aName: ansistring; const aNames:TArray<pAnsiChar>):boolean;
var i: integer;
begin
  result :=false;
  for i:=0 to high(aNames) do
    if aName = aNames[i] then exit(true)
end;

function INDEXOF_NAME(const aName: ansistring; const aNames:TArray<pAnsiChar>):integer;
var i: integer;
begin
  result := -1;
  for i:=0 to high(aNames) do
    if aName = aNames[i] then exit(i)
end;

{ TWorkloadSizes }

class operator TWorkloadSizes.Implicit(const a: TArray<longword>): TWorkloadSizes;
begin
  move(pointer(a)^, result, min(length(a),3)*sizeof(longint))
end;

{ TVulkanDevice }

function TVulkanDevice.getMemoryIndex(const memType: longword; const memPropertyFlags: VkMemoryPropertyFlags): longword;
var
  i: longword;
begin
  for i:=0 to memoryProperties.memoryTypeCount-1 do
    if (memType and (1 shl i)>0) and ((memoryProperties.memoryTypes[i].propertyFlags and memPropertyFlags) = memPropertyFlags) then
      exit(i);
  assert(false, 'Unable to find matching memory with type ['+intToStr(memType)+'] and properties ['+intToStr(memPropertyFlags)+']');
end;

{ TVulkanMemory }

//class operator TVulkanMemory.implicit(const val: pointer): TVulkanMemory;
//begin
//  FillChar(result, sizeof(TVulkanMemory), #0);
//  result.buffer := val;
//end;

class operator TVulkanMemory.initialize({$ifdef FPC}var{$else}out{$endif} mem: TVulkanMemory);
begin
  FillChar(mem, sizeOf(TVulkanMemory), #0)
end;

class operator TVulkanMemory.add(const src:TVulkanMemory; const aOffset:longint):TVulkanMemory  ;
begin
  assert(inRange(src.offset + aOffset, 0, src.Size), '[ERROR] offset is beyond the memory boundries.');
  result := src;
  result.offset:= src.offset + aOffset;
end;

class operator TVulkanMemory.add(const src:TVulkanMemory; const aOffset:int64):TVulkanMemory  ;
begin
  assert(inRange(src.offset + aOffset, 0, src.Size), '[ERROR] offset is beyond the memory boundries.');
  result := src;
  result.offset:= src.offset + aOffset;
end;


{ TVulkanArg }

class operator TVulkanArg.implicit(const src: pointer): TVulkanArg;
begin
  result.argType  := atPointer;
  result.vPointer := src;
end;

class operator TVulkanArg.implicit(const src: shortint): TVulkanArg;
begin
  result.argType  := atInt8;
  result.vInt8 := src;
end;

class operator TVulkanArg.implicit(const src: smallint): TVulkanArg;
begin
  result.argType  := atInt16;
  result.vInt16 := src;
end;

class operator TVulkanArg.implicit(const src: longint): TVulkanArg;
begin
  result.argType  := atInt32;
  result.vInt32 := src;
end;

class operator TVulkanArg.implicit(const src: int64): TVulkanArg;
begin
  result.argType  := atInt64;
  result.vInt64 := src;
end;

class operator TVulkanArg.implicit(const src: uint64): TVulkanArg;
begin
  result.argType  := atUInt64;
  result.vUInt64 := src;
end;

class operator TVulkanArg.implicit(const src: Half): TVulkanArg;
begin
  result.argType  := atHalf;
  result.vHalf := src;
end;

class operator TVulkanArg.implicit(const src: Single): TVulkanArg;
begin
  result.argType  := atSingle;
  result.vSingle := src;
end;

class operator TVulkanArg.implicit(const src: double): TVulkanArg;
begin
  result.argType  := atDouble;
  result.vDouble := src;
end;

class operator TVulkanArg.implicit(const src: TVulkanMemory): TVulkanArg;
begin
  result.Size := src.size;
  result.argType:=atPointer;// test
  result.vPointer := src.buffer;
end;

class operator TVulkanArg.implicit(const src: TVulkanArg): pointer;
begin
  result := src.vPointer;
end;

class operator TVulkanArg.implicit(const src: TVulkanArg): shortint;
begin
  result := src.vInt8;
end;

class operator TVulkanArg.implicit(const src: TVulkanArg): smallint;
begin
  result := src.vInt16;
end;

class operator TVulkanArg.implicit(const src: TVulkanArg): longint;
begin
  result := src.vInt32;
end;

class operator TVulkanArg.implicit(const src: TVulkanArg): int64;
begin
  result := src.vInt64;
end;

class operator TVulkanArg.implicit(const src: TVulkanArg): uint64;
begin
  result := src.vUInt64;
end;

class operator TVulkanArg.implicit(const src: TVulkanArg): Half;
begin
  result := src.vHalf;
end;

class operator TVulkanArg.implicit(const src: TVulkanArg): Single;
begin
  result := src.vSingle;
end;

class operator TVulkanArg.implicit(const src: TVulkanArg): double;
begin
  result := src.vDouble;
end;

class operator TVulkanArg.initialize({$ifdef fpc}var{$else}out{$endif} src: TVulkanArg);
begin
  src := default(TVulkanArg)
end;

{ TVulkanPipeline }

procedure TVulkanPipeline.free();
begin
  if not assigned(shader) then exit;
  vkDestroyDescriptorSetLayout(device, descSetLayout, nil);
  vkFreeDescriptorSets(device, descPool, 1, @descSet);
  vkDestroyDescriptorPool(device, descPool, nil);

  vkDestroyPipelineLayout(device, pipelineLayout, nil);
  vkDestroyPipeline(device, pipeline, nil);
  vkDestroyShaderModule(device, shader, nil);
  self := Default(TVulkanPipeline);
end;

{ TVulkanCompute }

class function TVulkanCompute.loadFile(const fileName: TFileName): RawByteString;
var
  f:file;
begin
  assert(fileExists(filename), 'File not found!');
  try
    assignFile(f, fileName);
    reset(f, 1);
    setLength(result, FileSize(f));
    if length(result)>0 then
      blockRead(f, result[1], length(result));
  finally
    close(f)
  end;
end;

class procedure TVulkanCompute.CreateInstance(const appName: ansistring);
var
  instanceCreateInfo         : VkInstanceCreateInfo;
  appInfo                    : vkApplicationInfo;
  extensions, validationLyr  : array of PAnsiChar;
  features                   : VkValidationFeaturesEXT ;
  enabledValidationFeatures  : array of VkValidationFeatureEnableEXT ;
  disabledValidationFeatures : array of VkValidationFeatureDisableEXT ;
  elementCount         : longword;
  //instLayerProps             : array of VkLayerProperties;
  //deviceExtProps             : array of VkExtensionProperties;

begin
//  SetExceptionMask([exZeroDivide, exInvalidOp, exPrecision]);
  instance                    :=    nil;
  SAFE_CALL(vkEnumerateInstanceLayerProperties(@elementCount, nil)) ;
  setLength(availableLayers, elementCount);
  SAFE_CALL(vkEnumerateInstanceLayerProperties(@elementCount, pointer(availableLayers)));

  SAFE_CALL(vkEnumerateInstanceExtensionProperties(nil, @elementCount, nil));
  setLength(availableExtensions, elementCount);
  SAFE_CALL(vkEnumerateInstanceExtensionProperties(nil, @elementCount, pointer(availableExtensions)));
  {$ifdef DEBUG}
  //extensions                  :=    [VK_EXT_DEBUG_UTILS_EXTENSION_NAME] ;
  //validationLyr               :=    [VK_EXT_VALIDATION_FEATURES_EXTENSION_NAME];
  //enabledValidationFeatures   :=    [VK_VALIDATION_FEATURE_ENABLE_DEBUG_PRINTF_EXT];
  {$endif}
  insert(VK_KHR_EXTERNAL_MEMORY_CAPABILITIES_EXTENSION_NAME, extensions, length(extensions));
  insert(VK_KHR_EXTERNAL_SEMAPHORE_CAPABILITIES_EXTENSION_NAME, extensions, length(extensions));
  insert(VK_KHR_EXTERNAL_FENCE_CAPABILITIES_EXTENSION_NAME, extensions, length(extensions));

  appInfo                     :=    default(VkApplicationInfo);
  appInfo.sType               :=    VK_STRUCTURE_TYPE_APPLICATION_INFO;
  appInfo.pApplicationName    :=    nil;//PChar(appName);
  appInfo.applicationVersion  :=    VK_MAKE_VERSION(1, 2, 0);
  appInfo.apiVersion          :=    VK_API_VERSION_1_2;

  features                    :=    default(VkValidationFeaturesEXT);
  features.enabledValidationFeatureCount  := length(enabledValidationFeatures);
  features.pEnabledValidationFeatures     := pointer(enabledValidationFeatures);
  features.disabledValidationFeatureCount := length(disabledValidationFeatures);
  features.pDisabledValidationFeatures    := pointer(disabledValidationFeatures);

  instanceCreateInfo          :=    default(VkInstanceCreateInfo);
  instanceCreateInfo.sType    :=    VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  instanceCreateInfo.enabledExtensionCount   := length(extensions);
  instanceCreateInfo.ppEnabledExtensionNames := pointer(extensions);
  instanceCreateInfo.enabledLayerCount       := length(validationLyr);
  instanceCreateInfo.ppEnabledLayerNames     := pointer(validationLyr);
  instanceCreateInfo.pNext                   := @features;
  instanceCreateInfo.pApplicationInfo        := @appInfo;

  // some GPU drivers do not check floating opertions
  // exceptions which eventually ends up being captured by pascal compiler,
  // disabling floating point operations exceptions below
  //SetExceptionMask([exInvalidOp, exPrecision, exUnderflow]);

  SAFE_CALL(vkCreateInstance(@instanceCreateInfo, nil, @instance));
end;

class procedure TVulkanCompute.DestroyInstance;
begin
  vkDestroyInstance(instance, nil);
end;

class function TVulkanCompute.deviceCount(): longword;
begin
  result :=0;
  SAFE_CALL(vkEnumeratePhysicalDevices(instance, @result, nil))
end;

class function TVulkanCompute.QueryPhysicalDevices(const flags: VkQueueFlags): TArray<
  TVulkanDevice>;
var
  pd: TArray<VkPhysicalDevice>;
  R : TArray<TVulkanDevice>;
  devCount : longword;
  i, J, k: Integer;
begin
  devCount := deviceCount();
  result := nil;
  setLength(r, devCount);
  setLength(pd, devCount);
  SAFE_CALL(vkEnumeratePhysicalDevices(instance, @devCount, pointer(pd)));
  for i:=0 to high(r) do begin
    r[i].index := i;
    r[i].queueIndex := -1;;
    r[i].PhysicalDevice := pd[i];
    r[i].deviceIdProperties.sType:=VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES;
    r[i].deviceProperties.sType:=VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
    r[i].deviceProperties.pNext:=@r[i].deviceIdProperties;
    vkGetPhysicalDeviceProperties2(pd[i], @r[i].deviceProperties);
    vkGetPhysicalDeviceFeatures(pd[i], @r[i].deviceFeatures);
    vkGetPhysicalDeviceMemoryProperties(pd[i], @r[i].memoryProperties);
    vkGetPhysicalDeviceQueueFamilyProperties(pd[i], @r[i].queuePropCount, nil);
    setLength(r[i].queueProperties, r[i].queuePropCount);
    vkGetPhysicalDeviceQueueFamilyProperties(pd[i], @r[i].queuePropCount, pointer(r[i].queueProperties));
    SAFE_CALL(vkEnumerateDeviceLayerProperties(pd[i], @devCount, nil));
    setLength(r[i].deviceLayerProperties, devCount);
    setLength(r[i].deviceExtProperties, devCount);
    SAFE_CALL(vkEnumerateDeviceLayerProperties(pd[i], @devCount, pointer(r[i].deviceLayerProperties)));
    SAFE_CALL(vkEnumerateDeviceExtensionProperties(pd[i], nil, @devCount, nil));
    setLength(r[i].deviceExtProperties, devCount);
    SAFE_CALL(vkEnumerateDeviceExtensionProperties(pd[i], nil, @devCount, pointer(r[i].deviceExtProperties)));
    for j:=0 to r[i].queuePropCount-1 do
      if 0<>(r[i].queueProperties[j].queueFlags and flags) then begin
        r[i].queueIndex := j;
        insert(r[i], result, length(result));
        break
      end;
  end;
end;

class function TVulkanCompute.CheckInstanceExtension(
  const aExtensionName: ansistring): boolean;
var
  i: Integer;
begin
  result := false;
  for i:=0 to high(availableExtensions) do begin
    //writeln(availableExtensions[i].extensionName);
    if aExtensionName = availableExtensions[i].extensionName then
      exit(true);
  end;

end;

constructor TVulkanCompute.Create(const deviceIndex: longint;
  aExtensions: TArray<pAnsiChar>; const queuePriority: single);
var
  queueInfo  : VkDeviceQueueCreateInfo;
  deviceInfo : VkDeviceCreateInfo;
  poolInfo   : VkCommandPoolCreateInfo;
  allocInfo  :VkCommandBufferAllocateInfo;
  fenceInfo : VkFenceCreateInfo;
  i: Integer;
begin
  vulkanDevice := vulkanDevices[deviceIndex];
  queueInfo := default(VkDeviceQueueCreateInfo);
  queueInfo.sType := VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
  queueInfo.queueFamilyIndex := vulkanDevice.queueIndex;
  queueInfo.queueCount := 1;
  queueInfo.pQueuePriorities := @queuePriority;
  //VK_KHR_cosh
  supportsInterOp:=CheckExtention(VK_KHR_EXTERNAL_MEMORY_EXTENSION_NAME)
    and CheckExtention(VK_KHR_EXTERNAL_SEMAPHORE_EXTENSION_NAME)
    and CheckExtention(VK_KHR_EXTERNAL_FENCE_EXTENSION_NAME)
    {$ifdef MSWINDOWS}
    and CheckExtention(VK_KHR_EXTERNAL_MEMORY_WIN32_EXTENSION_NAME)
    and CheckExtention(VK_KHR_EXTERNAL_SEMAPHORE_WIN32_EXTENSION_NAME)
    and CheckExtention(VK_KHR_EXTERNAL_FENCE_WIN32_EXTENSION_NAME)
    {$else}
    and CheckExtention(VK_KHR_EXTERNAL_MEMORY_FD_EXTENSION_NAME)
    and CheckExtention(VK_KHR_EXTERNAL_SEMAPHORE_FD_EXTENSION_NAME)
    and CheckExtention(VK_KHR_EXTERNAL_FENCE_FD_EXTENSION_NAME)
    {$endif}
    ;
  //supportsInterOp:=false;
  if supportsInterOp then begin
    insert(VK_KHR_EXTERNAL_MEMORY_EXTENSION_NAME, aExtensions, length(aExtensions));
    insert(VK_KHR_EXTERNAL_SEMAPHORE_EXTENSION_NAME, aExtensions, length(aExtensions));
    insert(VK_KHR_EXTERNAL_FENCE_EXTENSION_NAME, aExtensions, length(aExtensions));
  {$ifdef MSWINDOWS}
    insert(VK_KHR_EXTERNAL_MEMORY_WIN32_EXTENSION_NAME    , aExtensions, length(aExtensions));
    insert(VK_KHR_EXTERNAL_SEMAPHORE_WIN32_EXTENSION_NAME , aExtensions, length(aExtensions));
    insert(VK_KHR_EXTERNAL_FENCE_WIN32_EXTENSION_NAME     , aExtensions, length(aExtensions));
  {$else}
    insert(VK_KHR_EXTERNAL_MEMORY_FD_EXTENSION_NAME    , aExtensions, length(aExtensions));
    insert(VK_KHR_EXTERNAL_SEMAPHORE_FD_EXTENSION_NAME , aExtensions, length(aExtensions));
    insert(VK_KHR_EXTERNAL_FENCE_FD_EXTENSION_NAME     , aExtensions, length(aExtensions));
  {$endif}
  end;

  deviceInfo := default(VkDeviceCreateInfo);
  deviceInfo.sType := VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
  deviceInfo.queueCreateInfoCount := 1;
  deviceInfo.pQueueCreateInfos := @queueInfo;
  deviceInfo.enabledExtensionCount:=length(aExtensions);
  deviceInfo.ppEnabledExtensionNames:=pointer(aExtensions);
  SAFE_CALL(vkCreateDevice(VulkanDevice.PhysicalDevice, @deviceInfo, nil, @device));

  {$ifdef MSWINDOWS}
  vkGetMemoryWin32HandleKHR := vkGetDeviceProcAddr(device, 'vkGetMemoryWin32HandleKHR');
  {$else}
  vkGetMemoryFdKHR := vkGetDeviceProcAddr(device, 'vkGetMemoryFdKHR');
  {$endif}

  vkGetDeviceQueue(device, VulkanDevice.queueIndex, 0, @Queue);

  poolInfo := default(VkCommandPoolCreateInfo);
  poolInfo.sType := VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
  poolInfo.queueFamilyIndex := VulkanDevice.queueIndex;
  poolInfo.flags := longword(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT);
  SAFE_CALL(vkCreateCommandPool(device, @poolInfo, nil, @cmdPool));

  allocInfo := default(VkCommandBufferAllocateInfo);
  allocInfo.sType := VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
  allocInfo.commandPool := cmdPool;
  allocInfo.level := VK_COMMAND_BUFFER_LEVEL_PRIMARY;
  allocInfo.commandBufferCount := MAX_COMMAND_BUFFER_COUNT;
  SAFE_CALL(vkAllocateCommandBuffers(device, @allocInfo, @cmd.Buffers[0]));

  fenceInfo := default(VkFenceCreateInfo);
  fenceInfo.sType := VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
  for i:=0 to high(cmd.Fences) do begin
    cmd.Fences[i] := nil;
    SAFE_CALL(vkCreateFence(device, @fenceInfo, nil, @cmd.Fences[i]));
  end;

  //Ops := TVulkanOperations.Create;

  //CompileSPIRV('Z:\Development\vulkan_gemm\vec_add.comp');
end;

destructor TVulkanCompute.Destroy;
var
  i : longint;
begin
  //for p in Ops do
  //  p.value.free;
  //Ops.free;
  for i:=0 to high(vulkanPipelines) do
    if assigned(vulkanPipelines[i].device) then vulkanPipelines[i].free;
  for i:=0 to high(cmd.Fences) do
    vkDestroyFence(device, cmd.Fences[i], nil);
  vkFreeCommandBuffers(device, cmdPool, MAX_COMMAND_BUFFER_COUNT, @cmd.Buffers[0]);
  vkDestroyCommandPool(device, cmdPool, nil);
  vkDestroyDevice(device, nil);
  queue := nil;
  inherited Destroy;
end;

function TVulkanCompute.CheckExtention(const aExtension: ansistring): boolean;
var
  i: Integer;
begin
  result := false;
  for i:=0 to High(VulkanDevice.deviceExtProperties) do begin
      //writeln(VulkanDevice.deviceExtProperties[i][j].extensionName);
      if aExtension=VulkanDevice.deviceExtProperties[i].extensionName then
        exit(true);
  end;
end;

{
function TVulkanCompute.CompileSPIRV(const sourcefile: TFileName): RawByteString;
var
  shader, prog : GLuint;
  source : ansistring;
  sourcePtr : PAnsiChar;
  sourceLen : GlInt;
begin
  shader := glCreateShader(GL_COMPUTE_SHADER);
  source := loadFile(sourcefile);
  sourcePtr := PAnsiChar(source);
  sourceLen := length(source);

  glShaderSource(shader, 1, @sourcePtr, @sourceLen);
  glCompileShader(shader);
  glGetShaderiv(shader, GL_COMPILE_STATUS, @sourceLen);

  //prog := glCreateProgram();
  //glAttachShader(prog, shader);
  //glLinkProgram(prog);
  //glGetProgramiv(prog, GL_PROGRAM_BINARY_LENGTH, @sourceLen);


end;
}

function TVulkanCompute.createBuffer(const byteSize: VkDeviceSize; const usage: vkBufferUsageFlags): VkBuffer;
var createInfo:VkBufferCreateInfo;
begin
  createInfo := default(VkBufferCreateInfo);
  createInfo.sType := VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
  createInfo.size  := byteSize;
  createInfo.usage := usage;
  createInfo.sharingMode:= VK_SHARING_MODE_EXCLUSIVE;
  SAFE_CALL(vkCreateBuffer(device, @createInfo, nil, @result))
end;

function TVulkanCompute.allocMem(const buffer: VkBuffer; const memProperty: VkMemoryPropertyFlags): VkDeviceMemory;
var
  memReq  : VkMemoryRequirements;
  memInfo : VkMemoryAllocateInfo;
  memExportAllocInfo : VkExportMemoryAllocateInfo;
begin
  vkGetBufferMemoryRequirements(device, buffer , @memReq);
  memExportAllocInfo := default(VkExportMemoryAllocateInfo);
  memExportAllocInfo.sType:=VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO;
  {$ifdef MSWINDOWS}
  memExportAllocInfo.handleTypes:=longword(VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT);
  {$else}
  memExportAllocInfo.handleTypes:=longword(VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT);
  {$endif}
  memInfo := default(VkMemoryAllocateInfo);
  memInfo.sType := VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  memInfo.allocationSize:= memReq.size;
  if supportsInterOp then
    meminfo.pNext:=@memExportAllocInfo;
  memInfo.memoryTypeIndex := VulkanDevice.getMemoryIndex(memReq.memoryTypeBits, memProperty);
  try
    SAFE_CALL(vkAllocateMemory(device, @memInfo, nil, @result));
  except
    begin
      vkDestroyBuffer(device, buffer, nil);
      raise
    end;
  end;
  SAFE_CALL(vkBindBufferMemory(device, buffer, result, 0));
end;

function TVulkanCompute.createStorageMemory(const size: uint64): TVulkanMemory;
var
  memHandleInfo :
  {$ifdef MSWiNDOWS}
  VkMemoryGetWin32HandleInfoKHR;
  {$else}
  VkMemoryGetFdInfoKHR;
  {$endif}
begin
  result.buffer:=createBuffer(size);
  result.memory := allocMem(result.buffer);
  result.size := size;
  result.attributes := [maSource, maTarget, maStorage, maDevice, maPointerMath];

  if supportsInterOp then begin
    {$ifdef MSWINDOWS}
    memHandleInfo.sType      := VK_STRUCTURE_TYPE_MEMORY_GET_WIN32_HANDLE_INFO_KHR;
    memHandleInfo.pNext      := nil;
    memHandleInfo.memory     := result.memory;
    memHandleInfo.handleType := VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR;
    SAFE_CALL(vkGetMemoryWin32HandleKHR(device, @memHandleInfo, @result.handle));
    {$else}
    memHandleInfo.sType      := VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR;
    memHandleInfo.pNext      := nil;
    memHandleInfo.memory     := result.memory;
    memHandleInfo.handleType := VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT_KHR;
    SAFE_CALL(vkGetMemoryFdKHR(device, @memHandleInfo, @result.fd));
    {$endif}
  end;
end;

function TVulkanCompute.createStagingMemory(const size: uint64): TVulkanMemory;
var
  memHandleInfo :
  {$ifdef MSWiNDOWS}
  VkMemoryGetWin32HandleInfoKHR;
  {$else}
  VkMemoryGetFdInfoKHR;
  {$endif}
begin
  result.buffer:=createBuffer(size, VK_BUFFER_USAGE_STAGING);
  result.memory := allocMem(result.buffer, VK_MEMORY_PROPERTY_STAGING);
  result.size := size;
  result.attributes:= [maSource, maTarget, maHostVisible, maHostCoherent, maPointerMath];

  if supportsInterOp then begin
    {$ifdef MSWINDOWS}
    memHandleInfo.sType      := VK_STRUCTURE_TYPE_MEMORY_GET_WIN32_HANDLE_INFO_KHR;
    memHandleInfo.pNext      := nil;
    memHandleInfo.memory     := result.memory;
    memHandleInfo.handleType := VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT;
    SAFE_CALL(vkGetMemoryWin32HandleKHR(device, @memHandleInfo, @result.handle));
    {$else}
    memHandleInfo.sType      := VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR;
    memHandleInfo.pNext      := nil;
    memHandleInfo.memory     := result.memory;
    memHandleInfo.handleType := VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT;
    SAFE_CALL(vkGetMemoryFdKHR(device, @memHandleInfo, @result.fd));
    {$endif}
  end;
end;

function TVulkanCompute.createMemory(const N: uint64; const aPrecision: TVulkanPrecision; const attr: TVulkanMemoryAttrs): TVulkanMemory;
var
  uflags : VkBufferUsageFlags;
  pflag : VkMemoryPropertyFlags;
  sz : uint64;
  memHandleInfo :
  {$ifdef MSWiNDOWS}
  VkMemoryGetWin32HandleInfoKHR;
  {$else}
  VkMemoryGetFdInfoKHR;
  {$endif}
begin
  sz := (N*VulkanPrecisionBitSizes[aPrecision]+4) div 8;
  uflags := longword(VK_BUFFER_USAGE_STORAGE_BUFFER_BIT) *ord(maStorage in attr)
         or longword(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT)  *ord(maVertex in attr)
         or longword(VK_BUFFER_USAGE_INDEX_BUFFER_BIT)   *ord(maIndex in attr)
         or longword(VK_BUFFER_USAGE_STORAGE_BUFFER_BIT) *ord(maInDirect in attr)
         or longword(VK_BUFFER_USAGE_TRANSFER_SRC_BIT)   *ord(maSource in attr)
         or longword(VK_BUFFER_USAGE_TRANSFER_DST_BIT)   *ord(maTarget in attr)
         or longword(VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT)*ord(maPointerMath in attr);

  result.buffer := createBuffer(sz, uflags);


  pflag  := longword(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)*ord(maDevice in attr)
         or longword(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)*ord(maHostVisible in attr)
         or longword(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)*ord(maHostCoherent in attr)
         or longword(VK_MEMORY_PROPERTY_HOST_CACHED_BIT)*ord(maHostCached in attr);

  result.precision := aPrecision;
  result.memory := allocMem(result.buffer, pflag);
  result.size := sz;
  result.attributes:= attr;

  if supportsInterOp then begin
    {$ifdef MSWINDOWS}
    memHandleInfo.sType      := VK_STRUCTURE_TYPE_MEMORY_GET_WIN32_HANDLE_INFO_KHR;
    memHandleInfo.pNext      := nil;
    memHandleInfo.memory     := result.memory;
    memHandleInfo.handleType := VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_WIN32_BIT_KHR;
    SAFE_CALL(vkGetMemoryWin32HandleKHR(device, @memHandleInfo, @result.handle));
    {$else}
    memHandleInfo.sType      := VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR;
    memHandleInfo.pNext      := nil;
    memHandleInfo.memory     := result.memory;
    memHandleInfo.handleType := VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT_KHR;
    SAFE_CALL(vkGetMemoryFdKHR(device, @memHandleInfo, @result.fd));
    {$endif}
  end;
end;

procedure TVulkanCompute.freeMemory(const mem: TVulkanMemory);
begin
  vkFreeMemory(device, mem.memory, nil);
  vkDestroyBuffer(device, mem.buffer, nil);
end;

function TVulkanCompute.mapMemory(const mem: TVulkanMemory; const aOffset: longword): pointer;
begin
  SAFE_CALL(vkMapMemory(device, mem.memory, aOffset, VK_WHOLE_SIZE, 0, @result));
end;

procedure TVulkanCompute.unMapMemory(const mem: TVulkanMemory);
begin
  vkUnMapMemory(device, mem.memory);
end;

procedure TVulkanCompute.pushToDevice(const aData: pointer; const mem: TVulkanMemory; N: NativeInt);
var
  d : pointer;
  //cmdInfo  : VkCommandBufferBeginInfo;
  stagingMem : TVulkanMemory;
begin
  assert(assigned(aData));
  if N<0 then N := mem.size;
  //Assert((not CommandBufferStarted) or (N<$10000), 'ERROR [PushtoDevice] : buffer is too big to push to device during command record state!, retry after calling EndCommandBuffer()');

  if CommandBufferStarted and (N<$10000) then begin
    // works only if N is less than (0x10000) 65536 bytes
    // offset and dataSize must be multiples of 4
    // buffers must be created with VK_BUFFER_USAGE_TRANSFER_DST_BIT
    vkCmdUpdateBuffer(cmd.Buffers[0], mem.buffer, 0, N, aData);
    //cmdInfo:= default(VkCommandBufferBeginInfo);
    //cmdInfo.sType:= VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    //SAFE_CALL(vkBeginCommandBuffer(cmdBuffer, ))
  end else
  if not (maDevice in mem.attributes) then begin
    d := mapMemory(mem);
    move(aData^, d^, N);
    unMapMemory(mem);
  end else begin
    stagingMem := createStagingMemory(N);
    d := mapMemory(stagingMem);
    move(aData^, d^, N);
    unMapMemory(stagingMem);
    beginCommadBuffer;
    copyBuffer(stagingMem, mem);
    endCommandBuffer;
    finish;
    freeMemory(stagingMem);
  end;
end;

procedure TVulkanCompute.pullFromDevice(const aData: pointer; const mem: TVulkanMemory; N: NativeInt);
var d : pointer;
    stagingMem : TVulkanMemory;
    cmdInfo  : VkCommandBufferBeginInfo;
    cmdStarted : boolean;
begin
  assert(assigned(aData));
  if N<0 then N := mem.size;
  if not (maDevice in mem.attributes) then begin
    d := mapMemory(mem);
    move(d^, aData^, N);
    unMapMemory(mem);
  end else begin
    stagingMem := createStagingMemory(N);
    cmdStarted := commandBufferStarted;
    if not cmdStarted then
      beginCommadBuffer;
    copyBuffer(mem, stagingMem);
    endCommandBuffer;
    finish;
    d := mapMemory(stagingMem);
    move(d^, aData^, N);
    unMapMemory(stagingMem);
    freeMemory(stagingMem);
    if cmdStarted then
      beginCommadBuffer;
  end;
end;

procedure TVulkanCompute.copyBuffer(const src, dst: TVulkanMemory);
var bc:VkBufferCopy;
begin
  assert(src.size=dst.size, 'ERROR [copyBuffer] : src and dst sizes are not equal.');
  // [TVulkanCompute.copyBuffer] todo check offset overflow also
  bc.srcOffset := 0;
  bc.dstOffset := 0;
  bc.size      := src.size;
  vkCmdCopyBuffer(cmd.Buffers[0], src.buffer, dst.buffer, 1, @bc);
end;

procedure TVulkanCompute.copyBuffer(const src, dst: TVulkanMemory; const aRegions: TArray<VkDeviceSize>);
var i, j:longint;
begin
  assert(assigned(aRegions) and (length(aRegions) mod 3=0), 'ERROR [copyBuffer] : aRegions length must be multiples of 3.');
  // [TVulkanCompute.copyBuffer] todo check offset overflow also
  for i:=0 to (length(aRegions) div 3)-1 do begin
    j := i*3;
    assert(aRegions[j]+aRegions[j+2]<=src.size, format('ERROR [copyBuffer] : region [%d] source parameters out of bounds!',[i]));
    assert(aRegions[j+1]+aRegions[j+2]<=dst.size, format('ERROR [copyBuffer] : region [%d] target parameters out of bounds!',[i]));
  end;
  vkCmdCopyBuffer(cmd.Buffers[0], src.buffer, dst.buffer, length(aRegions) div 3, pointer(aRegions));
end;

function TVulkanCompute.loadShader(const fileNameSpirV: RawByteString
  ): VkShaderModule;
var
  spirv : RawByteString;
  mInfo : VkShaderModuleCreateInfo;
begin
  //assert((index<0) or (index>=length(shaders)) or not assigned(shaders[index]), 'A shader at index ['+IntToStr(index)+'] is already loaded!');
  spirv := loadFile(fileNameSpirV);
  mInfo:=default(VkShaderModuleCreateInfo);
  mInfo.sType := VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
  mInfo.codeSize := length(spirv);
  mInfo.pCode := Puint32_t(spirv);
  SAFE_CALL(vkCreateShaderModule(device, @mInfo, nil, @result));
end;

procedure TVulkanCompute.preparePipeline(const Op: TKernelHandle;
  const shader: VkShaderModule; const localThreads: TWorkloadSizes);
type
  TVkDescriptorSetLayoutBindings = array[0..VULKAN_ARGS_MAX_BUFFERS_COUNT-1] of VkDescriptorSetLayoutBinding;
var
  //pl : TVulkanPipeline;
  i//, j, k
    : longint;
  descLayoutBinds : TVkDescriptorSetLayoutBindings;
  pCreateInfo     : VkPipelineLayoutCreateInfo;
  descCreateInfo  : VkDescriptorSetLayoutCreateInfo;
  pSpecialMap     : array [0..2] of VkSpecializationMapEntry;
  pSpecialInfo    : VkSpecializationInfo;
  pStageInfo      : VkPipelineShaderStageCreateInfo;
  pComputeInfo    : VkComputePipelineCreateInfo;
  descPoolSize    : VkDescriptorPoolSize;
  descPoolInfo    : VkDescriptorPoolCreateInfo;
  allocInfo       : VkDescriptorSetAllocateInfo;

begin
  //j := 0; k := 0;
  //if not Ops.TryGetValue(Op, pl) then begin
    descLayoutBinds := default(TVkDescriptorSetLayoutBindings);
    //for i:=0 to high(args) do begin
    for i:=0 to VULKAN_ARGS_MAX_CONSTANTS_COUNT-1 do begin
      //if args[i].argType = atPointer then begin
        DescLayoutBinds[i].binding := i;
        DescLayoutBinds[i].descriptorType := VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
        DescLayoutBinds[i].descriptorCount := 1;
        DescLayoutBinds[i].stageFlags := longword(VK_SHADER_STAGE_COMPUTE_BIT);
        //inc(j)
      //end;
    end;

    if Op > high(vulkanPipelines) then
      setLength(vulkanPipelines, Op+1)
    else
      vulkanPipelines[Op].free() ;
    descCreateInfo := default(VkDescriptorSetLayoutCreateInfo);
    descCreateInfo.sType:=VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
    descCreateInfo.bindingCount := VULKAN_ARGS_MAX_BUFFERS_COUNT;
    descCreateInfo.pBindings := @descLayoutBinds[0];


    //pl := default(TVulkanPipeline);
    // pushSize is set to TVulkanConstants.OP size (=4) plus the number of constants in
    // args multiplied by 4 aligning to the rest of TVulkanConstants
    vulkanPipelines[Op].device := device;
    SAFE_CALL(vkCreateDescriptorSetLayout(device, @descCreateInfo, nil, @vulkanPipelines[Op].descSetLayout));

    vulkanPipelines[Op].constantRange.stageFlags := longword(VK_SHADER_STAGE_COMPUTE_BIT);
    vulkanPipelines[Op].constantRange.size := VULKAN_ARGS_MAX_CONSTANTS_COUNT*4;
    pCreateInfo := default(VkPipelineLayoutCreateInfo);
    pCreateInfo.sType := VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
    pCreateInfo.setLayoutCount := 1;
    pCreateInfo.pSetLayouts := @vulkanPipelines[Op].descSetLayout;
    pCreateInfo.pushConstantRangeCount:=1;
    pCreateInfo.pPushConstantRanges := @vulkanPipelines[Op].constantRange;

    SAFE_CALL(vkCreatePipelineLayout(device, @pCreateInfo, nil, @vulkanPipelines[Op].pipelineLayout));

    pStageinfo := default(VkPipelineShaderStageCreateInfo);
    pStageInfo.sType := VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    pStageInfo.stage := VK_SHADER_STAGE_COMPUTE_BIT;
    // todo embed .spv files with in the executable resources
    pStageInfo.module := shader;//loadShader(SPIRVFile);//shaders[ord(Op)];
    pStageInfo.pName := 'main';
{
    for i:=low(pSpecialMap) to high(pSpecialMap) do begin
      pSpecialMap[i].constantID := i;
      pSpecialMap[i].offset := i*sizeof(longword);
      pSpecialMap[i].size := sizeof(longword);
    end;
    //pSpecialInfo := default(VkSpecializationInfo);
    pSpecialInfo.mapEntryCount:= length(pSpecialMap);
    pSpecialInfo.pMapEntries := @pSpecialMap;
    pSpecialInfo.dataSize := sizeOf(localThreads);
    pSpecialInfo.pData := @localThreads;

    pStageInfo.pSpecializationInfo:= @pSpecialInfo;
}
    vulkanPipelines[Op].shaderId      := Op;
    pComputeInfo := default(VkComputePipelineCreateInfo);
    pComputeInfo.sType := VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO;
    pComputeInfo.stage := pStageInfo;
    pComputeInfo.layout:= vulkanPipelines[Op].pipelineLayout;
    SAFE_CALL(vkCreateComputePipelines(device, nil, 1, @pComputeInfo, nil, @vulkanPipelines[Op].pipeline));

    descPoolSize.&type := VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
    descPoolSize.descriptorCount := VULKAN_ARGS_MAX_BUFFERS_COUNT;

    descPoolInfo := default(VkDescriptorPoolCreateInfo);
    descPoolInfo.sType := VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    descPoolInfo.maxSets := 1;
    descPoolInfo.poolSizeCount := 1;
    descPoolInfo.pPoolSizes := @descPoolSize;
    SAFE_CALL(vkCreateDescriptorPool(device, @descPoolInfo, nil, @vulkanPipelines[Op].descPool));

    AllocInfo := default(VkDescriptorSetAllocateInfo);
    AllocInfo.sType := VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
    AllocInfo.descriptorPool := vulkanPipelines[Op].descPool;
    AllocInfo.descriptorSetCount := 1;
    AllocInfo.pSetLayouts := @vulkanPipelines[Op].descSetLayout;
    SAFE_CALL(vkAllocateDescriptorSets(device, @AllocInfo, @vulkanPipelines[Op].descSet));
end;

procedure TVulkanCompute.preparePipeline(const Op: TKernelHandle;
  const shader: VkShaderModule);
const DEFAULT_WORKLOAD :TWorkloadSizes = (x:$100; y:1; z:1);
begin
  preparePipeline(Op, shader, DEFAULT_WORKLOAD);
end;

procedure TVulkanCompute.dispatchPipeline(const Op: TkernelHandle;
  const args: TVulkanArgs; const x: longword; const y: longword;
  const z: longword);
type
  TVukanDescWrites = array[0..VULKAN_ARGS_MAX_BUFFERS_COUNT-1] of VkWriteDescriptorSet;
  TVulkanDescBufferinfo = array [0..VULKAN_ARGS_MAX_BUFFERS_COUNT-1] of VkDescriptorBufferInfo;
var
  bufInfo : TVulkanDescBufferInfo;
  writes : TVukanDescWrites;
  i, j, k, off:longint;
  pl : TVulkanPipeline;
  constArgs : TVulkanConstants;
begin
  //if not Ops.TryGetValue(Op, pl) then exit;
  j :=0; k := 0;
  writes := default(TVukanDescWrites);
  for i:=0 to high(args) do begin
    case args[i].argType of
      atPointer : begin
        bufInfo[j].buffer := args[i].vPointer;
        bufInfo[j].offset := 0;
        bufInfo[j].range  := VK_WHOLE_SIZE;


        writes[j].sType := VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
        writes[j].dstSet := vulkanPipelines[Op].descSet;
        writes[j].dstBinding:= j;
        writes[j].descriptorCount := 1;
        writes[j].descriptorType := VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
        writes[j].pBufferInfo := @bufInfo[j];
        inc(j)
      end;
      //atSingle, atInt32
      atInt64, atUInt64, atDouble:begin
        PInt64(@constArgs[k])^ := args[i].vInt64;
        inc(k, 2)
      end;
      else
      begin
        constArgs[k] := args[i].vInt32;
        inc(k)
      end;
      //else
      //  assert(false,'ERROR dispatchPipeline : unsupported datatype');
    end;
  end;
  vkCmdBindPipeline(cmd.Buffers[0], VK_PIPELINE_BIND_POINT_COMPUTE, vulkanPipelines[Op].pipeline);
  vkUpdateDescriptorSets(device, j, @writes[0], 0, nil);
  vkCmdBindDescriptorSets(cmd.Buffers[0], VK_PIPELINE_BIND_POINT_COMPUTE, vulkanPipelines[Op].pipelineLayout, 0, 1, @vulkanPipelines[Op].descSet, 0, nil);
  vkCmdPushConstants(cmd.Buffers[0], vulkanPipelines[Op].pipelineLayout, longword(VK_SHADER_STAGE_COMPUTE_BIT), 0, k*sizeOf(longint), @constArgs[0] );
  vkCmdDispatch(cmd.Buffers[0], x, y, z);
end;

procedure TVulkanCompute.beginCommadBuffer;
var info : VkCommandBufferBeginInfo;
begin
  if CommandBufferStarted then exit;
  info := default(VkCommandBufferBeginInfo);
  info.sType:=VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
  SAFE_CALL(vkBeginCommandBuffer(cmd.Buffers[0], @info));
  CommandBufferStarted := true
end;

procedure TVulkanCompute.endCommandBuffer;
begin
  if not CommandBufferStarted then exit;
  SAFE_CALL(vkEndCommandBuffer(cmd.Buffers[0]));
  CommandBufferStarted := false
end;

procedure TVulkanCompute.finish;
var
  submitInfo:VkSubmitInfo;
begin
  endCommandBuffer;// will check if started and end it of so
  submitInfo := default(VkSubmitInfo);
  submitInfo.sType := VK_STRUCTURE_TYPE_SUBMIT_INFO;
  submitInfo.commandBufferCount:=1;
  submitInfo.pCommandBuffers := @cmd.Buffers[0];
  SAFE_CALL(vkResetFences(device, 1, @cmd.Fences[0]));
  SAFE_CALL(vkQueueSubmit(queue, 1, @submitInfo, cmd.Fences[0]));
  SAFE_CALL(vkWaitForFences(device, 1, @cmd.Fences[0], VK_TRUE, uInt64.MaxValue));

  //SAFE_CALL(vkQueueSubmit(queue, 1, @submitInfo, nil));
  //SAFE_CALL(vkQueueWaitIdle(queue));
  //SAFE_CALL(vkDeviceWaitIdle(device));
end;


function CEIL_DIV(const M, N:longword):longword; inline;
begin
  result := (M + N-1) div N
end;


//function max(const a,b:NativeInt):longword;inline; overload;
//begin
//  if a>=b then exit(a) else exit(b)
//end;

(*
function max(const a,b:nfloat):nfloat;inline; overload;
begin
  if a>=b then exit(a) else exit(b)
end;

function max(const a,b:NativeInt):nativeInt;inline; overload;
begin
  if a>=b then exit(a) else exit(b)
end;

//function min(const a,b:longword):longword;inline; overload;
//begin
//  if a<=b then exit(a) else exit(b)
//end;

function min(const a,b:nfloat):nfloat;inline; overload;
begin
  if a<=b then exit(a) else exit(b)
end;

function min(const a,b:nativeInt):nativeInt;inline; overload;
begin
  if a<=b then exit(a) else exit(b)
end;
*)

//function array_sum(const N:longword; const a:Pnfloat):nfloat; overload;
//var
//  i: longword;
//begin
//  if not assigned(a) or (N=0) then exit(0);
//  result := a[0];
//  for i:= 1 to N-1 do
//    result := result + a[i]
//end;

function array_sum(const N:longword; const a:Pnfloat):single; overload;
var
  i: longword;
begin
  if not assigned(a) or (N=0) then exit(0);
  result := single(a[0]);
  for i:= 1 to N-1 do
    result := result + single(a[i])
end;

//function array_sum(const a:TArray<nfloat>):nfloat; overload;
//begin
//  result := array_sum(length(a), pointer(a))
//end;

function array_sum(const a:TArray<nfloat>):single; overload;
begin
  result := array_sum(length(a), pointer(a))
end;

function array_max(const N:longword; const a:Pnfloat):nfloat;overload;
var
  i: longword;
begin
  if not assigned(a) or (N=0) then exit(0);
  result := a[0];
  for i:=1 to N-1 do
    result := math.max(result, a[i])
end;

function array_max(const a:TArray<nfloat>):nfloat;overload;
begin
  result := array_max(length(a), pointer(a))
end;

function array_min(const N:longword; const a:Pnfloat):nfloat;overload;
var
  i: longword;
begin
  if not assigned(a) or (N=0) then exit(0);
  result := a[0];
  for i:=1 to N-1 do
    result := math.min(result, a[i])
end;

function array_min(const a:TArray<nfloat>):nfloat;overload;
begin
  result := array_max(length(a), pointer(a))
end;

procedure array_min_max(const N:longword; const a:pnfloat; const _min, _max: Pnfloat); overload;
var i:longword;
begin
  assert(assigned(_min) and assigned(_max));
  _min^ := a[0];
  _max^ := a[0];
  for i:=1 to N-1 do begin
    _min^ := math.min(_min^, a[i]);
    _max^ := math.max(_max^, a[i])
  end;
end;

procedure array_min_max(const a:TArray<nfloat>; var _min, _max: nfloat);overload;
begin
  array_min_max(length(a), pointer(a), @_min, @_max)
end;

//function array_sum_sqr_diff(const N:longword; const a:Pnfloat; const b:nfloat):nfloat;overload;
//var i:longword;
//  diff , r:single;
//begin
//  if not assigned(a) or (N=0) then exit(0);
//  diff := a[0] - b;
//  r := sqr(diff);
//  for i:=1 to N-1 do begin
//    diff := a[i] - b;
//    r := r + sqr(diff);
//  end;
//  result := r
//end;

function array_sum_sqr_diff(const N:longword; const a:Pnfloat; const b:single):single;overload;
var i:longword;
  diff :single;
begin
  if not assigned(a) or (N=0) then exit(0);
  diff := single(a[0]) - b;
  result := sqr(diff);
  for i:=1 to N-1 do begin
    diff := single(a[i]) - b;
    result := result + sqr(diff);
  end;
end;

//function array_sum_sqr_diff(const a:TArray<nfloat>; const b:nfloat):nfloat;overload;
//begin
//  result := array_sum_sqr_diff(length(a), pointer(a), b);
//end;

function array_sum_sqr_diff(const a:TArray<nfloat>; const b:single):single;overload;
begin
  result := array_sum_sqr_diff(length(a), pointer(a), b);
end;

//function array_variance(const N:longword; const mean:nfloat; const a:Pnfloat):nfloat; overload;
//var
//  i:longword;
//begin
//  if not assigned(a) or (N=0) or (N=1) then exit(0);
//  result := array_sum_sqr_diff(N, a, mean)/(N-1);
//end;

function array_variance(const N:longword; const mean:single; const a:Pnfloat):single; overload;
var
  i:longword;
begin
  if not assigned(a) or (N=0) or (N=1) then exit(0);
  result := array_sum_sqr_diff(N, a, mean)/(N-1);
end;

//function array_variance(const N:longword; const a:Pnfloat):nfloat; overload;
//var mean : nfloat;
//begin
//  if not assigned(a) or (N=0) or (N=1) then exit(0);
//  mean := array_sum(N, a)/ N;
//  result := array_variance(N, mean, a)
//end;

function array_variance(const N:longword; const a:Pnfloat):single; overload;
var mean : single;
begin
  if not assigned(a) or (N=0) or (N=1) then exit(0);
  mean := array_sum(N, a)/ N;
  result := array_variance(N, mean, a)
end;

//function array_variace(const a:TArray<nfloat>):nfloat; overload;
//begin
//  result := array_variance(length(a), pointer(a))
//end;

function array_variace(const a:TArray<nfloat>):single; overload;
begin
  result := array_variance(length(a), pointer(a))
end;

procedure array_rand(const N:longword; const start, finish:nfloat; const a:Pnfloat);overload;
var
  i: longword;
  scal : nfloat;
begin
  scal := finish -start;
  for i:=0 to N-1 do
    a[i] := random()*scal + start;
end;

function array_rand(const N:longword; const start:single = -1;const finish:single = 1):TArray<nfloat>;  overload;
begin
  setLength(result, N);
  array_rand(N, start, finish, pointer(result));
end;

procedure array_linSpace(const N:longword; const start, finish:nfloat; const a:Pnfloat);overload;
var
  i: longword;
  scal : nfloat;
begin
  scal := finish - start;
  for i:=0 to N-1 do
    a[i] := start + i*scal/N;
end;

function array_linSpace(const N:longword; const start:single = -1;const finish:single = 1):TArray<nfloat>;  overload;
begin
  setLength(result, N);
  array_linSpace(N, start, finish, pointer(result))
end;

procedure array_add(const N:longword; const a, b, c:Pnfloat); overload;
var i:longword;
begin
  assert(assigned(a) and assigned(b) and assigned(c));
  for i:=0 to N-1 do
    c[i] := a[i] + b[i]
end;

procedure array_add(const a, b, c:TArray<nfloat>);  overload;
var i:longword;
begin
  assert(assigned(a) and assigned(b) and assigned(c));
  array_add(min(min(length(a), length(b)), length(c)), pointer(a), pointer(b), pointer(c))
end;

procedure array_axpy(const N:longword; const a: nfloat; const x, y:Pnfloat);
var i:longword;
begin
  assert(assigned(x) and assigned(y));
  for i:=0 to N-1 do
    y[i] := a*x[i] + y[i]
end;


procedure array_print(const N:longword; const a:Pnfloat; const decimals: word=2);overload;
var
  s, sv:ansistring;
  //i,
    w:integer;
  r, c, rows, cols:integer;
begin
  if not assigned(a) or (N=0) then exit;
  rows := round(sqrt(N));
  cols := N div rows;
  w := length(intToStr(round(array_max(n, a))));
  //str(single(a[0]):w:decimals, sv);
  //s := intToStr(0)+' : '+sv+slineBreak;
  s := '';
  for r:=0 to rows-1 do begin
    for c := 0 to cols-1 do begin
      str(single(a[r*cols + c]):w+decimals+1:decimals, sv);
      if c > 0 then s:= s + ',' + sv else s := s + sv;
    end;
    writeln(s);
    s := ''
  end;
  //writeln(s);
end;

procedure array_print(const a:TArray<nfloat>; const decimals: word=2);overload;
begin
  array_print(length(a), pointer(a), decimals)
end;

procedure array_stat(const N:longword; const a:Pnfloat; const decimals: word=2); overload;
var
  i :longword;
  mih, mah : nfloat;
  mi, ma, mean, variance: single;
begin
  array_min_max(N, a, @mih, @mah);
  mi := mih; ma := mah;
  mean := array_sum(N, a)/N;
  variance := array_variance(N, mean, a);
  i := max(length(intTostr(round(mi))), length(intToStr(round(ma))));
  i := max(i, max(length(intTostr(round(mean))), length(intToStr(round(variance)))));
  writeln('[',N,'] mean :', mean:i:decimals, ', stdDev :', sqrt(variance):i:decimals, ', min/max :', mi:i:decimals, '/', ma:i:decimals);
end;

procedure array_stat(const a:TArray<nfloat>; const decimals: word=2); overload;
begin
  array_stat(length(a), pointer(a), decimals)
end;

function array_sum_sqr_diff(const N:longword; const a,b:Pnfloat):single; overload;
var i:longword;
begin
  assert(assigned(a) and assigned(b));
  result :=0;
  for i:=0 to N-1 do
    result := result + sqr(single(a[i]-b[i]));
end;

function array_sum_sqr_diff(const a,b:TArray<nfloat>):single; overload;
begin
  result := array_sum_sqr_diff(length(a), pointer(a), pointer(b))
end;

//function abs(const x:half):half;inline;
//begin
//  result := abs(single(x));
//end;

function array_sum_abs_diff(const N: longword; const a, b: Pnfloat): single;
var i:longword;
begin
  assert(assigned(a) and assigned(b));
  result :=0;
  for i:=0 to N-1 do
    result := result + abs(single(a[i]-b[i]));
end;

function array_sum_abs_diff(const a, b: TArray<nfloat>): single;
begin
  result := array_sum_abs_diff(length(a), pointer(a), pointer(b))
end;

function array_max_abs_diff(const N: longword; const a, b: Pnfloat): single;
var i:longword;
begin
  assert(assigned(a) and assigned(b));
  result :=0;
  for i:=0 to N-1 do
    result := math.max(abs(single(a[i]-b[i])), result);
end;

function array_max_abs_diff(const a, b: TArray<nfloat>): single;
begin
  result := array_max_abs_diff(min(length(a), length(b)), pointer(a), pointer(b))
end;

procedure array_print_diff(const N:longword; const a,b:Pnfloat; const Eps: single=0.000001); overload;
const EPSILON = 0.0001;
var
  i: longword; diff, err, aDiff, aa:single;
begin
  for i:=0 to N-1 do begin
    diff := a[i]-b[i];
    aDiff := abs(diff);
    aa := abs(a[i]);
    if (aa<EPSILON) and (aDiff<EPSILON) then
      continue;
    if aa>0 then err := aDiff/aa else err := aDiff;
    if abs(err)> Eps then
      writeln('[',i,']: ',single(a[i]):1:6,' / ',single(b[i]):1:6);
  end;
end;

procedure array_print_diff(const a,b:TArray<nfloat>; const Eps: single=0.000001); overload;
begin
  array_print_diff(min(length(a), length(b)), pointer(a), pointer(b), Eps);
end;

procedure array_fma(const N:longword; const a,b :nfloat; const x, y:Pnfloat); overload;
var i:longint;
begin
  assert(assigned(x) and assigned(y));
  for i:=0 to N-1 do
    y[i] := a*x[i] + b;
end;

procedure array_fma(const a,b :nfloat; const x, y:TArray<nfloat>); overload;
begin
  array_fma(length(x), a, b, pointer(x), pointer(y))
end;

{$ifdef _CPUX64}

procedure saxpy_avx2(const N:longword; const a:single; const X, Y:Psingle);assembler;{$ifdef fpc}nostackframe;{$endif}
asm
{$ifndef fpc}
//.NOSTACK
{$endif}
  mov          eax ,  N
  and          eax ,  31
  vbroadcastss ymm1,  a
  shr          N   ,  5
  jz           @SKIP1
@while1:
  vmulps       ymm0, ymm1, yword [X]
  vaddps       ymm0, ymm0, yword [Y]

  vmulps       ymm2, ymm1, yword [X+32]
  vaddps       ymm2, ymm2, yword [Y+32]

  vmulps       ymm3, ymm1, yword [X+32*2]
  vaddps       ymm3, ymm3, yword [Y+32*2]

  vmulps       ymm4, ymm1, yword [X+32*3]
  vaddps       ymm4, ymm4, yword [Y+32*3]

  vmovups      yword [Y]     , ymm0
  vmovups      yword [Y+32]  , ymm2
  vmovups      yword [Y+32*2], ymm3
  vmovups      yword [Y+32*3], ymm4
  add          X   , 4*8*sizeof(single)
  add          Y   , 4*8*sizeof(single)
  dec          N
  jnz          @while1

@SKIP1:

  mov          N   , eax
  shr          N   , 3
  jz           @SKIP2
@while2:
  vmulps       ymm0, ymm1, yword [X]
  vaddps       ymm0, ymm0, yword [Y]
  vmovups      yword [Y], ymm0
  add          X   , 8*sizeof(single)
  add          Y   , 8*sizeof(single)
  dec          N
  jnz          @while2

@SKIP2:
  and          eax  , 7
  jz           @done
@while3:
  vmulss       xmm0, xmm1, dword [X]
  vaddss       xmm0, xmm0, dword [Y]
  movss        dword [Y], xmm0
  add          X   , sizeof(single)
  add          Y   , sizeof(single)
  dec          eax
  jnz          @while3

@done:
end;

procedure haxpy_avx2(const N:longword; const a:single; const X, Y:PHalf);assembler;//{$ifdef fpc}nostackframe;{$endif}
const RND = 0;
var ar:packed array[0..7] of word;
asm
{$ifndef fpc}
//.NOSTACK
{$endif}
  mov          eax ,  N
  and          eax ,  31
  vbroadcastss ymm1,  a
  //vcvtsh2ss    ymm1,  a
  shr          N   ,  5
  jz           @SKIP1
@while1:

// default lazarus freepascal (v3.2) does not support
// intels F16C instructions, using OP cods instead

  //vcvtph2ps    ymm0, [x]
  //vcvtph2ps    ymm5, [y]
  db $C4, $C2, $7D, $13, $00       // vcvtph2ps ymm0, [x]
  db $C4, $C2, $7D, $13, $29       // vcvtph2ps ymm5, [y]
  vmulps       ymm0, ymm1, ymm0
  vaddps       ymm0, ymm0, ymm5

  //vcvtph2ps    ymm2, [x+16]
  //vcvtph2ps    ymm5, [y+16]
  db $C4, $C2, $7D, $13, $50, $10  // vcvtph2ps ymm2, [x+$10]
  db $C4, $C2, $7D, $13, $69, $10  // vcvtph2ps ymm5, [y+$10]
  vmulps       ymm2, ymm1, ymm2
  vaddps       ymm2, ymm2, ymm5

  //vcvtph2ps    ymm3, [x+2*16]
  //vcvtph2ps    ymm5, [y+2*16]
  db $C4, $C2, $7D, $13, $58, $20  // vcvtph2ps ymm3, [x+$20]
  db $C4, $C2, $7D, $13, $69, $20  // vcvtph2ps ymm5, [y+$20]
  vmulps       ymm3, ymm1, ymm3
  vaddps       ymm3, ymm3, ymm5

  //vcvtph2ps    ymm4, [x+3*16]
  //vcvtph2ps    ymm5, [y+3*16]
  db $C4, $C2, $7D, $13, $60, $30  // vcvtph2ps ymm4, [x+$30]
  db $C4, $C2, $7D, $13, $69, $30  // vcvtph2ps ymm5, [y+$30]
  vmulps       ymm4, ymm1, ymm4
  vaddps       ymm4, ymm4, ymm5

  //vcvtps2ph    [Y]     , ymm0, RND
  //vcvtps2ph    [Y+16]  , ymm2, RND
  //vcvtps2ph    [Y+16*2], ymm3, RND
  //vcvtps2ph    [Y+16*3], ymm4, RND
  db $C4, $C3, $7D, $1D, $01, RND      //  vcvtps2ph [y]    , ymm0, RND
  db $C4, $C3, $7D, $1D, $51, $10, RND //  vcvtps2ph [y+$10], ymm2, RND
  db $C4, $C3, $7D, $1D, $59, $20, RND //  vcvtps2ph [y+$20], ymm3, RND
  db $C4, $C3, $7D, $1D, $61, $30, RND //  vcvtps2ph [y+$30], ymm4, RND

  add          X   , 4*8*sizeof(Half)
  add          Y   , 4*8*sizeof(Half)
  dec          N
  jnz          @while1

@SKIP1:

  mov          N   , eax
  shr          N   , 3
  jz           @SKIP2
@while2:
  //vcvtph2ps    ymm0, [x]
  //vcvtph2ps    ymm5, [y]
  db $C4, $C2, $7D, $13, $00           // vcvtph2ps ymm0, [x]
  db $C4, $C2, $7D, $13, $29           // vcvtph2ps ymm5, [y]
  vmulps       ymm0, ymm1, ymm0
  vaddps       ymm0, ymm0, ymm5
  //vcvtps2ph    [Y], ymm0, RND
  db $C4, $C3, $7D, $1D, $01, RND      //  vcvtps2ph [y]    , ymm0, RND
  add          X   , 8*sizeof(half)
  add          Y   , 8*sizeof(half)
  dec          N
  jnz          @while2

@SKIP2:
  and          eax  , 7
  jz           @done

  //vcvtph2ps    ymm0, [x]
  //vcvtph2ps    ymm5, [y]
  db $C4, $C2, $7D, $13, $00           // vcvtph2ps ymm0, [x]
  db $C4, $C2, $7D, $13, $29           // vcvtph2ps ymm5, [y]
  vmulps       ymm0, ymm1, ymm0
  vaddps       ymm0, ymm0, ymm5
  //vcvtps2ph    ar  , ymm0, RND       // storing to the stack
  db $C4, $E3, $7D, $1D, $45, $F0, RND //  vcvtps2ph [rbp-$10], ymm0, RND
@while3:
  dec          eax
  mov          cx ,  word [ar + rax*2]
  mov          word [y + rax*2],  cx
  jnz          @while3

@done:
end;

{$endif}

//type
//  blasint = longint;
//  CBLAS_Layout = (CblasRowMajor = 101, CblasColMajor = 102);
//  CBLAS_ORDER = CBLAS_Layout;
//  CBLAS_TRANSPOSE = (CblasNoTrans = 111, CblasTrans = 112, CblasConjTrans = 113, CblasConjNoTrans = 114);
//procedure cblas_sgemm(Order:CBLAS_ORDER; TransA:CBLAS_TRANSPOSE; TransB:CBLAS_TRANSPOSE; M:blasint; N:blasint; K:blasint; alpha:single; A:Psingle; lda:blasint; B:Psingle; ldb:blasint; beta:single; C:Psingle; ldc:blasint); winapi ; external 'libopenblas.dll';


{$T+}
procedure array_gemm_nn(const M,N,K : longword; const ALPHA:single; const A:TArray<nfloat>; const lda:longword; const B:TArray<nfloat>; const ldb:longword; const BETA:single; const C:TArray<nfloat>; const ldc:longword); overload;
begin
  TQNNSingleOPS.cblas_sgemm(CBLAS_Layout.CblasRowMajor, CBLAS_TRANSPOSE.CblasNoTrans, CBLAS_TRANSPOSE.CblasNoTrans, M, N, K, ALPHA, pnfloat(A), lda, pnfloat(B), ldb, BETA, pnfloat(C), ldc);
end;

procedure array_gemm_nt(const M,N,K : longword; const ALPHA:single; const A:TArray<nfloat>; const lda:longword; const B:TArray<nfloat>; const ldb:longword; const BETA:single; const C:TArray<nfloat>; const ldc:longword); overload;
begin
  TQNNSingleOPS.cblas_sgemm(CBLAS_Layout.CblasRowMajor, CBLAS_TRANSPOSE.CblasNoTrans, CBLAS_TRANSPOSE.CblasTrans, M, N, K, ALPHA, pnfloat(A), lda, pnfloat(B), ldb, BETA, pnfloat(C), ldc)
end;

procedure array_gemm_tn(const M,N,K : longword; const ALPHA:single; const A:TArray<nfloat>; const lda:longword; const B:TArray<nfloat>; const ldb:longword; const BETA:single; const C:TArray<nfloat>; const ldc:longword); overload;
begin
  TQNNSingleOPS.cblas_sgemm(CBLAS_Layout.CblasRowMajor, CBLAS_TRANSPOSE.CblasTrans, CBLAS_TRANSPOSE.CblasNoTrans, M, N, K, ALPHA, pnfloat(A), lda, pnfloat(B), ldb, BETA, pnfloat(C), ldc)
end;
{$T-}

var FPUMask : TFPUExceptionMask;

  i : longint;
initialization
  //assert(SetEnvironmentVariableA('VK_LAYER_PRINTF_ONLY_PRESET', '1'), 'Cannot set Vulkan ENV for debugging!');
  //assert(SetEnvironmentVariableA('VK_LAYER_PRINTF_ENABLE ', '1'), 'Cannot set Vulkan ENV for debugging!');
  //assert(SetEnvironmentVariableA('VK_LAYER_PRINTF_TO_STDOUT', '1'), 'Cannot set Vulkan ENV for debugging!');

  FPUMask := GetExceptionMask;
  SetExceptionMask([exInvalidOp] + FPUMask);
  TVulkanCompute.CreateInstance(ExtractFileName(paramStr(0)));
  TVulkanCompute.VulkanDevices := TVulkanCompute.QueryPhysicalDevices();
  if isConsole then
    for i:=0 to high(TVulkanCompute.VulkanDevices) do
      writeln(i, ' ',TVulkanCompute.VulkanDevices[i].deviceProperties.properties.deviceName);
  //SetExceptionMask(FPUMask);


finalization
  //vkGetMemoryWin32HandleKHR := nil;
  //UnloadLibrary(vklib);
  TVulkanCompute.DestroyInstance();

end.

