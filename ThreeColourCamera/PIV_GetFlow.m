function [u, v, varargout] = PIV_GetFlow(XCorrMap)
%%% Given a cross-correlation map, determine the peak location
Method = '3 Point Gaussian';

u = zeros(size(XCorrMap,3), 1);
v = zeros(size(XCorrMap,3), 1);
u_offset = (size(XCorrMap,1)+1)/2;
v_offset = (size(XCorrMap,2)+1)/2;
MaxVals = zeros(size(XCorrMap,3), 1);
for Index = 1:size(XCorrMap,3)
    XCorr = XCorrMap(:,:,Index);
    switch Method
        case 'Peak Max'
            [MaxValue,MaxIndex] = max(XCorr(:));
            [I,J] = ind2sub([size(XCorrMap,1), size(XCorrMap,2)], MaxIndex);
            u(Index) = J - u_offset;
            v(Index) = I - v_offset;
        case '3 Point Gaussian'
            [MaxValue,MaxIndex] = max(XCorr(:));
            [I,J] = ind2sub([size(XCorrMap,1), size(XCorrMap,2)], MaxIndex);
            if (I == 1) || (I == size(XCorrMap,1)) || any(XCorr(I-1:I+1, J) < 0) || isnan(XCorr(I-1, J)) || isnan(XCorr(I+1, J))
                v(Index) = I - v_offset;
            else
                v(Index) = I - v_offset + (log(XCorr(I-1, J))-log(XCorr(I+1, J)))/...
                    (2*(log(XCorr(I-1, J)) + log(XCorr(I+1, J)) - 2*(log(XCorr(I, J)))));
            end
            
            if (J == 1) || (J == size(XCorrMap,2)) || any(XCorr(I, J-1:J+1) < 0) || isnan(XCorr(I, J-1)) || isnan(XCorr(I, J+1))
                u(Index) = J - u_offset;
            else
                u(Index) = J - u_offset + (log(XCorr(I, J-1))-log(XCorr(I, J+1)))/...
                    (2*(log(XCorr(I, J-1)) + log(XCorr(I, J+1)) - 2*(log(XCorr(I, J)))));
            end
    end
    MaxVals(Index) = MaxValue;
end

if nargout > 2
    varargout{1} = MaxVals;
end