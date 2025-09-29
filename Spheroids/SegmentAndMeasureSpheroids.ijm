#@ String runMode(choices=("Segment", "Update"), style="list") 
#@ String processMode(choices=("singleFile", "wholeFolder", "AllSubFolders"), style="list") 
#@ String fileExtension(label="File Extension",value=".czi", persist=true, description="eg .czi .tif, .h5") 
#@ File CellposeEnvPath(label="Cellpose Location", persist=true, style="directory", value="C:\\ProgramData\\anaconda3\\envs\\cellpose3", description="point to the location of the cellpose virtual environment eg C:\\ProgramData\\anaconda3\\envs\\cellpose3") 
#@ String CellposeModel(label="Cellpose Model", persist=true, value="cyto3", description="name of the cellpose model in , eg  = 'cyto3', leave empty if using own trained model") 
#@ File CellposeOwnModelPath(label="Cellpose Own Model Path", persist=true, style="file", description="point to the full path of your trained cellpose model") 
#@ Integer CellposeDiameter(label="Cellpose Diameter", min=10, max=20000, value=1275, persist=true, description="set to the typical diamter of the spheroid in pixel units") 
#@ Boolean BatchMode(label="Hide Images?", value=false, persist=true)
// #@ Integer(label="Num of pixels to erode from detected Spheroid", min=0, max=20, value=3, persist=true) erodeSpheroidPixels
// #@ Boolean(label="Apply backround subtraction before segmentation?",value=true, persist=true, description="Apply Rolling Ball Background subtraction?") applyRollingBallBGS
// #@ Integer(label="Rolling Ball Sigma", min=0, max=100, value=25, persist=true) rollingBallSigma
// #@ Integer(label="Minimum Paternal Mitochondria Intensity To Measure", min=0, max=20000, value=2000, persist=true) MinIntensityToMeasure


/*
 * SegmentAndMeasureSpheroids.ijm
 * 
 * Segment 2D Spheroids from brightfield images using Cellpose, and quantify its area, and typical radius. 
 * Estimate of the Spheroid volume  
 * Do this for all images in a a given folder or within its subfolders
 * 
 * Workflow
 * ========
 * - Read image, 
 * - Segment Spheroid: 
 * 		Run Cellpose 
 * 		Convert Labels to ROI
 * 		Measure
 *  - Save results 
 * 		- Create Quality control images
 * 		- save Rois - to enable manual correction of Spheroid regions with Update mode
 * 		- save results in a table with one line for each spheroid in each image
 * 
 *  If the sphroid segmentation is not good enouh for some of the spheroids, 
 *  you can use manually correct the spheroid segmentation (see below) and and run the macro in update mode. 
 *  This will use the manually corrected segmentation if this is available and the original automatic segmentation for all other spheroids
 * 
 * Usage
 * =====
 * 
 * 	1. Run in Segment Mode
 * 		- Set runMode to be Segment 
 * 		- Set processMode to singleFile or wholeFolder or AllSubfolders
 * 		- select Cellpose location, Cellpose Model and Cellpose Diameter
 * 	
 * 	3. Manual correction
 * 		- Careful inspection of results:  
 * 		- ... correct spheroids Rois if needed ... 
 * 		- Save as FN_RoiSet_Manual.zip
 * 		- Set runMode to be Update 
 * 		- Set processMode to singleFile or wholeFolder
 * 		
 * - NOTE: It is very important to inspect All quality control images to verify that segmentation is correct 
 * 
 * Output
 * ======
 * For each input image FN, the following output files are saved in ResultsSubFolder under the input folder
 * - FN_Overlay.tif 	- the original brightfield channel with overlay of the segmented Spheroids in magenta (SpheroidColor)
 * - FN_DetailedResults.xls - the detailed measurements with one line for each embros in the image  
 * - FN_SpheroidRoiSet.zip   - the Spheroid segments used for measurements - this file can be used for manually update 
 * 
 *  Overlay colors can be controled by SpheroidColor
 * 
 * AllDetailedResults_test.xls - Table with one line for each Spheroid in each image file  
 * SegmentAndMeasureSpheroids.txt - Parameters used during the latest run
 * 
 * Dependencies
 * ============
 * Fiji with ImageJ version > 1.54p (Check Help=>About ImageJ, and if needed use Help=>Update ImageJ...
 * This macro requires the following Update sites to be activate through Help=>Update=>Manage Update site
 * - BIOP Fiji Plugin (add "PTBIOP" to your selected Fiji Update Sites)
 * 
 * Please cite Fiji (https://imagej.net/Citing) and Cellpose (https://github.com/MouseLand/cellpose) 
 * 
 * By Ofra Golani, MICC Cell Observatory, Weizmann Institute of Science, July 2025
 * 
 */


