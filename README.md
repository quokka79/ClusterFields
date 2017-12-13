# ClusterFields

Getis &amp; Franklin's Local Point Pattern Analysis for Localisation Microscopy Images.

## What you need

To use this script, you need:

* A data table containing, at the bare minimum, the x and y coordinates of your reconstructed image.
  * Usually the image reconstruction gives you more information than this but all you really need are the xy coordinates.
  * The data table should be renamed to 1.txt (or .csv or whatever your file extension is).
  * Subsequent data tables should be similarly named, as consecutive numbers and with no gaps.
* A **ProcSettings.txt** file, which has been filled out to best describe the data table and how you want it processed.
* A **coords.txt** file, which contains the x and y coordinates for the regions that would like to analyse from within your data table file.
* MATLAB v2015 or more recent
* The various .m files that perform the cluster analysis, available here. 

## About coords.txt

Analysis is performed on square sub-regions within your main image field. The size of these regions is specified in ProcSettings.txt and the centre coordinates for each region is given in the coords.txt file.

Generally it is easier if you collect your data table files into one folder, rename them from 1 to however many files you have, and then use RegionFinder to mark your regions and build your coords.txt file.

The contents of coords.txt should look like this:

```
Cell 1 Reg 1    1    7285     12070
Cell 1 Reg 2    1    3935     7901
Cell 1 Reg 3    1    9762     6937
Cell 2 Reg 1    2    13990    3593
Cell 2 Reg 2    2    14790    11360
Cell 2 Reg 3    2    2241     12670
```

Each line of the file describes a single region to analyse. The parameters for each region are in tab-separated columns.

The first column contains a short description about the region, which might help you keep track of things, e.g. treatment conditions, dyes used, etc. This is basically a 'comment' space.

The second column identifies the data table file that the region comes from. These files should be named from 1.txt to N.txt (or 1.csv if that is what you are using … the exact extension is specified by your ProcSettings.txt file). Things will go wrong if you don't start your files at 1 and then number them sequentially.

The third and fourth columns contain the x and y coordinates, respectively, of the centre of your region of interest. The boundary coordinates of your region are calculated from these centre coordinates and the size of the region that you specify in ProcSettings.txt.

NB: This file doesn't have to be named *coords.txt* but that's what most people will call it. You can have several coords files in your processing folder and you just select the one you want to process with ClusterFields when you run the script, for example you may wish to quickly process only one region from each data table to check your processing looks ok before you re-process with the full coords file, in which you might have specified several regions per datatable.

## About ProcSettings.txt

The 'ProcSettings.txt' file is also required for cluster analysis. It contains specific settings for processing data tables in the folder you select. An example ProcSettings.txt file in this repository. The idea is that you keep a copy of this file in the folder with your input data so you have a record of how you processed that data.

