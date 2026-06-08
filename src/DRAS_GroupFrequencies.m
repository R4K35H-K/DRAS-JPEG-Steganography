function freqCellArray = DRAS_GroupFrequencies(QDCT)
% DRAS_GroupFrequencies: Groups QDCT coefficients from all 8x8 blocks by their frequency indices.
% Returns an 8x8 cell array where cell {i, j} contains the (i, j)-th DCT coefficient 
% from all blocks.

    [rows, cols] = size(QDCT);
    if mod(rows, 8) ~= 0 || mod(cols, 8) ~= 0
        error('The dimensions of the QDCT matrix must be a multiple of 8.');
    end

    numBlocksRows = rows / 8;
    numBlocksCols = cols / 8;

    freqCellArray = cell(8, 8);

    % Reshape QDCT into a 4D array
    reshapedQDCT = reshape(QDCT, 8, numBlocksRows, 8, numBlocksCols);

    % Permute dimensions to group coefficients
    regroupedQDCT = permute(reshapedQDCT, [1 3 2 4]);

    % Reshape to get the final grouping
    for i = 1:8
        for j = 1:8
            freqCellArray{i,j} = reshape(regroupedQDCT(i,j,:,:), numBlocksRows, numBlocksCols);
        end
    end
end
