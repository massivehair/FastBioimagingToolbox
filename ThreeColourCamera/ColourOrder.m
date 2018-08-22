function [Order, varargout] = ColourOrder(FilePath, varargin)
%%% Recover the identity of the camera that produced each frame
if nargin < 2
    TimeStampPresent = 'WithTimeStamp';
else
    TimeStampPresent = varargin{1};
end

FileID = fopen(FilePath);

switch TimeStampPresent
    case 'NoTimeStamp'
        FileContents = fgetl(FileID);
        Order = zeros(size(FileContents,2), 1);
        for index = 1:size(FileContents,2)
            Order(index) = sscanf(FileContents(index), '%d');
        end
    case 'WithTimeStamp'
        FileInfo = dir(FilePath);
        FileLine = fgetl(FileID);
        Order = zeros(ceil(FileInfo.bytes/(length(FileLine)+1)), 1, 'uint8');
        TimeStamp = zeros(ceil(FileInfo.bytes/(length(FileLine)+1)), 1, 'uint64');
        index = 1;
        while ~isempty(FileLine) && ischar(FileLine)
            LineNums = sscanf(FileLine, '%lu %lu');
            Order(index) = uint8(LineNums(1));
            TimeStamp(index) = LineNums(2);
            index = index + 1;
            FileLine = fgetl(FileID);
        end
        
        Order = Order(1:index-1);
        TimeStamp = TimeStamp(1:index-1);
end
fclose(FileID);

if nargout == 2;
    varargout{1} = TimeStamp;
end