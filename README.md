# FastBioimagingToolbox
Code accompaniment for the paper "High-Throughput Multiphoton Imaging: Seeing the Forest and the Trees"

The code is split into two parts: the code required for the Particle Imaging Velocimetry (PIV), and the code for the multicolour images and motion correction. These are in two separate folders. 

The PIV for Figure 1d,e,f,g was performed using PIV_Main_Loop.m to iterate over all the sub-frames and calculate the flow vectors for each vessel. The recovered flow vectors can then be visualized using Map_Main.m

Supplementary Video 1 was created using PlotVideo_CompareTumorNormal.m

Supplementary Video 2 was created using MovingVideoDeDrift_Main to recover the frame drift, and PlotVideo_Main to plot the flow. A single frame can be seen in Figure 1b.

Supplementary Video 3 was created using FindFrameMotionLowMem.m and ViewColourStackLowMem.m, and placed into one video using Lightworks.

Figure 2 was created using PlotVideo3Colour_Main.m to reconstruct the colour video, before taking a suitable example frame.

Dependencies: Along with the code here, you will also need savitzkyGolay2D_rle_coupling.m (https://uk.mathworks.com/matlabcentral/fileexchange/37147-savitzky-golay-smoothing-filter-for-2d-data) if you want to use some of the alternatives to Wiener Filtering in PIV_Core.m
