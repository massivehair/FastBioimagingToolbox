function [PIVData, MaskData] = PIV_Preprocess(DataIn, varargin)
%%% Preprocess the data to find the blood vessels as well as enhance the
%%% differences

Parser = inputParser;

addParameter(Parser,'Contrast','stdIntensity',...
    @(x) any(validatestring(x,{'max', 'mean', 'std', 'kurtosisIntensity', ...
    'meanIntensity', 'stdIntensity', 'IntensityAndFlow', 'StdFiltering', 'HighPassStd'})));
addOptional(Parser,'MaskThreshold',0.2,@isnumeric);

parse(Parser,varargin{:});


PIVData = DataIn(:,:,1:end);
if size(PIVData,3) > 1
    MeanData = cast(mean(DataIn,3), 'like', DataIn);
else
    MeanData = zeros('like', DataIn);
end
for index = 1:size(PIVData,3)
    %DiffData(:,:,index) = abs(Data(:,:,index)-Data(:,:,index+1));
    %DiffData(:,:,index) = Data(:,:,index)-Data(:,:,index+1);
    PIVData(:,:,index) = DataIn(:,:,index)-MeanData;
end

switch Parser.Results.Contrast
    case 'max'
        MaskData = max(PIVData,[],3);
    case 'mean'
        MaskData = mean(PIVData,3);
    case 'std'
        MaskData = std(single(PIVData),0,3);
    case 'kurtosisIntensity'
        MaskData = inpaint_nans(kurtosis(double(DataIn),1,3));
    case 'meanIntensity'
        MaskData = mean(DataIn,3);
    case 'stdIntensity'
        SmoothData = DataIn;
        for index = 1:size(SmoothData,3)
            SmoothData(:,:,index) = sort(DataIn(:,:,index),1);
            SmoothData(:,:,index) = DataIn(:,:,index) - repmat(SmoothData(100,:,index), [size(SmoothData,1),1]); % demodulate
            SmoothData(:,:,index) = imgaussfilt(SmoothData(:,:,index),2);
        end
        
        MaskData = std(single(SmoothData),0,3);
        
        MaskData = imgaussfilt(MaskData,2);
        MaskData = MaskData-imerode(MaskData, strel('disk', 25, 0));
    case 'IntensityAndFlow'
        MaskData = mean(PIVData,3) .* ((inpaint_nans(kurtosis(double(DataIn),1,3))).^0.4);
    case 'StdFiltering'
        Disk = strel('disk',13);
        FilterNHood = getnhood(Disk);
        MaskData = zeros(size(PIVData,1), size(PIVData,2));
        for index = 1:size(PIVData,3)
            MaskData = MaskData + stdfilt(double(PIVData(:,:,index)), FilterNHood);
        end
        MaskData = MaskData./size(PIVData,3);
    case 'HighPassStd'
        Disk = strel('disk',13);
        FilterNHood = getnhood(Disk);
        MaskData = zeros(size(PIVData,1), size(PIVData,2));
        for index = 1:size(PIVData,3)
            MaskData = MaskData + stdfilt(imsharpen(double(PIVData(:,:,index)), 'Radius', 2, 'Amount', 5, 'Threshold', 0.1), FilterNHood);
        end
        MaskData = MaskData./size(PIVData,3);
end

MaskData = MaskData < Parser.Results.MaskThreshold;