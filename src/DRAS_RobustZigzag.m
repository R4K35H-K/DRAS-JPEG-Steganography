function prioritizedZigzag = DRAS_RobustZigzag(QDCT, CoverQuantTable, ChannelQuantTable)
% DRAS_RobustZigzag: Prioritizes robust elements (determined by RoLoS quantization ratio check) 
% in zigzag scan order within an 8x8 block.
% Corresponds to Section 3.2.2 (Case 3: k is an Odd Integer).
%
% Inputs:
%   QDCT:              Quantized DCT coefficients matrix.
%   CoverQuantTable:   Quantization Table for Cover.
%   ChannelQuantTable: Quantization Table for Channel.
%
% Output:
%   prioritizedZigzag: Prioritized coefficients array.

    if ~isequal(size(QDCT), [8, 8]) || ~isequal(size(CoverQuantTable), [8, 8]) || ~isequal(size(ChannelQuantTable), [8, 8])
        error('QDCT, CoverQuantTable, and ChannelQuantTable must all be 8x8 matrices');
    end

    % Compute robust elements using RoLoS odd integer multiple logic (Ω(u,v) = 1 in paper)
    isOddMultiple = (mod(ChannelQuantTable, CoverQuantTable) == 0) & ...
                    (mod(ChannelQuantTable ./ CoverQuantTable, 2) == 1);
    isOddMultiple(1, 1) = 0; % Exclude DC coefficient

    % Define zigzag scanning pattern (excluding DC coordinate (1,1))
    zigzag = [9, 2, 3, 10, 17, 25, 18, ...
              11, 4, 5, 12, 19, 26, 33, 41, ...
              34, 27, 20, 13, 6, 7, 14, 21, ...
              28, 35, 42, 49, 57, 50, 43, 36, ...
              29, 22, 15, 8, 16, 23, 30, 37, ...
              44, 51, 58, 59, 52, 45, 38, 31, ...
              24, 32, 39, 46, 53, 60, 61, 54, ...
              47, 40, 48, 55, 62, 63, 56, 64];

    QDCTFlat = reshape(QDCT, 1, []);
    robustFlat = reshape(isOddMultiple, 1, []);

    % Separate robust (Ψ_R) and non-robust (Ψ_NR) locations
    robustIndices = zigzag(robustFlat(zigzag) == 1);
    nonRobustIndices = zigzag(robustFlat(zigzag) == 0);

    % Concatenate: Ψ = [Ψ_R || Ψ_NR]
    prioritizedIndices = [robustIndices, nonRobustIndices];
    prioritizedZigzag = QDCTFlat(prioritizedIndices);
end
