FileName = 'E:\Projects\Oliver Three Colours\Second mouse\Liver\Liver2_NaN_0.000000_0.000000.U16';
RefFileName = 'E:\Projects\Oliver Three Colours\References\Fluorescein_NaN_0.000000_0.000000.U16';
[Directory,FileNameRoot,FileType] = fileparts(FileName); % U16 or tif
WindowSize = [128, 128];
StepSize = [256, 256];
Tracking = 'Red Frame'; % Red Frame, Green Frame, Blue Frame, Mean
Method = '3 Point Gaussian';
ScaleFactor = 1; % KEEP THIS AT 1.
HighPass = 20;

[FrameID, TimeStamp] = ColourOrder([Directory, '\', FileNameRoot, '_FrameOrder.txt'], ...
    'WithTimeStamp'); 
FrameID = FrameID + 1; % Should probably remove the +1 as soon as I get the right LabVIEW code working.
AverageFrameRate = 1/(double(3*(TimeStamp(end)-TimeStamp(1))/length(TimeStamp))*100E-9);
CameraID = [1,3,2];

switch FileType
    case '.tif' % Not implemented yet
        Stack = uint16(TiffRead(FileName));
    case '.U16'        
        FrameSize = [1536,2048];
        FileID = fopen(FileName);
        FileInfo = dir(FileName);
        NumFrames = FileInfo.bytes./(prod(FrameSize)*2);
        
        RefFileID = fopen(RefFileName); % Get the reference image
        RefImage = zeros(fliplr(FrameSize));
        for index = 1:3
            RefImage = RefImage + double(flipud(fread(RefFileID, fliplr(FrameSize), 'uint16', 0, 'b')));
        end
        fclose(RefFileID);
        RefImage = imresize(RefImage(257:end-256, :) / 3, ScaleFactor);
        
        RGBFrame = zeros([FrameSize(2),FrameSize(1),3], 'uint16');
        RGBCount = [0,0,0];
        Offset = zeros(NumFrames-1, 2);
        clear NewFrame
        for index = 1:NumFrames
            if ~any(RGBCount == 0)
                RGBFrameDBL = double((RGBFrame(257:end-256, :, :)));
                RGBCount = [0,0,0];
                if ~exist('NewFrame', 'var')
                    switch Tracking
                        case 'Red Frame'
                            NewFrame = imresize(RGBFrameDBL(:,:,1), ScaleFactor);
                        case 'Green Frame'
                            NewFrame = imresize(RGBFrameDBL(:,:,2), ScaleFactor);
                        case 'Blue Frame'
                            NewFrame = imresize(RGBFrameDBL(:,:,3), ScaleFactor);
                        otherwise
                            NewFrame = imresize(mean(RGBFrameDBL,3), ScaleFactor);
                    end
                    IntensityOffset = mean(NewFrame(:));
                    NewFrame = NewFrame - IntensityOffset;
                    NewFrame = NewFrame./RefImage; % Compensate nonuniform excitation
                    NewFrame = NewFrame - imgaussfilt(NewFrame,HighPass); % High-pass filter the image to remove Gaussian envelope
                    Certainty = -inf; % Make sure we trigger a new reference frame
                    CurrentPosition = [0,0];
                    KnownPosition = [0,0];
                    
                    DrawnFrames = 1;
                    
                    %Crop = [round(size(NewFrame,1)/4), round(3*size(NewFrame,1)/4), ...
                    %    round(size(NewFrame,2)/4), round(3*size(NewFrame,2)/4)];
                    CropSize = 50;
                    Crop = [CropSize+1,size(NewFrame,1)-CropSize,CropSize+1,size(NewFrame,2)-CropSize];
                    NewFrame = NewFrame(Crop(1):Crop(2),Crop(3):Crop(4));
                    
                    %Margins = [round(size(NewFrame,1)/4), round(3*size(NewFrame,1)/4), ...
                    %    round(size(NewFrame,2)/4), round(3*size(NewFrame,2)/4)];
                    Margins = [1,size(NewFrame,1),1,size(NewFrame,2)];
                else
                    if Certainty < 10 || any(abs(CurrentPosition-KnownPosition)>StepSize/2)
                        disp(['New ref frame: ', num2str(DrawnFrames), ', position: ', num2str(CurrentPosition(1)), ' ', num2str(CurrentPosition(2))])
                        RefFrame = NewFrame;
                        KnownPosition = CurrentPosition;
                    end
                    switch Tracking
                        case 'Red Frame'
                            NewFrame = imresize(RGBFrameDBL(:,:,1), ScaleFactor) - IntensityOffset;
                        case 'Green Frame'
                            NewFrame = imresize(RGBFrameDBL(:,:,2), ScaleFactor) - IntensityOffset;
                        case 'Blue Frame'
                            NewFrame = imresize(RGBFrameDBL(:,:,3), ScaleFactor) - IntensityOffset;
                        otherwise
                            NewFrame = imresize(mean(RGBFrameDBL,3), ScaleFactor) - IntensityOffset;
                    end
                    NewFrame = NewFrame./RefImage; % Compensate nonuniform excitation
                    NewFrame = NewFrame - imgaussfilt(NewFrame,HighPass); % High-pass filter the image to remove Gaussian envelope
                    NewFrame = NewFrame(Crop(1):Crop(2),Crop(3):Crop(4));
                    
                    switch true
                        case true
                            [XCorrMap, Locations] = PIV_xcorr(RefFrame, NewFrame, WindowSize, StepSize);
                            XCorr = mean(XCorrMap,3);
                        case false
                            XCorr = conv2(RefFrame, rot90(conj(NewFrame(Margins(1):Margins(2),Margins(3):Margins(4))),2), 'same');
                    end
                    if DrawnFrames == 1
                        u_offset = floor((size(XCorr,1)+1)/2);
                        v_offset = floor((size(XCorr,2)+1)/2);
                    end
                    figure(1)
                    %imshow(RGBFrameDBL, 'InitialMagnification', 50)
                    imagesc(NewFrame(Margins(1):Margins(2),Margins(3):Margins(4)))
                    
                    figure(3)
                    imagesc(RefFrame)

                    XCorr = XCorr - mean(XCorr(:)); % Normalize
                    XCorr = XCorr ./ std(XCorr(:));
                    
                    Origin = floor((size(XCorr)+1)/2); % Suppress the weird origin effect by averaging surrounding pixels
                    XCorr(Origin(1),Origin(2)) = (XCorr(Origin(1)+1,Origin(2)) + XCorr(Origin(1)-1,Origin(2)) + ...
                        XCorr(Origin(1),Origin(2)+1) + XCorr(Origin(1),Origin(2)-1))./4;
                    
                    figure(2)
                    imagesc(XCorr)
                    [u,v,Certainty] = PIV_GetFlow(XCorr);
                    %switch Method
                    %    case 'Peak Max'
                    %        [Certainty,MaxIndex] = max(XCorr(:));
                    %        [I,J] = ind2sub([size(XCorr,1), size(XCorr,2)], MaxIndex);
                    %        u = J - u_offset;
                    %        v = I - v_offset;
                    %    case '3 Point Gaussian'
                    %        [Certainty,MaxIndex] = max(XCorr(:));
                    %        [I,J] = ind2sub([size(XCorr,1), size(XCorr,2)], MaxIndex);
                    %        if (I == 1) || (I == size(XCorr,1)) || isnan(XCorr(I-1, J)) || isnan(XCorr(I+1, J))
                    %            v = I - v_offset;
                    %        else
                    %            v = I - v_offset + (log(XCorr(I-1, J))-log(XCorr(I+1, J)))/...
                    %                (2*(log(XCorr(I-1, J)) + log(XCorr(I+1, J)) - 2*(log(XCorr(I, J)))));
                    %        end
                    %        
                    %        if (J == 1) || (J == size(XCorr,2)) || isnan(XCorr(I, J-1)) || isnan(XCorr(I, J+1))
                    %            u = J - u_offset;
                    %        else
                    %            u = J - u_offset + (log(XCorr(I, J-1))-log(XCorr(I, J+1)))/...
                    %                (2*(log(XCorr(I, J-1)) + log(XCorr(I, J+1)) - 2*(log(XCorr(I, J)))));
                    %        end
                    %end
                    hold on
                    scatter(u+u_offset,v+v_offset)
                    hold off
                    disp(['Frame ', num2str(DrawnFrames), ': ',  num2str((u+KnownPosition(1)-CurrentPosition(1))./ScaleFactor), ...
                        ' ', num2str((v+KnownPosition(2)-CurrentPosition(2))./ScaleFactor)])
                    Offset(DrawnFrames,:) = ([u,v]+KnownPosition-CurrentPosition)./ScaleFactor;
                    CurrentPosition = [u,v] + KnownPosition;
                    DrawnFrames = DrawnFrames + 1;
                    drawnow
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
end

%% Save drift data
Offset = Offset(1:DrawnFrames-1,:);

save([Directory, '\', FileNameRoot, '_Offset.mat'], 'Offset')