The 'ProcSettings.txt' file is required for cluster analysis.
It contains specific settings for processing tables in this folder.
The first four lines (below the asterisks in this example) are header lines and are ignored.
The first column contains variable names. These must not be changed.
The semicolon separator is required to correctly process this file.
The second column contains the values of their corresponding variables. You should edit these to match your desired settings.
The explanation column is for this file only and should not be included in an actual ProcSettings.txt file.
Example files are given in the Templates folder. Copy and modify these files as required.
You must rename example files to 'ProcSettings.txt' in order work with the script.
The order of these values is not important -- they can be on any line. You may want to rearrange the lines to put unimportant options at the bottom.
****************************************************************
A line containing any information you want to describe these settings
-----------------------------------------------------------------------------------------
VariableName		:	ExampleValue 	Type & Options			Explanation
-----------------------------------------------------------------------------------------
EmailMeAt			:	you@email.com	String					Add this line to have yourself emailed when the script has finished running.
GRIDMapSpacing		:	0.5				Integer					When constructing maps based on a regular grid, use this value. If less than one, grid spacing is this multiple of SamplingRadius. If 1 or more, spacing is in nm.
SkipToRegionNumber	:	1				Integer					Which line-number in your regions file to begin at? If something goes wrong you can easily pick up the processing again and skip those regions which were previously completed.
DataTableFileExt	:	txt				Text					The file extension of the file containing your image data
DataDelimiter		:	comma			tab,comma,space			How the data columns are separated in your data table file. Use the words tab, comma, or space, or the separation character itself (e.g. ;)
DataTableScale		:	100				Integer					The scale of the data table in pixels/nm
CoordsTableScale	:	100				Integer					The scale of your coordinates in pixels/nm
FooterLength		:	0				Integer					The number of lines at the end of data table which don't contain data
BlankFirstCol		:	False			True/False				If the first column of your data table is blank, set to true
InvertyAxis			:	False			True/False				If the coordinates of your yaxis are inverted, set to true
xCoordsColumn 		:	4				Integer					The column in the data table containing the x coordinates
yCoordsColumn		:	5				Integer					The column in the data table containing the y coordinates
PrecisionColumn		:	None			Integer/None			The column in the data table containing localisation precision values
PhotonColumn		:	None			Integer/None			The column in the data table containing photon count values
ChannelIDColumn		:	1				Integer/None			The column in the data table identifying which channel a molecule belongs to
xRegionLength		:	4000			Integer					The full length of your region's x dimension (nm). NB: this is no longer the 'half region size' value!
yRegionLength		:	4000			Integer					The full length of your region's y dimension (nm). NB: this is no longer the 'half region size' value!
ColMapMax			:	max99			Integer/max/maxNN(NN<=100)/maxNN (N>100)		Set to an integer value (explicit value), or to max to use that region's maximum L(r) value, or maxNN. If NN is <=100, use NNth percentile, if NN>100 use for NN percent-multiples of the L(r) max value.
PrecisionCrop		:	50				Integer					Crop data which is less-precisely localised than this value
PhotonCrop			:	400				Integer					Crop data which has less photons than this value
SamplingRadius		:	30				Integer					Radius (nm) within which events are counted to calculate L(r)
BinaryChangeHIGH	:	90				Integer					Molecules with L(r)>=BinaryChangeHIGH are considered to be within clusters
BinaryChangeLOW		:	90				Integer					Molecules with L(r)<=BinaryChangeHIGH are considered to be within holes
MaxEventsToProcess	:	10000000		Integer					Limit to the number of molecules to process within a cropped region (not whole image)
UseFolders			:	True			True/False				Save the data to separate folders. If false, data is saved to the current folder (can get messy).
DoTimeSeries		:	False			True/False				Enable live cell cluster analysis. Uses the next three variables.
TSWindow			:	1000			Integer					Make maps using this many acquisition data frames.
TSWinStep			:	500				Integer					Move the above window by this many acquisition data frames for the next cluster map.
TSNumFrames			:	3				Integer					Create this many cluster map 'frames' from the data.
ImageSize			:	17800			Integer					Size of a full image (nm).
DelDuplicatePts		:	False			True/False				Delete points with identical xy coordinates. rarely used and does not delete duplicates from other channels when bivariate is enabled.
ExcelHeaders		:	X,Y,Z, ... 		(various)				Comma separated labels to place at the top of your output tables. Labels for L(r) etc will be added automatically but this lets you rename your data headers if they are confusion.
DoBiVariate			:	False			True/False				Do BiVariate Ripleys (for points in Ch1 count points in Ch2 within r)
SaveXLS				:	True			True/False				Save data to Excel files. Windows only -- disable for OSX, Linux.
SaveTextFiles		:	True			True/False				Save data to Text files. These will appear in a sub-folder called Numbers.
UseGriddata			:	False			True/False				Interpolated colour maps with 'griddata v4' function. If 'false', uses scatteredInterp which is faster than griddata but not as smooth-looking.
GDInterpSpacing		:	5				Integer					If using griddata, set the grid spacing to this value (nm).