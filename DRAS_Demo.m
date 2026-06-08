%% DRAS Batch Demonstration Script
% This script demonstrates the batch workflow of the DRAS (Robust Steganography 
% against JPEG Recompression) algorithm:
% 1. Relative path setup and image selection.
% 2. Message embedding with DRAS (using dynamic UERD cost on-the-fly or loaded/dynamic J-UNIWARD).
% 3. Simulated Social Network Platform (SNP) recompression.
% 4. Message extraction and Bit Error Rate (BER) evaluation.

clc;
clear;
close all;
warning off;

%% 1. Configuration and Path Setup
DemoDir = fileparts(mfilename('fullpath')); % points to dras_matlab/
BaseDir = fileparts(DemoDir); % points to workspace root

% Add src folder to MATLAB search path
addpath(genpath(fullfile(DemoDir, 'src')));

% User Inputs
Payload = 10;          % Embedding Rate in Percentage (%)
ComQF = 80;            % Target Compression Quality Factor
Selected_Files = 10;   % Number of files to process

% Cost Function Settings ('UERD' or 'UNIWARD')
CostType = 'UERD';     % 'UERD' is default, computes on-the-fly without dependencies
UNIWARD_CostPath = ''; % Optional: path to precalculated UNIWARD costs (for batch mode)

% Define cover source folder (defaults to local repository cover_images)
CoverSourceFolder = fullfile(DemoDir, 'cover_images'); % Cover images should be of QF95 or greater

% Output and temporary directories
StegoFolder = fullfile(DemoDir, 'Stego_Images', ['Q' num2str(ComQF) '_P' num2str(Payload)]);
RecomTempFolder = fullfile(DemoDir, 'Temp_ReCompressed_Stego');
RecomStegoFolder = fullfile(DemoDir, 'Compressed_Stego_Images');
ResultsFolder = fullfile(DemoDir, 'Results');

% Create directories if they do not exist
if ~exist(StegoFolder, 'dir'), mkdir(StegoFolder); end
if ~exist(RecomTempFolder, 'dir'), mkdir(RecomTempFolder); end
if ~exist(RecomStegoFolder, 'dir'), mkdir(RecomStegoFolder); end
if ~exist(ResultsFolder, 'dir'), mkdir(ResultsFolder); end

% Clean up previous runs
delete(fullfile(StegoFolder, '*.jpg'));
delete(fullfile(RecomTempFolder, '*.jpg'));
delete(fullfile(RecomStegoFolder, '*.jpg'));

% Get files in cover directory
files = dir(fullfile(CoverSourceFolder, '*.jpg'));
if isempty(files)
    error('No cover images found at %s. Please verify path.', CoverSourceFolder);
end

fprintf('=== DRAS Batch Validation ===\n');
fprintf('Cover Folder      : %s\n', CoverSourceFolder);
fprintf('Payload Rate      : %d%%\n', Payload);
fprintf('Target QF         : %d\n', ComQF);
fprintf('Cost Type         : %s\n', CostType);
fprintf('Processing Files  : %d files\n\n', min(Selected_Files, length(files)));

%% 2. Processing Loop
ComputationTime = zeros(1, Selected_Files);
MsgLen = zeros(1, Selected_Files);
R_err = zeros(1, Selected_Files);
PSNR = zeros(1, Selected_Files);
SSIM = zeros(1, Selected_Files);

for w = 1:min(Selected_Files, length(files))
    CoverImg = fullfile(CoverSourceFolder, [num2str(w) '.jpg']);
    StegoImg = fullfile(StegoFolder, [num2str(w) '.jpg']);
    RecomImg_Temp = fullfile(RecomTempFolder, [num2str(w) '.jpg']);
    SNPImg = fullfile(RecomStegoFolder, [num2str(w) '.jpg']);
    
    fprintf(' [%d/%d] Processing %s...\n', w, Selected_Files, [num2str(w) '.jpg']);
    
    tic;
    %% 2.1 Embedding Stage
    [StegoImg, SecretMsg, msg_len, stc_n_msg_bits] = DRAS_Embed(CoverImg, StegoImg, RecomImg_Temp, ComQF, Payload, CostType, UNIWARD_CostPath);
    MsgLen(w) = msg_len;
    ComputationTime(w) = toc;
    
    %% 2.2 Quality Evaluation
    Cover_Image = imread(CoverImg);
    Stego_Image = imread(StegoImg);
    PSNR(w) = psnr(Cover_Image, Stego_Image);
    SSIM(w) = ssim(Cover_Image, Stego_Image);
    
    %% 2.3 Simulated SNP Recompression (Channel Attack)
    imwrite(imread(StegoImg), SNPImg, 'Quality', ComQF);
    
    %% 2.4 Message Extraction Stage
    % Get quantization tables for extraction
    C_Struct = jpeg_read(CoverImg);
    C_Quant = C_Struct.quant_tables{1, 1};
    
    SNP_Struct = jpeg_read(SNPImg);
    S_Quant = SNP_Struct.quant_tables{1, 1};
    
    ExtractedMsg = DRAS_Extract(SNPImg, C_Quant, S_Quant, msg_len, stc_n_msg_bits);
    
    %% 2.5 Robustness evaluation (BER)
    bit_errors = sum(bitxor(double(SecretMsg), double(ExtractedMsg)), 'all');
    R_err(w) = bit_errors / msg_len;
end

%% 3. Print Results Summary
avgCompTime = mean(ComputationTime);
avgBER = mean(R_err) * 100;
avgPSNR = mean(PSNR);
avgSSIM = mean(SSIM);
errorFreeCount = sum(R_err == 0);

fprintf('\n=== Results Summary ===\n');
fprintf('Average Embedding Time  : %.2f seconds\n', avgCompTime);
fprintf('Average PSNR            : %.2f dB\n', avgPSNR);
fprintf('Average SSIM            : %.4f\n', avgSSIM);
fprintf('Average Bit Error Rate  : %.2f%%\n', avgBER);
fprintf('Error-Free Extractions  : %d / %d\n', errorFreeCount, Selected_Files);
fprintf('========================\n');

% Save results
save(fullfile(ResultsFolder, ['DRAS_Results_P' num2str(Payload) '.mat']), 'MsgLen', 'ComputationTime', 'R_err', 'PSNR', 'SSIM');