function QuantTable = DRAS_GenQuantTable(QualityFactor)
% DRAS_GenQuantTable: Generates the standard JPEG luminance quantization table 
% for a given Quality Factor (1-100).
%
% Input:
%   QualityFactor: Target quality factor.
%
% Output:
%   QuantTable: 8x8 luminance quantization table.

    % Define base quantization matrix (Luminance)
    baseTable = [16 11 10 16 24 40 51 61; 
                 12 12 14 19 26 58 60 55;
                 14 13 16 24 40 57 69 56; 
                 14 17 22 29 51 87 80 62;
                 18 22 37 56 68 109 103 77; 
                 24 35 55 64 81 104 113 92;
                 49 64 78 87 103 121 120 101; 
                 72 92 95 98 112 100 103 99];
             
    if QualityFactor < 50
        scale = 5000 / QualityFactor;
    else
        scale = 200 - 2 * QualityFactor;
    end

    QuantTable = floor((scale * baseTable + 50) / 100);
    QuantTable(QuantTable == 0) = 1; % Prevent divide-by-zero
end
