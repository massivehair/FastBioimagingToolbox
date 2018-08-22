% Create a video of the recovered flow vectors
%% Set up parameters
Directory = 'D:\Projects\High Speed SWIR QDot Temporal Focusing\21st August 2015\Green dots\';
FileRoot = '(4) moving around 100fps';
StartFrame = 21900; % 7000 or 101 or 20450
ClipLength = 500;
CLims = [0,80];
ShowMask = true;
ShowDeDrift = false;
DeDriftType = 'Nothing'; % Subtract or Nothing
ShowFlow = true;
ShowFrameNumbers = false;
WriteVid = true;

if exist([Directory, FileRoot, '_Drift.mat'], 'file')
    load([Directory, FileRoot, '_Drift.mat']) % Load frame drift data
    DriftDiff = [0, 0; Drift(2:end,:)-Drift(1:end-1,:)];
elseif ShowDeDrift || ShowFlow
    warning('Drift file not found')
end

if exist([Directory, FileRoot, '_Results.mat'], 'file')
    load([Directory, FileRoot, '_Results.mat'])
else
    warning('Results file not found')
end
%% Create video
warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')

switch WriteVid
    case true
        VidHandle = VideoWriter([Directory, FileRoot, '_SuppVid2.mp4'], 'MPEG-4');
        VidHandle.Quality = 75;
        open(VidHandle)
end

switch ShowDeDrift
    case true
        GridPitch = 64;
        Grid = false(2160+GridPitch);
        for index = 1:GridPitch:2160+GridPitch
            for jndex = 1:GridPitch:2160+GridPitch
                Grid(max(index-1,1):index+1, max(jndex-1,1):jndex+1) = true;
            end
        end
        u_sumRun = 0;
        v_sumRun = 0;
end

if exist('Drift', 'var')
    h = waitbar(0,['Processing frame 0/', num2str(size(Drift,1))]);
else
    h = waitbar(0,['Processing frame 0/0']);
end
warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')

NumFrames = 0;
DirListing = dir([Directory, FileRoot, '*.tif']);

