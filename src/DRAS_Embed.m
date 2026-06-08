function [StegoPath, SecretMsg, MsgLen, stc_n_msg_bits] = DRAS_Embed(CoverPath, StegoPath, TempRecomPath, ComQF, Payload, CostType, UNIWARD_CostPath)
% DRAS_Embed: Implements the embedding process of the DRAS steganography algorithm.
%
% Inputs:
%   CoverPath:        Path to original cover JPEG image.
%   StegoPath:        Path where stego JPEG will be saved.
%   TempRecomPath:    Path for temporary simulated recompressed image.
%   ComQF:            Target channel compression quality factor.
%   Payload:          Embedding rate in percentage (%).
%   CostType:         Cost function to use: 'UERD' (default) or 'UNIWARD'.
%   UNIWARD_CostPath: Path to folder containing precalculated UNIWARD cost files.
%
% Outputs:
%   StegoPath:        Path to final saved stego JPEG.
%   SecretMsg:        Secret message vector embedded.
%   MsgLen:           Length of embedded secret message in bits.
%   stc_n_msg_bits:   Number of message bits embedded in each block.

    if nargin < 6 || isempty(CostType)
        CostType = 'UERD';
    end
    if nargin < 7
        UNIWARD_CostPath = '';
    end

    %% 1. Read QDCT and Quantization Table from Cover JPEG
    CoverStruct = jpeg_read(CoverPath);
    CoverQDCT = CoverStruct.coef_arrays{1, 1};
    CoverQuantTable = CoverStruct.quant_tables{1, 1};
    
    % Generate Channel Quantization Table and replicate matrices
    ChannelQuantTable = DRAS_GenQuantTable(ComQF);
    CoverQuantMatrix = repmat(CoverQuantTable, size(CoverQDCT) ./ 8);
    ChannelQuantMatrix = repmat(ChannelQuantTable, size(CoverQDCT) ./ 8);

    %% 2. Pre-processing / Channel Simulation
    % Compress cover image with ComQF to simulate the recompressed channel
    imwrite(imread(CoverPath), TempRecomPath, 'Quality', ComQF);
    TempCoverStruct = jpeg_read(TempRecomPath);
    ExpectedCoverQDCT = TempCoverStruct.coef_arrays{1, 1};

    %% 3. Secret Message Generation
    MsgLen = DRAS_CalcMsgLen(Payload, CoverQDCT);
    MsgMat = load('SecretMsg.mat');
    Message = MsgMat.msg;
    SecretMsg = uint8(Message(1:MsgLen));

    %% 4. Location Selection (RoLoS)
    ExpansionThreshold = 2; % Threshold parameter (Th)
    STC_CoverIndices = DRAS_GetRobustLoc(CoverQDCT, MsgLen, CoverQuantTable, ChannelQuantTable, ExpansionThreshold);

    %% 5. Cost Calculation
    if strcmpi(CostType, 'UERD')
        if ~isempty(UNIWARD_CostPath) % General precalculated cost path
            numbers = regexp(CoverPath, '(\d+)(?=\.jpg$)', 'match');
            if isempty(numbers)
                error('Cannot parse image index for UERD cost. Check CoverPath naming.');
            end
            coveridx = str2double(numbers{1});
            
            costFile = fullfile(UNIWARD_CostPath, ['rho' num2str(ComQF)], [num2str(coveridx) '.mat']);
            if exist(costFile, 'file')
                rho = load(costFile);
                UndetectabilityCostP1 = rho.var;
                UndetectabilityCostM1 = UndetectabilityCostP1;
            else
                warning('Precalculated UERD cost file not found at %s. Falling back to on-the-fly UERD cost.', costFile);
                [UndetectabilityCostP1, UndetectabilityCostM1] = DRAS_UERDcost(CoverQDCT, CoverQuantTable);
            end
        else
            [UndetectabilityCostP1, UndetectabilityCostM1] = DRAS_UERDcost(CoverQDCT, CoverQuantTable);
        end
    elseif strcmpi(CostType, 'UNIWARD')
        % Load precalculated UNIWARD costs from a path.
        % NOTE: For batch processing, J-UNIWARD cost computation is slow on-the-fly.
        % It is highly beneficial to first precalculate the costs of the full batch
        % offline (e.g. into .mat files) and then load them during embedding to enable
        % fast parallel/batch processing.
        
        if ~isempty(UNIWARD_CostPath)
            numbers = regexp(CoverPath, '(\d+)(?=\.jpg$)', 'match');
            if isempty(numbers)
                error('Cannot parse image index for UNIWARD cost. Check CoverPath naming.');
            end
            coveridx = str2double(numbers{1});
            
            costFile = fullfile(UNIWARD_CostPath, ['rho' num2str(ComQF)], [num2str(coveridx) '.mat']);
            if exist(costFile, 'file')
                rho = load(costFile);
                UndetectabilityCostP1 = rho.var;
                UndetectabilityCostM1 = UndetectabilityCostP1;
            else
                warning('UNIWARD cost file not found at %s. Falling back to dynamic J-UNIWARD cost.', costFile);
                [UndetectabilityCostP1, UndetectabilityCostM1] = DRAS_J_UNIWARDcost(CoverPath);
            end
        else
            % Calculate J-UNIWARD on-the-fly dynamically
            [UndetectabilityCostP1, UndetectabilityCostM1] = DRAS_J_UNIWARDcost(CoverPath);
        end
    else
        error('Unknown CostType: %s. Use UERD or UNIWARD.', CostType);
    end

    %% 6. Robustness Gating (Preventing small coefficients from modifying to avoid channel decoding failures)
    % Set costs to wet (10^10) if cover coefficient is smaller than half channel step size
    SelectedLocations = STC_CoverIndices;
    RobustnessThresholdMatrix = ceil(ChannelQuantMatrix / 2);
    
    % Critical Bugfix: Use correct indexing for SelectedLocations instead of logical indices directly on entire matrix
    invalidMask = abs(CoverQDCT(SelectedLocations)) < RobustnessThresholdMatrix(SelectedLocations);
    invalidLoc = SelectedLocations(invalidMask);
    UndetectabilityCostM1(invalidLoc) = 10^10;
    UndetectabilityCostP1(invalidLoc) = 10^10;

    % Prepare costs matrix for STC
    STC_Costs = zeros(3, length(SelectedLocations), 'single');
    STC_Costs(1, :) = reshape(UndetectabilityCostM1(SelectedLocations), 1, []);
    STC_Costs(3, :) = reshape(UndetectabilityCostP1(SelectedLocations), 1, []);

    %% 7. STC Embedding
    SelectedQDCT = ExpectedCoverQDCT(SelectedLocations);
    CoverSTC = SelectedQDCT';
    H = 10; % Trellis height
    
    [~, StegoSTC, stc_n_msg_bits, ~] = stc_pm1_pls_embed(int32(CoverSTC), STC_Costs, uint8(SecretMsg), H);
    
    % Handle message bits truncation/loss by STC if any
    STC_Bits_Loss = numel(SecretMsg) - sum(stc_n_msg_bits, 'all');
    if STC_Bits_Loss > 0
        SecretMsg = SecretMsg(1:end-STC_Bits_Loss);
        MsgLen = numel(SecretMsg);
    end
    
    % Verify embedding correctness
    stc_extract_msg_check = stc_ml_extract(int32(StegoSTC), stc_n_msg_bits, H);
    if ~isequal(double(stc_extract_msg_check), double(SecretMsg))
        error('STC embedding verification failed!');
    end

    %% 8. Mapping Stego Coefficients Back to Cover Domain (Channel Estimation Inverse)
    ModifiedCoverQDCT = ExpectedCoverQDCT;
    ModifiedCoverQDCT(SelectedLocations) = double(StegoSTC);
    
    % Map back: StegoQDCT = round((StegoSTC * ChannelQuantMatrix) / CoverQuantMatrix)
    StegoQDCT = round((ModifiedCoverQDCT(SelectedLocations) .* ChannelQuantMatrix(SelectedLocations)) ./ CoverQuantMatrix(SelectedLocations));
    
    % Construct the final Stego QDCT Matrix
    FinalStegoQDCT = CoverQDCT;
    FinalStegoQDCT(SelectedLocations) = StegoQDCT;

    %% 9. Write Stego JPEG Image
    StegoStruct = CoverStruct;
    StegoStruct.coef_arrays{1, 1} = double(FinalStegoQDCT);
    jpeg_write(StegoStruct, StegoPath);
end
