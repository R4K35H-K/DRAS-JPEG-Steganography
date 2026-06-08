function ExtractedMsg = DRAS_Extract(StegoPath, CoverQuantTable, ChannelQuantTable, MsgLen, STC_BlockBits, ExpansionThreshold)
% DRAS_Extract: Extracts the secret message from the received/recompressed stego JPEG image.
%
% Inputs:
%   StegoPath:         Path to the received stego JPEG image.
%   CoverQuantTable:   Quantization table of the original cover JPEG image.
%   ChannelQuantTable: Quantization table of the channel/stego JPEG image.
%   MsgLen:            Length of the secret message to be extracted in bits.
%   STC_BlockBits:     Number of message bits embedded per block (stc_n_msg_bits).
%   ExpansionThreshold: Multiplier threshold (Th) used during location selection.
%
% Output:
%   ExtractedMsg:      Vector of extracted secret message bits.

    if nargin < 6 || isempty(ExpansionThreshold)
        ExpansionThreshold = 2;
    end

    %% 1. Read QDCT from Stego JPEG
    StegoStruct = jpeg_read(StegoPath);
    StegoQDCT = StegoStruct.coef_arrays{1, 1};

    %% 2. Reconstruct the selected locations (RoLoS selection is symmetric)
    STC_CoverIndices = DRAS_GetRobustLoc(StegoQDCT, MsgLen, CoverQuantTable, ChannelQuantTable, ExpansionThreshold);

    %% 3. STC Syndrome Extraction
    H = 10; % Trellis height (must match embedding)
    StegoSTC = int32(StegoQDCT(STC_CoverIndices)');
    
    ExtractedMsg = stc_ml_extract(StegoSTC, STC_BlockBits, H);
    
    % Truncate to MsgLen
    ExtractedMsg = ExtractedMsg(1:MsgLen);
end
