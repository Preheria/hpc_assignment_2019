#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <math.h>
#include <unistd.h>
#include <semaphore.h>
#include <cuda_runtime_api.h>

/******************************************************************************
 * This program takes an initial estimate of m and c and finds the associated 
 * rms error. It is then as a base to generate and evaluate 8 new estimates, 
 * which are steps in different directions in m-c space. The best estimate is 
 * then used as the base for another iteration of "generate and evaluate". This 
 * continues until none of the new estimates are better than the base. This is
 * a gradient search for a minimum in mc-space.
 * 
 * To compile:
 *   nvcc -o lr_coursework lr_coursework.c -lm
 * 
 * To run:
 *   ./lr_coursework
 * 
 * Dr Kevan Buckley, University of Wolverhampton, 2018
 *****************************************************************************/



typedef struct point_t {
	double x;
	double y;
} point_t;

typedef struct mean_intercept 
{
	double mean,intercept,error;
} mean_intercept;

int n_data = 1000;
point_t data[] = {
  {83.40,147.61},{72.54,104.92},{65.45,133.77},{73.47,125.99},
  {76.86,154.92},{65.45,128.87},{78.30,144.23},{65.46,125.35},
  {90.55,155.58},{34.15,79.11},{80.14,148.12},{49.14,88.19},
  {29.59,71.28},{33.80,87.85},{60.49,113.09},{61.86,104.64},
  {51.46,103.14},{92.22,146.63},{20.85,75.45},{37.35,85.67},
  {37.03,81.01},{78.28,129.70},{24.30,72.23},{51.80,71.08},
  { 7.25,51.68},{23.35,81.55},{ 4.15,34.78},{17.35,65.95},
  {88.79,138.66},{14.42,44.89},{ 9.99,37.55},{21.65,61.09},
  {93.37,156.67},{93.84,158.24},{17.64,35.28},{88.45,143.46},
  {18.73,59.89},{25.84,62.90},{ 0.57,22.82},{45.79,95.26},
  {35.82,56.89},{87.20,158.45},{21.71,51.77},{87.34,145.72},
  {86.74,146.13},{39.91,84.15},{78.96,137.15},{85.24,158.70},
  {66.42,113.25},{75.63,127.04},{74.44,143.61},{23.77,67.40},
  {20.08,53.86},{48.10,86.28},{16.65,71.25},{41.24,85.45},
  {52.07,120.57},{46.09,88.49},{89.30,164.35},{10.87,43.98},
  {68.84,118.22},{71.18,128.73},{63.66,118.07},{ 8.91,49.19},
  {88.47,168.07},{67.78,108.50},{53.59,106.40},{53.50,92.92},
  {83.77,144.06},{19.14,61.12},{48.93,77.52},{88.98,137.77},
  {73.03,142.85},{18.12,51.13},{47.41,114.19},{85.65,154.59},
  { 8.95,29.40},{30.96,61.29},{11.83,48.41},{40.23,87.39},
  {61.20,126.26},{87.31,132.01},{48.23,96.56},{73.60,143.08},
  {50.48,113.60},{32.02,73.81},{19.67,46.99},{37.55,76.24},
  { 3.33,31.40},{32.43,49.02},{40.21,83.78},{17.80,59.31},
  { 5.22,28.61},{88.87,159.96},{46.16,90.25},{ 2.36,46.28},
  {51.44,90.08},{93.40,142.52},{ 4.98,49.09},{36.76,97.32},
  {23.77,49.73},{89.97,134.98},{ 8.82,50.94},{50.48,93.56},
  {65.04,114.55},{60.55,111.27},{35.97,73.02},{74.96,122.72},
  {12.86,40.67},{97.12,143.67},{89.34,166.30},{15.32,63.80},
  {28.54,72.89},{32.18,57.93},{44.06,104.11},{65.79,121.85},
  {98.20,158.24},{ 7.18,44.61},{58.37,120.42},{33.07,69.07},
  {42.11,93.45},{67.78,124.10},{93.68,178.02},{92.53,150.69},
  { 4.23,45.46},{84.16,155.47},{83.87,129.94},{96.19,162.44},
  {53.78,108.12},{60.75,111.66},{42.86,97.22},{59.00,125.00},
  {68.69,108.10},{33.26,65.97},{89.96,159.07},{59.56,111.42},
  {38.44,77.52},{84.89,128.41},{53.71,97.76},{84.69,147.55},
  {34.92,80.25},{21.00,32.76},{24.51,58.35},{35.35,63.64},
  { 5.72,38.76},{40.64,99.03},{47.22,89.87},{31.01,69.53},
  {13.80,44.85},{47.94,86.88},{95.28,167.60},{52.76,113.81},
  {96.62,154.41},{87.37,150.13},{33.17,78.65},{22.95,57.40},
  {45.54,81.41},{80.68,154.77},{54.78,101.60},{28.94,65.96},
  {40.51,88.07},{65.97,130.50},{48.89,97.36},{ 8.97,40.79},
  {87.46,150.28},{ 7.08,58.26},{11.21,40.91},{33.04,77.84},
  {76.77,133.75},{32.99,71.45},{ 1.25,29.89},{13.05,57.13},
  {31.55,68.39},{20.69,63.25},{74.36,124.05},{87.83,169.17},
  {37.17,74.95},{21.69,69.15},{77.26,140.43},{56.52,96.59},
  {78.25,124.38},{ 9.80,48.77},{60.95,126.66},{46.63,86.70},
  {94.97,161.81},{61.19,133.42},{85.30,157.05},{88.37,150.54},
  {30.38,80.82},{40.73,86.27},{48.27,93.38},{46.61,118.92},
  {51.96,112.30},{82.10,150.30},{58.30,102.70},{28.97,82.34},
  {81.84,156.07},{85.89,142.69},{90.17,160.60},{58.45,103.11},
  {79.40,137.68},{94.20,159.11},{66.26,121.98},{44.45,101.81},
  {22.52,54.95},{20.53,54.93},{97.16,138.84},{29.85,82.22},
  {58.75,95.56},{ 0.99,31.15},{35.24,79.11},{10.50,32.69},
  {45.92,80.33},{33.26,61.15},{61.26,125.23},{90.61,151.24},
  {29.02,77.77},{18.43,67.08},{63.61,123.62},{ 4.95,54.72},
  {91.58,164.86},{ 2.86,26.95},{10.89,34.21},{69.77,129.93},
  {20.43,56.17},{91.07,151.94},{ 8.72,55.49},{60.14,101.94},
  {50.19,110.14},{37.79,92.15},{87.60,153.34},{80.46,140.40},
  {10.83,45.06},{19.50,47.35},{34.86,71.46},{82.55,140.81},
  {36.35,92.74},{31.85,75.31},{98.21,168.27},{25.65,64.68},
  { 4.79,46.84},{18.89,50.58},{89.52,160.34},{61.00,102.25},
  {62.49,101.47},{66.21,120.08},{32.70,66.67},{85.58,147.20},
  {59.00,116.78},{19.79,64.14},{ 2.64,33.66},{55.75,112.67},
  {80.93,147.05},{49.55,91.02},{47.86,86.08},{61.20,101.88},
  {42.73,75.88},{15.85,51.98},{56.58,100.71},{65.74,120.30},
  {89.83,139.14},{23.74,58.40},{66.65,121.82},{75.30,127.15},
  {81.00,129.52},{78.99,142.73},{43.96,71.36},{93.42,157.45},
  {54.27,98.74},{ 9.46,46.38},{12.22,51.82},{96.14,156.01},
  {28.15,69.90},{47.06,102.39},{65.93,124.04},{23.25,66.72},
  {27.46,70.99},{19.40,52.03},{40.86,78.16},{11.91,49.30},
  {81.71,149.06},{84.59,132.85},{99.69,156.53},{45.76,100.75},
  {43.89,103.43},{ 5.46,61.86},{68.30,128.61},{85.41,154.66},
  {93.96,157.56},{ 0.54,38.56},{60.89,99.50},{99.57,166.06},
  {12.63,50.08},{57.83,101.57},{44.80,81.37},{ 3.66,50.59},
  {10.78,21.86},{ 9.47,49.11},{32.12,74.24},{84.46,135.50},
  {82.40,133.58},{34.94,74.69},{37.31,87.09},{ 0.98,29.20},
  {35.72,71.97},{41.90,95.63},{34.26,71.61},{64.62,123.18},
  {51.52,96.68},{26.67,72.74},{53.44,107.30},{42.70,87.66},
  {41.63,92.62},{10.04,44.58},{11.52,52.76},{27.46,70.45},
  {52.10,108.50},{13.78,66.70},{83.67,150.71},{83.01,152.01},
  {12.59,56.94},{ 8.03,50.32},{ 1.82,45.23},{34.37,57.19},
  {11.47,31.80},{92.91,126.10},{ 2.40,36.52},{62.51,116.81},
  {46.88,105.13},{53.38,110.69},{83.84,138.87},{91.99,167.77},
  {71.92,124.48},{39.36,84.07},{48.84,100.12},{99.64,169.86},
  {37.00,93.86},{31.98,82.30},{87.31,142.57},{45.93,93.09},
  { 6.42,48.32},{75.90,146.51},{ 2.14,23.27},{ 6.73,51.36},
  {48.43,92.35},{52.32,97.82},{57.85,107.39},{39.53,79.74},
  {69.47,117.61},{23.80,62.52},{ 2.79,29.28},{ 4.22,49.86},
  {76.98,144.11},{43.84,87.16},{12.92,40.18},{39.93,87.48},
  {75.42,118.12},{39.90,86.14},{52.81,114.23},{83.17,146.47},
  { 9.68,48.13},{69.79,122.59},{15.47,53.40},{39.36,94.16},
  {42.72,107.97},{58.18,93.58},{30.34,76.23},{ 4.26,24.92},
  {26.24,73.74},{53.53,107.66},{29.63,68.98},{59.69,110.63},
  {46.12,95.88},{65.15,113.95},{94.83,144.88},{61.43,101.46},
  {79.21,135.09},{88.66,155.32},{51.55,101.32},{41.81,98.30},
  {96.05,161.13},{44.75,108.04},{22.12,66.55},{24.89,62.24},
  {31.15,86.25},{36.86,91.64},{ 7.99,56.86},{22.93,63.10},
  {64.98,90.77},{58.74,125.70},{20.54,55.25},{78.33,137.23},
  {82.73,153.66},{11.39,46.82},{19.32,61.82},{26.50,71.45},
  { 7.50,49.88},{65.94,126.63},{35.42,72.80},{76.44,141.29},
  { 6.09,60.21},{52.65,117.56},{52.39,101.29},{25.83,70.15},
  {33.56,69.65},{ 7.33,37.91},{11.41,42.83},{56.62,112.19},
  { 6.50,41.54},{65.36,115.60},{86.39,132.14},{ 6.46,22.42},
  {53.02,116.69},{11.39,42.43},{49.49,102.72},{58.35,105.64},
  {48.49,93.73},{53.84,96.47},{44.67,83.11},{12.52,54.13},
  {81.10,154.15},{ 8.91,55.18},{55.47,108.23},{59.27,125.01},
  {40.15,105.41},{62.31,128.10},{ 2.64,31.22},{91.46,153.05},
  {74.79,137.07},{22.00,60.85},{48.25,66.27},{31.07,55.35},
  {99.43,167.69},{58.61,110.83},{ 8.74,45.26},{40.89,81.83},
  { 8.07,46.47},{81.47,143.52},{20.48,62.89},{66.21,121.29},
  {64.47,131.27},{23.27,75.31},{25.81,97.23},{81.82,141.75},
  {57.93,102.03},{32.67,80.39},{53.58,115.67},{73.34,141.86},
  {98.22,159.46},{17.55,57.75},{ 5.13,53.34},{40.18,87.19},
  {78.34,132.14},{71.08,136.72},{74.29,128.71},{52.15,110.47},
  {33.71,81.08},{51.33,87.46},{29.77,94.79},{28.26,76.34},
  {92.57,157.40},{93.84,172.74},{ 9.13,51.03},{23.50,46.37},
  {57.44,90.30},{10.05,50.90},{ 8.47,33.74},{11.35,59.42},
  {78.53,123.18},{97.12,164.55},{83.59,134.47},{55.47,118.31},
  {38.25,80.18},{21.33,62.64},{27.82,83.56},{32.73,55.80},
  {71.17,133.84},{92.01,157.99},{17.62,48.16},{82.54,158.45},
  {40.62,77.54},{43.98,85.94},{66.45,136.31},{66.20,119.80},
  {30.71,70.20},{93.78,152.38},{88.71,154.33},{28.83,74.37},
  {64.97,125.14},{64.85,111.34},{70.43,122.25},{77.78,123.19},
  {45.93,100.59},{13.38,43.19},{52.62,96.97},{83.78,142.15},
  {42.80,79.58},{67.94,106.57},{24.08,61.09},{75.76,125.71},
  { 4.52,42.12},{89.80,148.31},{ 7.62,39.74},{26.90,66.35},
  {60.34,124.21},{83.29,138.70},{52.39,104.57},{55.97,112.73},
  {78.80,129.25},{17.03,47.69},{58.27,109.93},{48.99,101.15},
  {58.57,100.57},{51.17,80.95},{20.86,80.08},{69.26,120.07},
  { 5.56,34.11},{56.44,111.58},{56.38,112.28},{25.47,92.76},
  {71.30,141.49},{26.30,66.17},{91.63,153.64},{86.31,150.87},
  {71.08,127.56},{18.72,69.86},{46.69,77.36},{29.02,69.91},
  {64.62,111.50},{62.67,129.28},{30.06,74.08},{53.66,93.78},
  {90.54,138.90},{23.41,72.52},{50.30,75.92},{21.96,51.95},
  {50.39,90.31},{10.12,47.62},{38.51,71.56},{80.32,161.92},
  {67.59,134.83},{32.94,69.58},{50.68,110.03},{55.14,102.49},
  {35.53,73.83},{27.85,71.35},{37.87,95.68},{77.13,134.39},
  {62.66,96.90},{38.97,90.73},{11.39,39.76},{41.97,90.25},
  {48.25,98.17},{78.93,139.09},{29.31,87.45},{30.63,65.73},
  {84.20,141.00},{89.57,165.60},{ 9.71,44.10},{23.07,51.55},
  {54.70,92.49},{92.63,147.99},{39.05,77.61},{30.13,77.69},
  {96.19,164.77},{35.73,88.90},{62.12,119.52},{94.80,162.03},
  {81.35,141.94},{ 0.03,30.20},{76.16,140.54},{26.10,86.91},
  {75.44,137.38},{97.34,166.59},{24.75,86.17},{96.95,169.17},
  {37.96,91.41},{59.64,94.86},{80.90,137.20},{62.06,127.69},
  {49.15,81.28},{66.99,131.85},{27.80,85.89},{94.81,155.85},
  {70.15,124.55},{40.24,99.85},{75.97,140.63},{62.89,111.40},
  {97.96,161.36},{29.10,74.01},{86.77,155.58},{ 1.72,45.19},
  {84.14,146.98},{53.53,101.31},{44.61,86.68},{88.78,145.86},
  {89.13,152.13},{43.27,84.02},{21.45,62.22},{39.51,95.07},
  {60.87,111.71},{32.46,98.03},{42.22,88.28},{11.35,51.14},
  {65.75,103.46},{97.34,165.81},{ 1.95,34.25},{34.67,54.13},
  {91.65,130.56},{52.66,83.06},{ 5.28,43.97},{16.27,38.54},
  {45.90,91.47},{98.75,173.56},{38.59,83.02},{30.95,74.27},
  {52.35,89.28},{15.20,45.19},{78.63,138.11},{68.61,112.98},
  {27.40,83.10},{37.56,93.54},{73.93,119.74},{78.76,126.99},
  {19.34,64.20},{41.68,88.98},{46.86,104.98},{64.65,126.49},
  { 9.84,42.12},{82.19,158.11},{84.25,164.14},{66.91,128.93},
  {18.23,51.05},{30.16,51.36},{ 3.22,49.29},{56.16,102.79},
  {73.30,127.84},{ 9.61,46.51},{69.38,126.25},{61.21,119.13},
  { 6.80,56.52},{45.93,85.27},{65.19,126.47},{35.62,67.20},
  {75.92,127.33},{85.11,154.35},{38.06,80.23},{83.37,133.27},
  {38.99,104.31},{49.04,98.81},{22.22,69.14},{92.11,153.89},
  {64.47,117.69},{73.09,123.90},{89.23,141.91},{89.64,149.03},
  {37.18,78.53},{ 8.09,48.76},{29.75,73.52},{65.93,115.28},
  {11.59,51.08},{56.33,121.44},{17.43,44.22},{81.80,126.95},
  {10.48,42.98},{ 9.56,51.95},{57.53,109.77},{39.33,104.40},
  {72.87,126.32},{ 5.48,27.14},{ 5.55,35.27},{16.47,59.61},
  {26.20,77.42},{22.54,55.07},{34.68,95.92},{29.58,60.17},
  {85.86,139.31},{97.99,159.54},{89.28,159.18},{35.95,93.54},
  { 9.30,52.11},{69.28,138.57},{66.97,135.08},{33.89,64.49},
  { 3.44,33.11},{73.07,128.74},{80.15,117.34},{73.89,120.38},
  {33.96,78.74},{51.70,93.38},{22.73,59.00},{41.65,86.22},
  {62.65,125.59},{32.89,67.71},{97.63,171.24},{88.86,164.21},
  {41.43,92.68},{ 0.45,38.49},{15.81,58.56},{15.13,44.16},
  {37.25,86.96},{43.15,88.16},{ 4.28,30.20},{88.71,161.50},
  {38.96,77.97},{90.28,145.13},{64.52,101.31},{15.35,57.64},
  {49.62,93.49},{ 3.52,25.43},{82.41,141.06},{91.46,168.64},
  {82.11,141.20},{87.83,145.49},{75.96,115.41},{89.78,150.54},
  {52.64,88.18},{20.56,56.77},{20.57,53.84},{ 0.25,27.55},
  {95.28,155.47},{44.27,99.18},{95.02,145.89},{ 1.98,45.53},
  {93.87,143.86},{14.10,56.01},{38.17,75.59},{19.86,58.24},
  {45.36,101.90},{ 6.95,63.58},{85.82,148.00},{68.90,118.55},
  {22.57,69.75},{47.92,111.17},{79.53,147.81},{91.50,147.24},
  {57.42,109.40},{34.40,91.33},{96.98,142.69},{73.21,141.54},
  {51.26,106.86},{95.83,171.12},{28.48,69.67},{67.52,131.14},
  {41.38,102.69},{54.51,107.24},{16.92,65.82},{36.83,87.52},
  {89.65,160.06},{20.76,63.42},{26.09,63.15},{ 7.32,36.77},
  {21.28,54.99},{37.48,88.59},{ 7.49,39.10},{22.38,64.85},
  {47.68,95.43},{99.11,162.36},{68.55,126.50},{ 1.37,51.29},
  {21.32,68.06},{26.85,68.71},{92.79,160.61},{77.57,133.32},
  {54.96,91.78},{41.13,92.66},{97.83,158.15},{17.50,58.32},
  {74.84,130.28},{81.59,141.48},{59.88,111.57},{58.20,98.21},
  {74.47,142.77},{58.72,118.42},{45.35,87.70},{38.49,92.27},
  {78.76,120.57},{12.91,55.02},{55.94,112.05},{52.81,83.76},
  {65.45,137.16},{62.12,114.92},{19.86,63.73},{39.40,104.00},
  {87.23,141.21},{54.12,101.50},{55.56,122.21},{17.95,44.35},
  {62.78,111.00},{10.52,37.86},{91.96,153.33},{42.66,89.54},
  {11.47,75.24},{96.49,165.44},{43.89,90.74},{20.36,51.37},
  {28.80,65.54},{45.55,104.84},{16.73,61.97},{82.40,144.38},
  {86.32,144.22},{70.70,113.32},{92.80,143.45},{39.04,90.76},
  {71.05,130.11},{26.39,59.69},{97.09,161.46},{80.81,147.79},
  {42.44,79.70},{41.30,85.83},{39.15,94.91},{55.08,117.42},
  { 4.29,51.07},{82.12,147.32},{65.83,112.89},{68.59,117.95},
  {15.10,35.93},{81.56,134.13},{ 8.34,50.35},{76.84,137.93},
  {61.72,115.31},{88.78,132.13},{19.61,64.58},{96.26,151.97},
  { 8.70,32.30},{ 7.61,28.60},{ 3.62,41.73},{97.46,158.55},
  {47.46,96.34},{77.40,124.96},{71.70,138.33},{12.50,43.39},
  {84.76,131.33},{76.32,150.87},{53.61,105.47},{91.55,156.41},
  {45.13,75.78},{52.21,102.83},{83.74,152.60},{13.47,48.42},
  {55.23,91.84},{61.12,115.02},{84.30,133.30},{15.93,60.33},
  {83.73,142.73},{92.37,139.03},{ 3.68,41.01},{71.95,127.08},
  {54.27,114.72},{52.37,107.05},{72.98,134.09},{10.23,48.74},
  { 5.08,44.39},{89.88,155.83},{24.53,65.76},{17.75,46.44},
  {47.44,74.55},{67.34,108.83},{85.39,151.12},{28.11,69.97},
  {58.66,135.29},{50.25,99.45},{79.97,138.24},{83.07,133.74},
  {92.45,156.72},{75.52,137.73},{58.28,125.05},{27.89,92.72},
  {99.19,165.98},{85.69,150.24},{63.90,123.00},{73.80,129.28},
  {24.32,74.44},{30.39,82.69},{60.82,108.06},{26.45,81.04},
  {37.23,97.70},{ 2.88,45.20},{ 1.83,44.48},{33.11,66.83},
  {50.58,101.71},{52.33,96.31},{72.32,126.15},{16.40,38.44},
  {53.81,121.79},{15.00,68.52},{24.89,61.86},{88.21,157.81},
  {71.94,134.93},{27.44,68.86},{31.65,67.28},{ 7.26,66.51},
  {75.74,134.12},{22.47,58.44},{32.61,92.25},{28.87,74.50},
  {32.92,77.74},{97.41,148.42},{16.19,59.59},{24.47,50.23},
  {43.14,74.40},{40.40,86.38},{56.27,108.81},{14.47,47.54},
  {90.07,158.11},{82.14,146.16},{83.47,144.99},{62.35,121.20},
  {42.20,82.19},{37.64,91.81},{69.08,88.79},{32.14,80.95},
  { 5.52,40.14},{55.71,89.94},{26.05,62.69},{49.56,100.16},
  {79.13,142.95},{34.78,68.33},{42.80,89.66},{27.22,40.42},
  {60.15,104.90},{91.22,161.89},{ 3.04,59.14},{95.86,177.76},
  {98.69,160.57},{61.47,107.57},{67.00,146.75},{38.29,65.52},
  {19.73,64.24},{20.96,68.66},{25.99,69.36},{68.08,116.16},
  {17.99,59.41},{44.36,95.32},{24.19,54.94},{40.07,96.17},
  {64.16,113.89},{ 6.80,52.64},{62.71,102.79},{70.46,114.76},
  {75.60,133.55},{32.76,71.87},{19.13,60.08},{49.90,92.52},
  {35.31,72.27},{61.72,133.80},{86.50,145.53},{11.83,45.72},
  {20.54,67.86},{44.27,119.83},{88.69,169.41},{50.40,101.31},
  {41.16,81.55},{49.37,99.91},{28.17,74.30},{ 0.67,32.54},
  {75.04,125.67},{43.73,98.11},{98.29,161.62},{ 2.78,37.29},
  { 2.87,35.28},{65.57,98.16},{55.35,121.82},{76.59,114.64},
  {28.37,73.69},{49.68,79.61},{77.90,125.07},{68.58,134.97},
  {36.81,78.69},{47.34,93.22},{55.76,122.80},{77.30,140.19},
  {69.24,118.57},{ 6.26,43.91},{31.13,69.37},{25.27,40.97},
  {51.55,87.23},{72.00,129.52},{67.84,117.33},{16.75,61.75},
  {60.46,123.82},{86.48,144.19},{32.65,89.43},{19.37,64.02},
  {43.58,77.28},{39.18,71.92},{12.25,47.77},{55.90,121.56},
  {91.01,145.92},{57.97,95.12},{ 0.72,39.01},{50.36,97.80},
  {83.65,145.58},{28.05,63.44},{70.27,125.92},{64.64,97.51},
  {42.99,94.15},{51.87,118.66},{19.72,65.03},{88.40,140.06}
};


