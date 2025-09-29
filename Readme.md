# [Paper Title Here]

**Authors:** [List of Authors Here]  
**DOI:** [To be added upon publication]

---

## Overview

This repository documents the image analysis workflows used in the paper.  
It consists of two main parts:

1. [Section to be described later]  
2. **Spheroids analysis** (detailed below)

---

## Spheroids Analysis

### Overview

Spheroids were segmented from the provided images, and their areas were measured.  
Segmentation was performed in **Fiji** using a **Cellpose** model trained on a sample of the dataset:  
`CP_SpheroidModel_20250724_090423`.

In rare cases, manual correction of the segmentation can be applied.  
The analysis is implemented in the Fiji script:  
`SegmentAndMeasureSpheroids.ijm`.

---

### Example Results

Two example overlay images are shown below (placeholders):  

| Input Overlay 1 | Input Overlay 2 |
|-----------------|-----------------|
| ![Overlay 1](spheroids/SampleData/results/overlay1_placeholder.png) | ![Overlay 2](spheroids/SampleData/results/overlay2_placeholder.png) |

👉 **Put your overlay images in**: `spheroids/SampleData/results/`  
Name them `overlay1_placeholder.png` and `overlay2_placeholder.png` until you replace with real outputs.

---

### Dependencies

- [Fiji](https://fiji.sc/) installed  
- [PTBIOP plugin for Fiji](https://biop.epfl.ch/)  
- **Cellpose 3 environment** (not Cellpose 4) — installation guide here:  
  [Forum: Install Cellpose 3](https://forum.image.sc/t/install-cellpose-3/112198)  

---

### Usage

1. Open Fiji.  
2. Drag & drop the script `spheroids/SegmentAndMeasureSpheroids.ijm` into Fiji.  
3. Configure the parameters (screenshot placeholder below):  

   ![Parameters Screenshot](spheroids/SampleData/results/parameters_placeholder.png)  
   👉 Save a screenshot of the parameters window as `parameters_placeholder.png` inside `spheroids/SampleData/results/`.

#### Parameters

- **RunMode**: `Segment` or `Update`  
- **ProcessMode**: `singleFile` / `wholeFolder` / `allSubFolders`  
- **Cellpose Location**: folder of the installed Cellpose environment  
- **CellposeModel**: leave empty  
- **Cellpose Own Model Path**: path to the trained Cellpose model  
- **Cellpose Diameter**: `1275`  

---

### Output

Results are saved under the `spheroids/SampleData/results/` folder.

For each input file (`FILENAME`):

- `FILENAME_DetailedResults.xls`  
- `FILENAME_Overlayf`  
- `FILENAME_SpheroidRoiSet.roi`  

Aggregated results:

- `AllDetailedResults_FolderName.xls`  
- `SegmentAndMeasureSpheroids.txt` (logs the parameters used for the run)  

---

### Manual Update

Manual corrections can be performed following the instructions in:  
[Manual Correction Section](https://github.com/WIS-MICC-CellObservatory/Crypts_SpatialOrganization)

---

## Repository Structure

