%% Set up parameters
WindowSize = [16,16];
MaxStep = [192,192];
PIVMethod = 'Cross-correlation';
SmoothMethod = 'Wiener';
FiltSize = 5;
DataFolder = 'G:\Projects\Red qdots high speed\';
SaveMatFile = true;
DisplayPIV = false;
SaveAsImage = false;

%% Locate all .tif / .U16 files in DataFolder; also set MaskThreshold
DirListing = dir([DataFolder, 'Area_*.U16']);
MaskThreshArray = ones(size(DirListing)) .* 0.2; % You'll have to populate this array on a per-file basis. Currently I just set everything to 0.2.

%% Loop over files
for FileNum = randperm(size(DirListing,1))
    %% Load Data
    disp([datestr(now), ' Loading ', DirListing(FileNum).name])
    
    FileName = DirListing(FileNum).name;
    MaskThreshold = MaskThreshArray(FileNum);
    
    PathIn = [DataFolder, FileName];
    %Data = PIV_TiffRead(PathIn); % Read data from TIFF file
    Data = PIV_U16Read(PathIn, [1920,1920]); % Read data from U16 file
    
    if size(Data,3) > 1
        %% PIV
        [~,SaveName,~] = fileparts(FileName);
        if ~exist([DataFolder,SaveName,'.mat'], 'file')
            [DiffData, Mask] = PIV_Preprocess(Data, MaskThreshold); % Take the difference, find all the capillaries
            switch DisplayPIV
                case false
                   clear Data
            end
            
            try
                disp(['Processing file ', DirListing(FileNum).name])
                [x, y, u, v, Certainty, u_sum, v_sum, Certainty_sum] = ...
                    PIV_Core(DiffData, Mask, WindowSize, MaxStep, ...
                    PIVMethod, SmoothMethod, FiltSize); % Do PIV
            catch
                disp('Error calculating PIV. Skipping file.')
                continue
            end
            clear DiffData Mask
            
            switch SaveMatFile
                case true
                    save([DataFolder,SaveName,'.mat'],'x', 'y', 'u', ...
                        'v', 'Certainty', 'u_sum', 'v_sum', ...
                        'Certainty_sum', 'WindowSize', 'MaxStep', ...
                        'PIVMethod', 'SmoothMethod', 'FiltSize', ...
                        'MaskThreshold')
            end
        else
            disp('Skipping PIV calculation - we appear to have done it before. Loading instead.')
            load([DataFolder,SaveName,'.mat'], 'x', 'y', 'u', 'v', 'Certainty', 'u_sum', 'v_sum', 'Certainty_sum')
        end
        %% Display
        switch DisplayPIV
            case true
                PIVData = struct('x', x, 'y', y, 'u', u, 'v', v, 'Certainty', Certainty,...
                    'u_sum', u_sum, 'v_sum', v_sum, 'Certainty_sum', Certainty_sum, ...
                    'WindowSize', WindowSize, 'MaxStep', MaxStep);
                figure(1)
                PIV_PlotFigure(Data, PIVData, 'DataDisplay', 'Zero Fill', 'DataCLims', [0,1], ...
                    'PIVDisplay', 'Colour Arrows', 'ArrowScale', 7, 'ColourBar', true, ...
                    'CLims', [0,30], 'FlowScale', 120, 'CBarLabel', 'Flow (\mum/s)')
                drawnow
        end
        
        clear Data PIVData x y u v Certainty u_sum v_sum Certainty_sum
        %% Save figure as a TIFF and SVG
        switch SaveAsImage
            case true
                saveas(gcf,[DataFolder,SaveName, 'FlowMap'], 'tiff')
                saveas(gcf,[DataFolder,SaveName, 'FlowMap'], 'svg')
        end
    else
        disp(['Skipping file since there is only one frame in it.'])
    end
end