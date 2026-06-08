function [UndetectabilityCostP1, UndetectabilityCostM1] = DRAS_UERDcost(CoverQDCT, CoverQuantTable)
% DRAS_UERDcost: Computes UERD (Uniform Embedding Revisited Distortion) costs 
% for QDCT coefficients based on block energies.
%
% Inputs:
%   CoverQDCT:       Quantized DCT coefficients matrix of the cover image.
%   CoverQuantTable: Quantization table matrix of the cover JPEG.
%
% Outputs:
%   UndetectabilityCostP1: UERD costs for +1 modifications.
%   UndetectabilityCostM1: UERD costs for -1 modifications.

    dctAC = CoverQDCT;
    % Remove DC coefficients (at block indices 1, 9, etc.)
    dctAC(1:8:end, 1:8:end) = 0;
    wetConst = 10^13;
    [X, Y] = size(CoverQDCT);

    % Set DC coefficient quantization table value to average of neighboring AC step sizes
    CoverQuantTable(1,1) = 0.5 * (CoverQuantTable(2,1) + CoverQuantTable(1,2));
    quantMatrix = repmat(CoverQuantTable, [X/8 Y/8]);

    dctAC_cols = im2col(quantMatrix .* dctAC, [8 8], 'distinct');

    J2 = sum(abs(dctAC_cols));
    J = ones(64,1) * J2;
    J = col2im(J, [8 8], [X Y], 'distinct'); 

    pad_size = 8;
    im2 = padarray(J, [pad_size pad_size], 'symmetric'); % energies of eight-neighbor blocks
    size2 = 2 * pad_size;
    im_l8 = im2(1+pad_size:end-pad_size, 1:end-size2);
    im_r8 = im2(1+pad_size:end-pad_size, 1+size2:end);
    im_u8 = im2(1:end-size2, 1+pad_size:end-pad_size);
    im_d8 = im2(1+size2:end, 1+pad_size:end-pad_size);
    im_l88 = im2(1:end-size2, 1:end-size2);
    im_r88 = im2(1+size2:end, 1+size2:end);
    im_u88 = im2(1:end-size2, 1+size2:end);
    im_d88 = im2(1+size2:end, 1:end-size2);
    
    energyNeighbor = (J + 0.25*(im_l8+im_r8+im_u8+im_d8) + 0.25*(im_l88+im_r88+im_u88+im_d88));
    rawCost = quantMatrix ./ energyNeighbor; 
    rawCost = rawCost / min(rawCost(:));
    UndetectabilityCostP1 = rawCost;
    UndetectabilityCostM1 = rawCost;
                
    UndetectabilityCostP1(UndetectabilityCostP1 > wetConst) = wetConst;
    UndetectabilityCostP1(isnan(UndetectabilityCostP1)) = wetConst;    
    UndetectabilityCostP1(CoverQDCT > 1023) = wetConst;

    UndetectabilityCostM1(UndetectabilityCostM1 > wetConst) = wetConst;
    UndetectabilityCostM1(isnan(UndetectabilityCostM1)) = wetConst;
    UndetectabilityCostM1(CoverQDCT < -1023) = wetConst;
end
