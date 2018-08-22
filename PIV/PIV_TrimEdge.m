function Mask = PIV_TrimEdge(x, y, FrameSize, Tolerance)
%%% Trim out any points which lie too close to the edge
Mask = false(size(x));

for index = 1:length(x)
    Mask(index) = abs(mod(x(index)+(FrameSize(1)/2), FrameSize(1))-FrameSize(1)/2) <= Tolerance(1) ||...
        abs(mod(y(index)+(FrameSize(2)/2), FrameSize(2))-FrameSize(2)/2) <= Tolerance(2);
end

end
