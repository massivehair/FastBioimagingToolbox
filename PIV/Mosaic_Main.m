Directory = 'G:\Projects\Red qdots high speed\';
FilePrefix = 'Area';
Listing = dir([Directory, FilePrefix, '*.U16']);

Coords = zeros(size(Listing,1),3);
for index = 1:size(Listing,1)
    CoordsLine = textscan(Listing(index).name,[FilePrefix, '_%f_%f_%f.U16']);
    Coords(index,:) = [CoordsLine{1}, CoordsLine{2}, CoordsLine{3}];
end

Data = zeros(1920,1920,size(Listing,1));
h = waitbar(0,['Loading data: 0/', num2str(size(Listing,1))]);
for index = 1:size(Listing,1)
    FlowData = PIV_U16Read([Directory, Listing(index).name], [1920,1920]);
    Data(:,:,index) = std(single(FlowData),0,3);
    
    if isvalid(h)
        waitbar(index/size(Listing,1), h, ['Loading data: ', ...
            num2str(index), '/', num2str(size(Listing,1))])
    end
end
close(h)

%% Calculate map

PixelSize = 6.5/(25*164.5/180);
CoordsPx = (Coords - ones(size(Coords,1),1)*min(Coords))./ PixelSize;
x_Full = [];
y_Full = [];
u_sum_Full = [];
v_sum_Full = [];
Certainty_sum_Full = [];

Scale = 0.3;

FullMap = zeros(ceil((max(CoordsPx(:,1:2))+[size(Data,1), size(Data,2)])*Scale));
for index = 1:size(Data,3)
    FrameCoords = round([CoordsPx(index,1), CoordsPx(index,2)]*Scale)+1;
    
    Frame = imresize(Data(:,:,index), Scale);
    ExistingFrame = FullMap(FrameCoords(1):FrameCoords(1)+size(Frame,1)-1, ...
        FrameCoords(2):FrameCoords(2)+size(Frame,2)-1);
    
    FullMap(FrameCoords(1):FrameCoords(1)+size(Frame,1)-1, ...
        FrameCoords(2):FrameCoords(2)+size(Frame,2)-1) = max(Frame, ExistingFrame);
    
    [~,MatFileName,~] = fileparts(Listing(index).name);
    MatFileName = [Directory, MatFileName, '.mat'];
    if exist(MatFileName, 'file')
        load(MatFileName, 'x', 'y', 'u_sum', 'v_sum', 'Certainty_sum')
        x_Full = [x_Full; x*Scale + FrameCoords(2)];
        y_Full = [y_Full; y*Scale + FrameCoords(1)];
        u_sum_Full = [u_sum_Full; u_sum];
        v_sum_Full = [v_sum_Full; v_sum];
        Certainty_sum_Full = [Certainty_sum_Full; Certainty_sum];
    end
end


%% Display
figure(1)
imagesc(FullMap, [2.5,10])
hold on
CertaintyThresh = 0.00001;
ArrowScale = 0.03;
quiver(x_Full(Certainty_sum_Full>CertaintyThresh), y_Full(Certainty_sum_Full>CertaintyThresh), ...
    u_sum_Full(Certainty_sum_Full>CertaintyThresh) .* ArrowScale,...
    v_sum_Full(Certainty_sum_Full>CertaintyThresh) .* ArrowScale, 0, 'g')
hold off