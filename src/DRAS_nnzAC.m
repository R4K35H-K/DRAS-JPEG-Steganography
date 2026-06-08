function numNZAC = DRAS_nnzAC(CoverQDCT)
% DRAS_nnzAC: Computes the number of non-zero AC coefficients in the QDCT matrix.
% Excluding DC coefficients (at block indices 1, 9, 17, etc.)

tempAC = CoverQDCT;
tempAC(1:8:end, 1:8:end) = 0; % Clear DC coefficients
numNZAC = nnz(tempAC);
end
