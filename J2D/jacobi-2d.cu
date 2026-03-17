#include <iostream>
#include <time.h>

#include <cuda.h>


double getTimeStamp() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double) ts.tv_sec + (double) ts.tv_nsec * 1.e-9;
}


#define checkCudaErrors(val) checkCudaErrorsImpl((val), #val, __FILE__, __LINE__)

inline void checkCudaErrorsImpl(cudaError_t result, char const *const func, const char *const file, int const line) {
    if (result) {
        fprintf(stderr, "CUDA error at %s:%d code=%d(%s) \"%s\" \n", file, line,
                static_cast<unsigned int>(result), cudaGetErrorName(result), func);
        exit(EXIT_FAILURE);
    } else {
        cudaError_t add_res = cudaGetLastError();
        if (add_res) {
            fprintf(stderr, "CUDA error at %s:%d code=%d(%s) \"%s\" \n", file, line,
                    static_cast<unsigned int>(add_res), cudaGetErrorName(add_res), func);
            exit(EXIT_FAILURE);
        }
    }
}


__global__ void jacobi(int n_x, int n_y, double *__restrict__ u, double *__restrict__ u_new) {
    int iStart = blockIdx.x * blockDim.x + threadIdx.x;
    int jStart = blockIdx.y * blockDim.y + threadIdx.y;

    int iStride = gridDim.x * blockDim.x;
    int jStride = gridDim.y * blockDim.y;

    for (int j = jStart + 1; j < n_y - 1; j += jStride)
        for (int i = iStart + 1; i < n_x - 1; i += iStride)
            u_new[i + j * n_x] = 0.25 * (u[i + j * n_x - 1] + u[i + j * n_x + 1] + u[i + n_x * (j - 1)] + u[i + n_x * (j + 1)]);
}


int main(int argc, char *argv[]) {
    // initialize parameters

    int n_x = 2048, n_y = 2048;

    if (argc > 1) n_x = atoi(argv[1]);
    if (argc > 2) n_y = atoi(argv[2]);

    int nIt = 100;

    if (argc > 3) nIt = atoi(argv[3]);

    int blockSize_x = 16, blockSize_y = 16;

    if (argc > 4) blockSize_x = atoi(argv[4]);
    if (argc > 5) blockSize_y = atoi(argv[5]);

    dim3 blockSize(blockSize_x, blockSize_y);

    int numBlocks_x = (n_x + blockSize_x - 1) / blockSize_x, numBlocks_y = (n_y + blockSize_y - 1) / blockSize_y;

    if (argc > 6) numBlocks_x = atoi(argv[6]);
    if (argc > 7) numBlocks_y = atoi(argv[7]);

    dim3 numBlocks(numBlocks_x, numBlocks_y);

    // allocate host memory

    double *u;
    double *u_new = new double[n_x * n_y];

    checkCudaErrors(cudaMallocHost(&u, sizeof(double) * n_x * n_y));
    checkCudaErrors(cudaMallocHost(&u_new, sizeof(double) * n_x * n_y));

    // initialize host memory

    for (int j = 0; j < n_y; ++j)
        for (int i = 0; i < n_x; ++i)
            if (0 == i || 0 == j || n_x - 1 == i || n_y - 1 == j)
                u[i + j * n_x] = 0.0;
            else
                u[i + j * n_x] = 10.0;

    // allocate device memory

    double *d_u, *d_u_new;

    checkCudaErrors(cudaMalloc((void **) &d_u, sizeof(double) * n_x * n_y));
    checkCudaErrors(cudaMalloc((void **) &d_u_new, sizeof(double) * n_x * n_y));

    // copy host memory to device
    //   copy both arrays since the second one includes boundary values

    checkCudaErrors(cudaMemcpy(d_u, u, sizeof(double) * n_x * n_y, cudaMemcpyHostToDevice));
    checkCudaErrors(cudaMemcpy(d_u_new, u_new, sizeof(double) * n_x * n_y, cudaMemcpyHostToDevice));

    checkCudaErrors(cudaDeviceSynchronize());

    // warmup
    jacobi<<<numBlocks, blockSize>>>(n_x, n_y, d_u, d_u_new);

    // perform measurement

    auto start = getTimeStamp();

    for (int i = 0; i < nIt; i += 1) {
        jacobi<<<numBlocks, blockSize>>>(n_x, n_y, d_u, d_u_new);
        // pointer swap
        std::swap(d_u, d_u_new);
    }
    checkCudaErrors(cudaDeviceSynchronize());

    auto end = getTimeStamp();

    double elapsed_seconds = end - start;
    std::cout << "elapsed time:  " << 1e3 * elapsed_seconds << " ms\n";
    std::cout << "per iteration: " << 1e3 * elapsed_seconds / nIt << " ms\n";
    std::cout << "performance: " << 1e-9 * (n_x-2) * (n_y-2) * nIt / elapsed_seconds << " GLUP/s\n";

    // copy data back to host

    checkCudaErrors(cudaMemcpy(u, d_u, sizeof(double) * n_x * n_y, cudaMemcpyDeviceToHost));
    checkCudaErrors(cudaMemcpy(u_new, d_u_new, sizeof(double) * n_x * n_y, cudaMemcpyDeviceToHost));

    // clean up resources

    cudaFree(d_u);
    cudaFree(d_u_new);

    cudaFree(u);
    cudaFree(u_new);

    return 0;
}
