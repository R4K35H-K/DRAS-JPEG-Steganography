function STC_CoverIndices = DRAS_GetRobustLoc(CoverQDCT, MsgLen, CoverQuantTable, ChannelQuantTable, ExpansionThreshold)
% DRAS_GetRobustLoc: Prepares the STC cover indices vector from the CoverQDCT matrix,
% message length, quantization tables, and expansion threshold.
%
% Inputs:
%   CoverQDCT:          Quantized DCT coefficients matrix of the cover image.
%   MsgLen:             Length of the secret message to be embedded.
%   CoverQuantTable:    Quantization table of the cover JPEG.
%   ChannelQuantTable:  Quantization table of the channel JPEG.
%   ExpansionThreshold: Multiplier threshold (Th) to determine the STC cover length.
%
% Output:
%   STC_CoverIndices:   Linear indices of the cover coefficients selected for STC.

    [rows, cols] = size(CoverQDCT);
    linearIndices = reshape(1:(rows * cols), rows, cols);
    
    % Calculate size of QDCT coefficients per frequency lattice
    blockSize = (rows * cols) / 64;
    
    % Calculate STC Cover length (excluding DC coefficients per block)
    % Since DC coefficients are excluded, the maximum number of AC coefficients is (rows * cols) - blockSize
    STC_Len = min(ExpansionThreshold * MsgLen, numel(CoverQDCT) - blockSize);
    
    % Calculate number of lattices needed
    numLattices = ceil(STC_Len / blockSize);
    
    % Group linear indices by frequency
    groupedIndices = DRAS_GroupFrequencies(linearIndices);
    
    % Prepare the STC Cover Indices by ordering AC lattices in robust zigzag order
    STC_CoverIndices = DRAS_PrepareCoverSTC(groupedIndices, STC_Len, numLattices, blockSize, CoverQuantTable, ChannelQuantTable);
end
