//{$apptype console}
unit quicknn_vulkan;

{$ifdef FPC}
  {$PackRecords C}
  {$mode Delphi}
  {$modeswitch advancedrecords}
  {$modeswitch typehelpers}
  {$modeswitch nestedprocvars}
  {$ifdef CPUX64}
    {$asmmode intel}
  {$endif}
{$endif}
{$TYPEINFO ON} // include typeinfo
{$C+} // enable assertions
{$H+}
{$pointermath on}
{$T+}
{$Z4}  // enums ar aligned to 4 bytes to match C API


interface
uses Sysutils, math, TypInfo, nVulkanHelper;

const AC_SWISH = 18;
type
  TQNNOperation = (
        vkopAdd
      , vkopSub
      , vkopMul
      , vkopActivate
      , vkopAxpy
      , vkopFill
      , vkopCopy
      , vkopFused_mul_add
      , vkopFused_add_add
      , vkopFused_add_mul
      , vkopFused_scale_bias
      , vkopFused_bias_scale
      , vkopFused_mul_scale
      , vkopFused_bias_mul_scale
      , vkopFused_scale_add
      , vkopFused_bias_add
      , vkopForward_bias
      , vkopMean
      , vkopVariance
      , vkopSoftmax
      , vkopUpsample
      , vkopNorm
      , vkopScale
      , vkopBias
      , vkopIm2Col
      , vkopGemm_nn
      , vkopGemm_nt
      , vkopGemm_tn
      , vkopGemm_nn_WarpTiling
      , vkopGemm_nt_WarpTiling
      , vkopGemm_tn_WarpTiling
    );



  { TQNNVulkan }

  TQNNVulkan = class(TVulkanCompute)

    procedure preparePipeline(const op:TQNNOperation);overload;
    procedure dispatchPipeline(const Op: TQNNOperation; const args: TVulkanArgs; const x:longword; const y:longword = 1; const z:longword =1); overload;
    procedure sgemm(const tranA, tranB:boolean; M, N, K :longint; const ALPHA :single; const A :PSingle; const lda :longint; const B:PSingle; const ldb :longint; const BETA :single; const C :PSingle; const ldc :longint);
    // always raw major
    procedure gemm(const tranA, tranB: boolean; const M, N, K: longint; const ALPHA: single; const A: TVulkanMemory; const lda: longint; const B: TVulkanMemory; const ldb: longint; const BETA: single; const C: TVulkanMemory; const ldc: longint);

    procedure QNNAdd(const dst, a, b: TVulkanMemory; const N:integer);
    procedure QNNAddInplace(const dst, a: TVulkanMemory; const N:integer);   overload;
    procedure QNNMul(const dst, a, b: TVulkanMemory; const N:integer);   overload;
    procedure QNNMulInplace(const dst, a: TVulkanMemory; const N:integer);   overload;
    procedure QNNScale(const dst, src:TVulkanMemory; const aScale:Single; const N:longint);   overload;
    procedure QNNScaleInplace(const dst: TVulkanMemory; const aScale: Single; const N: longint);overload;
    procedure QNNBias(const dst, src:TVulkanMemory; const aBias:Single; const N:longint);overload;
    procedure QNNBiasInplace(const dst:TVulkanMemory; const aBias:Single; const N:longint);overload;
    procedure QNNFusedMulAdd(const dst, src, srcM, srcA:TVulkanMemory; const N:longint);overload;
    procedure QNNFusedAddMul(const dst, src, srcA, srcM:TVulkanMemory; const N:longint);overload;
    procedure QNNFusedScaleBias(const dst, src:TVulkanMemory; const aScale, aBias:Single; const N:longint);overload;
    procedure QNNFusedBiasScale(const dst, src:TVulkanMemory; const aBias, aScale:Single; const N:longint);overload;
    procedure QNNFusedMulScale(const dst, src1, src2:TVulkanMemory; const aScale:Single; const N:longint);overload;
    procedure QNNFusedBiasMulScale(const dst, src, srcM:TVulkanMemory; const aBias, aScale:Single; const N:longint);overload;
    procedure QNNFusedScaleAdd(const dst, src, srcAdd:TVulkanMemory; const aScale:Single; const N:longint); overload;
    procedure QNNFusedBiasAdd(const dst, src, srcA:TVulkanMemory; const aBias:Single; const N:longint); overload;
    //function QNNDot(const a, b:TVulkanMemory; const N:longint):Single;
    procedure QNNAccAdd(const dst, a, b: TVulkanMemory; const N:integer);   overload;
    procedure QNNAccMul(const dst, a, b: TVulkanMemory; const N:integer);   overload;
    procedure QNNForwardBias(const dst, aBias:TVulkanMemory;const N, blockSize:integer; biasSize:integer = 0);// dst[i] = (i div blockSize) % biasSize
    procedure QNNMatMulNN(const C, A, B: TVulkanMemory; const M, K, N:integer);   overload;
    procedure QNNMatMulNT(const C, A, B: TVulkanMemory; const M, K, N:integer);   overload;
    procedure QNNMatMulTN(const C, A, B: TVulkanMemory; const M, K, N:integer);   overload;
    //procedure QNNMatTranspose(const dst, src: TVulkanMemory; const srcRows, srcCols: longint; srcStride:longint=0; dstStride:longint=0);
    procedure QNNLinear(const dst, x, W, B:TVulkanMemory; const seqLen, inDIM, outDIM: integer);
    procedure QNNLinearNoBias(const dst, x, W:TVulkanMemory; const seqLen, inDIM, outDIM: integer);
    //procedure QNNLinearNoBias_BF16(const dst, x:TVulkanMemory; const W: TVulkanMemory; const seqLen, inDIM, outDIM: integer);
    procedure QNNIm2Col(const aChannels, aHeight, aWidth
                     , kernelHeight, kernelWidth
                     , padHeight, padWidth
                     , strideY, strideX
                     , dilationY, dilationX: integer
                     ; const im: TVulkanMemory; const col: TVulkanMemory);
                     //; const imOffset: integer =0 ; const colOffset: integer =0);

    procedure QNNIm2ColStridedBatched(const aChannels, aHeight, aWidth
                     , kernelHeight, kernelWidth, padHeight, padWidth
                     , strideY, strideX, dilationY, dilationX: integer
                     ; const im: TVulkanMemory; const imStride: integer
                     ; const col: TVulkanMemory; const colStride: integer
                     ; const batch:integer);

    procedure QNNConv2d( const dst, src, weights, bias:TVulkanMemory;
                    const in_ch, out_ch, H, W, kH, kW, stride, padding:longint; const batch:longint =1);

    procedure QNNNorm(const N:longint; const dst, src:TVulkanMemory; const weights:TVulkanMemory; const stride:longint = 1);      overload;

    procedure QNNRMSNorm(const N:longint; const dst, src:TVulkanMemory; const weights:TVulkanMemory; const stride:longint = 1);   overload;
    procedure QNNRMSNormRows(const dst, src, weight:TVulkanMemory; const rows, dim: integer); overload;
    procedure QNNTanh(const dst:TVulkanMemory; const N:longint);

    procedure QNNQKRMSNorm(const Q, K, QWeights, KWeights:TVulkanMemory; const seq, heads, headDim:longint); overload;
    procedure QNNRMSNormSeq(const dst, normWeights:TVulkanMemory; const seq, heads, headDim:longint); overload;

    procedure QNNGroupNorm(const dst, src, gamma, beta : TVulkanMemory; const batch, channels, H, W, num_groups:integer);
    procedure QNNBatchNorm(const dst, src, running_mean, running_var, gamma, beta : TVulkanMemory; const batch, channels, H, W: integer);

    procedure QNNMinMax(const N:integer; const src:TVulkanMemory; out outMin, outMax: Single; const argMin: PInteger; const argMax:PInteger = nil; const stride:integer=1);
    function QNNMax(const N:integer; const src:TVulkanMemory; const arg:PInteger = nil; const stride:integer=1):Single;
    function QNNMin(const N:integer; const src:TVulkanMemory; const arg:PInteger = nil; const stride:integer=1):Single;
    function QNNMaxAbs(const N:integer; const src:TVulkanMemory; const stride:integer=1):Single;
    function QNNMinAbs(const N:integer; const src:TVulkanMemory; const stride:integer=1):Single;
    function QNNArgMax(const N:integer; const src:TVulkanMemory; const stride:integer=1):integer;
    function QNNArgMin(const N:integer; const src:TVulkanMemory; const stride:integer=1):integer;
    function QNNSum(const N:integer; const src:TVulkanMemory; const stride:integer=1):Single;
    function QNNSumSqr(const N:integer; const src:TVulkanMemory; const stride:integer=1):Single;
    function QNNSumSqrDiff(const N: integer; const src:TVulkanMemory; const aMean:Single; const stride:integer=1):Single;overload;
    function QNNSqrDistance(const N: integer; const src1, src2:TVulkanMemory; const stride:integer=1):Single;overload;
    function QNNMaxAbsDiff2(const N: integer; const src1, src2: TVulkanMemory; out outSrc1, outSrc2:Single; const stride: integer=1): Single; overload;
    function QNNMaxAbsDiff(const N: integer; const src1, src2: TVulkanMemory; const stride: integer=1): Single; overload;
    function QNNSumAbsDiff(const N: integer; const src1, src2: TVulkanMemory; const stride: integer=1): Single;  overload;
    function QNNSumAbsDiffScalar(const N: integer; const src: TVulkanMemory; const aMean:Single; const stride: integer=1): Single;  overload;
    function QNNMean(const N:integer; const src:TVulkanMemory; const stride:integer=1):Single;
    function QNNVariance(const N:integer; const src:TVulkanMemory; const aMean:Single; const stride:integer=1; const isPopulation:boolean=true):Single;
    procedure QNNSigmoidInplace(const x: TVulkanMemory; const N:integer); overload;
    procedure QNNSigmoid(const dst, src: TVulkanMemory; const N:integer); overload;
    procedure QNNSiluInplace(const x:TVulkanMemory; const N:integer);     overload;
    procedure QNNSilu(const dst, src:TVulkanMemory; const N:integer);     overload;
    procedure QNNSiluMul(const gate, up:TVulkanMemory; const N:integer);
    procedure QNNSoftmax(const x: TVulkanMemory; const N: integer); overload;
    procedure QNNSoftmaxRows(const x: TVulkanMemory; const rows, cols: integer); overload;
    procedure QNNAttention(const dst, Q, K, V: TVulkanMemory; const batch, heads, seq_q, seq_k, head_dim: longint; const scale: Single);
    //procedure QNNFlashAttentionHead(const dst, Q, K, V: TVulkanMemory; const seq_q, seq_k, head_dim: longint; const scale: Single);
    //procedure QNNFlashAttentionHeadTiled(const dst, Q, K, V: TVulkanMemory; const seq_q, seq_k, head_dim: longint;
    //                const scale: Single; const tile_scores: TVulkanMemory; const q_tile_size, k_tile_size: longint);
    procedure QNNFlashAttention(const dst, Q, K, V: TVulkanMemory; const heads, seq_q, seq_k, head_dim: longint; const scale: Single);
    procedure QNNUpSampleNearest(const dst, src: TVulkanMemory; const batch, channels, H, W, scale_h, scale_w: longint);
    procedure QNNUpSample(const dst, src: TVulkanMemory; const batch, channels, H, W:longint; const scale_h, scale_w: Single; const interpolation:longint);
    procedure QNNPatchify(const dst, src: TVulkanMemory; const batch, channels, H, W, patch_size: longint);
    procedure QNNUnpatchify(const dst, src: TVulkanMemory; const batch, channels, H, W, patch_size: longint);
    procedure QNNPermut(const dst, src:TVulkanMemory; const axisPerm:TArray<byte>; const inShape:TArray<int64>; var outShape:TArray<Int64>);
    procedure QNNReduce(const dst, src: TVulkanMemory; const inShape, reduceAxes: TArray<int64>; const reduceOp: longint; const divideByCount: boolean; out outShape: TArray<int64>; const keepDims: boolean = false); overload;
    procedure QNNCopy(const dst, src:TVulkanMemory; const N:integer); overload;
    procedure QNNCopyStrided(const dst:TVulkanMemory; const dstStride:integer; const src:TVulkanMemory; const srcStride: integer; const N:integer); overload;
    procedure QNNFill(const dst:TVulkanMemory; const val:Single; const N:integer; const stride:integer=1);
    procedure QNNBroadcast(const dst:pointer; const src; const srcSize, N:integer; const stride:integer=1);
    procedure QNNGatedAdd(const dst, gate, proj:TVulkanMemory; const seq, hidden:integer);
    procedure QNNComputeRoPE(const dst:TVulkanMemory; const maxSeq, dim:longint; const theta:Single);           overload;
    procedure QNNComputeRoPE(const cosOut,sinOut:TVulkanMemory; const maxSeqLen, headDim:longint; const theta:Single); overload;
    procedure QNNComputeRoPE2D(const cosDst,sinDst:TVulkanMemory; const patch_h, patch_w, dim:longint; const theta:Single);
    procedure QNNComputeRoPE2DOffset(const cosDst,sinDst:TVulkanMemory; const patch_h, patch_w, dim:longint; const theta:Single; const offset_t:longint);
    procedure QNNComputeRoPEText(const cosDst, sinDst: TVulkanMemory; const txt_seq, axis_dim: longint; const theta: Single);
    procedure QNNApplyRoPE(const dst, freqs: TVulkanMemory; const batch, seq, heads, head_dim: longint);        overload;
    procedure QNNApplyRoPE2(const dst, cosIn, sinIn: TVulkanMemory; const numHeads, headDim: longint); overload;
    procedure QNNApplyRoPE3(const dst, cosIn, sinIn: TVulkanMemory; const seqLen, numHeads, headDim: longint); overload;
    procedure QNNApplyRoPEQK(const q, k, cos_cache, sin_cache:TVulkanMemory; const seq_len, num_q_heads, num_kv_heads, head_dim:longint); overload;
    procedure QNNApplyRoPE2D(const dst, cos_freq, sin_freq : TVulkanMemory; const seq, heads, head_dim, dim: longint);
    function QNNTimeStepEmbedding(const t : Single;const dim:integer; const max_period:Single):TVulkanMemory;
    procedure QNNMatTriangularFill(const dim:integer; const dst:TVulkanMemory; const val:Single; const mask:PLongint=nil);
    procedure QNNMaskFill(const dst: TVulkanMemory; const mask:PLongint; const val:Single; const rows, cols:longint);
    procedure QNNAdaLN(const dst, src, bias, scale:TVulkanMemory; const seq, hidden:longint; const eps:Single = 0.00001);
    procedure QNNLINEAR_BF16_OR_F32(const dst, src:TVulkanMemory; const weight:TVulkanMemory; const weight_bf16:TVulkanMemory; const seq, srcDim, dstDim:integer);inline;

  end;

