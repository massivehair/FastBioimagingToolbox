function DataOut = PIV_TiffRead(PathIn, varargin)
%%% Load data from a TIFF file
%%%
%%% DataOut = PIV_TiffRead(PathIn, NumberImages)
%%%
%%% PathIn is the complete path to the .tif file
%%% NumberImages is the number of images to load from the TIFF file
%%%
%%% DataOut is the data in the TIFF file, in the format Height x Width x
%%% Number of Frames.

TifLink = Tiff(PathIn, 'r');
InfoImage=imfinfo(PathIn);
if nargin > 1
    NumberImages = varargin{1};
else
    NumberImages=length(InfoImage);
end

DataOut = zeros([InfoImage(1).Height, InfoImage(1).Width, NumberImages], 'int16');
for index=1:NumberImages
    TifLink.setDirectory(index);
    Frame = TifLink.read();
    
    DataOut(:,:,index) = int16(Frame);
end
TifLink.close();