for TiffIndex = 1:size(DirListing, 1)
    TiffObj = Tiff([Directory, DirListing(TiffIndex).name],'r');
    
    WhileCondition = true;
    while(WhileCondition)
        WhileCondition = (~lastDirectory(TiffObj)) && (NumFrames < (StartFrame + ClipLength));
        NumFrames = NumFrames + 1;
        if isvalid(h)
            if exist('Drift', 'var')
                waitbar(NumFrames/size(Drift,1), h, ['Processing frame ', ...
                    num2str(NumFrames), '/', num2str(size(Drift,1))])
            else
                waitbar(NumFrames/NumFrames, h, ['Processing frame ', ...
                    num2str(NumFrames), '/', num2str(NumFrames)])
            end
        end
        
        if NumFrames >= StartFrame % Fast-forward through all the data until we get to the start frame
            TiffFrame = uint8(imresize(ModulationCompensation(int32(read(TiffObj))), 1)+10);
            
            switch ShowMask
                case true
                    [~, Mask] = PIV_Preprocess(TiffFrame, 'MaskThreshold', MaskThreshold, 'Contrast', 'HighPassStd'); % Take the difference, find all the capillaries
                    MaskEdges = bwperim(Mask,8);
                    EdgesHighlighted = TiffFrame;
                    if exist('CLims', 'var') && ~isempty(CLims)
                        EdgesHighlighted = (EdgesHighlighted-CLims(1))./((CLims(2)-CLims(1))/255);
                    end
                    EdgesHighlighted(MaskEdges) = 255;
                    clear MaskEdges Mask
                case false
                    EdgesHighlighted = TiffFrame;
                    if exist('CLims', 'var') && ~isempty(CLims)
                        EdgesHighlighted = (EdgesHighlighted-CLims(1))./((CLims(2)-CLims(1))/255);
                    end
            end
            
            switch ShowDeDrift
                case true
                    if NumFrames <= size(Drift,1)
                        u_sumRun = Drift(NumFrames,1) * 2;
                        v_sumRun = Drift(NumFrames,2) * 2;
                    else
                        u_sumRun = Drift(end,1) * 2;
                        v_sumRun = Drift(end,2) * 2;
                    end
                    
                    GridMoved = Grid(mod(round(v_sumRun),GridPitch)+1:mod(round(v_sumRun),GridPitch)+2160, ...
                        mod(round(u_sumRun),GridPitch)+1:mod(round(u_sumRun),GridPitch)+2160);
                    EdgesHighlighted(GridMoved) = 255;
            end
            
            switch ShowFlow
                case true
                    if ~isnan(PIVResults(NumFrames).u)
                        switch DeDriftType
                            case 'Subtract'
                                PIVData = struct('x', PIVResults(NumFrames).x, 'y', PIVResults(NumFrames).y, 'u', ...
                                    PIVResults(NumFrames).u - DriftDiff(NumFrames,1), 'v', PIVResults(NumFrames).v - DriftDiff(NumFrames,2), ...
                                    'Certainty', PIVResults(NumFrames).Certainty, 'u_sum', PIVResults(NumFrames).u - DriftDiff(NumFrames,1), ...
                                    'v_sum', PIVResults(NumFrames).v - DriftDiff(NumFrames,2), 'Certainty_sum', PIVResults(NumFrames).Certainty, ...
                                    'WindowSize', WindowSize, 'MaxStep', MaxStep);
                            case 'Nothing'
                                PIVData = struct('x', PIVResults(NumFrames).x, 'y', PIVResults(NumFrames).y, 'u', ...
                                    PIVResults(NumFrames).u, 'v', PIVResults(NumFrames).v, ...
                                    'Certainty', PIVResults(NumFrames).Certainty, 'u_sum', PIVResults(NumFrames).u, ...
                                    'v_sum', PIVResults(NumFrames).v, 'Certainty_sum', PIVResults(NumFrames).Certainty, ...
                                    'WindowSize', WindowSize, 'MaxStep', MaxStep);
                        end
                        
                    else
                        PIVData = struct('x', [], 'y', [], 'u', [], 'v', [], 'Certainty', [], 'u_sum', [], ...
                            'v_sum', [], 'Certainty_sum', [], 'WindowSize', WindowSize, 'MaxStep', MaxStep);
                    end
                    figure(1)
                    PIV_PlotFigure(EdgesHighlighted, PIVData, 'DataDisplay', 'Frame', 'FrameNumber', 1, 'DataCLims', [0,255], ...
                        'PIVDisplay', 'Colour Arrows', 'ArrowScale', 21, 'ColourBar', true, 'CertaintyThresh', -inf,...
                        'FlowScale', 28.45, 'CBarLabel', 'Flow (\mum/s)', 'CLims', [0, 500], ...
                        'ArrowLineWidth', max(size(EdgesHighlighted))/50000, 'ColourMap', @jet)
                    
                    EHFlowMap = print('-RGBImage', ['-r', num2str(round(max(size(EdgesHighlighted))/9),3)]);
                    drawnow
                otherwise
                    %figure(1)
                    %imagesc(EdgesHighlighted)
                    %drawnow
            end
            switch WriteVid
                case true
                    switch ShowFlow
                        case true
                            switch ShowFrameNumbers
                                case true
                                    EHFlowMap = insertText(EHFlowMap,[0,0],num2str(NumFrames),...
                                        'TextColor','white','FontSize',18,'BoxColor','blue', 'BoxOpacity', 0.8);
                            end
                            writeVideo(VidHandle,EHFlowMap) % Load the flow map into the Videowriter object
                        otherwise
                            switch ShowFrameNumbers
                                case true
                                    EdgesHighlighted = insertText(EdgesHighlighted,[0,0],num2str(NumFrames),...
                                        'TextColor','white','FontSize',18,'BoxColor','blue', 'BoxOpacity', 0.8);
                            end
                            writeVideo(VidHandle,imresize(EdgesHighlighted, 0.5)) % Load into Videowriter object
                    end
            end
        end
        if WhileCondition
            nextDirectory(TiffObj)
        end
    end
    TiffObj.close()
    if NumFrames >= (StartFrame + ClipLength)
        break
    end
end

if exist('VidHandle', 'var')
    close(VidHandle)
end

close(h)
warning('on', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')