implementation
uses quicknncpu, nChrono;

function ceil(const a, b: longint):longint;overload;
begin
  result := (1 + (a-1) div b)*b
end;

{ TQNNVulkan }

procedure TQNNVulkan.preparePipeline(const op: TQNNOperation);
begin
  // todo Embed SPIRV files
  preparePipeline(longint(op), loadShader('../../../src/vulkan/spv/'+copy(LowerCase(getEnumName(TypeInfo(TQNNOperation), ord(op))), 5) + '.comp.float.spv'));
end;

procedure TQNNVulkan.dispatchPipeline(const Op: TQNNOperation;
  const args: TVulkanArgs; const x: longword; const y: longword;
  const z: longword);
begin
  dispatchPipeline(TKernelHandle(op), args, x, y, z);
end;

procedure TQNNVulkan.sgemm(const tranA, tranB: boolean; M, N, K: longint;
  const ALPHA: single; const A: PSingle; const lda: longint; const B: PSingle;
  const ldb: longint; const BETA: single; const C: PSingle; const ldc: longint);
const
  BN = 128;
  BM = 128;
  WORKGROUP_SIZE_X = 8 ; // 128;
  WORKGROUP_SIZE_Y = 8; //1;
  WORKGROUP_SIZE_Z = 1;
var aSize, bSize,cSize : int64;
    vkA, vkB, vkC : TVulkanMemory;

