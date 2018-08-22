function [ShiftRMSMap, varargout] = PIV_ShiftRMS(Image, Image2, WindowSize, VectorEstimate, MaxStep, varargin)
%%% Get the cross-correlation for each location in the image
% [ShiftRMSMap, varargout] = PIV_ShiftRMS(Image, Image2, WindowSize, VectorEstimate, MaxStep, varargin)
% Image and Image2 are the frames before and after motion respectively
% WindowSize is the size of the interrogation window
% MaxStep is the largest step over which the cross-correlation is
% calculated, and is not always used
% Mask is a logical array that masks out unwanted pixels in Image and
% Image2
% Locations is an array describing the locations at which correlations will
% be measured
%
% ShiftRMSMap is a 3D array describing the cross-correlation at each point
% described in Locations
% LocationsOut returns the locations that are measured

if nargin <= 5
    Mask = ones(size(Image));
    [Y, X] = meshgrid(1:WindowSize(1):size(Image,1), 1:WindowSize(2):size(Image,2));
    Locations = [Y(:),X(:)];
elseif nargin == 6
    Mask = varargin{1};
    [Y, X] = meshgrid(1:WindowSize(1):size(Image,1), 1:WindowSize(2):size(Image,2));
    Locations = [Y(:),X(:)];
    MaskedLocs = false(size(Locations,1),1);
    for Index = 1:size(Locations, 1)
        MaskedLocs(Index) = Mask(Locations(Index,1), Locations(Index,2));
    end
    Locations = Locations(~MaskedLocs,:);
else
    Mask = varargin{1};
    Locations = varargin{2};
end

ShiftRMSMap = zeros(2*MaxStep(1)+1, 2*MaxStep(2)+1, size(Locations,3));

ImageCopy = double(Image);
Image2Copy = double(Image2);

ImageCopy(Mask) = NaN;
ImageCopy = padarray(ImageCopy, WindowSize, NaN);
Image2Copy(Mask) = NaN;
Image2Copy = padarray(Image2Copy, WindowSize + MaxStep + abs(VectorEstimate), NaN);
I = (-MaxStep(1):MaxStep(1))+VectorEstimate(1);
J = (-MaxStep(2):MaxStep(2))+VectorEstimate(2);
for Index = 1:size(Locations, 1)
    Window = ImageCopy(Locations(Index, 1) : ...
        Locations(Index, 1) + 2*WindowSize(1), ...
        Locations(Index, 2) : ...
        Locations(Index, 2) + 2*WindowSize(2));
    
    ShiftRMSTemp = zeros(MaxStep*2 + 1);

    for Jndex = 1:size(ShiftRMSTemp,1)
        for Kndex = 1:size(ShiftRMSTemp,2)
            Window2 = Image2Copy(Locations(Index, 1) + MaxStep(1) + I(Jndex): ...
                Locations(Index, 1) + 2*WindowSize(1) + MaxStep(1) + I(Jndex), ...
                Locations(Index, 2) + MaxStep(2) + J(Kndex): ...
                Locations(Index, 2) + 2*WindowSize(2) + MaxStep(2) + J(Kndex));
            WindowDifference = Window(:)-Window2(:);
            ShiftRMSTemp(Jndex, Kndex) = sqrt(nanmean((WindowDifference).^2));%.*sum(isnan(WindowDifference));
        end
    end
    
    ShiftRMSMap(:,:,Index) = -ShiftRMSTemp;
end

if nargout == 2
    varargout{1} = Locations;
end

ShiftRMSMap = ShiftRMSMap - min(ShiftRMSMap(:)) + 1;