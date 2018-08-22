function ImageOut = HSVtoRGB(H,S,V)
%%% Convert HSV image planes to a single RGB image

ImageSize = max([size(H); size(S); size(V)]);
if any(size(H) ~= ImageSize)
    imresize(H, ImageSize)
end
if any(size(S) ~= ImageSize)
    imresize(S, ImageSize)
end
if any(size(V) ~= ImageSize)
    imresize(V, ImageSize)
end

% Chroma is easy to calculate from Value:

if all(size(unique(V(:))) == [1,1])
    V = ones(size(1));
else
    V = V - min(V(:));
    V = V/max(V(:));
end
Chroma = V .* S;

% calculate RGB
X = Chroma.*(1-abs(mod(H,2)-1));
R = zeros(ImageSize);
G = zeros(ImageSize);
B = zeros(ImageSize);

Mask = (H >= 0 & H < 1);
R(Mask) = Chroma(Mask);
G(Mask) = X(Mask);

Mask = (H >= 1 & H < 2);
R(Mask) = X(Mask);
G(Mask) = Chroma(Mask);

Mask = (H >= 2 & H < 3);
G(Mask) = Chroma(Mask);
B(Mask) = X(Mask);

Mask = (H >= 3 & H < 4);
G(Mask) = X(Mask);
B(Mask) = Chroma(Mask);

Mask = (H >= 4 & H < 5);
R(Mask) = X(Mask);
B(Mask) = Chroma(Mask);

Mask = (H >= 5 & H < 6);
R(Mask) = Chroma(Mask);
B(Mask) = X(Mask);

R = R + V-Chroma;
G = G + V-Chroma;
B = B + V-Chroma;

ImageOut = cat(3,R,G,B);