begin
  assert(not tranA , 'TVulknCompte.sgemm : not implemrnted with the current arguments!');

  if tranA then begin
    aSize := K*lda*sizeof(single);
    //if vkA.size < aSize then
    begin
      if vkA.size > 0 then
        Self.freeMemory(vkA);
      vkA := createStorageMemory(aSize);
    end
  end else begin
    aSize := M*lda*sizeof(single);
    //if vkA.size < aSize then
    begin
      if vkA.size > 0 then
        Self.freeMemory(vkA);
      vkA := createStorageMemory(aSize);
    end;
  end;

  if tranB then begin
    bSize := N*ldb*sizeof(single);
    //if vkB.size <bSize then
    begin
      if vkB.size > 0 then
        Self.freeMemory(vkB);
      vkB := createStorageMemory(bSize);
    end
  end else begin
    bSize :=  K*ldb*sizeof(single);
    //if vkB.size < bSize then
    begin
      if vkB.size > 0 then
        Self.freeMemory(vkB);
      vkB := createStorageMemory(bSize);
    end;
  end;

  cSize := M*ldc*sizeof(single);
  //if vkC.size < cSize then
  begin
    if vkC.size > 0 then
      Self.freeMemory(vkC);
    vkC := createStorageMemory(cSize);
  end;




  pushToDevice(A, vkA);
  pushToDevice(B, vkB);
  pushToDevice(C, vkC);

  beginCommadBuffer;

  if (not tranA) and (not tranB) then begin
    if (high(vulkanPipelines)<ord(vkopGemm_nn)) or not assigned(vulkanPipelines[ord(vkopGemm_nn)].pipeline) then
      preparePipeline(vkopGemm_nn);
    //dispatchPipeline(vkopGemm_nn_WrapTiling, [M, N, K, ALPHA, vkA.buffer, 0, lda, vkB.buffer, 0, ldb, BETA, vkC.buffer, 0, ldc],
    //                               CEIL_DIV(N, BN), CEIL_DIV(M, BM)
    //                    )
    dispatchPipeline(vkopGemm_nn, [M, N, K, 1.0, vkA.buffer, 0, lda, vkB.buffer, 0, ldb, 0.0, vkC.buffer, 0, ldc],
                                   (M + WORKGROUP_SIZE_X-1) div WORKGROUP_SIZE_X,
                                   (N + WORKGROUP_SIZE_Y-1) div WORKGROUP_SIZE_Y,
                                   1 //(K+WORKGROUP_SIZE_Z-1) div WORKGROUP_SIZE_Z
                        )
  end
  else if (not tranA) and tranB then begin
    if (high(vulkanPipelines)<ord(vkopGemm_nt)) or not assigned(vulkanPipelines[ord(vkopGemm_nt)].pipeline) then
      preparePipeline(vkopGemm_nt);
    //dispatchPipeline(vkopGemm_nt_WrapTiling, [M, N, K, ALPHA, vkA.buffer, 0, lda, vkB.buffer, 0, ldb, BETA, vkC.buffer, 0, ldc],
    //                               CEIL_DIV(N, BN), CEIL_DIV(M, BM)
    //                    );
    dispatchPipeline(vkopGemm_nt, [M, N, K, ALPHA, vkA.buffer, 0, lda, vkB.buffer, 0, ldb, BETA, vkC.buffer, 0, ldc],
                                   (M + WORKGROUP_SIZE_X-1) div WORKGROUP_SIZE_X,
                                   (N + WORKGROUP_SIZE_Y-1) div WORKGROUP_SIZE_Y
                    );
  end;
  if CommandBufferStarted then begin
    endCommandBuffer;
    finish
  end;
  pullFromDevice(C, vkC, cSize);

end;

procedure TQNNVulkan.gemm(const tranA, tranB: boolean; const M, N, K: longint; const ALPHA: single; const A: TVulkanMemory; const lda: longint; const B: TVulkanMemory; const ldb: longint; const BETA: single; const C: TVulkanMemory; const ldc: longint);
const
  BN = 128;
  BM = 128;

  // naive gemm
  WORKGROUP_SIZE_X = 64; // 128;
  WORKGROUP_SIZE_Y = 128; //1;
  WORKGROUP_SIZE_Z = 1;