An example of the structure is below. Any line beginning with the hash character (#) is treated as a comment line and is ignored, i.e. you can change them or leave them or do whatever you want, so long as the line begins with a hash.

Other lines contain the variables and their values, separated by a colon and some tabs.

The first column contains variable names – these must not be changed – the correspond directly to variables used by MATLAB. The colon separator is also essential to correctly process this file but you can have as many tabs between things as you like, in order to make the file easier to read.

The second column contains the values for the corresponding variable on that line. You should edit these to match your intended processing conditions.

```
#use a hash character to create a comment line. Comment lines are skipped by the script
SkipToRegionNumber    :    1
DataTableFileExt    :    txt

# this can be useful to keep notes about what things to. You can also insert blank lines to help split up the sections.
DataDelimiter        :    comma
DataTableScale        :    100       # You can also have comment lines like this.
```
... and so on and so forth ...

Example files are given in the Templates folder. Copy and modify these files as required. The file must always be named 'ProcSettings.txt' in order work with the script, i.e. if you copy from the templates file you will need to rename it yourself. 

You really only need those lines which are directly relevant to your processing workflow. However, it's a good idea to include all lines (as in the demo file) so that you can recycle and tweak ProcSettings.txt between analyses with ease.

The order of these variables is not important – they can be on any line that you like. You may want to rearrange the lines to put unimportant or rarely altered options at the bottom and more frequently changed lines towards the top.

The lines are explained below:

### ProcSettings.txt - General options

| VariableName	| Example Value	 | Permitted Values	 | Explanation  |
|-------------|:-------------:|:-------------:|-------------|
|SkipToRegionNumber	| 1	| Integer	| Which line-number in your regions file to begin processing at? Normally you start at Line 1, but if something goes wrong you can easily pick up the processing again at Line X, effectively skipping the regions that were already processed.	|
|EmailMeAt	| bob@address	| Email address	| MATLAB will try and email you at this address when it has completed everything. It won't email you if the script crashes for any reason. You will need to edit ProcessingDone.m to reflect your mail server settings.	|
| VerboseUpdates		|  false  |  True/False  | Relates more information about the state of processing than usual.  |
| IAmBoring			|  False		|  True/False  |  Set this to true to disable sound effects upon completion. This will also prevent the display of the ASCII art kittens. You monster.  |

### ProcSettings.txt - Input options

| VariableName	| Example Value	 | Permitted Values	 | Explanation  |
|-------------|:-------------:|:-------------:|-------------|
|ImageSize	| 18000	| Number	| How wide is your entire image (nm)? This is the whole image size ... not just the maximum x or y value of an event.	|
|xCoordsColumn	| 4	| Integer	| 	The column in the data table containing the x coordinates.	|
|yCoordsColumn	| 5	| Integer	| The column in the data table containing the y coordinates.	|
|ChannelIDColumn	| 11	| Integer/None	| The column in the data table the channel ID. Set to 'None' if there is no channel ID column.	|
|PrecisionColumn	| None	| Integer/None	| If your data contains a localisation precision (uncertainty) column **and** you want to make use of it for additional filtering (poorly localised points will be removed) then you can set it here. Otherwise just type None to skip any filtering by precision. 	|
|PhotonColumn	| None	| Integer/None	| If your data contains a photon-count (intensity) column **and** you want to make use of it for additional filtering (dim points will be removed) then you can set it here. Otherwise just type None to skip any filtering by photon count. 	|
|DataTableFileExt	| txt	| Text	| The file extension of the file containing your image data.	|
|DataDelimiter	| comma	| tab/comma/space	| How the data columns are separated in your data table file. Use the words tab, comma, or space, or the separation character itself (e.g. ;).	|
|CoordsTableScale	| 1	| Number	| The scale of your coordinates in units per nm. Usually this is the same as your DataTableScale (e.g. if you used RegionFinder) but sometimes it is not.	|
|DataTableScale	| 1	| Number	| The scale of the data table in units per nm.	|
|FooterLength	| 0	| Integer	| The number of lines at the end of data table which don't contain data, e.g. if there's an inconvenient footer included.	|
|BlankFirstCol	| FALSE	| True/False	| Is your data table's first column empty?  (e.g. from some early versions of Zeiss Elyra software)	|
|InvertyAxis	| FALSE	| True/False	| Are your y-axis coordinates inverted? (e.g. from some early versions of Zeiss Elyra software)	|


### ProcSettings.txt - Output options
| VariableName	| Example Value	 | Permitted Values	 | Explanation  |
|-------------|:-------------:|:-------------:|-------------|
|UseFolders	| TRUE	| True/False	| Save the data to separate folders. If false, data is saved to the current folder (can get messy).	|
|SaveImages	| True	| True/False	| Save any kind of image. Setting this to false will speed things up dramatically as only the G&F values are calculated and saved to text/Excel files; no images are saved at all. 	|
| SavePointPlots		|  True		| True/False	|  Save a plot which only contains the points within a region; events are blue on a white background.  |
| SaveGFPlots			|  True		| True/False	|  Save a plot of the points coloured by their G&F L(r) value.  |
| Save3DContours		|  False		| True/False	|  Experimental. Set to false to save time and data. Set this to true to generate contour plots for future use with topographic prominence processing.  |
|SaveXLS	| TRUE	| True/False	| Save data to Excel files. Windows only – disable for OSX, Linux.	**Important!** Set 'SaveXLS' to false if you have a lot of regions. As the Excel file grows, Matlab has to wait for Excel to load and save the entire file for each new region. This bogs down the entire computer and you are better off using SaveTextFiles anyway.  |
|SaveTextFiles	| TRUE	| True/False	| Save data to Text files. These will appear in a sub-folder called Numbers. You can import these into Excel afterwards to reconstitute the Excel file that you disabled in the line above.  	|
| SaveCroppedRegions	|  False		| True/False	|  Save xy cropped regions including edge-padding (a border around each side equal to SamplingRadius to obviate edge effects). Probably not useful in most circumstances.  |
| GetHeadersFromTable |  True        | True/False	|  If enabled then ClusterFields will attempt to read the headers from the first line of each data table. If disabled (i.e. set to false) then you **MUST** specify a value for ExcelHeaders to match your data tables' actual headers.  |
|ExcelHeaders	| X,Y,Z, …	| (various)	| Delimited labels to place at the top of your output tables. Labels for L(r) etc will be added automatically but this lets you rename your data headers if they are confusingly labelled in their current state.	|

### ProcSettings.txt - Processing options

| VariableName	| Example Value	 | Permitted Values	 | Explanation  |
|-------------|:-------------:|:-------------:|-------------|
|xRegionLength	| 3000	| Number	| The full length of your ROI x dimension (nm). NB: this is no longer the 'half region size' value from older versions!	|
|yRegionLength	| 3000	| Number	| The full length of your ROI y dimension (nm). NB: this is no longer the 'half region size' value from older versions!	|
|SamplingRadius	| 30	| Number	| Radius (nm) within which events are counted to calculate L(r).	|
|PrecisionCrop	| 50	| Number	| Crop data which is poorly localised, i.e. events with a localisation precision less than this value are kept. You need to set PrecisionColumn to an integer for this to have any effect.	|
|PhotonCrop	| 400	| Integer	| Crop data which has less photons than this value. You need to set PhotonColumn to an integer for this to have any effect.	|

### ProcSettings.txt - Memory management options
Having too many points can bog down processing. For certain cases you can randomly delete some points and still get a useful answer, especially if testing something out.

| VariableName	| Example Value	 | Permitted Values	 | Explanation  |
|-------------|:-------------:|:-------------:|-------------|
|DelDuplicatePts	| False	| True/False	| Delete points with identical x-y coordinates. Set this to true if you have unmerged data or get singularity warnings when doing map interpolation. Enabling this does not delete duplicates from other channels when bivariate is enabled.	|
| MaxEventsToProcess	|  0		    | Integer	|  The maximum number of points in the *cropped region* (including the edge-padding) to consider.  |

Note: This *does not* relate to the number of points in your *entire* image area, only the events after cropping to your region size.
* Set this value to zero to disable this feature.
* Set the value to a very high (e.g. 10000000) to effectively disable the feature, i.e. if you are certain you'll never have that many events per region.
* Set this lower (e.g. around 25000) if you receive out of memory errors, especially if you are enabling the generation of interpolated cluster maps (DoInterpMaps = true, below).
* Set this to your lowest event count/region if you want to equalise your region-event-count between conditions.

### ProcSettings.txt - Coloured cluster map options

| VariableName	| Example Value	 | Permitted Values	 | Explanation  |
|-------------|:-------------:|:-------------:|-------------|
| DoInterpMaps        |  False       | True/False	|  Interpolate a cluster map for a region's events. Setting this to false will not produce interpolated colour maps and will save a lot of time.  |
| ColMapMax           |  200	*or* max99 *or* max		| Various 	|  Maximum value for the colour scale of interpolated cluster maps. Set this to a fixed integer to maintain consistent-looking maps. Other values are: max (for each map's maximum L(r) value), or maxN )for the Nth percent of the maximum value in that region). If N ≤ 100, use Nth percentile as the colour map maximum – this can prevent odd looking maps if you have one very very dense cluster. If N > 100 use for NN percent-multiples of the L(r) max value.  |
| CustomColorMap		|  jet			|  Any valid cmap name  | Which colormap to use when rendering images. Default is jet or parula, depending your MATLAB version.  |
| UseGriddata         |  True        | True/False	|  Use Matlab's griddata_v4 function to interpolate colour maps. Set to false to use the faster (but sometimes less smooth-looking) triscatteredinterp function instead.  |
| GDInterpSpacing		|  5           | Number	|  Spacing of the interpolation grid, in table units (i.e. nm).  |


### ProcSettings.txt - 'Grid' cluster map options
Grid Maps is essentially the bivariate L(r) values measured for a regular xy lattice of points, using your data points as a 'second channel'. Good for sparse data points when interpolated cluster maps show flaring.

| VariableName	| Example Value	 | Permitted Values	 | Explanation  |
|-------------|:-------------:|:-------------:|-------------|
| DoGridMaps          |  False       | True/False	|Do grid maps processing; this is in addition to the regular G&F processing.    |
| GridMapSpacing      |  0.5         | Number	|  How to space the grid points. Values <1 are interpreted as multiples of sampling radius. Values >1 are interpreted as a grid point spacing in xy, in nm.  |
| GridColMapMax       |  200         | Number	|  Maximum value for the colour scale of Grid-cluster maps. Set this to an integer or to max or to maxNN (see ColMapMax for explanation).  |
| GridBinChangeHIGH   |  80          | Number	|  In-cluster threshold. Same as explained above but these are for the Grid-cluster maps.  |
| GridBinChangeLOW    |  60          | Number	|  In-hole threshold. Same as explained above but these are for the Grid-cluster maps.  |

### ProcSettings.txt - Bivariate analysis options

| VariableName	| Example Value	 | Permitted Values	 | Explanation  |
|-------------|:-------------:|:-------------:|-------------|
| DoBiVariate         |  False       | True/False	|  Perform bivariate G&F between two or three channels. In addition to the standard univariate (within channel) clustering, each channel is also compared against the other(s).  |
| ChannelIDColumn     |  None        | Integer	|  This must be set to the column containing the channel ID for each line of data. If your channels are in separate files, check the wiki for the channel concatenating tool.  |
| BiVarSamplingRadius |  50          | Number	|  Radius in which to search for neighbouring events from the other channel. Generally you might set this larger than your within-channel search radius.  |
| BiVarChangeHIGH     |  100         | Number	|  In-cluster threshold. Same as other thresholds but these are for the bivariate maps.  |
| BiVarChangeLOW      |  120         | Number	|  In-hole threshold. Same as other thresholds but these are for the bivariate maps.  |

### ProcSettings.txt - Binary cluster map options
The coloured maps are binarised at each of the following thresholds. There are two for historical reasons but it's a handy way to try out two different threshold values at the same time.

| VariableName	| Example Value	 | Permitted Values	 | Explanation  |
|-------------|:-------------:|:-------------:|-------------|
| BinaryChangeHIGH    |  80          | Number	|  L(r) value at which an event is considered to be 'in a cluster'.  |
| BinaryChangeLOW     |  60          | Number	|  L(r) value at which an event is considered to be 'in a hole'. This is essentially the same as the above line, but the colours are inverted for the threshold plots.  |

### ProcSettings.txt - 'Blob' type binary map options
Points above your clustering threshold (BinaryChangeHIGH, below), i.e. 'in cluster' points are rendered as a solid disk. Disks in clusters overlap to form the cluster outlines. Points below the threshold are removed.

| VariableName	| Example Value	 | Permitted Values	 | Explanation  |
|-------------|:-------------:|:-------------:|-------------|
|DoClustersByBlobs	| True	| True/False	|Make 'blob' style cluster maps? This is in addition to the regular thresholding-of-colourmaps way. 	|
|RenderBlobsDiskSize	| 23	| Number	| Disk size with which to draw each in-cluster point. This is roughly equivalent to pixel size, i.e. equiv. to nm in most cases. So for a 40-50 nm diameter 'blob' use 20-25 for the disk size.	|


### ProcSettings.txt - Time-series options
This particular part hasn't been touched in a long time so I can't say that it will still work if you enable it.

| VariableName	| Example Value	 | Permitted Values	 | Explanation  |
|-------------|:-------------:|:-------------:|-------------|
| DoTimeSeries		|  False       | True/False	|  For live-data. Probably not working any more, so leave this as false.  |
| TSWindow			|  1000        | Integer	|  The size of the window (in acquisition frames) from which to consider events for a cluster map.  |
| TSWinStep			|  500         | Integer	|  The size of the jump (in acquisition frames) to slide the window when making the next 'map frame'.  |
| TSNumFrames			|  3           | Integer	|  How many times to jump the window, i.e. how many 'map frames' to create.  |

