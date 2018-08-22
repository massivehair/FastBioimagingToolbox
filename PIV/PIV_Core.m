function [x, y, u, v, varargout] = PIV_Core(DataIn, Mask, varargin)
%%% [x, y, u, v, Certainty, u_sum, v_sum, Certainty_sum] = PIV_Core(DataIn, Mask, WindowSize, MaxStep, PIVMethod, SmoothMethod, FiltSize, CertaintyThresh)
%%%
%%% DataIn is a height x width x frames array of pre-processed data.
%%% Mask is a logical array of pixels to exclude from PIV.
%%% WindowSize is the size of the cross-correlation window.
%%% MaxStep is how far the cross-correlation window can move to find a
%%% correlation.
%%% PIVMethod can be 'RMS Deviation' or 'Cross-correlation' (default); RMS
%%% takes the mean squared error between frames, whereas cross-correlation
%%% takes the cross correlation.
%%% SmoothMethod is the method used to smooth the data before PIV. It can
%%% be 'Savitzky Golay', 'Wiener' (default) or 'Gaussian'.
%%% FiltSize is the size of the smoothing filter.
%%%
%%% x and y are the coordinates where the correlation windows are taken
%%% from.
%%% u and v are the displacement vectors obtained from cross-correlation.
%%% Certainty is the ratio of the cross-correlation peak to the sum of the
%%% autocorrelation function.
%%% u_sum, v_sum and Certainty_sum are the same values, but summed over all
%%% frames.

%% Set defaults
if nargin > 2
    WindowSize = varargin{1};
    if isempty(WindowSize)
        WindowSize = [8,8];
    end
else
    WindowSize = [8,8];
end
if nargin > 3
    MaxStep = varargin{2};
    if isempty(MaxStep)
        MaxStep = [24,24];
    end
else
    MaxStep = [24,24];
end
if nargin > 4
    PIVMethod = varargin{3};
    if isempty(PIVMethod)
        PIVMethod = 'Cross-correlation';
    end
else
    PIVMethod = 'Cross-correlation';
end
if nargin > 5
    SmoothMethod = varargin{4};
    if isempty(PIVMethod)
        SmoothMethod = 'Wiener';
    end
else
    SmoothMethod = 'Wiener';
end
if nargin > 6
    FiltSize = varargin{5};
    if isempty(FiltSize)
        FiltSize = 5;
    end
else
    FiltSize = 5;
end
if nargin > 7
    CertaintyThresh = varargin{6};
    if isempty(CertaintyThresh)
        CertaintyThresh = -Inf;
    end
else
    CertaintyThresh = -Inf;
end

%% Algorithm

for index = 1:size(DataIn,3);
    switch SmoothMethod
        case 'Savitzky Golay'
            DataIn(:,:,index) = savitzkyGolay2D_rle_coupling(size(DataIn, 1), size(DataIn, 2), double(DataIn(:,:,index)), FiltSize, FiltSize, 2);
        case 'Wiener'
            DataIn(:,:,index) = wiener2(DataIn(:,:,index), [FiltSize, FiltSize]);
        case 'Gaussian'
            DataIn(:,:,index) = imgaussfilt(DataIn(:,:,index), FiltSize);
    end
end

switch 'Low memory'
    case 'Low memory'
        for index = 1:size(DataIn,3)-1;
            switch PIVMethod
                case 'RMS Deviation'
                    [XCorrMap, Locations] = PIV_ShiftRMS(DataIn(:,:,index), DataIn(:,:,index+1), WindowSize, [0,0],  MaxStep, Mask);
                otherwise % Cross correlation
                    [XCorrMap, Locations] = PIV_xcorr(DataIn(:,:,index), DataIn(:,:,index+1), WindowSize, MaxStep, Mask);
            end
            if index == 1
                y = Locations(:,1);
                x = Locations(:,2);
                u = cell(size(DataIn,3)-1,1);
                v = u;
                Certainty = u;
                XCorrSum = zeros(size(XCorrMap));
                XCorrCumul = zeros(size(XCorrMap));
            end
            XCorrCumul = XCorrCumul + XCorrMap;
            [u{index}, v{index}, MaxVals] = PIV_GetFlow(XCorrCumul);
            Certainty{index} = MaxVals./squeeze(sum(sum(XCorrMap)));
            
            XCorrCumul(:,:,Certainty{index} > CertaintyThresh) = 0;
            
            XCorrSum = XCorrSum + XCorrMap;
        end
        
        [u_sum, v_sum, MaxVals] = PIV_GetFlow(XCorrSum);
        Certainty_sum = MaxVals./squeeze(sum(sum(XCorrSum)));
        
    otherwise
        for index = 1:size(DataIn,3)-1;
            switch PIVMethod
                case 'RMS Deviation'
                    [XCorrMap, Locations] = PIV_ShiftRMS(DataIn(:,:,index), DataIn(:,:,index+1), WindowSize, [0,0],  MaxStep, Mask);
                otherwise
                    [XCorrMap, Locations] = PIV_xcorr(DataIn(:,:,index), DataIn(:,:,index+1), WindowSize, MaxStep, Mask);
            end
            if index == 1
                y = Locations(:,1);
                x = Locations(:,2);
                u = cell(size(DataIn,3)-1,1);
                v = u;
                MaxVals = u;
                XCorrArray = cell(size(DataIn,3)-1,1);
            end
            XCorrArray{index} = XCorrMap;
            [u{index}, v{index}, MaxVals{index}] = PIV_GetFlow(XCorrMap);
            
        end
        
        XCorrSum = XCorrArray{1};
        for index = 2:size(XCorrArray,1)
            XCorrSum = XCorrSum + XCorrArray{index};
        end
        
        [u_sum, v_sum, MaxVals_sum] = PIV_GetFlow(XCorrSum);
        Certainty_sum = MaxVals_sum./squeeze(sum(sum(XCorrSum)));
        
        Certainty = cell(size(DataIn,3)-1,1);
        for index = 1:size(MaxVals,1)
            %MinXCorrMap = squeeze(min(min(XCorrArray{index})));
            %Certainty{index} = (MaxVals{index}-MinXCorrMap)./(squeeze(sum(sum(XCorrArray{index})))./((size(XCorrArray{index},1).*size(XCorrArray{index},2)))-MinXCorrMap);
            Certainty{index} = MaxVals{index}./squeeze(sum(sum(XCorrArray{index})));
        end
end

if nargout > 4
    varargout{1} = Certainty;
end
if nargout > 5
    varargout{2} = u_sum;
end
if nargout > 6
    varargout{3} = v_sum;
end
if nargout > 7
    varargout{4} = Certainty_sum;
end