begin
  assert(not tranA , 'TVulknCompte.sgemm : not implemrnted with the current arguments!');



  //if not(
  //    (high(vulkanPipelines) > max(longint(opGemm_nn_WrapTiling), longint(opGemm_nt))) and
  //    assigned(vulkanPipelines[longint(opGemm_nn_WrapTiling)].pipeline) and
  //    assigned(vulkanPipelines[longint(opGemm_nt_WrapTiling)].pipeline)
  //  ) then begin
  //    preparePipeline(opGemm_nn_WrapTiling);
  //    preparePipeline(opGemm_nn);
  //    preparePipeline(opGemm_nt_WrapTiling);
  //end;


  if (not tranA) and (not tranB) then begin
    if (high(vulkanPipelines)<ord(vkopGemm_nn_WarpTiling)) or not assigned(vulkanPipelines[ord(vkopGemm_nn_WarpTiling)].pipeline) then
      preparePipeline(vkopGemm_nn_WarpTiling);
    if not CommandBufferStarted then beginCommadBuffer;
    dispatchPipeline(vkopGemm_nn_WarpTiling,
    [M, N, K, ALPHA, A.buffer, A.offset, lda, B.buffer, B.offset, ldb, BETA, C.buffer, C.offset, ldc],
                                   CEIL_DIV(N, BN), CEIL_DIV(M, BM)
                        )
    //dispatchPipeline(vkopGemm_nn, [M, N, K, ALPHA, A.buffer, A.offset, lda, B.buffer, B.offset, ldb, BETA, C.buffer, C.offset, ldc],
    //                               (M + WORKGROUP_SIZE_X-1) div WORKGROUP_SIZE_X,
    //                               (N + WORKGROUP_SIZE_Y-1) div WORKGROUP_SIZE_Y,
    //                               (K + WORKGROUP_SIZE_Z-1) div WORKGROUP_SIZE_Z
    //                    );
  end
  else if (not tranA) and tranB then begin
    if (high(vulkanPipelines)<ord(vkopGemm_nt)) or not assigned(vulkanPipelines[ord(vkopGemm_nt)].pipeline) then
      preparePipeline(vkopGemm_nt);
    if not CommandBufferStarted then beginCommadBuffer;
    //dispatchPipeline(opGemm_nt_WrapTiling, [M, N, K, ALPHA, A.buffer, offsetA, lda, B.buffer, offsetB, ldb, BETA, C.buffer, offsetC, ldc],
    //                               CEIL_DIV(N, BN), CEIL_DIV(M, BM)
    //                    );
    dispatchPipeline(vkopGemm_nt, [M, N, K, ALPHA, A.buffer, A.offset, lda, B.buffer, B.offset, ldb, BETA, C.buffer, C.offset, ldc],
                                   (M + WORKGROUP_SIZE_X-1) div WORKGROUP_SIZE_X,
                                   (N + WORKGROUP_SIZE_Y-1) div WORKGROUP_SIZE_Y,
                                   (K + WORKGROUP_SIZE_Z-1) div WORKGROUP_SIZE_Z
                      );
  end else if tranA and (not tranB) then begin
    if (high(vulkanPipelines)<ord(vkopGemm_tn)) or not assigned(vulkanPipelines[ord(vkopGemm_tn)].pipeline) then
      preparePipeline(vkopGemm_tn);
    if not CommandBufferStarted then beginCommadBuffer;
    //dispatchPipeline(opGemm_tn_WrapTiling, [M, N, K, ALPHA, A.buffer, offsetA, lda, B.buffer, offsetB, ldb, BETA, C.buffer, offsetC, ldc],
    //                               CEIL_DIV(N, BN), CEIL_DIV(M, BM)
    //                    );
    dispatchPipeline(vkopGemm_tn, [M, N, K, ALPHA, A.buffer, A.offset, lda, B.buffer, B.offset, ldb, BETA, C.buffer, C.offset, ldc],
                                   (M + WORKGROUP_SIZE_X-1) div WORKGROUP_SIZE_X,
                                   (N + WORKGROUP_SIZE_Y-1) div WORKGROUP_SIZE_Y,
                                   (K + WORKGROUP_SIZE_Z-1) div WORKGROUP_SIZE_Z
                      );
  end;

end;

const LOCAL_WG_SIZE =$100;

procedure TQNNVulkan.QNNAdd(const dst, a, b: TVulkanMemory; const N: integer);
const op = vkopAdd;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [a, b, dst, N, a.offset, 1, b.offset, 1, dst.offset, 1], CEIL_DIV(N, LOCAL_WG_SIZE))

end;

procedure TQNNVulkan.QNNAddInplace(const dst, a: TVulkanMemory; const N: integer);
const op = vkopAdd;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [a, dst, dst, N, a.offset, 1, dst.offset, 1, dst.offset, 1], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNMul(const dst, a, b: TVulkanMemory; const N: integer);
const op = vkopMul;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [a, b, dst, N, a.offset, 1, b.offset, 1, dst.offset, 1], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNMulInplace(const dst, a: TVulkanMemory; const N: integer);
const op = vkopMul;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [a, dst, dst, N, a.offset, 1, dst.offset, 1, dst.offset, 1], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNScale(const dst, src: TVulkanMemory; const aScale: Single;
  const N: longint);
const op = vkopScale;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [src, dst, N, dst.offset, 1, aScale], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNScaleInplace(const dst: TVulkanMemory; const aScale: Single;
  const N: longint);
const op = vkopScale;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [dst, dst, N, dst.offset, 1, aScale], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNBias(const dst, src: TVulkanMemory; const aBias: Single;
  const N: longint);
const op = vkopBias;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [src, dst, N, dst.offset, 1, aBias], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNBiasInplace(const dst: TVulkanMemory; const aBias: Single;
  const N: longint);
const op = vkopBias;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [dst, dst, N, dst.offset, 1, aBias], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNFusedMulAdd(const dst, src, srcM, srcA: TVulkanMemory;
  const N: longint);
const op = vkopFused_mul_add;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [src, srcM, srcA, dst, N, src.offset, 1, srcM.offset, 1, srcA.offset, 1, dst.offset, 1], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNFusedAddMul(const dst, src, srcA, srcM: TVulkanMemory;
  const N: longint);
const op = vkopFused_add_mul;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [src, srcA, srcM, dst, N, src.offset, 1, srcA.offset, 1, srcM.offset, 1, dst.offset, 1], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNFusedScaleBias(const dst, src: TVulkanMemory; const aScale,
  aBias: Single; const N: longint);
const op = vkopFused_scale_bias;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [src, dst, N, src.offset, dst.offset, aScale, aBias], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNFusedBiasScale(const dst, src: TVulkanMemory; const aBias,
  aScale: Single; const N: longint);
const op = vkopFused_bias_scale;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [src, dst, N, src.offset, dst.offset, aBias, aScale], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNFusedMulScale(const dst, src1, src2: TVulkanMemory;
  const aScale: Single; const N: longint);
const op = vkopFused_mul_scale;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [src1, src2, dst, N, src1.offset, 1, src2.offset, 1, dst.offset, 1, aScale], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNFusedBiasMulScale(const dst, src, srcM: TVulkanMemory;
  const aBias, aScale: Single; const N: longint);
const op = vkopFused_bias_mul_scale;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [src, srcM, dst, N, src.offset, 1, srcM.offset, 1, dst.offset, 1, aBias, aScale], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNFusedScaleAdd(const dst, src, srcAdd: TVulkanMemory;
  const aScale: Single; const N: longint);
const op = vkopFused_scale_add;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [src, srcAdd, dst, N, src.offset, 1, srcAdd.offset, 1, dst.offset, 1, aScale], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNFusedBiasAdd(const dst, src, srcA: TVulkanMemory;
  const aBias: Single; const N: longint);
const op = vkopFused_bias_add;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [src, srcA, dst, N, src.offset, 1, srcA.offset, 1, dst.offset, 1, aBias], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

//function TQNNVulkan.QNNDot(const a, b: TVulkanMemory; const N: longint): Single;
//begin
//  assert(false, 'QNNDot : not implemented!');
//end;

procedure TQNNVulkan.QNNAccAdd(const dst, a, b: TVulkanMemory; const N: integer);
const op = vkopFused_add_add;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [a, b, dst, dst, N, a.offset, 1, b.offset, 1, dst.offset, 1, dst.offset, 1], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNAccMul(const dst, a, b: TVulkanMemory; const N: integer);
const op = vkopFused_mul_add;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [a, b, dst, dst, N, a.offset, 1, b.offset, 1, dst.offset, 1, dst.offset, 1], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNForwardBias(const dst, aBias: TVulkanMemory; const N,
  blockSize: integer; biasSize: integer);
