# ClusterFields

Getis &amp; Franklin Local Point Pattern Analysis for Localisation Microscopy Images

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

The 'ProcSettings.txt' file is als orequired for cluster analysis. It contains specific settings for processing data tables in the folder you select. An example ProcSettings.txt file in this repository. The idea is that you keep a copy of this file in the folder with your input data so you have a record of how you processed that data.

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

Example files are given in the Templates folder. Copy and modify these files as required. The file must always be named 'ProcSettings.txt' in order work with the script, i.e. if you copy from the templates file you will need to rename it yourself. The order of these values is not important – they can be on any line. You may want to rearrange the lines to put unimportant options at the bottom and more frequently changed lines towards the top.

The lines are explained here:

| VariableName	| Example Value	 | Permitted Values	 | Explanation  |
|-------------|:-------------:|:-------------:|-------------|
|SkipToRegionNumber	| 1	| Integer	| Which line-number in your regions file to begin processing at? Normally you start at Line 1, but if something goes wrong you can easily pick up the processing again at Line X, effectively skipping the regions that were already processed.	|
|SaveImages	| True	| True/False	| Save the images from the standard cluster analysis. Disabling images will significantly speed up the processing. If you have elected to do GRID or Blobs then these images will still be saved.	|
|DoClustersByBlobs	| True	| True/False	| Events will be thresholded by L® value and then rendered as disks; overlapping disks will be merged into clusters.	|
|RenderBlobsDiskSize	| 23	| Integer	| The size of the disk to use when rendering events as blobs.	|
|xRegionLength	| 3000	| Integer	| The full length of your region's x dimension (nm). NB: this is no longer the 'half region size' value from older versions!	|
|yRegionLength	| 3000	| Integer	| The full length of your region's y dimension (nm). NB: this is no longer the 'half region size' value from older versions!	|
|SamplingRadius	| 30	| Integer	| Radius (nm) within which events are counted to calculate L(r).	|
|BinaryChangeHIGH	| 90	| Integer	| Molecules with L(r) ≥ BinaryChangeHIGH are considered to be within clusters.	|
|BinaryChangeLOW	| 90	| Integer	| Molecules with L(r) ≤ BinaryChangeHIGH are considered to be within holes.	|
|ColMapMax	| max99	|  Integer alone 	|  Set to an integer value for an explicit maximum value of the colour scale  |
|         	|       |   Just 'max'   	|  Set to max to use that region's maximum L(r) value. as the upper limit  |
|         	|       |  max followed by Integer 	|  Set to maxN. If N ≤ 100, use Nth percentile as the colour map maximum – this can prevent odd looking maps if you have one very very dense cluster. If N > 100 use for NN percent-multiples of the L(r) max value.	|
|DoGRIDMaps	| True	| True/False	| Analyse relative to regular grid (essentially bivariate).	|
|GRIDMapSpacing	| 0.5	| Integer	| When constructing maps based on a regular grid, use this value. If less than one, grid spacing is this multiple of SamplingRadius. If 1 or more, spacing is in nm.	|
|DoBiVariate	| True	| True/False	| Do bivariate G&F, comparing Ch1 to Ch2 and vice versa. Can handle up to three channels.	|
|ChannelIDColumn	| 11	| Integer/None	| The column in the data table the channel ID. Set to 'None' if there is no channel ID column.	|
|BiVarSamplingRadius	| 30	| Integer	| Radius (nm) within which events from the other channel are counted to calculate bivariate L(r).	|
|BiVarChangeHIGH	| 90	| Integer	| Molecules with L(r) ≥ BinaryChangeHIGH are considered to be within clusters relative to the other channel.	|
|BiVarChangeLOW	| 90	| Integer	| Molecules with L(r) ≤ BinaryChangeHIGH are considered to be within holes relative to the other channel.	|
|PrecisionColumn	| None	| Integer/None	| The column in the data table containing localisation precision values.If you don't have such a column (or don't want the software to use it) then set this value to None.	|
|PrecisionCrop	| 50	| Integer	| Crop data which is poorly localised, i.e. events with a localisation precision less than this value are kept. You need to set PrecisionColumn for this to have any effect.	|
|PhotonColumn	| None	| Integer/None	| The column in the data table containing photon count values. If you don't have such a column (or don't want the software to use it) then set this value to None.	|
|PhotonCrop	| 400	| Integer	| Crop data which has less photons than this value. You need to set PhotonColumn for this to have any effect.	|
|MaxEventsToProcess	| 10000000	| Integer	| Limit to the number of molecules to process within a cropped region (not whole image). Set very large to not crop.	|
|DelDuplicatePts	| False	| True/False	| Delete points with identical xy coordinates. rarely used and does not delete duplicates from other channels when bivariate is enabled.	|
|UseFolders	| TRUE	| True/False	| Save the data to separate folders. If false, data is saved to the current folder (can get messy).	|
|SaveXLS	| TRUE	| True/False	| Save data to Excel files. Windows only – disable for OSX, Linux.	|
|SaveTextFiles	| TRUE	| True/False	| Save data to Text files. These will appear in a sub-folder called Numbers.	|
|UseGriddata	| FALSE	| True/False	| Interpolated colour maps with 'griddata v4' function. If 'false', uses scatteredInterp which is faster than griddata but not as smooth-looking.	|
|GDInterpSpacing	| 5	| Integer	| If using griddata, set the grid spacing to this value (nm).	|
|DataTableFileExt	| txt	| Text	| The file extension of the file containing your image data.	|
|DataDelimiter	| comma	| tab/comma/space	| How the data columns are separated in your data table file. Use the words tab, comma, or space, or the separation character itself (e.g. ;).	|
|CoordsTableScale	| 100	| Integer	| The scale of your coordinates in pixels/nm. Usually this is the same as your DataTableScale (e.g. if you used RegionFinder) but sometimes it is not.	|
|DataTableScale	| 100	| Integer	| The scale of the data table in pixels/nm.	|
|FooterLength	| 0	| Integer	| The number of lines at the end of data table which don't contain data.	|
|BlankFirstCol	| FALSE	| True/False	| If the first column of your data table is blank (e.g. each line begins with your delimiter character, e.g. a tab) then set this to True.	|
|InvertyAxis	| FALSE	| True/False	| If the coordinates of your yaxis are inverted, set to true. Generally this is a Zeiss 'feature'.	|
|xCoordsColumn	| 4	| Integer	| 	The column in the data table containing the x coordinates.	|
|yCoordsColumn	| 5	| Integer	| The column in the data table containing the y coordinates.	|
|ExcelHeaders	| X,Y,Z, …	| (various)	| Comma separated labels to place at the top of your output tables. Labels for L(r) etc will be added automatically but this lets you rename your data headers if they are confusion.	|
|ImageSize	| 18000	| Integer	| Size of a full image (nm). This should be the full range of the camera region, not the min/max of your table, e.g. 180 px wide image at 100 nm/px = 18000 nm.	|
|DoTimeSeries	| FALSE	| True/False	| Enable live cell cluster analysis. Uses the next three variables.	|
|TSWindow	| 1000	| Integer	| Make maps using this many acquisition data frames.	|
|TSWinStep	| 500	| Integer	| Move the above window by this many acquisition data frames for the next cluster map.
|TSNumFrames	| 3	| 	Integer	| Create this many cluster map 'frames' from the data.	|
|EmailMeAt	| bob@address	| Email address	| MATLAB will try and email you at this address when it has completed everything. It won't email you if the script crashes for any reason. You will need to edit ProcessingDone.m to reflect your mail server settings.	|
