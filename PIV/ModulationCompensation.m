function Data = ModulationCompensation(Data, varargin)
%%% Compensate for sCMOS noise
% Methods: 
% 1: Take the Parameters(1)th lowest value in the row (default)
% 2: Take the mean of the Parameters(1) leftmost columns

if size(varargin,2) == 0
    Method = 1;
    Parameters = 200;
elseif size(varargin,2) == 1
    Method = varargin{1};
    Parameters = 200;
else
    Method = varargin{1};
    Parameters = varargin{2};
end

if size(Data,3) > 1
    WaitbarHandle = waitbar(0,'Demodulating...');
else
    WaitbarHandle = NaN;
end
for Index = 1:size(Data,3)
    if size(Data,3) == 1
        Frame = Data;
    else
        Frame = Data(:,:,Index);
    end
    
    switch Method
        case 1
            SortedFrame = double(sort(Frame,2));
            Frame = double(Frame) - SortedFrame(:,Parameters(1))*ones(1,size(Frame,2));
        case 2
            Frame = double(Frame) - mean(Frame(:,1:Parameters(1)),2)*ones(1,size(Frame,2));
    end
    if size(Data,3) == 1
        Data = cast(Frame, 'like', Data);
    else
        Data(:,:,Index) = cast(Frame, 'like', Data);
    end
    
    if ishandle(WaitbarHandle)
        waitbar(Index/size(Data,3), WaitbarHandle, ['Demodulating...', num2str(Index), '/', num2str(size(Data,3))])
    end
end
if ishandle(WaitbarHandle)
    close(WaitbarHandle)
end