// ============ Parameters =======================================
var macroVersion = "v1";

// Cellpose Parameters 
//var CellposeEnvPath = "C:\\ProgramData\\anaconda3\\envs\\cellpose3";
//var CellposeModel = "cyto3 ";
//var CellposeOwnModelPath = ""; //path\\to\\own_cellpose_model";
//var CellposeDiameter = 1275 ;
var CellposeCh1 = 0;
var CellposeCh2 = -1;
var CellposeAdditionalFlags = "--use_gpu";

var SpheroidColor = "magenta";
var LineWidth = 5;

var SpheroidRoisSuffix = "_SpheroidRoiSet"; 

var ResultsSubFolder = "Results";
var cleanupFlag = 1; 
var debugFlag = 0; 

// Global Parameters
var SummaryTable = "SummaryResults.xls";
var AllDetailedTable = "DeatiledResults.xls";
var CellposeExtention = "-cellpose";
var SuffixStr = "";
var SegTypeStr = "";
var TimeString;
var saveIlastikOutputFileFlag = 1;
var SaveColorCodeImages = 0;
var generateSummaryLines = 1;

// ================= Main Code - Don't Change below this line ====================================

Initialization();
setBatchMode(BatchMode);

// Choose image file or folder
if (matches(processMode, "singleFile")) {
	file_name=File.openDialog("Please select an image file to analyze");
	directory = File.getParent(file_name);
	}
else if (matches(processMode, "wholeFolder")) {
	directory = getDirectory("Please select a folder of images to analyze"); }

else if (matches(processMode, "AllSubFolders")) {
	parentDirectory = getDirectory("Please select a Parent Folder of subfolders to analyze"); }


// Analysis 
if (matches(processMode, "wholeFolder") || matches(processMode, "singleFile")) {
	resFolder = directory + File.separator + ResultsSubFolder + File.separator; 
	File.makeDirectory(resFolder);
	print("inDir=",directory," outDir=",resFolder);
	SavePrms(resFolder);
	
	if (matches(processMode, "singleFile")) {
		ProcessFile(directory, resFolder, file_name); }
	else if (matches(processMode, "wholeFolder")) {
		ProcessFiles(directory, resFolder); }
}

else if (matches(processMode, "AllSubFolders")) {
	list = getFileList(parentDirectory);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(parentDirectory + list[i])) {
			subFolderName = list[i];
			subFolderName = substring(subFolderName, 0,lengthOf(subFolderName)-1);

			directory = parentDirectory + subFolderName + File.separator;
			resFolder = directory + ResultsSubFolder + File.separator; 
			File.makeDirectory(resFolder);
			print("inDir=",directory," outDir=",resFolder);
			SavePrms(resFolder);
			CloseTable(AllDetailedTable);
			ProcessFiles(directory, resFolder);
			print("Processing ",subFolderName, " Done");
		}
	}
}

if (cleanupFlag==true) 
{
	CloseTable(SummaryTable);	
	CloseTable(AllDetailedTable);	
}
setBatchMode(false);
print("=================== Done ! ===================");

// ================= Helper Functions ====================================

