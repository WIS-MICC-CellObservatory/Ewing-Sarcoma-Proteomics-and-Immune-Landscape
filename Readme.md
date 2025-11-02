# [Proteomic landscapes of Ewing sarcoma unravel immunological regulation of tumor progression ]

**Authors:** [Sagi Gordon, Vishnu Mohan, Rachel Shukrun, Ofra Golani, Shani Metzger, Osnat Sher, Michal Manisterski, Roni Oren, Liat Fellus-Alyagor, Lir Beck, Yoseph Addadi, Benjamin Dekel, Ronit Elhasid and Tamar Geiger]  
**DOI:** [To be added upon publication]

---

## Overview

This repository documents the image analysis workflows used in the paper.  
It consists of two main parts:

1. **Immunu-Fluorescence Panels**

Image data are available in the BioImage Archive (http://www.ebi.ac.uk/bioimage-archive) under accession number S-BIAD1597.
      
3. **Spheroids analysis** 

 
---

## Immunu-Fluorescence Panels

### Overview

Nuclear segmentation was performed using the “Nuclei” model of **Cellpose** 2.0 followed by expansion (estimated diameter of 14 pixels, expansion of up to 5 pixels) as implemented in the Qupath Cellpose extension v0.9.6.  A Random Trees machine learning object classifier was trained in **Qupath** v0.5.1 on a training panel of representative stitched regions of 500*500µm from multiple slides. Proteomic regions of interest (ROIs) were manually annotated on the Opal slides with guidance from consecutive H&E sections. All downstream analysis were performed with percentage of cells expressing the marker in  these P-ROIs. 

This workflow was implemented as QuPath script.. 

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

| 010625-A673_Parental_ETOPOSIDE-DOXO_B2 | 010625-A673_Parental_ETOPOSIDE-DOXO_B10 |
|-----------------|-----------------|
| ![Overlay 1](Spheroids/SampleData/Results/png/010625-A673_Parental_ETOPOSIDE-DOXO_B2_Overlay.png) | ![Overlay 2](Spheroids/SampleData/Results/png/010625-A673_Parental_ETOPOSIDE-DOXO_B10_Overlay.png) |


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

   ![Parameters Screenshot](Spheroids/SpheroidsGUI.PNG)  
   
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
- `FILENAME_Overlay.tif`  
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

