FileName = 'E:\Projects\Oliver Three Colours\Second mouse\Liver\Liver2_NaN_0.000000_0.000000.U16';
[Directory,FileNameRoot,FileType] = fileparts(FileName); % U16 or tif
SaveVid = true;
DeDrift = 'Smooth';
SmoothWidth = 400;

[FrameID, TimeStamp] = ColourOrder([Directory, '\', FileNameRoot, '_FrameOrder.txt'], ...
    'WithTimeStamp'); 
FrameID = FrameID + 1; % Should probably remove the +1 as soon as I get the right LabVIEW code working.
AverageFrameRate = 1/(double(3*(TimeStamp(end)-TimeStamp(1))/length(TimeStamp))*100E-9);
CameraID = [1,3,2];

switch DeDrift
    case 'None'
        % Don't de-drift
    otherwise
        try
            clear Offset
            clear BigFrame
            load([Directory, '\', FileNameRoot, '_Offset.mat'])
            Offset = cumsum([0,0;-1*Offset]);
            %Offset = cumsum([0,0;0,0;-1*Offset]);
            switch DeDrift
                case 'Smooth'
                    Offset(:,1) = Offset(:,1)-smooth(Offset(:,1), SmoothWidth);
                    Offset(:,2) = Offset(:,2)-smooth(Offset(:,2), SmoothWidth);
            end
            
            Offset = real(Offset);
            
            Offset(:,1) = Offset(:,1) - min(Offset(:,1))+1; % +1 because Matlab.
            Offset(:,2) = Offset(:,2) - min(Offset(:,2))+1;
            
            Offset = round(Offset);
        catch
        end
end

switch FileType
    case '.tif'
        Stack = uint16(TiffRead(FileName));
    case '.U16'
        switch SaveVid
            case true
                switch DeDrift
                    case 'None'
                        VidHandle = VideoWriter([Directory, '\', FileNameRoot, '.mp4']);
                    otherwise
                        VidHandle = VideoWriter([Directory, '\', FileNameRoot, '_smoothed','.mp4']);
                end
                VidHandle.FrameRate = AverageFrameRate;
                VidHandle.Quality = 75;
                open(VidHandle)
        end
        
        FrameSize = [1536,2048]; % Would be [1536, 2048] but we trim the frame
        FileID = fopen(FileName);
        FileInfo = dir(FileName);
        NumFrames = FileInfo.bytes./(prod(FrameSize)*2);
        
        figure(1)
        RGBFrame = zeros([FrameSize(2),FrameSize(1),3], 'uint16');
        RGBCount = [0,0,0];
        DrawnFrames = 1;
        
        h = waitbar(0,['Processing frame 0/', num2str(NumFrames)]);
        for index = 1:NumFrames
            if ~any(RGBCount == 0)
                if isvalid(h)
                    waitbar(index/NumFrames, h, ['Processing frame ', ...
                        num2str(index), '/', num2str(NumFrames)])
                end
                
                RGBFrameU8 = uint8((RGBFrame(257:end-256, :, :)-350)./12);
                %RGBFrameU8(:,:,2:3) = 0; % Just look at the red channel HACK
                if exist('Offset', 'var')
                    if DrawnFrames >= 1 % Do we want to blank every frame, or leave the residual images?
                        RGBFrameU8Big = zeros([ceil(size(RGBFrameU8,1)+max(Offset(:,2))),ceil(size(RGBFrameU8,2)+max(Offset(:,1))),3], 'uint8');
                    end
                    RGBFrameU8Big(Offset(DrawnFrames,2):Offset(DrawnFrames,2)+size(RGBFrameU8,1)-1,...
                        Offset(DrawnFrames,1):Offset(DrawnFrames,1)+size(RGBFrameU8,2)-1,:) = RGBFrameU8;
                    imshow(RGBFrameU8Big, 'InitialMagnification', 33)
                    DrawnFrames = DrawnFrames+1;
                else
                    imshow(RGBFrameU8, 'InitialMagnification', 50)
                end
                
                drawnow
                %RGBCount = RGBCount - 1;
                RGBCount = [0,0,0];
                switch SaveVid
                    case true
                        if exist('Offset', 'var')
                            writeVideo(VidHandle,RGBFrameU8Big)
                        else
                            writeVideo(VidHandle,RGBFrameU8)
                        end
                end
            end
            switch FrameID(index)
                case 1
            RGBFrame(:,:,CameraID(FrameID(index))) = flipud(fread(FileID, fliplr(FrameSize), 'uint16', 0, 'b'));
                case 2
            RGBFrame(:,:,CameraID(FrameID(index))) = fread(FileID, fliplr(FrameSize), 'uint16', 0, 'b');
                case 3
            RGBFrame(:,:,CameraID(FrameID(index))) = fread(FileID, fliplr(FrameSize), 'uint16', 0, 'b');
            end
            RGBCount(FrameID(index)) = RGBCount(FrameID(index)) + 1;
        end
        fclose(FileID);
        switch SaveVid
            case true
                close(VidHandle)
        end
        if isvalid(h)
            close(h)
        end
end