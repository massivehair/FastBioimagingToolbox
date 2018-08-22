Directory = 'D:\PIV Local Copy\Red qdots high speed\';
FilePrefix = 'Area';
Listing = dir([Directory, FilePrefix, '_*.U16']);
DataCLims = [2,10];
FlowCLims = [0,5000];
ImageSize = [1920, 1920];
PixelSize = 6.5/(25*164.5/180);
Scale = 0.6; % Display scale - how much do we shrink the image by to fit everything in memory?
SaveFrame = true;

Coords = zeros(size(Listing,1),3);
for index = 1:size(Listing,1)
    CoordsLine = textscan(Listing(index).name,[FilePrefix, '_%f_%f_%f.U16']);
    Coords(index,:) = [CoordsLine{1}, CoordsLine{2}, CoordsLine{3}];
end
CoordsPx = (Coords - ones(size(Coords,1),1)*min(Coords))./ PixelSize;

Heights = unique(Coords(:,3))';

    %% Calculate map
for HIndex = Heights;
    
    ThisPlane = find(Coords(:,3) == HIndex);
    
    Data = zeros(ImageSize(1),ImageSize(2),sum(Coords(:,3) == HIndex), 'single');
    h = waitbar(0,['Loading data: 0/', num2str(size(Data,3))]);
    for index = 1:size(Data,3)
        FlowData = PIV_U16Read([Directory, Listing(ThisPlane(index)).name], [1920,1920]);
        Data(:,:,index) = std(single(FlowData),0,3);
        
        if isvalid(h)
            waitbar(index/size(Data,3), h, ['Loading data: ', ...
                num2str(index), '/', num2str(size(Data,3))])
        end
    end
    close(h)
    
    x_Full = [];
    y_Full = [];
    u_sum_Full = [];
    v_sum_Full = [];
    Certainty_sum_Full = [];
    
    FullMap = zeros(ceil((max(CoordsPx(:,1:2))+[size(Data,1), size(Data,2)])*Scale), 'single');
    for index = 1:size(Data,3)
        FrameCoords = round([CoordsPx(ThisPlane(index),1), CoordsPx(ThisPlane(index),2)]*Scale)+1;
        
        Frame = imresize(Data(:,:,index), Scale);
        ExistingFrame = FullMap(FrameCoords(1):FrameCoords(1)+size(Frame,1)-1, ...
            FrameCoords(2):FrameCoords(2)+size(Frame,2)-1);
        
        FullMap(FrameCoords(1):FrameCoords(1)+size(Frame,1)-1, ...
            FrameCoords(2):FrameCoords(2)+size(Frame,2)-1) = max(Frame, ExistingFrame);
        
        [~,MatFileName,~] = fileparts(Listing(ThisPlane(index)).name);
        MatFileName = [Directory, MatFileName, '.mat'];
        if exist(MatFileName, 'file')
            load(MatFileName, 'x', 'y', 'u', 'v', 'Certainty', 'u_sum', 'v_sum', ...
                'Certainty_sum', 'WindowSize', 'MaxStep')
            
            Mask = ~PIV_TrimEdge(x, y, [size(Data,1), size(Data,2)], [25,25]);
            
            x_Full = [x_Full; x(Mask)*Scale + FrameCoords(2)];
            y_Full = [y_Full; y(Mask)*Scale + FrameCoords(1)];
            u_sum_Full = [u_sum_Full; u_sum(Mask)];
            v_sum_Full = [v_sum_Full; v_sum(Mask)];
            Certainty_sum_Full = [Certainty_sum_Full; Certainty_sum(Mask)];
        end
    end
    PIVData = struct('x', x_Full, 'y', y_Full, 'u', [], 'v', [], 'Certainty', [],...
        'u_sum', u_sum_Full, 'v_sum', v_sum_Full, 'Certainty_sum', Certainty_sum_Full, ...
        'WindowSize', WindowSize, 'MaxStep', MaxStep);
    
    figure(1)
    title(['Height: ', num2str(HIndex), 'um'])
    axis equal tight
    %PIV_PlotFigure(FullMap, PIVData, 'DataDisplay', 'Stack Average', 'DataCLims', [], ...
    %    'PIVDisplay', 'Colour Arrows', 'ArrowScale', 7, 'ColourBar', true, ...
    %    'FlowScale', 28.45, 'CBarLabel', 'Flow (\mum/s)', 'ArrowLineWidth', 0.5)
    
    PIV_PlotFigure(FullMap, PIVData, 'DataDisplay', 'Stack Average', 'DataCLims', DataCLims, ...
        'PIVDisplay', 'Colour Arrows', 'ArrowScale', 15, 'ColourBar', true, ...
        'FlowScale', 28.45, 'CBarLabel', 'Flow (\mum/s)', 'ArrowLineWidth', ...
        max(size(FullMap))/150000, 'ColourMap', @jet, 'CertaintyThresh', -inf,...
        'CLims', FlowCLims)
    
    drawnow
    
    switch SaveFrame % Save frame
        case true
            switch 'High res'
                case 'Normal'
                    FigureData = print('-RGBImage', ['-r',num2str(round(max(size(FullMap))/5),3)]);
                case 'High res'
                    clear Data % Spare some memory - this is going to be a big image
                    clear FlowData
                    
                    Fig2Hdl = figure(2);
                    set(gcf,'paperunits','inches')
                    FigurePos = get(gcf, 'Position');
                    disp('Plotting figure...')
                    PIV_PlotFigure(FullMap, PIVData, 'DataDisplay', 'None', 'DataCLims', DataCLims, ...
                        'PIVDisplay', 'Colour Arrows', 'ArrowScale', 15, 'ColourBar', false, ...
                        'FlowScale', 28.45, 'CBarLabel', 'Flow (\mum/s)', 'ArrowLineWidth', ...
                        max(size(FullMap))/600000, 'ColourMap', @jet, 'CertaintyThresh', -inf,...
                        'CLims', FlowCLims)
                    
                    ScreenRes=get(0,'ScreenPixelsPerInch');
                    set(gcf, 'Position', [FigurePos(1), FigurePos(2), ScreenRes*2, ScreenRes*2])
                    ylim([1,size(FullMap,1)])
                    xlim([1,size(FullMap,2)])
                    set(gca, 'Units', 'normalized', 'Position', [0 0 1 1])
                    disp('Printing figure...')
                    ArrowDataRGB = print('-RGBImage', ['-r',num2str(max(size(FullMap))/2)]);
                    close(Fig2Hdl)
                    disp('Thresholding...')
                    ArrowMask = (ArrowDataRGB(:,:,1) ~= 255) | (ArrowDataRGB(:,:,2) ~= 255) | (ArrowDataRGB(:,:,3) ~= 255);
                    FigureData = uint8(255.*(FullMap-DataCLims(1))./(DataCLims(2)-DataCLims(1)));
                    FigureData = cat(3,FigureData,FigureData,FigureData);
                    disp('Combining arrows and data...')
                    FigureData(cat(3,ArrowMask, ArrowMask, ArrowMask)) = ArrowDataRGB(cat(3,ArrowMask, ArrowMask, ArrowMask));
            end
            if HIndex == Heights(1)
                if exist([Directory, FilePrefix, '.tif'], 'file')
                    delete([Directory, FilePrefix, '.tif'])
                end
                TiffHandle = Tiff([Directory, FilePrefix, '.tif'],'a');
            end
            
            tagstruct.ImageLength = size(FigureData,1);
            tagstruct.ImageWidth = size(FigureData,2);
            tagstruct.Photometric = Tiff.Photometric.RGB;
            tagstruct.BitsPerSample = 8;
            tagstruct.SamplesPerPixel = 3;
            tagstruct.RowsPerStrip = 16;
            tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
            tagstruct.Software = 'MATLAB';
            TiffHandle.setTag(tagstruct)
            clear tagstruct
            TiffHandle.write(FigureData);
            
            if HIndex == Heights(end)
                TiffHandle.close()
            else
                TiffHandle.writeDirectory()
            end
    end
end