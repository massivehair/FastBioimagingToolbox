FileName = 'E:\Projects\Oliver Three Colours\First go, fixed and moving\FixedAndMoving_NaN_0.000000_0.000000.U16';
[Directory,FileNameRoot,FileType] = fileparts(FileName); % U16 or tif

FrameID = ColourOrder([Directory, '\', FileNameRoot, '_FrameOrder.txt'], ...
    'WithTimeStamp') + 1; % Should probably remove the +1 as soon as I get the right LabVIEW code working.

switch FileType
    case '.tif'
        Stack = uint16(TiffRead(FileName));
    case '.U16'
        FrameSize = [1536,2048];
        FileID = fopen(FileName);
        FileInfo = dir(FileName);
        NumFrames = FileInfo.bytes./(prod(FrameSize)*2);
        Stack = zeros([FrameSize, NumFrames], 'uint16');
        for index = 1:size(Stack,3)
            Stack(:,:,index) = fread(FileID, fliplr(FrameSize), 'uint16', 0, 'b')';
        end
        fclose(FileID);
end

%% Display
figure(1)
RGBFrame = zeros([size(Stack,1),size(Stack,2),3], 'uint16');
RGBCount = [0,0,0];
for index = 1:size(Stack,3)
    if any(RGBCount > 1)
        imshow(RGBFrame.*16)
        drawnow
        RGBCount = [0,0,0];
    end
    RGBFrame(:,:,FrameID(index)) = Stack(:,:,index);
    RGBCount(FrameID(index)) = RGBCount(FrameID(index)) + 1;
end