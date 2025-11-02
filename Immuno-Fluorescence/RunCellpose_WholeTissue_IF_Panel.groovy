/* Script for IF-Panel quantification, implementing the following workflow
   For each annotation of class "wholeTissueClass" :
   - Segment cells based on nuclei segmentation followed by expansion, filtering too-big nuclei, and classying the cells.
   - Classify cells using pre-trained bject classifier "CellClassifierName" 
   - Save annotation and detections table into "ResultsSubFolder"
   
 Usage: 
 - Annotate regons of interest and set them to the class name saved in "wholeTissueClass" variable ("Proteomics ROI")
 - Set the variable "CellClassifierName" to the name of the proper classifier based on the analyzed Panel
 
 Note: if you have a new panel, you need to train a classifier before analysis by: 
 - Select representative regions from multiple slides, 
 - Create training image , which combine the selected regions of the different slides
 - Run cell segmentation
 - Annotate cell classes and train classifier
*/

import qupath.ext.biop.cellpose.Cellpose2D
//import qupath.lib.images.ImageData
//import qupath.lib.images.servers.ConcatChannelsImageServer
//import qupath.lib.images.servers.TransformedServerBuilder

// Control script workflow
def detectCells     = 1
def filterSomeCells = 1 // discard cells by size and intensity
def classifyCells   = 1
def saveResults     = 1

// Further object filtering parameters
def MaxNucArea= 180
def MinNucArea= 0
def MinNucIntensity=0    //remove any detections with an intensity less than or equal to this value

// Cell classification 
def CellClassifierName = 'EWS_Panel1_improved_3' //'Sagi_EWS_Panel2_21112024'  'EWS_Panel3_1_points3'

// Cell segmentation parameters 
// Specify the model name (cyto, nuc, cyto2, omni_bact tissuenet TN1 TN2 TN3 CP CPx livecell LC1 LC2 LC3 LC4 or a path to your custom model)
def wholeTissueClass = "Proteomics ROI"
def pixelWidth = 0.5001
def pathModel = 'nuc' 

// specify the nuclei channel : dsDNA or Mucin2 for Goblet cells
def nucChannel = 'Nuclei' 
def cellDiameter = 14    // pixels 
def regularClass = 'Nuclei'
def CellExpansion = 5.0
def tileSize = 1024

// Results parameters  
def ResultsSubFolder = 'export'

// run Cellpose. Careful of the channels names
def cellpose = Cellpose2D.builder( pathModel )
        .pixelSize( pixelWidth)             // Resolution for detection in um
//      .channels( membraneChannel, nucChannel )	      // Select detection channel(s)
      .channels( nucChannel )	      // Select detection channel(s)
        .normalizePercentilesGlobal(0.1, 99.8, 10)
        .tileSize(tileSize)                  // If your GPU can take it, make larger tiles to process fewer of them. 
        .cellprobThreshold(-1)          // Threshold for the mask detection, defaults to 0.0
        .flowThreshold(0.7)              // Threshold for the flows, defaults to 0.4 
        .diameter(cellDiameter)                   // Median object diameter. Set to 0.0 for the `bact_omni` model or for automatic computation
        .classify(regularClass)         // PathClass to give newly created objects
        .cellExpansion(CellExpansion)   // Approximate cells based upon nucleus expansion
        .measureShape()                 // Add shape measurements
        .measureIntensity()             // Add cell intensity measurements (in all compartments)  
        .simplify(1.6)                    // Simplification 1.6 by default, set to 0 to get the cellpose masks as precisely as possible
        .build()

// Run detection for the selected objects
def imageData = getCurrentImageData()
// Get name of current image    
def name = GeneralTools.getNameWithoutExtension(imageData.getServer().getMetadata().getName())

resetSelection()
//selectObjectsByClassification("WholeTissue");
selectObjectsByClassification(wholeTissueClass);
    
def annotations = getSelectedObjects()
if (annotations .isEmpty()) {
    //Dialogs.showErrorMessage("Cellpose", "Please select a parent object!")
    print("Image: " + name + " - No Annotation of Class WholeTissue found");
    return
}

// Run detection for the selected objects
println '========= Segment regular cells... =============='

if (detectCells == 1)
{
    
    // Note here that it is the imageData we created above and not the result of getCurrentImageData()
    cellpose.detectObjects(imageData, annotations)
    
    if (filterSomeCells == 1)
    {
        println '============== Filter Out small / big / deem Cells ... =================='
        // Filter Nuc by size and Intensity
        NucAreaMeasurement='Nucleus: Area µm^2' //Name of the measurement you want to perform filtering on
        if (CellExpansion == 0) 
        {
            NucAreaMeasurement='Area µm^2' //Name of the measurement you want to perform filtering on
        }
        toDelete =  getDetectionObjects().findAll {measurement(it, NucAreaMeasurement) > MaxNucArea}
        removeObjects(toDelete, true)
        toDelete1 =  getDetectionObjects().findAll {measurement(it, NucAreaMeasurement) < MinNucArea}
        removeObjects(toDelete1, true)
        
        NucIntensityMeasurement='Nuclei: Nucleus: Mean' //Name of the measurement you want to perform filtering on
        if (CellExpansion == 0)
        {
            NucIntensityMeasurement='Nuclei: Mean' //Name of the measurement you want to perform filtering on
        }
        toDelete2 = getDetectionObjects().findAll {measurement(it, NucIntensityMeasurement) <= MinNucIntensity}
        removeObjects(toDelete2, true)
    }                
} // end of if (detectCells == 1) 

// Classify Cells 
if (classifyCells == 1)
{
    println '============== Classfying Cells ... =================='            
    resetDetectionClassifications();
    cells = getCellObjects()
    classifier = loadObjectClassifier(CellClassifierName)
    classifier.classifyObjects(imageData, cells, false)
    fireHierarchyUpdate()
}

if (saveResults == 1)
{
    // save annotations
    //File directory = new File(buildFilePath(PROJECT_BASE_DIR,'export'));
    File directory = new File(buildFilePath(PROJECT_BASE_DIR,ResultsSubFolder));
    directory.mkdirs();
    //imageName = ServerTools.getDisplayableImageName(imageData.getServer())
    imageName = GeneralTools.getNameWithoutExtension(getCurrentImageData().getServer().getMetadata().getName())
    saveAnnotationMeasurements(buildFilePath(directory.toString(),imageName+'_annotations.csv'));
    saveDetectionMeasurements(buildFilePath(directory.toString(),imageName+'_detections.csv'));
}
    
//println 'Done!'
println '========= Done! =============='