const op = vkopForward_bias;
begin
  if biasSize=0 then biasSize := N div blockSize;
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;
  dispatchPipeline(op, [dst, aBias, N, biasSize, blockSize, dst.offset, aBias.offset], CEIL_DIV(N, LOCAL_WG_SIZE))
end;

procedure TQNNVulkan.QNNMatMulNN(const C, A, B: TVulkanMemory; const M, K,
  N: integer);
const
  op = vkopGemm_nn;
  WORKGROUP_SIZE_X = 8;
  WORKGROUP_SIZE_Y = 8;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [M, N, K, 1.0, A, A.offset, K, B, B.offset, N, 0.0, C, C.offset, M],
    (M + WORKGROUP_SIZE_X-1) div WORKGROUP_SIZE_X,
    (N + WORKGROUP_SIZE_Y-1) div WORKGROUP_SIZE_Y
  )
end;

procedure TQNNVulkan.QNNMatMulNT(const C, A, B: TVulkanMemory; const M, K, N: integer);
const
  op = vkopGemm_nt;
  WORKGROUP_SIZE_X = 8;
  WORKGROUP_SIZE_Y = 8;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [M, N, K, 1.0, A, A.offset, K, B, B.offset, K, 0.0, C, C.offset, M],
    (M + WORKGROUP_SIZE_X-1) div WORKGROUP_SIZE_X,
    (N + WORKGROUP_SIZE_Y-1) div WORKGROUP_SIZE_Y
  )
end;

procedure TQNNVulkan.QNNMatMulTN(const C, A, B: TVulkanMemory; const M, K,
  N: integer);
const
  op = vkopGemm_tn;
  WORKGROUP_SIZE_X = 8;
  WORKGROUP_SIZE_Y = 8;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  dispatchPipeline(op, [M, N, K, 1.0, A, A.offset, M, B, B.offset, N, 0.0, C, C.offset, M],
    (M + WORKGROUP_SIZE_X-1) div WORKGROUP_SIZE_X,
    (N + WORKGROUP_SIZE_Y-1) div WORKGROUP_SIZE_Y
  )
end;

//procedure TQNNVulkan.QNNMatTranspose(const dst, src: TVulkanMemory; const srcRows,
//  srcCols: longint; srcStride: longint; dstStride: longint);
//begin
//
//end;

procedure TQNNVulkan.QNNLinear(const dst, x, W, B: TVulkanMemory; const seqLen,
  inDIM, outDIM: integer);
var i:longint;
begin
  gemm(false, true,
              seqLen, outDIM, inDIM,
              1.0, x, inDIM, W, inDIM,
              0.0, dst, outDIM);

  (* Add bias if present *)
  if assigned(b.buffer) then
    QNNForwardBias(dst, B, seqLen*outDIM, 1, outDIM);
    //for i := 0 to seqLen-1 do
    //   QNNAddInplace(dst + i*outDIM, B, outDIM)
end;

procedure TQNNVulkan.QNNLinearNoBias(const dst, x, W: TVulkanMemory; const seqLen,
  inDIM, outDIM: integer);
begin
  gemm(false, true,
              seqLen, outDIM, inDIM,
              1.0, x, inDIM, W, inDIM,
              0.0, dst, outDIM);
end;

//procedure TQNNVulkan.QNNLinearNoBias_BF16(const dst, x: TVulkanMemory;
//  const W: TVulkanMemory; const seqLen, inDIM, outDIM: integer);
//begin
//
//end;

procedure TQNNVulkan.QNNIm2Col(const aChannels, aHeight, aWidth, kernelHeight,
  kernelWidth, padHeight, padWidth, strideY, strideX, dilationY,
  dilationX: integer; const im: TVulkanMemory; const col: TVulkanMemory);
const
  op = vkopIm2Col;
  WORKGROUP_SIZE_X = 16;
  WORKGROUP_SIZE_Y = 16;
var
  N, size_h, padding_h, col_h, padding_w, size_w, col_w, ceiled_w, ceiled_h:SizeInt;
begin
  if (high(vulkanPipelines)<ord(op)) or not assigned(vulkanPipelines[ord(op)].pipeline) then
    preparePipeline(op);

  if not CommandBufferStarted then beginCommadBuffer;

  size_h      := aHeight + 2 * padHeight;
  padding_h   := dilationY * (kernelHeight - 1) + 1;
  if size_h >= padding_h then
    col_h       := (size_h - padding_h) div strideY + 1
  else
    col_h       := 1;
  size_w      := aWidth + 2 * padWidth;
  padding_w   := dilationX * (kernelWidth - 1) + 1;
  if size_w >= padding_w then
    col_w       := (size_w - padding_w) div strideX + 1
  else
    col_w       := 1;
  ceiled_w    := Ceil(col_w, WORKGROUP_SIZE_X);
  ceiled_h    := Ceil(col_h, WORKGROUP_SIZE_Y);

  N := ceiled_h * aChannels;

  dispatchPipeline(op,
  [im, col, aHeight, aWidth, aChannels
  , col_h, col_w
  , kernelHeight, kernelWidth
  , padHeight, padWidth
  , strideY, strideX
  , dilationY, dilationX, 0{0 = correlation, 1 = convolution(revesed)}, im.offset, col.offset],
    (ceiled_w + WORKGROUP_SIZE_X-1) div WORKGROUP_SIZE_X,
    (N + WORKGROUP_SIZE_Y-1) div WORKGROUP_SIZE_Y
  )

end;

procedure TQNNVulkan.QNNIm2ColStridedBatched(const aChannels, aHeight, aWidth,
  kernelHeight, kernelWidth, padHeight, padWidth, strideY, strideX, dilationY,
  dilationX: integer; const im: TVulkanMemory; const imStride: integer;
  const col: TVulkanMemory; const colStride: integer; const batch: integer);
var
  b: Integer;
begin
  for b:=0 to batch-1 do
    QNNIm2Col(
      aChannels, aHeight, aWidth,
      kernelHeight, kernelWidth, padHeight, padWidth,
      strideY, strideX, dilationY, dilationX,
      im + b*imStride,
      col + b*colStride);
end;

procedure TQNNVulkan.QNNConv2d(const dst, src, weights, bias: TVulkanMemory;
  const in_ch, out_ch, H, W, kH, kW, stride, padding: longint;
  const batch: longint);
var
  outW, outH, kSize, imColSize, filters, outImgSize
  , k, inVolume, b, c, strideA, strideB, strideC: integer;

  col_size, {max_col_size, }tile_col_size, row_size: IntPtr;
  col: TVulkanMemory;
  col_ptr, in_b, out_b, out_tile, out_ch_ptr: TVulkanMemory;
  tile_rows, tile_start, tile_end, tile_h, tile_pixels,
    col_row, ic, kernel_row, kernel_col, oh, ow, ih, iw, {col_idx, }oc, i, outSpatial,
    input_col: longint;
  b_val: single;

