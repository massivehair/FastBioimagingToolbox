%% Set up parameters
WindowSize = [16,16];
MaxStep = [192,192];
PIVMethod = 'Cross-correlation';
SmoothMethod = 'Wiener';
FiltSize = 5;

%% Load Data
DataFolder = 'G:\Projects\Red qdots high speed\';
%FileName = 'Area_192.307692_2115.384615_350.000000.U16'; % Poor demarcation
FileName = 'ZStack_-1.000000_-1.000000_320.000000.U16'; % Good demarcation
MaskThreshold = 0.2;

PathIn = [DataFolder, FileName];
%Data = PIV_TiffRead(PathIn); % Read data from TIFF file
Data = PIV_U16Read(PathIn, [1920,1920]); % Read data from U16 file

%% PIV
StartTime = tic;
[DiffData, Mask] = PIV_Preprocess(Data, MaskThreshold); % Take the difference, find all the capillaries

[x, y, u, v, Certainty, u_sum, v_sum, Certainty_sum] = PIV_Core(DiffData,...
    Mask, WindowSize, MaxStep, PIVMethod, SmoothMethod, FiltSize); % Do PIV

[~,SaveName,~] = fileparts(FileName);
save([DataFolder,SaveName,'.mat'],'x', 'y', 'u', 'v', 'Certainty', ...
    'u_sum', 'v_sum', 'Certainty_sum', 'WindowSize', 'MaxStep', ...
    'PIVMethod', 'SmoothMethod', 'FiltSize')

disp(['PIV time: ', num2str(toc(StartTime)), 's'])
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