# DRAS (Downward Recompression Robust Steganography) - MATLAB Implementation

This repository contains the official MATLAB implementation of the **DRAS** steganography scheme for JPEG images, as described in the paper:
> **Dealing with downward recompression for robust steganography in high quality JPEG images** (Journal of Visual Communication and Image Representation, 2026)

## Repository Structure

To keep the repository clean and portable, the root folder contains only the main execution scripts and documentation, while core algorithms and helpers are isolated in the `src/` directory:

```
/dras_matlab/
  ├── DRAS_Demo.m                 # Main batch demo runner (configured with relative paths)
  ├── Generate_UNIWARD_Costs.m    # J-UNIWARD cost precalculation utility [NEW]
  ├── Generate_UERD_Costs.m       # UERD cost precalculation utility [NEW]
  ├── README.md                   # This documentation file
  ├── cover_images/               # Sample cover images for out-of-the-box demonstration
  └── src/                        # Implementation functions and dependencies
        ├── DRAS_Embed.m          # Core embedding routine (Algorithm 2)
        ├── DRAS_Extract.m        # Core extraction routine (Section 3.4)
        ├── DRAS_GetRobustLoc.m   # Robust coefficients selection (Algorithm 1 / Section 3.2.2)
        ├── DRAS_PrepareCoverSTC.m # Reorders lattices and builds STC cover vector
        ├── DRAS_RobustZigzag.m   # Prioritizes robust frequency lattices (RoLoS)
        ├── DRAS_GroupFrequencies.m # Groups coefficients by frequency
        ├── DRAS_nnzAC.m          # Non-zero AC counter
        ├── DRAS_CalcMsgLen.m     # Computes length of secret message vector
        ├── DRAS_GenQuantTable.m  # Standard JPEG quantization table generator
        ├── DRAS_UERDcost.m       # Fast on-the-fly UERD cost function
        ├── DRAS_J_UNIWARDcost.m  # On-the-fly J-UNIWARD cost function (optional)
        ├── SecretMsg.mat         # Sample secret message data
        └── *.mexw64              # Syndrome-Trellis Codes (STC) & JPEG Toolbox MEX binaries
```

---

## Variable Mapping to Research Paper

Variables in the codebase are named descriptively to map directly to the research paper concepts:

| Research Concept | Paper Symbol | Variable Name |
| :--- | :---: | :--- |
| JPEG cover image | $\mathbf{X}_C$ | `CoverPath` |
| JPEG stego image | $\mathbf{Y}$ | `StegoPath` |
| Cover QDCT coefficients | $\mathbf{C}$ | `CoverQDCT` |
| Cover quantization table | $\mathbf{Q}_C$ | `CoverQuantTable` |
| Channel quantization table | $\mathbf{Q}_{Ch}$ | `ChannelQuantTable` |
| Expected cover QDCT | $\mathbf{C}_{Ch}$ | `ExpectedCoverQDCT` |
| Secret message bits | $\mathbf{m}$ | `SecretMsg` |
| Extracted message bits | $\hat{\mathbf{m}}$ | `ExtractedMsg` |
| Secret message length | $l$ | `MsgLen` |
| Distortion costs (+1) | $\rho^+_i$ | `UndetectabilityCostP1` |
| Distortion costs (-1) | $\rho^-_i$ | `UndetectabilityCostM1` |
| Multiplier threshold | $T_h$ | `ExpansionThreshold` |
| Selected STC cover indices | $\Psi$ | `STC_CoverIndices` |
| STC sub-message lengths | - | `stc_n_msg_bits` |

---

## Configuration Options

Inside `DRAS_Demo.m`, you can configure the cost calculation type using `CostType`:
1. **`'UERD'` (Default)**: Computes UERD distortion on-the-fly. This requires no external files and runs dynamically.
2. **`'UNIWARD'`**: Dynamically computes J-UNIWARD costs on-the-fly (or loads them from disk if precalculated). If target precalculated `.mat` files are not found, the algorithm falls back to dynamic J-UNIWARD cost calculation with a warning.

## Running the Demo

Open MATLAB, navigate to `/dras_matlab/`, and execute:
```matlab
run('DRAS_Demo.m')
```
The script will run batch processing over 10 cover images in the workspace's dataset and output a results summary including Bit Error Rates (BER) and PSNR metrics.

---

## Citation

If you use this code or dataset in your research, please cite the published paper:

**DOI:** [10.1016/j.jvcir.2026.104817](https://doi.org/10.1016/j.jvcir.2026.104817)

**BibTeX:**
```bibtex
@article{kumar2026dealing,
  title={Dealing with downward recompression for robust steganography in high quality JPEG images},
  author={Kumar, Rakesh and Bansal, Savina and Bansal, R. K.},
  journal={Journal of Visual Communication and Image Representation},
  pages={104817},
  year={2026},
  publisher={Elsevier},
  doi={10.1016/j.jvcir.2026.104817}
}
```

**APA Citation:**
Kumar, R., Bansal, S., & Bansal, R. K. (2026). Dealing with downward recompression for robust steganography in high quality JPEG images. *Journal of Visual Communication and Image Representation*, 104817. https://doi.org/10.1016/j.jvcir.2026.104817