begin
  outH := (H + 2 * padding - kH) div stride + 1;
  outW := (W + 2 * padding - kW) div stride + 1;
  outSpatial := outH*outW;
  col_size := in_ch * kH * kW * outH * outW;

  tile_rows := outH;
  //{$ifdef CONV_TILE}
  //if col_size > MAX_COL_SIZE then
  //    begin
  //        row_size := in_ch * kH * kW * outW;
  //        tile_rows := MAX_COL_SIZE div row_size;
  //        if tile_rows < 1 then
  //            tile_rows := 1
  //    end;
  //tile_col_size := in_ch * kH * kW * tile_rows * outW;
  //{$endif}
  if KH*KW<>1 then
     col := createStorageMemory(in_ch*kH*kW*tile_rows*outW*sizeof(single));
  for b := 0 to batch -1 do begin
    in_b := src + b * in_ch * H * W;
    out_b := dst + b * out_ch * outH * outW;
    tile_start := 0;
    while tile_start < outH do begin
      tile_end := tile_start+tile_rows;
      if tile_end > outH then
          tile_end := outH;
      tile_h := tile_end-tile_start;
      tile_pixels := tile_h * outW;
      col_row := 0;
      if KH*KW=1 then // if pointwise conv
        col := in_b // [in_ch, kH, kW, tile_rows, outW])
      else
        QNNIm2Col(in_ch, H, W, KH, KW, padding, padding, stride, stride, 1, 1, in_b, col);
      K := in_ch * kH * kW;
      out_tile := out_b+tile_start * outW;
      gemm(false, false, out_ch, tile_pixels, K, 1.0, weights, K, col, tile_pixels, 0.0, out_tile, outH * outW);
      inc(tile_start, tile_rows)
    end;
    if assigned(bias.buffer) then
      QNNForwardBias(out_b, bias, out_ch*outSpatial, outSpatial);
  end;

end;

procedure TQNNVulkan.QNNNorm(const N: longint; const dst, src: TVulkanMemory;
  const weights: TVulkanMemory; const stride: longint);
begin

end;

procedure TQNNVulkan.QNNRMSNorm(const N: longint; const dst, src: TVulkanMemory;
  const weights: TVulkanMemory; const stride: longint);
begin

end;

procedure TQNNVulkan.QNNRMSNormRows(const dst, src, weight: TVulkanMemory;
  const rows, dim: integer);
begin

end;

procedure TQNNVulkan.QNNTanh(const dst: TVulkanMemory; const N: longint);
begin

end;

procedure TQNNVulkan.QNNQKRMSNorm(const Q, K, QWeights, KWeights: TVulkanMemory;
  const seq, heads, headDim: longint);
begin

end;

procedure TQNNVulkan.QNNRMSNormSeq(const dst, normWeights: TVulkanMemory; const seq,
  heads, headDim: longint);
begin

end;

procedure TQNNVulkan.QNNGroupNorm(const dst, src, gamma, beta: TVulkanMemory;
  const batch, channels, H, W, num_groups: integer);
begin

end;

procedure TQNNVulkan.QNNBatchNorm(const dst, src, running_mean, running_var,
  gamma, beta: TVulkanMemory; const batch, channels, H, W: integer);
begin

end;

procedure TQNNVulkan.QNNMinMax(const N: integer; const src: TVulkanMemory; out
  outMin, outMax: Single; const argMin: PInteger; const argMax: PInteger;
  const stride: integer);
begin

end;

function TQNNVulkan.QNNMax(const N: integer; const src: TVulkanMemory;
  const arg: PInteger; const stride: integer): Single;
begin

end;

function TQNNVulkan.QNNMin(const N: integer; const src: TVulkanMemory;
  const arg: PInteger; const stride: integer): Single;
begin

end;

function TQNNVulkan.QNNMaxAbs(const N: integer; const src: TVulkanMemory;
  const stride: integer): Single;
begin

end;

function TQNNVulkan.QNNMinAbs(const N: integer; const src: TVulkanMemory;
  const stride: integer): Single;
begin

end;

function TQNNVulkan.QNNArgMax(const N: integer; const src: TVulkanMemory;
  const stride: integer): integer;
begin

end;

function TQNNVulkan.QNNArgMin(const N: integer; const src: TVulkanMemory;
  const stride: integer): integer;
begin

end;

function TQNNVulkan.QNNSum(const N: integer; const src: TVulkanMemory;
  const stride: integer): Single;
begin

end;

function TQNNVulkan.QNNSumSqr(const N: integer; const src: TVulkanMemory;
  const stride: integer): Single;
begin

end;

function TQNNVulkan.QNNSumSqrDiff(const N: integer; const src: TVulkanMemory;
  const aMean: Single; const stride: integer): Single;
begin

end;

function TQNNVulkan.QNNSqrDistance(const N: integer; const src1, src2: TVulkanMemory;
  const stride: integer): Single;
begin

end;

function TQNNVulkan.QNNMaxAbsDiff2(const N: integer; const src1, src2: TVulkanMemory;
  out outSrc1, outSrc2: Single; const stride: integer): Single;
begin

end;

function TQNNVulkan.QNNMaxAbsDiff(const N: integer; const src1, src2: TVulkanMemory;
  const stride: integer): Single;
begin

end;

function TQNNVulkan.QNNSumAbsDiff(const N: integer; const src1, src2: TVulkanMemory;
  const stride: integer): Single;
begin

end;

function TQNNVulkan.QNNSumAbsDiffScalar(const N: integer; const src: TVulkanMemory;
  const aMean: Single; const stride: integer): Single;
begin

end;

function TQNNVulkan.QNNMean(const N: integer; const src: TVulkanMemory;
  const stride: integer): Single;
begin

end;

function TQNNVulkan.QNNVariance(const N: integer; const src: TVulkanMemory;
  const aMean: Single; const stride: integer; const isPopulation: boolean
  ): Single;
begin

end;

procedure TQNNVulkan.QNNSigmoidInplace(const x: TVulkanMemory; const N: integer);
begin

end;

procedure TQNNVulkan.QNNSigmoid(const dst, src: TVulkanMemory; const N: integer);
begin

end;

procedure TQNNVulkan.QNNSiluInplace(const x: TVulkanMemory; const N: integer);
begin

end;

procedure TQNNVulkan.QNNSilu(const dst, src: TVulkanMemory; const N: integer);
begin

end;

procedure TQNNVulkan.QNNSiluMul(const gate, up: TVulkanMemory; const N: integer);
begin

end;

procedure TQNNVulkan.QNNSoftmax(const x: TVulkanMemory; const N: integer);
begin

end;

procedure TQNNVulkan.QNNSoftmaxRows(const x: TVulkanMemory; const rows, cols: integer
  );
begin

end;

procedure TQNNVulkan.QNNAttention(const dst, Q, K, V: TVulkanMemory; const batch,
  heads, seq_q, seq_k, head_dim: longint; const scale: Single);
begin

end;

procedure TQNNVulkan.QNNFlashAttention(const dst, Q, K, V: TVulkanMemory;
  const heads, seq_q, seq_k, head_dim: longint; const scale: Single);
begin

end;

procedure TQNNVulkan.QNNUpSampleNearest(const dst, src: TVulkanMemory; const batch,
  channels, H, W, scale_h, scale_w: longint);
begin

end;

procedure TQNNVulkan.QNNUpSample(const dst, src: TVulkanMemory; const batch,
  channels, H, W: longint; const scale_h, scale_w: Single;
  const interpolation: longint);
begin

end;

procedure TQNNVulkan.QNNPatchify(const dst, src: TVulkanMemory; const batch,
  channels, H, W, patch_size: longint);
begin

end;

