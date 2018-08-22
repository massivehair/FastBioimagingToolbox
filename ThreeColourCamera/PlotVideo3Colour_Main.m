% Create a video of the recovered flow vectors
%% Set up parameters
FileName = 'E:\Projects\Oliver Three Colours\Second mouse\Hoechst injection\Hoechst_NaN_0.000000_0.000000.U16';
[Directory,FileRoot,FileType] = fileparts(FileName);
[FrameID, TimeStamp] = ColourOrder([Directory, '\', FileRoot, '_FrameOrder.txt'], ...
    'WithTimeStamp');
FrameID = FrameID + 1; % Should probably remove the +1 as soon as I get the right LabVIEW code working.
AverageFrameRate = 1/(double(3*(TimeStamp(end)-TimeStamp(1))/length(TimeStamp))*100E-9);
CameraID = [1,3,2];

StartFrame = 0;
ShowDeDrift = true;
WriteVid = false;
%% Create video
warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')

switch WriteVid
    case true
        VidHandle = VideoWriter([Directory, '\', FileRoot, '_OffsetOverlay.mp4'], 'MPEG-4');
        VidHandle.Quality = 75;
        open(VidHandle)
end

switch ShowDeDrift
    case true
        GridPitch = 512;
        Grid = false(2160+GridPitch);
        for index = 1:GridPitch:2160+GridPitch
            for jndex = 1:GridPitch:2160+GridPitch
                Grid(max(index-1,1):index+1, max(jndex-1,1):jndex+1) = true;
            end
        end
        u_sumRun = 0;
        v_sumRun = 0;
        
        try
            clear Offset
            clear BigFrame
            load([Directory, '\', FileRoot, '_Offset.mat'])
            Offset = cumsum([0,0;-1*Offset]);
            
            % Subtract the mean motion, correct the 'high frequencies'
            %Offset(:,1) = Offset(:,1)-smooth(Offset(:,1), SmoothWidth);
            %Offset(:,2) = Offset(:,2)-smooth(Offset(:,2), SmoothWidth);
            
            Offset = real(Offset);
            
            Offset(:,1) = Offset(:,1) - min(Offset(:,1))+1; % +1 because Matlab.
            Offset(:,2) = Offset(:,2) - min(Offset(:,2))+1;
            
            Offset = round(Offset);
        catch
        end
        
end

h = waitbar(0,['Processing frame 0/', num2str(size(Offset,1))]);
warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')

NumFrames = 0;

FrameSize = [1536,2048]; % Would be [1536, 2048] but we trim the frame
FileID = fopen(FileName);
FileInfo = dir(FileName);
TotalFrames = FileInfo.bytes./(prod(FrameSize)*2);

figure(1)
RGBFrame = zeros([FrameSize(2),FrameSize(1),3], 'uint16');
RGBCount = [0,0,0];
DrawnFrames = 1;

for FrameIndex = 1:TotalFrames
    NumFrames = NumFrames + 1;
    if isvalid(h)
        waitbar(NumFrames/size(Offset,1), h, ['Processing frame ', ...
            num2str(DrawnFrames), '/', num2str(size(Offset,1))])
    end
    if NumFrames >= StartFrame % Fast-forward through all the data until we get to the start frame
        if any(RGBCount > 1)
            RGBFrameU8 = uint8((RGBFrame(257:end-256, :, :)-350)./12);
            if exist('Offset', 'var')
                u_sumRun = Offset(DrawnFrames,1) * 2;
                v_sumRun = Offset(DrawnFrames,2) * 2;
                GridMoved = Grid(mod(round(v_sumRun),GridPitch)+1:mod(round(v_sumRun),GridPitch)+size(RGBFrameU8,1), ...
                    mod(round(u_sumRun),GridPitch)+1:mod(round(u_sumRun),GridPitch)+size(RGBFrameU8,2));
                RGBFrameU8([GridMoved(:);GridMoved(:);GridMoved(:)]) = 255; % NOT COMPLETE YET
                imshow(RGBFrameU8, 'InitialMagnification', 50)
            else
                imshow(RGBFrameU8, 'InitialMagnification', 50)
            end
            drawnow
            DrawnFrames = DrawnFrames+1;
            RGBCount = [0,0,0];
            switch WriteVid
                case true
                    if exist('Offset', 'var')
                        writeVideo(VidHandle,RGBFrameU8Drift)
                    else
                        writeVideo(VidHandle,RGBFrameU8)
                    end
            end
        end
        switch FrameID(FrameIndex)
            case 1
                RGBFrame(:,:,CameraID(FrameID(FrameIndex))) = flipud(fread(FileID, fliplr(FrameSize), 'uint16', 0, 'b'));
            case 2
                RGBFrame(:,:,CameraID(FrameID(FrameIndex))) = fread(FileID, fliplr(FrameSize), 'uint16', 0, 'b');
            case 3
                RGBFrame(:,:,CameraID(FrameID(FrameIndex))) = fread(FileID, fliplr(FrameSize), 'uint16', 0, 'b');
        end
        RGBCount(FrameID(FrameIndex)) = RGBCount(FrameID(FrameIndex)) + 1;
    end
end

if exist('VidHandle', 'var')
    close(VidHandle)
end

close(h)
warning('on', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')