double residual_error(double x, double y, double m, double c) {
	double e = (m * x) + c - y;
  	return e * e;
}

__device__ double residual_err(double x, double y, double m, double c) {
	double e = (m * x) + c - y;
  	return e * e;
}



int time_difference(struct timespec *start, struct timespec *finish,
                    long long int *difference) {
  	long long int ds =  finish->tv_sec - start->tv_sec; 
  	long long int dn =  finish->tv_nsec - start->tv_nsec; 

	if(dn < 0 ) {
    	ds--;
    	dn += 1000000000; 
  	} 
  	*difference = ds * 1000000000 + dn;
  	return !(*difference > 0);
	}

double rms_error(double m, double c) {
  	int i;
  	double mean;
  	double error_sum = 0;
  
  	for(i=0; i<n_data; i++) {
    	error_sum += residual_error(data[i].x, data[i].y, m, c);  
  	}
  
  	mean = error_sum / n_data;
  
  	return sqrt(mean);
}

__global__ void find_err(mean_intercept *mi, point_t *data, double *eacherror) {
  	int i;
  	i = threadIdx.x + blockIdx.x * blockDim.x;
	eacherror[i] = residual_err(data[i].x, data[i].y, mi->mean, mi->intercept);  	
}



int main() {
  	int i;
  	double bm = 1.3;
  	double bc = 10;
	double be;
	double dm[8];
  	double dc[8];
  	double e[8];
 	double step = 0.01;
  	double best_error = 999999999;
  	int best_error_i;
  	int minimum_found = 0;

  	struct timespec start, finish;   
  	long long int time_elapsed;
	double *eacherror;
	point_t *d_data;
	mean_intercept *mi;
	double total_error;
	double mean;

	
  	double om[] = {0,1,1, 1, 0,-1,-1,-1};
  	double oc[] = {1,1,0,-1,-1,-1, 0, 1};
	
	// allocate Unified Memory -- accessible from both CPU and GPU  
	cudaMallocManaged((void **)&mi, sizeof(mean_intercept) * 8);
	cudaMallocManaged(&eacherror, sizeof(double) * 1000);

	// dynamically allocates memory on device (GPU)
	cudaMalloc(&d_data, sizeof(point_t) * 1000);

  	clock_gettime(CLOCK_MONOTONIC, &start);

  	be = rms_error(bm, bc);

	// Transfer data from CPU (host) to GPU (device)
	cudaMemcpy(d_data,data, sizeof(data), cudaMemcpyHostToDevice);

	// defining block and grid dimensions of (10(x),1(y),1(z)) and (100 (x), 1(y), 1(x))
	dim3 bd(10, 1, 1);
  	dim3 gd(100, 1, 1);

  	while(!minimum_found) {
    	for(i=0;i<8;i++) {
     		dm[i] = bm + (om[i] * step);
      		dc[i] = bc + (oc[i] * step);

			mi[i].mean = dm[i];
			mi[i].intercept = dc[i];
			//executes kernal function passing three variables as parameter
 		 	// <<<gd,bd>>> represents grid and block dimensions respectively
      		find_err<<<gd,bd>>>(&mi[i],d_data,eacherror);
			
			// Wait for GPU to finish before accessing on host
			cudaDeviceSynchronize();
	
			for (int k = 0; k < 1000; k++){
				
				total_error += eacherror[k];
			}
				mean = total_error/1000 ;
							

				e[i] = sqrt(mean);
		  		if(e[i] < best_error) {
		    		best_error = e[i];
		    		best_error_i = i;
      			}
				total_error = 0;
		}
    	

    	/*printf("best m,c is %lf,%lf with error %lf in direction %d\n", 
      	dm[best_error_i], dc[best_error_i], best_error, best_error_i);*/
    	if(best_error < be) {
      		be = best_error;
      		bm = dm[best_error_i];
      		bc = dc[best_error_i];
    	} else {
      	minimum_found = 1;
    	}
  	}
  	printf("minimum m,c is %lf,%lf with error %lf\n", bm, bc, be);
	
  	clock_gettime(CLOCK_MONOTONIC, &finish);
  	time_difference(&start, &finish, &time_elapsed);
  	printf("Time elapsed was %lldns or %0.9lfs\n", time_elapsed,(time_elapsed/1.0e9));

	// Free memory
	cudaFree(&mi);
	cudaFree(&eacherror);
	cudaFree(&d_data); 
  	return 0;
}


