function [XCorrMap, varargout] = PIV_xcorr(Image, Image2, WindowSize, MaxStep, varargin)
%%% Get the cross-correlation for each location in the image
% [XCorrMap, LocationsOut] = PIV_xcorr(Image, Image2, WindowSize, MaxStep, Mask, Locations)
% Image and Image2 are the frames before and after motion respectively
% WindowSize controls the size of the interrogation window: size of the window = WindowSize*2 + 1
% MaxStep is the largest step over which the cross-correlation is
% calculated, and is not always used
% Mask is a logical array that masks out unwanted pixels in Image and
% Image2
% Locations is an array describing the locations at which correlations will
% be measured
%
% XCorrMap is a 3D array describing the cross-correlation at each point
% described in Locations
% LocationsOut returns the locations that are measured

if nargin <= 4
    Mask = ones(size(Image));
    [Y, X] = meshgrid(1:WindowSize(1):size(Image,1), 1:WindowSize(2):size(Image,2));
    Locations = [Y(:),X(:)];
elseif nargin == 5
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

if any(MaxStep > WindowSize)
    FrameType = 'Big Frame';
else
    FrameType = 'Small Frame';
end

XCorrMap = zeros(2*MaxStep(1)+1, 2*MaxStep(2)+1, size(Locations,3));
switch FrameType
    case 'Big Frame'
        ImageCopy = double(Image)-mean(Image(:));
        Image2Copy = double(Image2)-mean(Image2(:));
    case 'Small Frame'
        ImageCopy = double(Image);
        Image2Copy = double(Image2);
end

%ImageCopy(Mask) = 0;
ImageCopy = padarray(ImageCopy, WindowSize+MaxStep);
%Image2Copy(Mask) = 0;
Image2Copy = padarray(Image2Copy, WindowSize+MaxStep);
for Index = 1:size(Locations, 1)
    Window = ImageCopy(Locations(Index, 1) + MaxStep(1) : ...
        Locations(Index, 1) + 2*WindowSize(1) + MaxStep(1), ...
        Locations(Index, 2) + MaxStep(2) : ...
        Locations(Index, 2) + 2*WindowSize(2) + MaxStep(2));
    switch FrameType
        case 'Big Frame'
            Frame = Image2Copy(Locations(Index, 1) : ...
                Locations(Index, 1) + 2*WindowSize(1) + 2*MaxStep(1), ...
                Locations(Index, 2) : ...
                Locations(Index, 2) + 2*WindowSize(2) + 2*MaxStep(2));
            %XCorrTemp = conv2(Frame, rot90(conj(Window),2), 'valid');
            XCorrTemp = normxcorr2(Window,Frame); % Use the normalized version
            XCorrTemp = XCorrTemp(size(Window,1):size(XCorrTemp,1)-size(Window,1)+1,size(Window,2):size(XCorrTemp,2)-size(Window,2)+1);
        case 'Small Frame'
            Frame = Image2Copy(Locations(Index, 1) + MaxStep(1) : ...
                Locations(Index, 1) + 2*WindowSize(1) + MaxStep(1), ...
                Locations(Index, 2) + MaxStep(2) : ...
                Locations(Index, 2) + 2*WindowSize(2) + MaxStep(2));
            XCorrTemp = conv2(Frame, rot90(conj(Window),2), 'same');
    end
    XCorrMap(:,:,Index) = XCorrTemp;
    
    switch false % Debugging - plot the window and the frame
        case true
            figure(1)
            imagesc(Window)
            figure(2)
            imagesc(Frame)
            figure(3)
            imagesc(XCorrTemp)
            drawnow
    end
end

if nargout == 2
    varargout{1} = Locations;
end