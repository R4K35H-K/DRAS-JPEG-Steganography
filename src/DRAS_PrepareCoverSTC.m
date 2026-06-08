function [CoverSTC, groupedFrequenciesZigzag] = DRAS_PrepareCoverSTC(groupedFrequencies, STC_Len, numLattices, blockSize, CoverQuantTable, ChannelQuantTable)
% DRAS_PrepareCoverSTC: Prepares the cover STC vector by ordering AC lattices
% according to the prioritized robust zigzag order and extracting elements.
%
% Inputs:
%   groupedFrequencies: Cell array of size 8x8 containing coefficients grouped by frequency.
%   STC_Len:            Syndrome Trellis Codes cover length.
%   numLattices:        Number of frequency lattices (64).
%   blockSize:          Number of blocks (size of each lattice).
%   CoverQuantTable:    Quantization Table for Cover.
%   ChannelQuantTable:  Quantization Table for Channel.
%
% Outputs:
%   CoverSTC:                 Prepared STC cover vector.
%   groupedFrequenciesZigzag: groupFrequencies rearranged in robust zigzag order.

    % Rearrange cell array according to the robust zigzag pattern (RoLoS)
    groupedFrequenciesZigzag = DRAS_RobustZigzag(groupedFrequencies, CoverQuantTable, ChannelQuantTable);
    
    % Initialize CoverSTC
    CoverSTC = zeros(numLattices * blockSize, 1);
    
    n = 1;
    for i = 1:numLattices
        if n > STC_Len
            break; % Exit if we've filled the STC cover vector
        end
        
        coeffs = groupedFrequenciesZigzag{i}(:);
        l = min(n + length(coeffs) - 1, STC_Len); 
        CoverSTC(n:l) = coeffs(1:(l - n + 1));
        n = l + 1;
        
        if n > STC_Len
            break; 
        end
    end
    
    % Trim CoverSTC to STC_Len if it's longer
    if length(CoverSTC) > STC_Len
        CoverSTC = CoverSTC(1:STC_Len);
    end
end
