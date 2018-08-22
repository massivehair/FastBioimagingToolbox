DataDir = 'E:\Projects\Oliver Three Colours\First go, fixed and moving\';
FileName = 'FixedAndMoving_NaN_0.000000_0.000000';
RGBOrder = [3,2,1];
FileID = fopen([DataDir, FileName, '.U16']);

FrameID = fopen([DataDir, FileName, '_FrameOrder.txt']);
CPlanes = fscanf(FrameID, '%s');
fclose(FrameID);

FrameSize = fliplr([1536,2048]);
RGBFrame = zeros(FrameSize(1), FrameSize(2), 3, 'uint8');

for index = 1:1000
    for jndex = 1:3
        Frame = fread(FileID, FrameSize, 'uint16', 0, 'b');
        for kndex = 1:3
            if sscanf(CPlanes((index*3)+jndex-1), '%u') == RGBOrder(kndex)
                RGBFrame(:, :, kndex) = uint8(Frame./16);
            end
        end
    end
    imshow(RGBFrame)
    drawnow
end

fclose(FileID);