Directory = 'E:\Projects\Oliver Three Colours\Mosaic\';
FilePrefix = 'Mosaic';
FileType = 'U16'; % U16 or tif
Listing = dir([Directory, FilePrefix, '*.', FileType]);
CameraID = [1,3,2];

Coords = zeros(size(Listing,1),2);
for index = 1:size(Listing,1)
    CoordsLine = textscan(Listing(index).name,[FilePrefix, '_%f_%f.', FileType]);
    Coords(index,:) = [CoordsLine{1}, CoordsLine{2}];
end

Data = zeros(1536,1536,3,size(Listing,1), 'uint16');
h = waitbar(0,['Loading data: 0/', num2str(size(Listing,1))]);
for index = 1:size(Listing,1)
    switch FileType
        case 'tif'
            SingleFrame = uint16(TiffRead([Directory, Listing(index).name]));
        case 'U16'
            FileID = fopen([Directory, Listing(index).name]);
            SingleFrame = cat(3, fread(FileID, [2048,1536], 'uint16', 0, 'b')', ...
                fread(FileID, [2048,1536], 'uint16', 0, 'b')', ...
                fread(FileID, [2048,1536], 'uint16', 0, 'b')');
            fclose(FileID);
    end
    FrameOrder = ColourOrder([Directory, Listing(index).name(1:end-4), '_FrameOrder.txt'])+1;
    for jndex = 1:3
        Data(:,:,CameraID(FrameOrder(jndex)),index) = SingleFrame(:,257:end-256,jndex);
    end
    
    if isvalid(h)
        waitbar(index/size(Listing,1), h, ['Loading data: ', ...
            num2str(index), '/', num2str(size(Listing,1))])
    end
end
close(h)

%% Calculate map

PixelSize = 0.31; %6.5/(25*164.5/180); %0.31
CoordsPx = (Coords - ones(size(Coords,1),1)*min(Coords))./ PixelSize;

Scale = 1;

FullMap = zeros([ceil((max(CoordsPx(:,1:2))+[size(Data,1), size(Data,2)])*Scale),3], 'uint16');
for index = 1:size(Data,4)
    FrameCoords = round([CoordsPx(index,1), CoordsPx(index,2)]*Scale)+1;
    
    Frame = cat(3, rot90(imresize(Data(:,:,1,index), Scale), 2), ...
        rot90(imresize(Data(:,:,2,index), Scale), 2), ...
        fliplr(imresize(Data(:,:,3,index), Scale)));
    
    ExistingFrame = FullMap(FrameCoords(1):FrameCoords(1)+size(Frame,1)-1, ...
        FrameCoords(2):FrameCoords(2)+size(Frame,2)-1, :);
    
    switch 'max'
        case 'mean'
            FullMap(FrameCoords(1):FrameCoords(1)+size(Frame,1)-1, ...
                FrameCoords(2):FrameCoords(2)+size(Frame,2)-1,:) = (Frame + ExistingFrame)./2;
        case 'max'
            FullMap(FrameCoords(1):FrameCoords(1)+size(Frame,1)-1, ...
                FrameCoords(2):FrameCoords(2)+size(Frame,2)-1,:) = max(Frame, ExistingFrame);
        case 'min'
            FullMap(FrameCoords(1):FrameCoords(1)+size(Frame,1)-1, ...
                FrameCoords(2):FrameCoords(2)+size(Frame,2)-1,:) = min(Frame, ExistingFrame);
    end
end


% Display
figure(1)
imshow(uint8(FullMap./12))
%figure(2)
%imagesc(FullMap(:,:,1))
%axis image
%figure(3)
%imagesc(FullMap(:,:,2))
%axis image
%figure(4)
%imagesc(FullMap(:,:,3))
%axis image