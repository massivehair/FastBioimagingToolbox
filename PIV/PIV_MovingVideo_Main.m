%% Set up parameters
WindowSize = [32,32];
MaxStep = [224,224]; % Was 192 (128+64), now 128+64+32
PIVMethod = 'Cross-correlation';
SmoothMethod = 'Wiener';
FiltSize = 5;
MaskThreshold = 32;
SaveMatFile = true;

Directory = 'G:\Projects\High Speed SWIR QDot Temporal Focusing\21st August 2015\Green dots';
FilePrefix = '(4) moving around 100fps';

load(['G:\Projects\High Speed SWIR QDot Temporal Focusing', '\', FilePrefix, '_Drift.mat'])

DirListing = dir([Directory, '\', FilePrefix, '*.tif']);

h = waitbar(0,['Frame 0, processing ', DirListing(1).name(size(FilePrefix,2)+1:end), ' ', num2str(1), '/', num2str(1)]);

FrameNumber = 0;

%% Do PIV over all files
for index = 1:length(DirListing)
    FileName = DirListing(index).name;
    [~,SaveName,~] = fileparts(FileName);
    
    warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')
    TiffObj = Tiff([Directory, '\', DirListing(index).name],'r');
    NumFrames = 1;
    
    while(~lastDirectory(TiffObj)) % Count how many frames are in the TIFF file
        nextDirectory(TiffObj)
        NumFrames = NumFrames + 1;
    end
    
    setDirectory(TiffObj,1)
    
    x = cell(0,1);
    y = cell(0,1);
    u = cell(0,1);
    v = cell(0,1);
    Certainty = cell(0,1);
    
    DoLoop = true; % By default, process the file
    if exist([Directory,'\', SaveName,'.mat'], 'file')
        load([Directory,'\', SaveName,'.mat'])
        if size(x,2) >= NumFrames
            DoLoop = false; % Unless the file already exists AND there are no unprocessed frames
        end
    end
        
    if DoLoop
        for jndex = 1:NumFrames
            FrameNumber = FrameNumber + 1;
            
            if isvalid(h)
                waitbar(jndex/NumFrames, h, ['Frame ', num2str(FrameNumber), ', processing ', ...
                    DirListing(index).name(size(FilePrefix,2)+1:end), ' ', num2str(jndex), '/', num2str(NumFrames)])
            end
            
            if jndex > size(x,2) % don't overwrite already-calculated values
                TiffFrame = ModulationCompensation(int32(read(TiffObj)));
                [~, Mask] = PIV_Preprocess(TiffFrame, 'MaskThreshold', MaskThreshold, 'Contrast', 'HighPassStd'); % Take the difference, find all the capillaries
                
                switch SmoothMethod
                    case 'Savitzky Golay'
                        TiffFrame = savitzkyGolay2D_rle_coupling(size(TiffFrame, 1), size(TiffFrame, 2), ...
                            double(TiffFrame), FiltSize, FiltSize, 2);
                    case 'Wiener'
                        TiffFrame = wiener2(double(TiffFrame), [FiltSize, FiltSize]);
                    case 'Gaussian'
                        TiffFrame = imgaussfilt(TiffFrame, FiltSize);
                end
                
                if FrameNumber > 1
                    try
                        % Calculate sample positions
                        
                        [Ymesh, Xmesh] = meshgrid(mod(round(-Drift(FrameNumber,1)), WindowSize(1))+1:WindowSize(1):size(TiffFrame,1), ...
                            mod(round(-Drift(FrameNumber,2)), WindowSize(2))+1:WindowSize(2):size(TiffFrame,2));
                        Locations = [Ymesh(:),Xmesh(:)];
                        MaskedLocs = false(size(Locations,1),1);
                        for Index = 1:size(Locations, 1)
                            MaskedLocs(Index) = Mask(Locations(Index,1), Locations(Index,2));
                        end
                        Locations = Locations(~MaskedLocs,:);
                        
                        % Perform PIV
                        [XCorrMap] = PIV_xcorr(RefFrame, TiffFrame, WindowSize, MaxStep, Mask, Locations);
                        
                        y{jndex} = Locations(:,1);
                        x{jndex} = Locations(:,2);
                        
                        XCorrNorm = PIV_NormalizeCorrMap(XCorrMap, Locations(:,1), Locations(:,2), TiffFrame, WindowSize);
                        
                        [u{jndex}, v{jndex}, MaxVals] = PIV_GetFlow(XCorrNorm);
                        Certainty{jndex} = MaxVals./squeeze(sum(sum(XCorrNorm)));
                    catch
                        disp(['Error calculating PIV. Skipping frame ', num2str(FrameNumber)])
                    end
                    RefFrame = TiffFrame;
                else % For the first frame, just get the reference frame and return zero
                    switch SmoothMethod
                        case 'Savitzky Golay'
                            RefFrame = savitzkyGolay2D_rle_coupling(size(TiffFrame, 1), size(TiffFrame, 2), ...
                                double(TiffFrame), FiltSize, FiltSize, 2);
                        case 'Wiener'
                            RefFrame = wiener2(double(TiffFrame), [FiltSize, FiltSize]);
                        case 'Gaussian'
                            RefFrame = imgaussfilt(TiffFrame, FiltSize);
                    end
                    x{jndex} = [];
                    y{jndex} = [];
                    u{jndex} = [];
                    v{jndex} = [];
                    Certainty{jndex} = [];
                end
                
                switch SaveMatFile
                    case true
                        save([Directory,'\',SaveName,'.mat'],'x', 'y', 'u', ...
                            'v', 'Certainty', 'WindowSize', 'MaxStep', ...
                            'PIVMethod', 'SmoothMethod', 'FiltSize', ...
                            'MaskThreshold')
                end
                
            elseif jndex == size(x,1) % The last frame we calculated
                TiffFrame = ModulationCompensation(int32(read(TiffObj)));
                switch SmoothMethod
                    case 'Savitzky Golay'
                        RefFrame = savitzkyGolay2D_rle_coupling(size(TiffFrame, 1), size(TiffFrame, 2), ...
                            double(TiffFrame), FiltSize, FiltSize, 2);
                    case 'Wiener'
                        RefFrame = wiener2(double(TiffFrame), [FiltSize, FiltSize]);
                    case 'Gaussian'
                        RefFrame = imgaussfilt(TiffFrame, FiltSize);
                end
            end
            
            if jndex < NumFrames
                nextDirectory(TiffObj)
            end
        end

    else
        if size(DirListing,1) > index
            FileNameNext = DirListing(index).name;
            [~,SaveNameNext,~] = fileparts(FileNameNext);
            if ~exist([Directory,SaveNameNext,'.mat'], 'file') % Check if the next file exists too
                setDirectory(TiffObj,NumFrames); % If not, the last frame is in this TIFF file. Process the reference frame.
                TiffFrame = ModulationCompensation(int32(read(TiffObj)));
                switch SmoothMethod
                    case 'Savitzky Golay'
                        RefFrame = savitzkyGolay2D_rle_coupling(size(TiffFrame, 1), size(TiffFrame, 2), ...
                            double(TiffFrame), FiltSize, FiltSize, 2);
                    case 'Wiener'
                        RefFrame = wiener2(double(TiffFrame), [FiltSize, FiltSize]);
                    case 'Gaussian'
                        RefFrame = imgaussfilt(TiffFrame, FiltSize);
                end
            end
        end
        FrameNumber = FrameNumber + NumFrames;
    end
    warning('on', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')
    TiffObj.close()
end
close(h)
