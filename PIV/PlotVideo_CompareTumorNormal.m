% Create a video comparing flow in two different locations
%% Set up parameters
Directory = 'D:\Projects\High Speed SWIR QDot Temporal Focusing\21st August 2015\Green dots\';
FileRoot = '(4) moving around 100fps';
LeftStartFrame = 16800; % 7000 or 101 or 20450
RightStartFrame = 21900; %18500
ClipLength = 300;
WriteVid = true;

if exist([Directory, FileRoot, '_Drift.mat'], 'file')
    load([Directory, FileRoot, '_Drift.mat']) % Load frame drift data
    DriftDiff = [0, 0; Drift(2:end,:)-Drift(1:end-1,:)];
elseif ShowDeDrift || ShowFlow
    warning('Drift file not found')
end
%% Create video
warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')

h = waitbar(0,['Processing frame 0/', num2str(size(Drift,1))]);
warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')

NumFrames = 0;
DirListing = dir([Directory, FileRoot, '*.tif']);

LeftData = zeros([960, 960, ClipLength], 'uint8');
RightData = zeros([960, 960, ClipLength], 'uint8');

for TiffIndex = 1:size(DirListing, 1)
    TiffObj = Tiff([Directory, DirListing(TiffIndex).name],'r');
    
    WhileCondition = true;
    while(WhileCondition)
        WhileCondition = (~lastDirectory(TiffObj)) && (NumFrames < (max(LeftStartFrame, RightStartFrame) + ClipLength - 1));
        NumFrames = NumFrames + 1;
        if isvalid(h)
                waitbar(NumFrames/size(Drift,1), h, ['Processing frame ', ...
                    num2str(NumFrames), '/', num2str(size(Drift,1))])
        end
            
        if ((NumFrames >= LeftStartFrame) && (NumFrames < LeftStartFrame + ClipLength)) ||...
                ((NumFrames >= RightStartFrame) && (NumFrames < RightStartFrame + ClipLength)) % Fast-forward through all the data
            TiffFrame = uint8(imresize(ModulationCompensation(int32(read(TiffObj))), 1)+10);
            if ((NumFrames >= LeftStartFrame) && (NumFrames < LeftStartFrame + ClipLength))
                LeftData(:,:,LeftStartFrame + ClipLength - NumFrames) = imresize(TiffFrame, [size(LeftData,1), size(LeftData,2)]);
            end
            
            if ((NumFrames >= RightStartFrame) && (NumFrames < RightStartFrame + ClipLength))
                RightData(:,:,RightStartFrame + ClipLength - NumFrames) = imresize(TiffFrame, [size(RightData,1), size(RightData,2)]);
            end
        end
        if WhileCondition
            nextDirectory(TiffObj)
        end
    end
    TiffObj.close()
    if NumFrames >= (max(LeftStartFrame, RightStartFrame) + ClipLength - 1)
        break
    end
end

if exist('VidHandle', 'var')
    close(VidHandle)
end

close(h)
warning('on', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')
%% Write video
CLims = [0,70];
Text = {'Edge of tumour nodule', 350, 900, 1, ClipLength;...
    'Within tumour nodule', 1250, 900, 1, ClipLength;...
    'Stagnant flow', 1020, 500, 1, 250;...
    'Reversing flow', 1490, 650, 1, 210;...
    'wtGFP expression', 1600, 250, 200, ClipLength};
Arrows = {[1190,515,1220,500], 1,250;...
    [1675,675,1710,680], 1,210;...
    [1600,300,1550,460], 200,ClipLength;...
    [1650,300,1670,450], 200,ClipLength};
switch WriteVid
    case true
        VidHandle = VideoWriter([Directory, FileRoot, '_TumourCompare.mp4'], 'MPEG-4');
        VidHandle.Quality = 75;
        open(VidHandle)
        for index = 1:ClipLength
            VidFrame = [LeftData(:,:,index),RightData(:,:,index)];
            
            VidFrame = (VidFrame-CLims(1))./((CLims(2)-CLims(1))/255);
            for jndex = 1:2
                if (index >= Text{jndex,4}) && (index <= Text{jndex,5})
                    VidFrame = insertText(VidFrame,[Text{jndex,2},Text{jndex,3}],Text{jndex,1},...
                        'TextColor','white','FontSize',32,'BoxColor','blue', 'BoxOpacity', 0.5);
                end
            end
            for jndex = 3:size(Text,1)
                if (index >= Text{jndex,4}) && (index <= Text{jndex,5})
                    VidFrame = insertText(VidFrame,[Text{jndex,2},Text{jndex,3}],Text{jndex,1},...
                        'TextColor','white','FontSize',24,'BoxColor','black', 'BoxOpacity', 0.0);
                end
            end
            for jndex = 1:size(Arrows,1)
                if (index >= Arrows{jndex,2}) && (index <= Arrows{jndex,3})
                    VidFrame = insertArrow(VidFrame,Arrows{jndex,1});
                end
            end
            writeVideo(VidHandle,VidFrame) % Load the flow map into the Videowriter object
        end
        close(VidHandle)
end