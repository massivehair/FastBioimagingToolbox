function [DriftVectors, varargout] = PIV_DeDriftGetVectors(ImageStack, varargin)

Parser = inputParser;

addOptional(Parser,'InitialReferenceFrame',[],@isnumeric);
addOptional(Parser,'ReferenceDriftThreshold',ceil(min(size(ImageStack,1), size(ImageStack,2))./10),@isnumeric);
addOptional(Parser,'WindowSize',[128,128],@isnumeric);
addOptional(Parser,'MaxStep',[256,256],@isnumeric);
addOptional(Parser,'WeightByIntensity',true,@islogical);
addOptional(Parser,'PreProcessRefFrame',false,@islogical);
addOptional(Parser,'KnownOffset',[0,0],@isnumeric);

parse(Parser,varargin{:});

u_known = Parser.Results.KnownOffset(1);
v_known = Parser.Results.KnownOffset(2);

DriftVectors = NaN(size(ImageStack,3), 2);

if ~isempty(Parser.Results.InitialReferenceFrame)
    if Parser.Results.PreProcessRefFrame
        RefFrame = PIV_DeDriftPreprocess(Parser.Results.InitialReferenceFrame);
    else
        RefFrame = Parser.Results.InitialReferenceFrame;
    end
    
    CurrentFrame = PIV_DeDriftPreprocess(ImageStack(:,:,1));
    [XCorrMap, Locations] = PIV_xcorr(RefFrame, CurrentFrame, Parser.Results.WindowSize, Parser.Results.MaxStep);
    switch Parser.Results.WeightByIntensity % Weight the correlation maps by the window intensity?
        case false
            XCorrSum = sum(XCorrMap,3);
        case true
            XCorrSum = zeros(size(XCorrMap,1), size(XCorrMap,2));
            for kndex = 1:size(Locations,1)
                Window = ImageStack(max(Locations(kndex,1)-(Parser.Results.WindowSize(1)/2),1):...
                    min(Locations(kndex,1)+(Parser.Results.WindowSize(1)/2),size(ImageStack,1)),...
                    max(Locations(kndex,2)-(Parser.Results.WindowSize(2)/2),1):...
                    min(Locations(kndex,2)+(Parser.Results.WindowSize(2)/2),size(ImageStack,2)), 1);
                XCorrSum = XCorrSum + sum(Window(:)).*XCorrMap(:,:,kndex);
            end
    end
    
    [u_sum, v_sum] = PIV_GetFlow(XCorrSum);
    DriftVectors(1,:) = [u_known-u_sum, v_known-v_sum];
    
    if sqrt(u_sum.^2 + v_sum.^2) > Parser.Results.ReferenceDriftThreshold
        RefFrame = CurrentFrame;
        u_known = DriftVectors(1,1);
        v_known = DriftVectors(1,2);
    end
else
    RefFrame = PIV_DeDriftPreprocess(ImageStack(:,:,1));
    DriftVectors(1,:) = [u_known,v_known];
end

for index = 2:size(ImageStack,3)
    CurrentFrame = PIV_DeDriftPreprocess(ImageStack(:,:,index));
    
    [XCorrMap, Locations] = PIV_xcorr(RefFrame, CurrentFrame, Parser.Results.WindowSize, Parser.Results.MaxStep);
    switch Parser.Results.WeightByIntensity % Weight the correlation maps by the window intensity?
        case false
            XCorrSum = sum(XCorrMap,3);
        case true
            XCorrSum = zeros(size(XCorrMap,1), size(XCorrMap,2));
            for kndex = 1:size(Locations,1)
                Window = ImageStack(max(Locations(kndex,1)-(Parser.Results.WindowSize(1)/2),1):...
                    min(Locations(kndex,1)+(Parser.Results.WindowSize(1)/2),size(ImageStack,1)),...
                    max(Locations(kndex,2)-(Parser.Results.WindowSize(2)/2),1):...
                    min(Locations(kndex,2)+(Parser.Results.WindowSize(2)/2),size(ImageStack,2)), index);
                XCorrSum = XCorrSum + sum(Window(:)).*XCorrMap(:,:,kndex);
            end
    end
    
    [u_sum, v_sum] = PIV_GetFlow(XCorrSum);
    DriftVectors(index,:) = [u_known-u_sum, v_known-v_sum];
    
    if sqrt(u_sum.^2 + v_sum.^2) > Parser.Results.ReferenceDriftThreshold
        RefFrame = CurrentFrame;
        u_known = DriftVectors(index,1);
        v_known = DriftVectors(index,2);
    end
end

if nargout >= 2
    varargout{1} = RefFrame;
end

if nargout >= 3
    varargout{2} = [u_known, v_known];
end