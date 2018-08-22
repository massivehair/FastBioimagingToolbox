function FrameOut = PIV_DeDriftPreprocess(Frame, varargin)

Parser = inputParser;

addOptional(Parser,'RemoveWhiteBands',true,@islogical);
addParameter(Parser,'LowPassMethod','Median',...
    @(x) any(validatestring(x,{'None', 'Median', 'Gaussian'})));
addOptional(Parser,'LP_MedianSize',[21,21],@isnumeric);
addOptional(Parser,'LP_GaussianSize',11,@isnumeric);
addParameter(Parser,'HighPassMethod','EdgeEnhancement',...
    @(x) any(validatestring(x,{'None', 'EdgeEnhancement'})));
addOptional(Parser,'HP_EdgeSmoothSize',5,@isnumeric);
addOptional(Parser,'HP_SharpenSize',21,@isnumeric);
addOptional(Parser,'HP_SharpenAmount',1,@isnumeric);
addOptional(Parser,'HP_SharpenThreshold',0.1,@isnumeric);

parse(Parser,varargin{:});

FrameOut = Frame;

if Parser.Results.RemoveWhiteBands
    if isa(FrameOut, 'uint16')
        SatValue = 65535;
    else
        SatValue = 255;
    end
    
    for kndex = 1:size(FrameOut,1)
        SatPix = FrameOut(kndex,:) >= SatValue;
        if mean(SatPix) > 0.2 % More than 20% of pixels are fully on in the row
            FrameOut(kndex,SatPix) = 0;
        end
    end
end

switch Parser.Results.LowPassMethod
    case 'Median'
        FrameOut = medfilt2(FrameOut, [Parser.Results.LP_MedianSize(1), Parser.Results.LP_MedianSize(2)]);
    case 'Gaussian'
        FrameOut = imgaussfilt(FrameOut, Parser.Results.LP_GaussianSize);
end

switch Parser.Results.HighPassMethod
    case 'EdgeEnhancement'
        FrameOut = imgaussfilt(FrameOut,Parser.Results.HP_EdgeSmoothSize);
        [FrameOut, ~] = imgradient(FrameOut, 'sobel');
    case 'Sharpen'
        FrameOut = imsharpen(FrameOut, 'Radius', Parser.Results.HP_SharpenSize, ...
            'Amount', Parser.Results.HP_SharpenAmount, 'Threshold', Parser.Results.HP_SharpenThreshold);
end