procedure TQNNVulkan.QNNUnpatchify(const dst, src: TVulkanMemory; const batch,
  channels, H, W, patch_size: longint);
begin

end;

procedure TQNNVulkan.QNNPermut(const dst, src: TVulkanMemory; const axisPerm: TArray<
  byte>; const inShape: TArray<int64>; var outShape: TArray<Int64>);
begin

end;

procedure TQNNVulkan.QNNReduce(const dst, src: TVulkanMemory; const inShape,
  reduceAxes: TArray<int64>; const reduceOp: longint;
  const divideByCount: boolean; out outShape: TArray<int64>;
  const keepDims: boolean);
begin

end;

procedure TQNNVulkan.QNNCopy(const dst, src: TVulkanMemory; const N: integer);
begin

end;

procedure TQNNVulkan.QNNCopyStrided(const dst: TVulkanMemory;
  const dstStride: integer; const src: TVulkanMemory; const srcStride: integer;
  const N: integer);
begin

end;

procedure TQNNVulkan.QNNFill(const dst: TVulkanMemory; const val: Single;
  const N: integer; const stride: integer);
begin

end;

procedure TQNNVulkan.QNNBroadcast(const dst: pointer; const src; const srcSize,
  N: integer; const stride: integer);
begin

end;

procedure TQNNVulkan.QNNGatedAdd(const dst, gate, proj: TVulkanMemory; const seq,
  hidden: integer);
begin

end;

procedure TQNNVulkan.QNNComputeRoPE(const dst: TVulkanMemory; const maxSeq,
  dim: longint; const theta: Single);
begin

end;

procedure TQNNVulkan.QNNComputeRoPE(const cosOut, sinOut: TVulkanMemory;
  const maxSeqLen, headDim: longint; const theta: Single);
begin

end;

procedure TQNNVulkan.QNNComputeRoPE2D(const cosDst, sinDst: TVulkanMemory;
  const patch_h, patch_w, dim: longint; const theta: Single);
begin

end;

procedure TQNNVulkan.QNNComputeRoPE2DOffset(const cosDst, sinDst: TVulkanMemory;
  const patch_h, patch_w, dim: longint; const theta: Single;
  const offset_t: longint);
begin

end;

procedure TQNNVulkan.QNNComputeRoPEText(const cosDst, sinDst: TVulkanMemory;
  const txt_seq, axis_dim: longint; const theta: Single);
begin

end;

procedure TQNNVulkan.QNNApplyRoPE(const dst, freqs: TVulkanMemory; const batch, seq,
  heads, head_dim: longint);
begin

end;

procedure TQNNVulkan.QNNApplyRoPE2(const dst, cosIn, sinIn: TVulkanMemory;
  const numHeads, headDim: longint);
begin

end;

procedure TQNNVulkan.QNNApplyRoPE3(const dst, cosIn, sinIn: TVulkanMemory;
  const seqLen, numHeads, headDim: longint);
begin

end;

procedure TQNNVulkan.QNNApplyRoPEQK(const q, k, cos_cache, sin_cache: TVulkanMemory;
  const seq_len, num_q_heads, num_kv_heads, head_dim: longint);
begin

end;

procedure TQNNVulkan.QNNApplyRoPE2D(const dst, cos_freq, sin_freq: TVulkanMemory;
  const seq, heads, head_dim, dim: longint);
begin

end;

function TQNNVulkan.QNNTimeStepEmbedding(const t: Single; const dim: integer;
  const max_period: Single): TVulkanMemory;
begin

end;

procedure TQNNVulkan.QNNMatTriangularFill(const dim: integer;
  const dst: TVulkanMemory; const val: Single; const mask: PLongint);
begin

end;

procedure TQNNVulkan.QNNMaskFill(const dst: TVulkanMemory; const mask: PLongint;
  const val: Single; const rows, cols: longint);
begin

end;

procedure TQNNVulkan.QNNAdaLN(const dst, src, bias, scale: TVulkanMemory; const seq,
  hidden: longint; const eps: Single);
begin

end;

procedure TQNNVulkan.QNNLINEAR_BF16_OR_F32(const dst, src: TVulkanMemory;
  const weight: TVulkanMemory; const weight_bf16: TVulkanMemory; const seq,
  srcDim, dstDim: integer);
begin

end;

{$define test}
{$ifdef TEST}

var
  vk  : TQNNVulkan;
{$endif}

procedure testGemm();
const
  M : longint = $1000;
  N : longint = $1000;
  K : longint = $1000;
  lda = $1000;
  ldb = $1000;
  ldc = $1000;
  //WORKGROUP_SIZE_X = 128;
  //WORKGROUP_SIZE_Y = 1;
  //WORKGROUP_SIZE_Z = 1;

  BN = 128;
  BM = 128;
var
  A, B, C, res : TArray<nfloat>;
  AA,BB, CC: TVulkanMemory;
  ss : uint64; f:single;
begin
  A := array_rand(M*lda, -10, 10);//[1,2,3,4,5,6,7,8,9];
  B := array_rand(ldb*N, -10, 10);
  C := array_rand(ldb*N, -10, 10);
  res := copy(C);
  AA := vk.createStorageMemory(length(A)*sizeof(nfloat));
  vk.pushToDevice(A, AA);
  BB := vk.createStorageMemory(length(B)*sizeof(nfloat));
  vk.pushToDevice(B, BB);
  CC := vk.createStagingMemory(M*ldc*sizeof(nfloat));
  vk.pushToDevice(C, CC);
  vk.preparePipeline(vkopGemm_nn_WarpTiling);
  ss := clock();
  array_gemm_nn(M, N, K, 1.5, A, lda, B, ldb, 0.5, res, ldc);
  //array_gemm_nt(M, N, K, 1.5, A, K, B, K, 0.5, res, N);
  f := (clock()-ss)/CLOCKS_PER_SEC;
  writeln('CPU : ', f:1:3,'s ', ((2*M*N*K div 1000000)/f)/1000000:1:3,' TFLOPs');


  ss := clock();
  vk.gemm(false, false, M, N, K, 1.5, AA, lda, BB, ldb, 0.5, CC, ldc);
  //vk.gemm(false, true, M, N, K, 1.5, AA, K, BB, K, 0.5, CC, N);
  vk.finish;
  f := (clock()-ss)/CLOCKS_PER_SEC;
  writeln('VULKAN : ', f:1:3,'s ', ((2*M*N*K div 1000000)/f)/1000000:1:3,' TFLOPs');

  vk.pullFromDevice(pointer(C), CC);
  setLength(A, 0); setlength(B, 0);
  writeln('MAX ABS DIFF : ', array_max_abs_diff(length(res), pointer(C), pointer(res)):0:3);
  //array_print(C);
  //writeln('');
  //array_print(res);
  vk.freeMemory(AA);
  vk.freeMemory(BB);
  vk.freeMemory(CC);
end;

procedure testElementWise();
const N = $80000;
var
  A, B, C, res : TArray<nfloat>;
  AA,BB, CC: TVulkanMemory;
  ss: UInt64;
