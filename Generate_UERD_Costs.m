%% UERD Cost Precalculation Script for DRAS
% This script precalculates UERD costs for a batch of cover JPEG images
% and saves them to .mat files.

clc;
clear;
close all;
warning off;

%% 1. Configuration
DemoDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(DemoDir, 'src')));

CoverSourceFolder = fullfile(DemoDir, 'cover_images');
% Set the QF index folder name to match your target Quality Factor (e.g. ComQF = 80)
TargetQF = 80; 
OutputFolder = fullfile(DemoDir, 'UERD_Costs', ['rho' num2str(TargetQF)]);

if ~exist(OutputFolder, 'dir')
    mkdir(OutputFolder);
end

% Get list of JPEG files
files = dir(fullfile(CoverSourceFolder, '*.jpg'));
if isempty(files)
    error('No cover images found in %s', CoverSourceFolder);
end

fprintf('=== Generating UERD Costs (DRAS) ===\n');
fprintf('Source Folder : %s\n', CoverSourceFolder);
fprintf('Output Folder : %s\n', OutputFolder);
fprintf('Total Images  : %d\n\n', length(files));

%% 2. Generation Loop
tic;
for w = 1:length(files)
    CoverImgPath = fullfile(CoverSourceFolder, files(w).name);
    
    % Extract image index (e.g., 1 from '1.jpg')
    numbers = regexp(files(w).name, '(\d+)(?=\.jpg$)', 'match');
    if isempty(numbers)
        fprintf(' [!] Skipping %s (cannot parse numerical index)\n', files(w).name);
        continue;
    end
    coveridx = str2double(numbers{1});
    
    OutputFile = fullfile(OutputFolder, [num2str(coveridx) '.mat']);
    fprintf(' [%d/%d] Calculating UERD cost for %s...\n', w, length(files), files(w).name);
    
    % Read QDCT and Quantization table
    CoverStruct = jpeg_read(CoverImgPath);
    CoverQDCT = CoverStruct.coef_arrays{1, 1};
    CoverQuantTable = CoverStruct.quant_tables{1, 1};
    
    % Compute UERD costs
    [UndetectabilityCostP1, ~] = DRAS_UERDcost(CoverQDCT, CoverQuantTable);
    
    % Save with the variable name 'var' (as expected by the Embed function)
    var = UndetectabilityCostP1;
    save(OutputFile, 'var');
end
elapsedTime = toc;
fprintf('\nCost generation completed in %.2f seconds.\n', elapsedTime);