//===============================================================================================================
// Loop on all files in the folder and Run analysis on each of them
function ProcessFiles(directory, resFolder) 
{
	dir1=substring(directory, 0,lengthOf(directory)-1);
	idx=lastIndexOf(dir1,File.separator);
	subdir=substring(dir1, idx+1,lengthOf(dir1));

	// Get the files in the folder 
	fileListArray = getFileList(directory);
	
	// Loop over files
	for (fileIndex = 0; fileIndex < lengthOf(fileListArray); fileIndex++) {
		if (endsWith(fileListArray[fileIndex], fileExtension) ) {
			file_name = directory+File.separator+fileListArray[fileIndex];
			//open(file_name);	
			//print("\nProcessing:",fileListArray[fileIndex]);
			showProgress(fileIndex/lengthOf(fileListArray));
			ProcessFile(directory, resFolder, file_name);
		} // end of if 
	} // end of for loop

	if (isOpen(AllDetailedTable))
	{
		if (generateSummaryLines)
			GenerateSummaryLines(AllDetailedTable);
		selectWindow(AllDetailedTable);
		AllDetailedTable1 = replace(AllDetailedTable, ".xls", "");
		print("AllDetailedTable=",AllDetailedTable,"AllDetailedTable1=",AllDetailedTable1,"subdir=",subdir);
		saveAs("Results", resFolder+AllDetailedTable1+"_"+subdir+".xls");
		run("Close");  // To close non-image window
	}
	
	// Cleanup
	if (cleanupFlag==true) 
	{
		CloseTable(AllDetailedTable);	
	}
} // end of ProcessFiles


