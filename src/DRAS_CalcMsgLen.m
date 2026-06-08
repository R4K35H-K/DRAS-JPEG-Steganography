function MsgLen = DRAS_CalcMsgLen(Payload, CoverQDCT)
% DRAS_CalcMsgLen: Calculates the message length dynamically based on the payload rate (%) 
% and available non-zero AC coefficients.

numNZAC = DRAS_nnzAC(CoverQDCT); % Number of non-zero AC QDCT Coefficients
MsgLen = ceil((Payload / 100) * numNZAC);
end