begin
  A := array_rand(N, -10, 10);
  B := array_rand(N, -10, 10);
  setLength(C, N);

  AA := vk.createStorageMemory(N*SizeOf(single));
  BB := vk.createStorageMemory(N*SizeOf(single));
  CC := vk.createStorageMemory(N*SizeOf(single));

  ss := clock();
  TQNNSingleOPS.QNNAdd(pointer(C), Pointer(A), pointer(B), N);
  writeln('CPU : ', (clock() - ss)/CLOCKS_PER_SEC:1:3,'s');

  vk.pushToDevice(A, AA);
  vk.pushToDevice(B, BB);
  ss := clock();
  vk.QNNAdd(CC, AA, BB, N);
  vk.finish();
  writeln('VULKAN : ', (clock() - ss)/CLOCKS_PER_SEC:1:3,'s');
  setLength(res, N);
  vk.pullFromDevice(res, CC);

  //setLength(A, 0); setlength(B, 0);
  writeln('MAX ABS DIFF : ', array_max_abs_diff(N, pointer(res), pointer(C)):0:3);

  vk.freeMemory(AA);
  vk.freeMemory(BB);
  vk.freeMemory(CC);

end;

procedure testIM2Col();
const
  kH = 5; kW = 5; inCH = $40; inH = $200; inW = $200;
  STRIDE = 1; PADDING = kH div 2; DILATION = 1;
var
  A, B, C, res : TArray<nfloat>;
  AA,BB: TVulkanMemory;
  outH, outW : uint64;
  ss : clock_t;
begin
  A := array_rand(inH*inW*inCH, -100, 100);
  outH := (inH + 2 * PADDING - kH) div STRIDE + 1;
  outW := (inW + 2 * PADDING - kW) div STRIDE + 1;

  setLength(B, inCH*kH*kW*outH*outW);
  ss := clock();
  TQNNSingleOPS.QNNIm2Col(inCH, inH, inW, kH, kW, PADDING, PADDING, STRIDE, STRIDE, DILATION, DILATION, pointer(A), pointer(B), 0, 0, true);
  writeln('CPU : ', (clock() - ss)/CLOCKS_PER_SEC:1:3,'s');

  AA := vk.createStorageMemory(length(A)*sizeof(single));
  BB := vk.createStagingMemory(length(B)*sizeof(single));
  vk.pushToDevice(A, AA);
  ss := clock();
  vk.QNNIm2Col(inCH, inH, inW, kH, kW, PADDING, PADDING, STRIDE, STRIDE, DILATION, DILATION, AA, BB);
  vk.finish;
  writeln('VULKAN : ', (clock() - ss)/CLOCKS_PER_SEC:1:3,'s');
  setLength(res, length(B));
  vk.pullFromDevice(Res, BB);

  writeln('MAX ABS DIFF : ', array_max_abs_diff(B, res):0:3);

  array_stat(B);
  array_stat(res);


end;

initialization
  vk := TQNNVulkan.Create(1);
  //writeln(vk.VulkanDevice.deviceProperties.properties.deviceName);
  //vk.CheckExtention('');

  //testGemm();

  //testElementWise();

  //testIM2col();

  //readln;



(*
  A := array_rand(M*K, -5, 5);
  B := rand_array(N*K, -5, 5);
  AA := vk.createStorageMemory(M*K*sizeof(nfloat));
  BB := vk.createStorageMemory(N*K*sizeof(nfloat));
  setLength(C  , M*N);//C := array_rand(M*N, -10, 10);
  setLength(res, M*N);

  CC := vk.createStorageMemory(M*N*sizeof(nfloat));  //vk.pushToDevice(C, CC);

  //array_stat(A);
  //array_stat(B);
  //array_add(a, b, c);
  //array_stat(C);

  vk.preparePipeline(ord(opGemm_nn_WrapTiling), vk.loadShader('../src/vulkan/spv/' + copy(getEnumName(TypeInfo(TQNNOperation), ord(opGemm_nn_WrapTiling)), 3)+'.comp.float.spv'));
  //vk.preparePipeline(ord(opGemm_nt_WrapTiling), vk.loadShader('../src/vulkan/spv/' + copy(getEnumName(TypeInfo(TQNNOperation), ord(opGemm_nt_WrapTiling)), 3)+'.comp.float.spv'));
  //vk.preparePipeline(ord(opGemm_tn_WrapTiling), vk.loadShader('../src/vulkan/spv/' + copy(getEnumName(TypeInfo(TQNNOperation), ord(opGemm_tn_WrapTiling)), 3)+'.comp.float.spv'));
  //vk.preparePipeline(ord(opGemm_nn), vk.loadShader('../src/vulkan/spv/' + copy(getEnumName(TypeInfo(TQNNOperation), ord(opGemm_nn)), 3)+'.comp.float.spv'));

  writeln('work groups : ',  CEIL_DIV(N, BN), ' X ', CEIL_DIV(M, BM));


  vk.pushToDevice(A, AA);
  vk.pushToDevice(B, BB);
  vk.beginCommadBuffer;
  ms := GetTickCount64;

  //workgroups := (N+WORKGROUP_SIZE-1) div WORKGROUP_SIZE;

  //vk.dispatchPipeline(ord(opGemm_nn), [M, N, K, 1.0, AA, 0, K, BB, 0, N, 0.0, CC, 0, N],
  //                               (M + WORKGROUP_SIZE_X-1) div WORKGROUP_SIZE_X,
  //                               (N + WORKGROUP_SIZE_Y-1) div WORKGROUP_SIZE_Y,
  //                               1 //(K+WORKGROUP_SIZE_Z-1) div WORKGROUP_SIZE_Z
  //                    );


  vk.dispatchPipeline(ord(opGemm_nn_WrapTiling), [M, N, K, 1.0, AA.buffer, 0, K, BB.buffer, 0, N, 0.0, CC.buffer, 0, N],
                                 CEIL_DIV(N, BN), CEIL_DIV(M, BM)
                      );
  //vk.dispatchPipeline(ord(opGemm_nt_WrapTiling), [M, N, K, 1.0, AA.buffer, 0, K, BB.buffer, 0, K, 0.0, CC.buffer, 0, N],
  //                               CEIL_DIV(N, BN), CEIL_DIV(M, BM)
  //                    );

  vk.endCommandBuffer;
  vk.finish;
  vk.pullFromDevice(C, CC);
  writeln('GPU : ',GetTickCount64-ms,'ms');


  ms := GetTickCount64;
  //array_gemm_nt(M, N, K, 1.0, A, K, B, K, 0.0, res, N);
  array_gemm_nn(M, N, K, 1.0, A, K, B, N, 0.0, res, N);
  //array_gemm_tn(M, N, K, 1.0, A, M, B, N, 0.0, res, N);
  writeln('CPU : ',GetTickCount64-ms,'ms');
  writeln('CPU/GPU Diff: ', single(array_sum_sqr_diff(C, res)):1:6);

  writeln('Vulkan Compute:');
  array_print(C, 1);
  array_stat(C, 2);

  writeln('CPU Compute:');
  array_print(res, 1);
  array_stat(res, 2);


  //vk.dispatchPipeline(NN_SGEMM1_NN, args, workgroups);
  //vk.pullFromDevice(mems[2], storageMems[2]);

  vk.freeMemory(AA);
  vk.freeMemory(BB);
  vk.freeMemory(CC);
  vk.free;
  //array_add(length(res), pointer(mems[0]), pointer(mems[1]), pointer(res));
  //array_fma(3, 4, mems[0], mems[2]);

  //array_print_diff(C, res, 0.05);

  readln
*)

finalization
  freeAndNil(vk)

end.

