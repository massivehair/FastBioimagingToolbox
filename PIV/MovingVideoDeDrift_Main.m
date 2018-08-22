% Go through the whole dataset and recover the frame drift for each
Directory = 'D:\PIV Local Copy\Moving around';
FilePrefix = '(4) moving around 100fps';
DeDriftThreshold = 128; % How many pixels can the camera shift before we need to redefine the reference frame?
UnlockMaxFrames = 100; % How many frames can the drift be zero before we redefine the reference frame?
UnlockShift = 1; % How far can a frame shift before it is considered non-static?
FileOut = ['D:\PIV Local Copy\Moving around\', FilePrefix, '_Drift.mat'];
SaveFile = true;

if exist(FileOut, 'file')
    load(FileOut)
else 
    Drift = zeros([0,2]);
end

DirListing = dir([Directory, '\', FilePrefix, '*.tif']);

h = waitbar(0,['Frame 0, processing ', DirListing(1).name(size(FilePrefix,2)+1:end), ' ', num2str(1), '/', num2str(1)]);

FrameNumber = 0;
FramesSinceRef = 0;

for index = 1:length(DirListing)
    warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')
    TiffObj = Tiff([Directory, '\', DirListing(index).name],'r');
    NumFrames = 1;
    
    while(~lastDirectory(TiffObj)) % Count how many frames are in the TIFF file
        nextDirectory(TiffObj)
        NumFrames = NumFrames + 1;
    end
    
    setDirectory(TiffObj,1)
    warning('on', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')
    
    %TagNames = TiffObj.getTagNames();
    %ImageWidth = TiffObj.getTag('ImageWidth');
    %ImageHeight = TiffObj.getTag('ImageLength');
    %TiffFrame = zeros(ImageWidth/2, ImageHeight/2, 'uint8');
    
    warning('off', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')
    for jndex = 1:NumFrames
        
        FrameNumber = FrameNumber + 1;
        
        if isvalid(h)
            waitbar(jndex/NumFrames, h, ['Frame ', num2str(FrameNumber), ', processing ', ...
                DirListing(index).name(size(FilePrefix,2)+1:end), ' ', num2str(jndex), '/', num2str(NumFrames)])
        end
        
        if FrameNumber > size(Drift,1) % don't overwrite already-calculated values
            TiffFrame = imresize(ModulationCompensation(double(read(TiffObj))), 0.5);
            
            if (FramesSinceRef > UnlockMaxFrames) && (FrameNumber > UnlockMaxFrames) && ...
                    all(all((Drift((FrameNumber-UnlockMaxFrames+1):(FrameNumber-1),:) ...
                    - Drift((FrameNumber-UnlockMaxFrames):(FrameNumber-2),:)) < UnlockShift))
                [DriftVectors, RefFrame, KnownOffset] = PIV_DeDriftGetVectors(TiffFrame, ...
                    'InitialReferenceFrame', RefFrame, 'ReferenceDriftThreshold', DeDriftThreshold, ...
                    'KnownOffset', KnownOffset, 'RequestRefUpdate', true);
                FramesSinceRef = 0;
            elseif FrameNumber > 1
                OldKnownOffset = KnownOffset;
                [DriftVectors, RefFrame, KnownOffset] = PIV_DeDriftGetVectors(TiffFrame, ...
                    'InitialReferenceFrame', RefFrame, 'ReferenceDriftThreshold', DeDriftThreshold, 'KnownOffset', KnownOffset);
                if all(OldKnownOffset == KnownOffset)
                    FramesSinceRef = FramesSinceRef + 1;
                else
                    FramesSinceRef = 0;
                end
            else
                RefFrame = PIV_DeDriftPreprocess(TiffFrame);
                KnownOffset = [0,0];
                DriftVectors = [0,0];
            end
            
            Drift(FrameNumber,:) = DriftVectors;
            switch SaveFile
                case true
                    save(FileOut, 'Drift')
            end
            
        elseif FrameNumber == size(Drift,1)
            TiffFrame = imresize(ModulationCompensation(double(read(TiffObj))), 0.5);
            RefFrame = PIV_DeDriftPreprocess(TiffFrame);
            KnownOffset = Drift(FrameNumber,:);
        end
        
        if jndex < NumFrames
            nextDirectory(TiffObj)
        end
    end
    warning('on', 'MATLAB:imagesci:tiffmexutils:libtiffWarning')
    TiffObj.close()
end
close(h)