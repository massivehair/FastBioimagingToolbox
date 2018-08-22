function DataOut = PIV_U16Read(PathIn, FrameSize, varargin)
%%% Load data from a TIFF file
%%%
%%% DataOut = PIV_U16Read(PathIn, FrameSize, NumberImages)
%%%
%%% PathIn is the complete path to the .U16 file
%%% NumberImages is the number of images to load from the U16 file
%%%
%%% FrameSize is the size of the frame in pixels, [Height, Width]
%%%
%%% DataOut is the data in the U16 file, in the format Height x Width x
%%% Number of Frames.

try 
    FileInfo=dir(PathIn);
    if nargin > 2
        NumberImages = min(floor((FileInfo.size./2)./(FrameSize(1).*FrameSize(2))), varargin{1});
    else
        NumberImages = floor((FileInfo.bytes./2)./(FrameSize(1).*FrameSize(2)));
    end
    
    File = fopen(PathIn);
    DataOut = fread(File, FrameSize(1).*FrameSize(2).*NumberImages, 'uint16=>int16', 0, 'l');
    DataOut = reshape(DataOut, [FrameSize(1), FrameSize(2), NumberImages]);
    fclose(File);
catch
    DataOut = [];
    warning(['Error loading data from ', PathIn])
end