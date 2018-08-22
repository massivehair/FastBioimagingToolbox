%% Set up parameters
WindowSize = [16,16];
MaxStep = [192,192];
PIVMethod = 'Cross-correlation';
SmoothMethod = 'Wiener';
FiltSize = 5;

%% Load Data
DataFolder = 'G:\Projects\High Speed SWIR QDot Temporal Focusing\21st August 2015\Green dots\';
FileName = '(4) moving around 100fps@0011.tif';
MaskThreshold = 3;

PathIn = [DataFolder, FileName];
Data = PIV_TiffRead(PathIn); % Read data from TIFF file
%Data = PIV_U16Read(PathIn, [1920,1920]); % Read data from U16 file

%% PIV
StartTime = tic;
for index = 1:size(Data,3)-1
    DataSubset = Data(:,:,index:index+1);
    [DiffData, Mask] = PIV_Preprocess(DataSubset, MaskThreshold, 'Contrast', 'StdFiltering'); % Take the difference, find all the capillaries
    
    figure(1)
    imagesc(DataSubset(:,:,1))
    
    figure(2)
    imagesc(Mask)
    
    [x, y, u, v, Certainty, u_sum, v_sum, Certainty_sum] = PIV_Core(DiffData,...
        Mask, WindowSize, MaxStep, PIVMethod, SmoothMethod, FiltSize); % Do PIV
end
disp(['PIV time: ', num2str(toc(StartTime)), 's'])

[~,SaveName,~] = fileparts(FileName);
%save([DataFolder,SaveName,'.mat'],'x', 'y', 'u', 'v', 'Certainty', ...
%    'u_sum', 'v_sum', 'Certainty_sum', 'WindowSize', 'MaxStep', ...
%    'PIVMethod', 'SmoothMethod', 'FiltSize')
%% Display
PIVData = struct('x', x, 'y', y, 'u', u, 'v', v, 'Certainty', Certainty,...
    'u_sum', u_sum, 'v_sum', v_sum, 'Certainty_sum', Certainty_sum, ...
    'WindowSize', WindowSize, 'MaxStep', MaxStep);
figure(1)
PIV_PlotFigure(Data, PIVData, 'DataDisplay', 'Stack Average', 'DataCLims', [], ...
    'PIVDisplay', 'Colour Arrows', 'ArrowScale', 7, 'ColourBar', true, ...
    'FlowScale', 1, 'CBarLabel', 'Flow (\mum/s)', 'ArrowLineWidth', 0.5)

%for index = 1:size(u,1)
%    % Just pull out a frame at a time
%    PIVData = struct('x', x, 'y', y, 'u', u, 'v', v, 'Certainty', Certainty,...
%        'u_sum', u(index), 'v_sum', v(index), 'Certainty_sum', Certainty(index), ...
%        'WindowSize', WindowSize, 'MaxStep', MaxStep);
%    figure(2)
%    PIV_PlotFigure(Data, PIVData, 'DataDisplay', 'Frame', 'FrameNumber', index, 'DataCLims', [], ...
%        'PIVDisplay', 'Colour Arrows', 'ArrowScale', 7, 'ColourBar', true, ...
%        'CLims', [0,30], 'FlowScale', 120, 'CBarLabel', 'Flow (?m/s)')
%    drawnow
%end