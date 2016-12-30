#include "dynet/cuda.h"
#include "dynet/gpu-ops.h"
#include "dynet/gpu-kernels.h"
#include "dynet/functors.h"

namespace dynet {
namespace gpu {

// CUDA kernel. Each thread takes care of one element of c
__global__ void ker_sparse_assign(int n, unsigned int *idx, float *src, float *trg) {
  // Get our global thread ID
  int id = blockIdx.x*blockDim.x+threadIdx.x;
 
  // Make sure we do not go out of bounds
  if (id < n)
    trg[idx[id]] = src[id];

  __syncthreads();
}

void sparse_assign(int n, unsigned int *idx, float *src, float *trg) {
  if(n > 0) {
    auto tb = SizeToBlockThreadPair(n);
    int total_size = tb.first*tb.second;
    for(int curr_pos = 0; curr_pos < n; curr_pos += total_size)
      ker_sparse_assign<<<tb.first, tb.second>>>(min(total_size, n-curr_pos), idx+curr_pos, src+curr_pos, trg);
  }
}

// CUDA kernel. Each thread takes care of one element of c
__global__ void ker_sparse_subtract(int n, unsigned int *idx, float *src, float *trg) {
  // Get our global thread ID
  int id = blockIdx.x*blockDim.x+threadIdx.x;
 
  // Make sure we do not go out of bounds
  if (id < n)
    trg[idx[id]] -= src[id];

  __syncthreads();
}

void sparse_subtract(int n, unsigned int *idx, float *src, float *trg) {
  if(n > 0) {
    auto tb = SizeToBlockThreadPair(n);
    int total_size = tb.first*tb.second;
    for(int curr_pos = 0; curr_pos < n; curr_pos += total_size)
      ker_sparse_subtract<<<tb.first, tb.second>>>(min(total_size, n-curr_pos), idx+curr_pos, src+curr_pos, trg);
  }
}

// CUDA kernel. Each thread takes care of one element of c
__global__ void ker_sparse_to_dense(int n, unsigned int *idx, float *src, float *trg) {
  // Get our global thread ID
  int id = blockIdx.x*blockDim.x+threadIdx.x;
 
  // Make sure we do not go out of bounds
  if (id < n)
    trg[id] = src[idx[id]];

  __syncthreads();
}

void sparse_to_dense(int n, unsigned int *idx, float *src, float *trg) {
  if(n > 0) {
    auto tb = SizeToBlockThreadPair(n);
    int total_size = tb.first*tb.second;
    for(int curr_pos = 0; curr_pos < n; curr_pos += total_size)
      ker_sparse_to_dense<<<tb.first, tb.second>>>(min(total_size, n-curr_pos), idx+curr_pos, src, trg+curr_pos);
  }
}

// CUDA kernel. Each thread takes care of one element of c
__global__ void ker_const_init(int n, float val, float *trg) {
  // Get our global thread ID
  int id = blockIdx.x*blockDim.x+threadIdx.x;
 
  // Make sure we do not go out of bounds
  if (id < n)
    trg[id] = val;

  __syncthreads();
}

void const_init(int n, float val, float *trg) {
  auto tb = SizeToBlockThreadPair(n);
  int total_size = tb.first*tb.second;
  for(int curr_pos = 0; curr_pos < n; curr_pos += total_size)
    ker_const_init<<<tb.first, tb.second>>>(min(total_size, n-curr_pos), val, trg+curr_pos);
}

// CUDA kernel. Each thread takes care of one element of c
__global__ void ker_sparse_lookup(int n, unsigned *idx, int bsize, float mult, float* src, float *trg) {
  // Get our global thread ID
  int id = blockIdx.x*blockDim.x+threadIdx.x;
 
  // Make sure we do not go out of bounds
  if (id < n*bsize)
    trg[id] = src[idx[id/bsize]*bsize+id%bsize] * mult;

  __syncthreads();
}

void sparse_lookup(int n, unsigned *idx, int bsize, float mult, float *src, float *trg) {
  if(n > 0) {
    auto tb = SizeToBlockThreadPair(n*bsize);
    int total_size = tb.first*tb.second;
    for(int curr_pos = 0; curr_pos < n; curr_pos += total_size/bsize)
      ker_sparse_lookup<<<tb.first, tb.second>>>(min(total_size/bsize, n-curr_pos), idx+curr_pos, bsize, mult, src, trg+curr_pos*bsize);
  }
}

} // namespace gpu
} // namespace dynet