//===============================================================================================================
// Run analysis of single file
function ProcessFile(directory, resFolder, file_name) 
{

	// ===== Open File ========================
	print(file_name);
	if ( endsWith(file_name, "h5") )
		run("Import HDF5", "select=["+file_name+"] datasetname=[/data: (1, 1, 1024, 1024, 1) uint8] axisorder=tzyxc");
	else if (endsWith(file_name, "czi") )
		//run("Bio-Formats Importer", "open=["+file_name+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack");
		//run("Bio-Formats Importer", "open=A:/vishnum/Spheroids/01062025/010625-A673_Parental_DOXO-RSL3_Erastin/B2.czi autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");		
		run("Bio-Formats Importer", "open=["+file_name+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	else
		open(file_name);

	directory = File.directory;
	origName = getTitle();
	Im = getImageID();
	origNameNoExt = File.getNameWithoutExtension(file_name);

	//run("Duplicate...", "title=Ch1 duplicate channels=1");

	CellposeOutFile = origNameNoExt+CellposeExtention;
	if (matches(runMode,"Segment")) 
	{

		getVoxelSize(pixelWidth, pixelHeight, pixelDepth, pixelUnit);
	
		// Segmentation is based on cellpose 
		print("Running Cellpose...");
		run("Cellpose ...", "env_path="+CellposeEnvPath+" env_type=conda model="+CellposeModel+" model_path="+CellposeOwnModelPath+" diameter="+CellposeDiameter+" ch1="+CellposeCh1+" ch2="+CellposeCh2+" additional_flags="+CellposeAdditionalFlags);
		
		selectWindow(CellposeOutFile);
		
		setVoxelSize(pixelWidth, pixelHeight, pixelDepth, pixelUnit);
		run("glasbey on dark");

		run("Label image to ROIs", "rm=[RoiManager[]");
		
		roiManager("Set Color", SpheroidColor);
		roiManager("Set Line Width", LineWidth);
		roiManager("Associate", "false");

	} else if (matches(runMode,"Update")) {
		GetSpheroidsFromRoiFile(directory, resFolder, origName, origNameNoExt);
	}

	nSpheroid = roiManager("count");
	aSegMode =  newArray(nSpheroid);
	aFileName = newArray(nSpheroid);
	aName = newArray(nSpheroid);
	aArea = newArray(nSpheroid);
	aEffectiveRadius = newArray(nSpheroid);
	aEstimatedVolume = newArray(nSpheroid);
	aMajor = newArray(nSpheroid);
	aMinor = newArray(nSpheroid);
	aCirc = newArray(nSpheroid);
	aFeret = newArray(nSpheroid);
	aMinFeret = newArray(nSpheroid);
	aAR = newArray(nSpheroid);
	aRound = newArray(nSpheroid);
	aSolidity = newArray(nSpheroid);

	// Collect Results for each Spheroid
	if ( matches(runMode,"Segment") || matches(runMode,"Update") ) 
	{
		run("Set Measurements...", "area fit shape feret's redirect=None decimal=3");
		Table.reset("Results");
		selectWindow(origName);
		roiManager("Measure");	
		run("Select None");

		// Collect results for each Spheroid 
		for (n = 0; n < nSpheroid; n++) 
		{
			aFileName[n] = origNameNoExt;
			aArea[n] = getResult("Area", n);
			if (matches(runMode,"Segment"))
				aSegMode[n] = "Auto";
			if (matches(runMode,"Update"))
				aSegMode[n] = SegTypeStr;
			roiManager("select", n);
			aName[n] = "Spheroid_"+d2s(n+1,0);
			roiManager("rename", aName[n]);
			aEffectiveRadius[n] = sqrt(aArea[n] / PI);
			aEstimatedVolume[n] = 4/3 * PI * aEffectiveRadius[n] * aEffectiveRadius[n] * aEffectiveRadius[n];
			aMajor[n] = getResult("Major", n);
			aMinor[n] = getResult("Minor", n);
			aCirc[n] = getResult("Circ.", n);
			aFeret[n] = getResult("Feret", n);
			aMinFeret[n] = getResult("MinFeret", n);
			aAR[n] = getResult("AR", n);
			aRound[n] = getResult("Round", n);
			aSolidity[n] = getResult("Solidity", n);
		}
		roiManager("deselect");
		Array.show("DetailedResults", aFileName, aSegMode, aName, aArea, aEffectiveRadius, aEstimatedVolume, aMajor, aMinor, aCirc, aFeret, aMinFeret, aAR, aRound, aSolidity);
		
		// create QA images
		SaveOverlayImage(origName, "", SpheroidColor, origNameNoExt, "_Overlay"+SuffixStr+".tif", resFolder, 0);
		
		//print(origName, nSpheroid, nElongated, percentElongated, meanArea, meanAR, meanCirc, meanRound);
		if (matches(runMode,"Segment")) 
		{
			SaveSpheroidsRois(resFolder+origNameNoExt+SpheroidRoisSuffix);
		}
		
		// =========== Add lines for each Spheroid to All Detailed Table =============
		AppendTables(AllDetailedTable,"DetailedResults");
		run("Clear Results");
			
		selectWindow("DetailedResults");
		saveAs("Results", resFolder+origNameNoExt+"_DetailedResults.xls");		
		CloseTable(origNameNoExt+"_DetailedResults.xls");
	}

	if (debugFlag) waitForUser;
	if(cleanupFlag) Cleanup();

	//setBatchMode(false);
} // end of ProcessFile


//===============================================================================================================
// append the content of additonalTable to bigTable
// if bigTable does not exist - create it 
// if additonalTable is empty or dont exist - do nothing
function AppendTables(bigTable, additonalTable)
{

	// if additonalTable is empty or don't exist - do nothing
	if (!isOpen(additonalTable)) return;
	selectWindow(additonalTable);
	nAdditionalRows = Table.size;
	if (nAdditionalRows == 0) return;
	Headings = Table.headings;
	headingArr = split(Headings);

	if (!isOpen(bigTable))
	{
		Table.create(bigTable);
	}
	selectWindow(bigTable);
	nRows = Table.size;

	// loop over columns of additional Table and add them to bigTable
	for (i = 0; i < headingArr.length; i++)
	{
		selectWindow(additonalTable);
		ColName = headingArr[i];
		valArr = Table.getColumn(ColName);
		if (valArr.length == 0) continue;
		
		selectWindow(bigTable);
		for (j = 0; j < nAdditionalRows; j++)
		{
			//print(i, ColName, j, valArr[j]);
			Table.set(ColName, nRows+j, valArr[j]); 
		}
	}

	selectWindow(bigTable);
	Table.showRowNumbers(true);
	Table.update;
	
} // end of AppendTables


//===============================================================================================================
function GenerateSummaryLines(tableName)
{
	if (isOpen(tableName))
	{
		//Table.rename(tableName, "Results");
		selectWindow(tableName);
		nRows = Table.size;
		Headings = Table.headings;
		headingArr = split(Headings);

		selectWindow(tableName);
		Table.set("Label", nRows, "MeanValues"); 
		Table.set("Label", nRows+1, "StdValues"); 
		Table.set("Label", nRows+2, "MinValues"); 
		Table.set("Label", nRows+3, "MaxValues"); 
		for (i = 0; i < headingArr.length; i++)
		{
			ColName = headingArr[i];
			if (matches(ColName, "Label")) continue;

			valArr = Table.getColumn(ColName);
			valArr = Array.trim(valArr, nRows);
			Array.getStatistics(valArr, minVal, maxVal, meanVal, stdVal);
			if (!isNaN(meanVal))
			{
				Table.set(ColName, nRows,   meanVal); 
				Table.set(ColName, nRows+1, stdVal); 
				Table.set(ColName, nRows+2, minVal); 
				Table.set(ColName, nRows+3, maxVal); 
			}
		}
		Table.update;
	}
} // end of GenerateSummaryLines




//===============================================================================================================
// used in Update mode
function GetSpheroidsFromRoiFile(directory, resFolder, origName, origNameNoExt)
{
	baseRoiName = resFolder+origNameNoExt+SpheroidRoisSuffix;
	manualROIFound = OpenExistingROIFile(baseRoiName);
	if (manualROIFound) 
	{
		SuffixStr = "_Manual";
		SegTypeStr = "Manual";
	}
	else 
	{	
		SuffixStr = "";
		SegTypeStr = "Auto";
	}
	print(origName, SuffixStr, SegTypeStr);
}

		
//===============================================================================================================
function SaveSpheroidsRois(FullRoiNameNoExt)
{
	nRois = roiManager("count");
	if (nRois > 1)
		//roiManager("Save", resFolder+origNameNoExt+CellRoisSuffix+".zip");
		roiManager("Save", FullRoiNameNoExt+".zip");
	if (nRois == 1)
		//roiManager("Save", resFolder+origNameNoExt+CellRoisSuffix+".roi");
		roiManager("Save", FullRoiNameNoExt+".roi");
}


//===============================================================================================================
function Initialization()
{
	requires("1.53i");
	run("Check Required Update Sites");

	setBatchMode(false);
	run("Close All");
	print("\\Clear");
	run("Options...", "iterations=1 count=1 black");
	roiManager("Reset");

	// Name Settings, Set output Suffixes based on SegMode
	if (matches(runMode, "Segment")) 
	{
		SummaryTable = "SummaryResults.xls";
		AllDetailedTable = "AllDetailedResults.xls";
	} else  // (SegMode=="Update") 
	{
		SummaryTable = "SummaryResults_Manual.xls";
		AllDetailedTable = "AllDetailedResults_Manual.xls";
	}	
	CloseTable("Results");
	CloseTable("DetailedResults");
	CloseTable(SummaryTable);
	CloseTable(AllDetailedTable);

	run("Collect Garbage");

	print("Initialization Done");
}



//===============================================================================================================
function Cleanup()
{
	run("Select None");
	run("Close All");
	run("Clear Results");
	roiManager("reset");
	run("Collect Garbage");

	CloseTable("DetailedResults");
}


//===============================================================================================================
function CloseTable(TableName)
{
	if (isOpen(TableName))
	{
		selectWindow(TableName);
		run("Close");
	}
}

//===============================================================================================================
//function SaveOverlayImage(imageName, MaskImage, MaskColor, baseSaveName, Suffix, resDir)
function SaveOverlayImage(imageID, MaskImage, MaskColor, baseSaveName, Suffix, resDir, showLabels)
{
	// Overlay Cells
	selectImage(imageID);
	roiManager("Deselect");
	if (showLabels) 
		roiManager("Show All with labels");
	else 
		roiManager("Show All without labels");

	// Optionally Overlay Mask Area
	run("Flatten");
	im = getImageID();
	if (lengthOf(MaskImage) > 0)
	{
		selectImage(MaskImage);
		run("Create Selection");
		selectImage(im);
		run("Restore Selection");
		run("Properties... ", "  stroke="+MaskColor);
		run("Properties... ", "  width="+LineWidth);
		run("Flatten");
	}
	saveAs("Tiff", resDir+baseSaveName+Suffix);
}


//===============================================================================================================
// Open File_Manual.zip ROI file  if it exist, otherwise open  File.zip
// returns 1 if Manual file exist , otherwise returns 0
function OpenExistingROIFile(baseRoiName)
{
	roiManager("Reset");
	manaulROI = baseRoiName+"_Manual.zip";
	manaulROI1 = baseRoiName+"_Manual.roi";
	origROI = baseRoiName+".zip";
	origROI1 = baseRoiName+".roi";
	
	if (File.exists(manaulROI))
	{
		print("opening:",manaulROI);
		roiManager("Open", manaulROI);
		manualROIFound = 1;
	} else if (File.exists(manaulROI1))
	{
		print("opening:",manaulROI1);
		roiManager("Open", manaulROI1);
		manualROIFound = 1;
	} else // Manual file not found, open original ROI file 
	{
		if (File.exists(origROI))
		{
			print("opening:",origROI);
			roiManager("Open", origROI);
			manualROIFound = 0;
		} else if (File.exists(origROI1))
		{
			print("opening:",origROI1);
			roiManager("Open", origROI1);
			manualROIFound = 0;
		} else {
			print(origROI," Not found");
			exit("You need to Run the macro in *Segment* mode before running again in *Update* mode");
		}
	}
	return manualROIFound;
}


//===============================================================================================================
function SavePrms(resFolder)
{
	// print parameters to Prm file for documentation
	PrmFile = resFolder+"SegmentAndMeasureSpheroids.txt";
	File.saveString("macroVersion="+macroVersion, PrmFile);
	File.append("", PrmFile); 
	setTimeString();
	File.append("RunTime="+TimeString, PrmFile)
	File.append("runMode="+runMode, PrmFile); 
	File.append("processMode="+processMode, PrmFile); 
	File.append("fileExtension="+fileExtension, PrmFile); 
	File.append("SpheroidColor="+SpheroidColor, PrmFile); 
	File.append("LineWidth="+LineWidth, PrmFile); 
	File.append("CellposeEnvPath="+CellposeEnvPath, PrmFile); 
	File.append("CellposeModel="+CellposeModel, PrmFile); 
	File.append("CellposeOwnModelPath="+CellposeOwnModelPath, PrmFile); 
	File.append("CellposeDiameter="+CellposeDiameter, PrmFile); 
	File.append("CellposeCh1="+CellposeCh1, PrmFile); 
	File.append("CellposeCh2="+CellposeCh2, PrmFile); 
	File.append("CellposeAdditionalFlags="+CellposeAdditionalFlags, PrmFile); 
	File.append("SpheroidRoisSuffix="+SpheroidRoisSuffix, PrmFile); 
}


//===============================================================================================================
function setTimeString()
{
	MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
	DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	TimeString ="Date: "+DayNames[dayOfWeek]+" ";
	if (dayOfMonth<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year+", Time: ";
	if (hour<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+hour+":";
	if (minute<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+minute+":";
	if (second<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+second;
}

