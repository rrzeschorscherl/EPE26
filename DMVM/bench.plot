set terminal png size 1024,768 enhanced font ,12
set output 'dmvm.png'
set xlabel '#rows'
set xrange [1000:]
set yrange [0:]
set ylabel 'Performance [MFLOP/s]'
set logscale x

plot 'bench.dat' u 1:2 w linespoints title 'dmvm'
