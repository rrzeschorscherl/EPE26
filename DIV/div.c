/*
 * =======================================================================================
 *
 *      Author:   Jan Eitzinger (je), jan.eitzinger@fau.de
 *      Copyright (c) 2019 RRZE, University Erlangen-Nuremberg
 *
 *      Permission is hereby granted, free of charge, to any person obtaining a copy
 *      of this software and associated documentation files (the "Software"), to deal
 *      in the Software without restriction, including without limitation the rights
 *      to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *      copies of the Software, and to permit persons to whom the Software is
 *      furnished to do so, subject to the following conditions:
 *
 *      The above copyright notice and this permission notice shall be included in all
 *      copies or substantial portions of the Software.
 *
 *      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *      SOFTWARE.
 *
 * =======================================================================================
 */
#define _GNU_SOURCE
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <math.h>

#define N 2000000000

double getTimeStamp()
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1.e-9;
}


int main (int argc, char** argv)
{
  double E, S;
  double  delta_x = 1./N;
  double x, sum;

  for(int k=0; k<2; ++k) {
  S = getTimeStamp();

  sum = 0.0;
  #pragma unroll(32)
#pragma omp parallel for reduction(+:sum)
  for(int i=0; i<N; i++) {
     double x = (i + 0.5) * delta_x;
     sum = sum + 4.0 / (1.0 + x * x);
  }

  E = getTimeStamp();
  }
  printf("Pi=%.15lf in %.5lf s\n",
          sum * delta_x,
          E - S);

  return EXIT_SUCCESS;
}
