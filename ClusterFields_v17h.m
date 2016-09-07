%{
   ________           __            _______      __    __    
  / ____/ /_  _______/ /____  _____/ ____(_)__  / /___/ /____
 / /   / / / / / ___/ __/ _ \/ ___/ /_  / / _ \/ / __  / ___/
/ /___/ / /_/ (__  ) /_/  __/ /  / __/ / /  __/ / /_/ (__  ) 
\____/_/\__,_/____/\__/\___/_/  /_/   /_/\___/_/\__,_/____/  
                                                             
%}

ClusterFieldsVersion = 'v17h_XX_June2015_Developmental';

%{

Information about this script can be found on the wiki.

%}

%% Housekeeping
home %clean up the command window
rng('shuffle')  % set the random seed

disp('---------------------ClusterFields---------------------');
disp(ClusterFieldsVersion);


%% Load Coords.txt and ProcSettings.txt
    if verLessThan('matlab','8.1.0') && ~strcmpi(version('-release'),'2013a') % 8.3.0 = 2014a
        error('You require a more recent version of MATLAB');
    end
    [FileNameC,PathNameC] = uigetfile({'*coord*.txt*';'*.txt';'*.*'},'Choose your Coordinates file');
    if PathNameC ~=0
        cd(PathNameC);
        coordinates=dlmread(FileNameC, '\t', 0,1); %read in the file, tab-delimited, ignoring the first column (which contains user notes and comments)
    else
        error('Cancelled?! So rude.');
    end

    InfoMessage = ['Coordinates loaded from ' fullfile(PathNameC,FileNameC)];
    disp(InfoMessage);

% Import processing settings
    ProcSet = LoadProcSettings;

% How many regions are we working on?
    NumberOfRegions=size(coordinates,1); 

% Throw error in case you try to 'skip ahead' too far
    if NumberOfRegions < ProcSet.SkipToRegionNumber 
        ErrorMessage = ['You are trying to skip ahead to Region ', num2str(ProcSet.SkipToRegionNumber),' but there are only ', num2str(NumberOfRegions(1)),' region(s) in the coordinates file. Check your settings...'];
        errordlg(ErrorMessage);
    end

% Find the starting point
    TotalNumberofDataTables=max(coordinates(:,1));
    StartingTable=(coordinates(ProcSet.SkipToRegionNumber,1));
    StartingTableCoordsBeginAtLine = find(coordinates(:,1)==StartingTable,1); 

% Switch if path contains non-excel friendly chars
% % <  >  ?  [ ]  :  |  *
if ProcSet.SaveXLS && ~isempty(regexp(PathNameC,'\[|\]|\||\?', 'once'))
    ErrorMessage = 'You can''t save Excel data to a folder containing [ ] | or ? characters. Either disable saving data to Excel or run the script on data without those characters in the file-path and try again.';
    errordlg(ErrorMessage);
end

%Display some information
    if ProcSet.SkipToRegionNumber ~=1
        InfoMessage = '  [!]  Skip-ahead was requested.';
        disp(InfoMessage);
        
        InfoMessage = ['        ''--> Starting at Line ' num2str(ProcSet.SkipToRegionNumber) ' in your coords file (Table ' num2str(StartingTable) '.)'];
        disp(InfoMessage);
    end
    if ~ProcSet.SaveImages
        InfoMessage = '  [!]  No images will be saved.';
        disp(InfoMessage);
    end
%     if ~ProcSet.SaveImages && ProcSet.DoClustersByBlobs
%         InfoMessage = '  [*]  Blobs images will be saved.';
%         disp(InfoMessage);
%     end
    if ~ProcSet.DoInterpMaps
        InfoMessage = '  [!]  Skipping Interpolated cluster maps.';
        disp(InfoMessage);
    end
    if ~ProcSet.DoClustersByBlobs
        InfoMessage = '  [!]  Skipping Clusters-by-blobs.';
        disp(InfoMessage);
        end
    if ~ProcSet.DoGridMaps
        InfoMessage = '  [!]  Skipping Grid-based cluster maps.';
        disp(InfoMessage);
    end
    if ~ProcSet.SaveXLS
        InfoMessage = '  [!]  Data will not be saved to Excel.';
        disp(InfoMessage);
    end
    if ProcSet.DoBiVariate
        InfoMessage = '  [*]  BiVariate Analysis selected.';
        disp(InfoMessage);
    end
    if ProcSet.VerboseUpdates
        InfoMessage = '  [*]  Verbose progress updates enabled.';
        disp(InfoMessage);
    end
% Misc - Hide warnings
    if ProcSet.SaveXLS == true
        warning('off','MATLAB:xlswrite:AddSheet'); % Turn off warnings about Excel operations
    end

    if ProcSet.UseGriddata == true
        warning('off','MATLAB:griddata:DuplicateDataPoints'); % Turn off griddata warning about duplicate points
    end   

% Misc - Clean up temporary variables
    clear FileNameC InfoMessage ClusterFieldsVersion
%% Rebuild the coordinates file for time-series data
% This will generate a new coordinates table with the time-cropping column i.e. for each time-window that is required for the cluster-movie, the region
% coordinates need to be copied to as many new lines as there will be cluster-movie frames, with each line references to a frame-window

if ProcSet.DoTimeSeries
    FinalCoordsSize = NumberofRegions * ProcSet.TSNumFrames;
    tempX=zeroes(FinalCoordsSize,3);
    temp3=[];  %create two empty arrays
    temp5=[];
    for CurrentRegionID=1:NumberOfRegions; %for each row in the coords table ...
        x=[];           %new blank array x
        for times=1:ProcSet.TSNumFrames; %copy the current row to x for as many times as numberofframes
            x=vertcat(x,coordinates(CurrentRegionID,:));
        end
        temp4=[]; % new blank array temp4
        for times=1:ProcSet.TSNumFrames;
            winstart=ProcSet.TSWinStep*(times-1); %build a list of the frame numbers to look at
            temp4=vertcat(temp4,winstart); %copy each frame number to temp4
        end
        temp3=horzcat(x,temp4); %merge the coords and frame numbers
        temp5=vertcat(temp5,temp3); %copy the merged coords and frame numbers to a new coords table and go to the next line in the original coords file
    end 
    clear temp3; %=[];  %empty out temp3 table to save memory
    coordinates=temp5; % replace the imported coordinates file with the time-series version.
    
    clear tempX temp3 temp5 x times
end

%% Prepare folders and colourmaps etc
    if ProcSet.UseFolders==true

        if ProcSet.SaveImages
            if ~exist(strcat(PathNameC,'Colour'),'dir')
                mkdir('Colour');
            end
            
            if ~exist(strcat(PathNameC,'Thr-Holes'),'dir')
                mkdir('Thr-Holes');
            end
            
            if ~exist(strcat(PathNameC,'Thr-Clusters'),'dir')
                mkdir('Thr-Clusters');
            end
            
            if ~exist(strcat(PathNameC,'Greyscale'),'dir')
                mkdir('Greyscale');
            end
            
            if ProcSet.SavePointPlots && ~exist(strcat(PathNameC,'Points'),'dir')
                mkdir('Points');
            end
            
            if ProcSet.SaveGFPlots && ~exist(strcat(PathNameC,'GF-Points'),'dir')
                mkdir('GF-Points');
            end
            
            if ~exist(strcat(PathNameC,'FIGs'),'dir')
                mkdir('FIGs');
            end

            if ProcSet.DoGridMaps
                if ~exist(strcat(PathNameC,'Colour/Grid-maps'),'dir')
                    mkdir('Colour/Grid-maps');
                end
                
                if ~exist(strcat(PathNameC,'Thr-Holes/Grid-maps'),'dir')
                    mkdir('Thr-Holes/Grid-maps');
                end
                
                if ~exist(strcat(PathNameC,'Thr-Clusters/Grid-maps'),'dir')
                    mkdir('Thr-Clusters/Grid-maps');
                end
                
                if ~exist(strcat(PathNameC,'Greyscale/Grid-maps'),'dir')
                    mkdir('Greyscale/Grid-maps');
                end
                
                if ~exist(strcat(PathNameC,'FIGs/Grid-maps'),'dir')
                    mkdir('FIGs/Grid-maps');
                end
            end
            
            if ProcSet.DoClustersByBlobs
                if ~exist(strcat(PathNameC,'Numbers\Centroids'),'dir')
                    mkdir('Numbers\Centroids');
                end
            end
            
        end
        
        if ProcSet.SaveImages && ProcSet.DoClustersByBlobs
            if ~exist(strcat(PathNameC,'Thr-Clusters/Blobs'),'dir')
                mkdir('Thr-Clusters/Blobs');
            end       
%             
%             if ~exist(strcat(PathNameC,'Thr-Clusters/Blobs/WithPoints'),'dir')
%                 mkdir('Thr-Clusters/Blobs/WithPoints');
%             end       
            
            if ~exist(strcat(PathNameC,'Thr-Clusters/Blobs/LabelledMaps'),'dir')
                mkdir('Thr-Clusters/Blobs/LabelledMaps');
            end       
        end
        
        if ProcSet.SaveTextFiles
            if ~exist(strcat(PathNameC,'Numbers'),'dir')
                mkdir('Numbers');
            end
            
            if ~exist(strcat(PathNameC,'Numbers\RegionTables'),'dir')
               mkdir('Numbers\RegionTables');
            end
            
            if ~exist(strcat(PathNameC,'Numbers\Summaries'),'dir')
               mkdir('Numbers\Summaries');
            end
            
        end

    end

% pad the size of the regions in preparation for cluster analysis
% this avoids edge effects
areaX_padded=(ProcSet.xRegionLength/2)+ProcSet.SamplingRadius;
areaY_padded=(ProcSet.yRegionLength/2)+ProcSet.SamplingRadius;

%used for the percentage progress reporting
RegionCounter = 1;

%Display some information
disp('---------------------------------------------------------');
InfoMessage=[datestr(fix(clock),'HH:MM:SS'),9,'Processing ' num2str(NumberOfRegions - ProcSet.SkipToRegionNumber + 1) ' regions across ' num2str(TotalNumberofDataTables - StartingTable + 1) ' data tables'];
disp(InfoMessage);
disp('---------------------------------------------------------');

%% Begin Processing data tables
PreviousRegionTimestamp = 0; % Initialise the timing tracker.
tic; %start the clock to track processing time

for CurrentTableID=StartingTable:TotalNumberofDataTables;

    CurrentRegionFileName=strcat(num2str(CurrentTableID), strcat('.',ProcSet.DataTableFileExt));
    
    % error if the data table txt file doesn't exist
    if exist(CurrentRegionFileName, 'file') == 0
        ErrorMessage = ['Cannot find the data table file ', CurrentRegionFileName, '.'];
        errordlg(ErrorMessage);
    end
    
    
    if isfield(ProcSet,'GetHeadersFromTable') && ProcSet.GetHeadersFromTable
        % open the first line containing the headers
        fid = fopen(CurrentRegionFileName);
        tline = fgetl(fid);
        tline = strrep(tline,'"',''); % strip any quote marks out
        ProcSet.ExcelHeaders = strsplit(tline,{ProcSet.DataDelimiter});
        fclose(fid);
        clear tline
    end
    
    
    % Otherwise load the file
    FileID = fopen(CurrentRegionFileName);    
    
    %Calculate how many rows of data in the current raw data table, accounting for data-table footers
    if ProcSet.FooterLength==0
        % No stupid footer? Reading is easy!
        if ProcSet.BlankFirstCol==false
            data_full=dlmread(CurrentRegionFileName, ProcSet.DataDelimiter, 1, 0); %read data from row 1 col 0
        else
            data_full=dlmread(CurrentRegionFileName, ProcSet.DataDelimiter, 1, 1); %read data from row 1 col 1 (skip blank col)
        end
    else
        numRows = str2num(perl('countlines.pl', CurrentRegionFileName) );
        FinalDataRow=numRows-ProcSet.FooterLength;

        tLines = fgets(FileID); % Read the first line (headers)
        tLines = fgets(FileID); % Read in the second line (first row of data)

        if ProcSet.DataDelimiter == '\t'
                numCols = numel(strfind(tLines,9));
        else
            numCols = numel(strfind(tLines,ProcSet.DataDelimiter));
        end

        if ProcSet.BlankFirstCol==false
            data_full=dlmread(CurrentRegionFileName, ProcSet.DataDelimiter, [1 0 FinalDataRow numCols]); %read data from row 1 col 0
        else
            data_full=dlmread(CurrentRegionFileName, ProcSet.DataDelimiter, [1 1 FinalDataRow numCols]); %read data from row 1 col 1 (skip blank col)
        end
    end
        
    fclose(FileID);

    coordinates2=coordinates; %coordinates(ProcSet.SkipToRegionNumber:end,:);
    coordinates2(coordinates2(:,1)~=CurrentTableID,:)=[]; %delete those rows which are not from the current region ID from coordinates2
    TotalNumberOfRegions=size(coordinates2,1); %how many regions (rows) in coordinates2 now?

    % Check if the table is the right size
    if ProcSet.InvertyAxis == true && max(data_full(:,ProcSet.yCoordsColumn)) > ProcSet.ImageSize
        ErrorMessage = ['You indicated y-axis inversion is in effect but this image (Table-', num2str(CurrentTableID), ') is larger (', num2str(max(data_full(:,ProcSet.yCoordsColumn))) ,') than what you stated (', num2str(ProcSet.ImageSize) ,') for the variable ''ImageSize''.'];
        errordlg(ErrorMessage);
    end
        
    %Gets the correct region to begin at when skipping ahead    
    if coordinates(ProcSet.SkipToRegionNumber,1) == CurrentTableID
        SkipToTableRegionID = size(coordinates,1) - size(coordinates(ProcSet.SkipToRegionNumber:end,:),1) + 2 - StartingTableCoordsBeginAtLine;
    else
        SkipToTableRegionID = 1; % If we're not skipping halfway into a list of regions, then start at the first one
    end
        
    if ProcSet.ChannelIDColumn ~=0
        NumberOfChannels=max(data_full(:,ProcSet.ChannelIDColumn)); %how many channels?
        if NumberOfChannels >= 4
            ErrorMessage = ['Data appears to have (', num2str(NumberOfChannels), ') channels. If you do not have a specific Channel ID column, set this variable to ''None'' in ProcSettings.'];
            error(ErrorMessage);
        end
    else
        NumberOfChannels=1;
    end
    
    if ProcSet.DoBiVariate == true && NumberOfChannels  == 1
        ErrorMessage = 'Bivariate analsis requested but only data has only one channel.';
        error(ErrorMessage);
    end
    
%% Create regions and do cluster analysis
    for CurrentRegionID=SkipToTableRegionID:TotalNumberOfRegions;

        if ProcSet.VerboseUpdates
            ShowInfoMessage(['Starting Table ',num2str(CurrentTableID),' Region ',num2str(CurrentRegionID),' processing ...']);
        end
            
        data_region=data_full;

        %Convert table pixel values into nm values
        if ProcSet.DataTableScale ~= 1
            data_region(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn)=data_region(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn)*ProcSet.DataTableScale;
        end

        %Delete poorly localised molecules
        if ProcSet.PrecisionColumn ~= 0
            PrecisionCrop = find(data_region(:,ProcSet.PrecisionColumn) >= ProcSet.PrecisionCrop); %find rows exceeding precision threshold
            data_region(PrecisionCrop,:)=[]; % delete those rows
            clear PrecisionCrop
        end

        %Delete dim molecules
        if ProcSet.PhotonColumn ~= 0
            PhotonCrop = find(data_region(:,ProcSet.PhotonColumn) <= ProcSet.PhotonCrop); %find rows with too few photos
            data_region(PhotonCrop,:)=[]; % delete those rows
            clear PhotonCrop
        end
        
        %Crop the full table to the current region coords plus padding
        %equivalent to sampling radius (ProcSet.SamplingRadius) to avoid edge effects
        padded_region_xmin = ceil((coordinates2(CurrentRegionID,2)*ProcSet.CoordsTableScale)-areaX_padded);
        padded_region_xmax = floor(padded_region_xmin + 2 * areaX_padded);
        if ProcSet.InvertyAxis==true; % Zeiss y-axis direction
            padded_region_ymin = ceil(ProcSet.ImageSize-coordinates2(CurrentRegionID,3)*ProcSet.CoordsTableScale-areaY_padded);
            padded_region_ymax = floor(padded_region_ymin + 2 * areaY_padded);
        else % normal y-axis direction
            padded_region_ymin = ceil(coordinates2(CurrentRegionID,3)*ProcSet.CoordsTableScale-areaY_padded);
            padded_region_ymax = floor(padded_region_ymin + 2 * areaY_padded);
        end
        
        % the region to be processed for cluster analysis
        data_region = RegionCropper(data_region, [padded_region_xmin padded_region_xmax padded_region_ymin padded_region_ymax], [ProcSet.xCoordsColumn ProcSet.yCoordsColumn]);
        
        % catch errors if the table is empty!

        strict_region_xmin = padded_region_xmin + ProcSet.SamplingRadius;
        strict_region_xmax = padded_region_xmax - ProcSet.SamplingRadius;
        strict_region_ymin = padded_region_ymin + ProcSet.SamplingRadius;
        strict_region_ymax = padded_region_ymax - ProcSet.SamplingRadius;
        
        % Save the padded region for posterity
        if isfield(ProcSet,'SaveCroppedRegions') && ProcSet.SaveCroppedRegions == true
            TXTFileName = fullfile('Numbers',strcat('T',num2str(CurrentTableID),'R',num2str(CurrentRegionID),'-RegionCropped.txt')); %replace .txt with .csv if needed
            fid = fopen(TXTFileName,'w');
            stringy = '%s';
            for g = 1:(length(ProcSet.ExcelHeaders)-1)
                stringy = strcat(stringy,'\t%s'); % replace \t with a comma for csv
            end
            fprintf(fid,stringy,ProcSet.ExcelHeaders{:});
            fprintf(fid,'\r\n');
            fid = fclose(fid);
            dlmwrite(TXTFileName,data_region,'-append','delimiter','\t');     
        end
        
    %% Process region for each channel
        for ChannelID=1:NumberOfChannels;
        
        % Segregate multichannel data for bivariate
            if ProcSet.ChannelIDColumn ~= 0
                if ProcSet.DoBiVariate == true && NumberOfChannels > 1
                    % Copy other channels to new tables
                    for OtherChannelID = 1:NumberOfChannels;
                        if OtherChannelID ~= ChannelID % dont process the current 'main' channel!
                            ChannelCopy=find(data_region(:,ProcSet.ChannelIDColumn)==OtherChannelID);
                            if OtherChannelID == 1
                                data_region_Ch1 = data_region(ChannelCopy,:);
%                                 total_events_region_ch1 = size(data_region_Ch1,1);
                            end
                            if OtherChannelID == 2
                                data_region_Ch2 = data_region(ChannelCopy,:);
%                                 total_events_region_ch2 = size(data_region_Ch2,1);
                            end
                            if OtherChannelID == 3
                                data_region_Ch3 = data_region(ChannelCopy,:);
%                                 total_events_region_ch3 = size(data_region_Ch3,1);
                            end
                            clear ChannelCopy
                        end
                    end
                end
                %Keep only the principle channel in data_region
                ChannelCrop=find(data_region(:,ProcSet.ChannelIDColumn)~=ChannelID);
                data_region_ch = data_region;
                data_region_ch(ChannelCrop,:)=[];
                clear ChannelCrop
            else % if ProcSet.ChannelIDColumn == 0 then No channel column was specified
                data_region_ch = data_region;
            end
            
        % split into time windows
        % This code has not been updated to include variable locations of
        % frame index. It expects FrameID to be in column 2 of the data
        % table.
            if ProcSet.DoTimeSeries==true;
                tcrops=find(data_region_ch(:,2)<coordinates2(CurrentRegionID,4));
                data_region_ch(tcrops,:)=[]; 
                tcropl=find(data_region_ch(:,2)>coordinates2(CurrentRegionID,4)+ProcSet.TSWindow);
                data_region_ch(tcropl,:)=[];
                clear tcrops tcrop1
            end

        % Cap the number of molecules to process
            % This variable is either a number or a boolean false
            total_events_region = size(data_region_ch,1);
            if isfield(ProcSet,'MaxEventsToProcess') && ProcSet.MaxEventsToProcess > 1
                
                % calculate the fraction of the padded area wrt to the
                % actual specified area
                padded_area = (padded_region_xmax - padded_region_xmin)*(padded_region_ymax-padded_region_ymin);
                specified_area = (strict_region_xmax-strict_region_xmin)*(strict_region_ymax-strict_region_ymin);
                %adjust MaxEventsToProcess to account for the increased
                %area
                AdjustedMaxEventsToProcess = floor((padded_area / specified_area) * ProcSet.MaxEventsToProcess);
          %      ExpectedEventsInRegion = size(data_region_ch,1) / (padded_area / specified_area);
                               
                if AdjustedMaxEventsToProcess < total_events_region
                    InfoMessage =  [datestr(fix(clock),'HH:MM:SS'),9,'[!]',9,'T',num2str(CurrentTableID),'R',num2str(CurrentRegionID),'Ch',num2str(ChannelID),' has ',num2str(total_events_region),' events,'];
                    disp(InfoMessage);
                    InfoMessage =  [9,9,9,'exceeding MaxEventsToProcess=',num2str(AdjustedMaxEventsToProcess),' events (adjusted from ',num2str(ProcSet.MaxEventsToProcess),' events to account for edge padding).'];
                    disp(InfoMessage);
                    InfoMessage =  [9,9,9,num2str(total_events_region - AdjustedMaxEventsToProcess),' events in excess will be ignored (',num2str(floor(100*(total_events_region - AdjustedMaxEventsToProcess)/total_events_region)),'% of this region''s total.)'];
                    disp(InfoMessage);
                    [data_region_ch, ~] = CropMaxMolecules(data_region_ch,AdjustedMaxEventsToProcess);
                end
                
                if exist('data_region_Ch1','var') && AdjustedMaxEventsToProcess < size(data_region_Ch1,1)
                    InfoMessage =  [datestr(fix(clock),'HH:MM:SS'),9,'[!]',9,'Number of events in Ch1 (',num2str(size(data_region_Ch1,1)),') exceeds maximum specified in ProcSettings (',num2str(ProcSet.MaxEventsToProcess),'). Excess events are ignored.'];
                    disp(InfoMessage);
                    [data_region_Ch1, ~] = CropMaxMolecules(data_region_Ch1,AdjustedMaxEventsToProcess);
                end
                
                if exist('data_region_Ch2','var') && AdjustedMaxEventsToProcess < size(data_region_Ch2,1)
                    InfoMessage =  [datestr(fix(clock),'HH:MM:SS'),9,'[!]',9,'Number of events in Ch2 (',num2str(size(data_region_Ch2,1)),') exceeds maximum specified in ProcSettings (',num2str(ProcSet.MaxEventsToProcess),'). Excess events are ignored.'];
                    disp(InfoMessage);
                    [data_region_Ch2, ~] = CropMaxMolecules(data_region_Ch2,AdjustedMaxEventsToProcess);
                end
                
                if exist('data_region_Ch3','var') && AdjustedMaxEventsToProcess < size(data_region_Ch3,1)
                    InfoMessage =  [datestr(fix(clock),'HH:MM:SS'),9,'[!]',9,'Number of events in Ch3 (',num2str(size(data_region_Ch3,1)),') exceeds maximum specified in ProcSettings (',num2str(ProcSet.MaxEventsToProcess),'). Excess events are ignored.'];
                    disp(InfoMessage);
                    [data_region_Ch3, ~] = CropMaxMolecules(data_region_Ch3,AdjustedMaxEventsToProcess);
                end
            end
            
       % delete duplicate points (sometimes stops MATLAB crashes when fitting griddata)
            if isfield(ProcSet,'DelDuplicatePts')
                if ProcSet.DelDuplicatePts
                    data_region_ch = DeleteDuplicatePoints(data_region_ch,ProcSet.xCoordsColumn,ProcSet.yCoordsColumn);
                    if exist('data_region_Ch1','var')
                        data_region_Ch1 = DeleteDuplicatePoints(data_region_Ch1,ProcSet.xCoordsColumn,ProcSet.yCoordsColumn);
                    end                
                    if exist('data_region_Ch2','var')
                        data_region_Ch2 = DeleteDuplicatePoints(data_region_Ch2,ProcSet.xCoordsColumn,ProcSet.yCoordsColumn);
                    end                
                    if exist('data_region_Ch3','var')
                        data_region_Ch3 = DeleteDuplicatePoints(data_region_Ch3,ProcSet.xCoordsColumn,ProcSet.yCoordsColumn);
                    end
                end
            end
            
        %% Calculate Univariate G&F cluster values for the current channel
        
        if ProcSet.VerboseUpdates
            ShowInfoMessage('Starting G&F calcs...');
        end
        
        % G&F measurement done in function GF_measure
            data_GF = GF_Measure(data_region_ch(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn),ProcSet.SamplingRadius,(2 * areaX_padded),(2 * areaY_padded));
            
        % Combine GF Data to the padded region
            data_region_ch_GF = horzcat(data_region_ch,data_GF);
            
        %Column containing GF values, found at the end of the new region table
            Main_Ch_GFCol = size(data_region_ch_GF,2);
            
            ExcelHeaders2 = ProcSet.ExcelHeaders;
            ExcelHeaders2{:,length(ExcelHeaders2) + 1} = strcat('L(',num2str(ProcSet.SamplingRadius),')-Ch',num2str(ChannelID));

        if ProcSet.VerboseUpdates
            ShowInfoMessage('Completed G&F calcs.');
        end
        
        %% Calculate Biovariate G&F cluster values for the current channel relative to the other channel(s).
        
            if ProcSet.DoBiVariate == true
                
                if ProcSet.VerboseUpdates
                    ShowInfoMessage('Starting bivariate G&F calcs...');
                end
                
                if exist('data_region_Ch1','var') %Append Current Ch vs Ch1 to results
                    data_GF_Ch1 = GF_Measure(data_region_ch(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn),ProcSet.BiVarSamplingRadius,(2 * areaX_padded),(2 * areaY_padded),data_region_Ch1(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn));
                    data_region_ch_GF = horzcat(data_region_ch_GF,data_GF_Ch1);
                    GF_Ch1_Col = size(data_region_ch_GF,2);
                    ExcelHeaders2{:,length(ExcelHeaders2) + 1} = strcat('L(',num2str(ProcSet.BiVarSamplingRadius),')-Ch',num2str(ChannelID),'vsCh1');
                end
                
                if exist('data_region_Ch2','var') %Append Current Ch vs Ch2 to results
                    data_GF_Ch2 = GF_Measure(data_region_ch(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn),ProcSet.BiVarSamplingRadius,(2 * areaX_padded),(2 * areaY_padded),data_region_Ch2(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn));
                    data_region_ch_GF = horzcat(data_region_ch_GF,data_GF_Ch2);
                    GF_Ch2_Col = size(data_region_ch_GF,2);
                    ExcelHeaders2{:,length(ExcelHeaders2) + 1} = strcat('L(',num2str(ProcSet.BiVarSamplingRadius),')-Ch',num2str(ChannelID),'vsCh2');
                end
                
                if exist('data_region_Ch3','var') %Append Current Ch vs Ch3 to results
                    data_GF_Ch3 = GF_Measure(data_region_ch(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn),ProcSet.BiVarSamplingRadius,(2 * areaX_padded),(2 * areaY_padded),data_region_Ch3(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn));
                    data_region_ch_GF = horzcat(data_region_ch_GF,data_GF_Ch3);
                    GF_Ch3_Col = size(data_region_ch_GF,2);
                    ExcelHeaders2{:,length(ExcelHeaders2) + 1} = strcat('L(',num2str(ProcSet.BiVarSamplingRadius),')-Ch',num2str(ChannelID),'vsCh3');
                end
                
                if ProcSet.VerboseUpdates
                    ShowInfoMessage('Completed bivariate G&F calcs.');
                end
            end

            %trim away the points within the padded boundary
            data_region_ch_GF= RegionCropper(data_region_ch_GF, [strict_region_xmin strict_region_xmax strict_region_ymin strict_region_ymax], [ProcSet.xCoordsColumn ProcSet.yCoordsColumn]);

        %% Create the images
        
        % Build a specific file name for this Table-Region-Channel dataset
            ImgFileName = strcat('Table',num2str(CurrentTableID),' Region',num2str(CurrentRegionID),' Ch',num2str(ChannelID));
            
        %% Cluster extraction by point threshold and disk rendering - Main Channel (Main_Ch_GFCol) Only
            if ProcSet.DoClustersByBlobs
                
            if ProcSet.VerboseUpdates
                ShowInfoMessage('Starting clusters by blobs...');
            end
            
            % Create a disk scaling image
            if exist('Thr-Clusters\Blobs\Blob Standard - Disk - Size 1-100.png','file') == 0
                TestImg = [];
                TestImg2 = zeros(3000,3000);
                for d = 1:100
                    DiskArray = repmat(0,300);
                    DiskArray(150,150) = 1;
                    StructElement = strel('disk',d,8);
                    DemoClusterMask = imdilate(DiskArray,StructElement);
                    TestImg = horzcat(TestImg,DemoClusterMask);
                end
                %rearrange the array
                TestImg2(1:300,1:3000) = TestImg(1:300,1:3000);
                TestImg2(301:600,1:3000) = TestImg(1:300,3001:6000);
                TestImg2(601:900,1:3000) = TestImg(1:300,6001:9000);
                TestImg2(901:1200,1:3000) = TestImg(1:300,9001:12000);
                TestImg2(1201:1500,1:3000) = TestImg(1:300,12001:15000);
                TestImg2(1501:1800,1:3000) = TestImg(1:300,15001:18000);
                TestImg2(1801:2100,1:3000) = TestImg(1:300,18001:21000);
                TestImg2(2101:2400,1:3000) = TestImg(1:300,21001:24000);
                TestImg2(2401:2700,1:3000) = TestImg(1:300,24001:27000);
                TestImg2(2701:3000,1:3000) = TestImg(1:300,27001:30000);
                % render cluster image and save
                imwrite(TestImg2,fullfile('Thr-Clusters\Blobs',strcat('Blob Standard - Disk - Size 1-100.png')),'png');
                clear TestImg TestImg2 DemoClusterMask d StructElement DiskArray
            end
                
            % create new table containing only the clustered molecules
                IndexAboveThreshold = find(data_region_ch_GF(:,Main_Ch_GFCol) >= ProcSet.BinaryChangeHIGH);
                ClusteredData = horzcat(IndexAboveThreshold,data_region_ch_GF(IndexAboveThreshold,ProcSet.xCoordsColumn),data_region_ch_GF(IndexAboveThreshold,ProcSet.yCoordsColumn),data_region_ch_GF(IndexAboveThreshold,Main_Ch_GFCol));
            %plot the points as 1 px each, save, close
                figure('Color',[1 1 1], 'Visible', 'off', 'Renderer', 'OpenGL', 'Units', 'inches');
                axes('Parent',figure,'Layer','top', 'YTick',zeros(1,0),'XTick',zeros(1,0),'DataAspectRatio', [1,1,1],'position',[0,0,1,1]);            
                box('off');
            %define the 'paper' dimensions
                set(gcf, 'PaperUnits', 'inches', 'PaperSize', [10 10], 'PaperPositionMode', 'manual', 'PaperPosition', [0 0 10 10],'Visible','off');
                scatter(ClusteredData(:,2),ClusteredData(:,3),1,'k.');
                axis([strict_region_xmin strict_region_xmax strict_region_ymin strict_region_ymax])
                set(gca, 'Visible', 'off'); %hide the axes
                axis square
            % to create a 1px/nm image
                SaveHighDPI = strcat('-r',num2str(ProcSet.xRegionLength / 10));
                print('-dpng',SaveHighDPI,'ClusMaskTmp.png');
                close(gcf);

            % Reopen as image data, dilate points by the Blobs disk
                ClusterMask = imread('ClusMaskTmp.png');
                ClusterMask = im2bw(ClusterMask,0.5);
                ClusterMask = ~ClusterMask; %invert
                se2 = strel('disk',ceil(ProcSet.RenderBlobsDiskSize));
                ClusterMask2 = imdilate(ClusterMask,se2);
                ClusterMask2 = imfill(ClusterMask2,'holes'); % fill in holes
                
            % Test! Apply another round of dilation followed by two
            % erosions. This should reduce the cauliflower effect?
                se3 = strel('disk',2);
                se4 = strel('disk',5);
                ClusterMask3 = imdilate(ClusterMask2,se3);
                ClusterMask3 = imerode(ClusterMask3,se4);
                ClusterMask3 = imfill(ClusterMask3,'holes'); % fill in holes
                
            % render cluster image and save
                imwrite(ClusterMask3,fullfile('Thr-Clusters\Blobs',strcat(ImgFileName,' Clusters by Blobs.png')),'png');
                % close(gcf);
            
            % do image proc and stats
                islands = bwconncomp(ClusterMask2);
                label_clusters = labelmatrix(islands);
                stats = regionprops(label_clusters,'all');
                clusmap_scale = ProcSet.xRegionLength / size(label_clusters,1); % conversion factor to resize 

                % total_clusters = max(max(label_clusters));% FYI length(stats) also equals the cluster count
                % Export stats to text file?
                
            % export individual cluster images
%             for u=1:size(stats,1)
%                 imagesc(stats(u,1).Image);
%             end
                % imagesc(stats(36,1).Image); % display image of only cluster 36

            % Assign each clustered point a clusterID using the regionprops polygon
                ClusterIDCol = size(data_region_ch_GF,2)+1;
                if isempty(stats) % no clusters detected
                 data_region_ch_GF(:,ClusterIDCol) = 0;
                    fname = fullfile('.\Numbers\Centroids',strcat(ImgFileName,' Centroids List.txt'));
                    fid = fopen(fname,'w');
                    fprintf(fid,'%s','No clusters detected with your settings.');
                    fclose(fid);
                    clear fname
                else  % clusters detected ... generate a summary
                    for clusterID = 1:length(stats)
                        clusterpoly_tmp = (stats(clusterID,1).ConvexHull)*clusmap_scale;
                        clusterpoly_tmp(:,1) = clusterpoly_tmp(:,1) + strict_region_xmin; % convert polygon image coords to datatable coords
                        clusterpoly_tmp(:,2) = strict_region_ymax - clusterpoly_tmp(:,2); % because image origin is flipped on y axis to the data origin
                        mypoints = inpolygon(ClusteredData(:,2),ClusteredData(:,3),clusterpoly_tmp(:,1),clusterpoly_tmp(:,2));
                        data_region_ch_GF(ClusteredData(mypoints,1),ClusterIDCol) = clusterID;

                        %copy centroids for labelling purposes
                        ClusterCentroids(clusterID,1) = clusterID;
                        ClusterCentroids(clusterID,2:3) = stats(clusterID,1).Centroid ;
                    end
                    % Export ClusterCentroids
                    dlmwrite(fullfile('Numbers\Centroids',strcat(ImgFileName,' Centroids List.txt')),ClusterCentroids,'\t');
                end

            % sanity check here -- demote events and clusters that have
            % fewer than X events or are below a certain size (e.g. 1.1 x
            % strel area). Fill in those clusters in the map.
            
            % Make labelled cluster map in random colours
                ClusterMapRGB = label2rgb(label_clusters,'cool','w','shuffle');
                figure('Color',[1 1 1], 'Visible', 'off', 'Renderer', 'OpenGL', 'Units', 'pixels');
                axes('Parent',figure,'Layer','top', 'YTick',zeros(1,0),'XTick',zeros(1,0),'DataAspectRatio', [1,1,1],'position',[0,0,1,1]);            
                box('off');
                set(gcf, 'PaperUnits', 'inches', 'PaperSize', [10 10], 'PaperPositionMode', 'manual', 'PaperPosition', [0 0 10 10],'Visible','off');
                imagesc(ClusterMapRGB);
                axis square tight image
                set(gca,'XTickLabel','','YTickLabel','','XTick', [],'YTick', [])
                if ~isempty(stats) % clusters detected, label them
                    text(ClusterCentroids(:,2),ClusterCentroids(:,3),num2str(ClusterCentroids(:,1)),'HorizontalAlignment','center','VerticalAlignment','middle');
                end
                SavePNG('Thr-Clusters\Blobs\LabelledMaps',strcat(ImgFileName,' Cluster ID Map'),ProcSet.UseFolders);
                close(gcf);

                ExcelHeaders2{:,length(ExcelHeaders2) + 1} = 'ClusterID';

                clear xMin xMax yMin yMax blob_id2 px_id blob2data blob_id blob_pixels blob_px
                clear IndexAboveThreshold label_clusters label2 ClusterCentroids ClusteredData ClusterMask2 se2 islands ClusterMask
                delete('ClusMaskTmp.png');
                close all
                
                if ProcSet.VerboseUpdates
                    ShowInfoMessage('Finished clusters by blobs.');
                end
            end
            
        %% Save the region data to excel and/or text files

            if ProcSet.SaveXLS == true
                XLSFileName = 'regions';
                SaveClusterResults('xls',XLSFileName,[CurrentTableID CurrentRegionID ChannelID],data_region_ch_GF,Main_Ch_GFCol,ProcSet,ExcelHeaders2);
            end

            if ProcSet.SaveTextFiles == true
                TXTFileName = strcat('T',num2str(CurrentTableID),'R',num2str(CurrentRegionID),'Ch',num2str(ChannelID),'.txt'); %replace .txt with .csv if needed
                SaveClusterResults('txt',TXTFileName,[CurrentTableID CurrentRegionID ChannelID],data_region_ch_GF,Main_Ch_GFCol,ProcSet,ExcelHeaders2);
            end
            
        %% Measure GF relative to a regular xy grid
        
        if ProcSet.DoGridMaps
            
            if ProcSet.VerboseUpdates
                ShowInfoMessage('Starting clusters by GRID...');
            end
            
            if ProcSet.GridMapSpacing < 1
                GridSpacing = ProcSet.SamplingRadius * ProcSet.GridMapSpacing;
            else
                GridSpacing = ProcSet.GridMapSpacing;
            end

            [gridX,gridY] = meshgrid(padded_region_xmin+(GridSpacing/2):GridSpacing:padded_region_xmax-(GridSpacing/2),padded_region_ymin+(GridSpacing/2):GridSpacing:padded_region_ymax-(GridSpacing/2));
            gridXY = [gridX(:), gridY(:)];

            testfn = GF_Measure(gridXY,ProcSet.SamplingRadius,(2 * areaX_padded),(2 * areaY_padded),data_region_ch(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn));
            
            % Normalise baseline to zero -- this removes cases where an isolated data point creates a 'mound' within the grid. 
            lowest_nonzerogf = min(testfn(isfinite(testfn)&(testfn~=0))); % ignores NaNs, Infs and zeros
            testfn(testfn~=0) = testfn(testfn~=0) - lowest_nonzerogf; %Values that are already zero are not modified.
            
            % combine GF values with grid xy coords
            gridXY(:,3) = testfn(:,1); 
            
        %Readjust the grids to match the cropped area
            gridXY = RegionCropper(gridXY, [padded_region_xmin+ProcSet.SamplingRadius padded_region_xmax-ProcSet.SamplingRadius padded_region_ymin+ProcSet.SamplingRadius padded_region_ymax-ProcSet.SamplingRadius], [1 2]);
            gridX(:,find(gridX(1,:)<padded_region_xmin+ProcSet.SamplingRadius | gridX(1,:)>padded_region_xmax-ProcSet.SamplingRadius)) = [];
            gridY(find(gridY(:,1)<padded_region_ymin+ProcSet.SamplingRadius | gridY(:,1)>padded_region_ymax-ProcSet.SamplingRadius),:) = [];
            gridX(size(gridY,1)+1:end,:) = [];
            gridY(:,size(gridX,2)+1:end) = [];
                       
            % plot gf of cropped points
%             scatter(gridXY(:,1),gridXY(:,2), 5, gridXY(:,3),'filled');
%             axis square
%             axis([data_xmin data_xmin+ProcSet.xRegionLength data_ymax-ProcSet.yRegionLength data_ymax])
%             set(gca, 'Visible', 'off'); %hide the axes
%             SaveEPS('GF-Points','GFPoints_GRID',ProcSet.UseFolders); 
%             SavePNG('GF-Points','GFPoints_GRID',ProcSet.UseFolders); 
            
        % transform grid array into a pixel map for contouring
            map = zeros(size(gridX,2),size(gridY,1));
            for px=1:numel(map)
                map(px) = gridXY(px,3);
            end

            if ProcSet.SaveImages
                
                PaperPrintWidth = 10;
                PlotPrintWidth = 10;
                % Generate the plots
                figure('Color','w', 'Visible', 'off', 'Renderer', 'OpenGL', 'Units', 'inches');
                colormap(ProcSet.CustomColorMap);
                % centre the plot axes
                set(gca,'Position',[((PaperPrintWidth-PlotPrintWidth)/2)/PaperPrintWidth ((PaperPrintWidth-PlotPrintWidth)/2)/PaperPrintWidth PlotPrintWidth/PaperPrintWidth PlotPrintWidth/PaperPrintWidth]); % left-edge bottom-edge width height
                set(gca,'DataAspectRatio', [1,1,1]);
                box('off');
                hold('on');
                % specify the "paper size"
                set(gcf, 'PaperUnits', 'inches', ...
                         'PaperSize', [PaperPrintWidth PaperPrintWidth], ...
                         'PaperPositionMode', 'manual', ...
                         'PaperPosition', [0 0 PaperPrintWidth PaperPrintWidth], ...
                         'Visible','off');
                %plot the 3D contour map
                [ContourArray,ContourMap] = contour3(gridX,gridY,map,100);
                caxis([0 ceil(max(gridXY(:,3)))]);
                % fix and tidy the axes
                axis([strict_region_xmin, strict_region_xmax, strict_region_ymin, strict_region_ymax]);   
                axis square image tight
                set(gca, 'Visible','off');

                %Save the 3D Contour Array for later processing
                save(fullfile('FIGs/Grid-maps', strcat(ImgFileName,' 3D Contour Array - GRID.mat')),'ContourArray');

                if ProcSet.UseFolders==true
                    hgsave(fullfile('FIGs/Grid-maps', strcat(ImgFileName,' 3D Contours - GRID.fig')));
                else
                    hgsave(strcat(ImgFileName, ' 3D Contours - GRID.fig'));
                end
                close(gcf)

                %Grid-based cluster map

                if ischar(ProcSet.GridColMapMax)
                    if strcmpi(ProcSet.GridColMapMax,'max')
                        ProcSet.GridColMapMax = max(gridXY(:,3));
                    else
                        CMaxPercent = str2double(ProcSet.ColMapMax(1,4:end));
                        if CMaxPercent > 100
                            ProcSet.GridColMapMax = (CMaxPercent/100) * max(gridXY(:,3));
                        else
                            CMaxSorted = sort(gridXY(:,3));
                            CMaxCount = numel(find(CMaxSorted>0));
                            CMaxTop = ceil(((1-(CMaxPercent/100))*CMaxCount));
                            ProcSet.GridColMapMax = CMaxSorted(length(CMaxSorted)-CMaxTop,1);
                        end
                        clear CMaxPercent CMaxSorted CMaxCount CMaxTop
                    end
                end

                % Generate the plots
                figure('Color','w', 'Visible', 'off', 'Renderer', 'OpenGL', 'Units', 'inches');
                colormap(ProcSet.CustomColorMap);
                % centre the plot axes
                set(gca,'Position',[((PaperPrintWidth-PlotPrintWidth)/2)/PaperPrintWidth ((PaperPrintWidth-PlotPrintWidth)/2)/PaperPrintWidth PlotPrintWidth/PaperPrintWidth PlotPrintWidth/PaperPrintWidth]); % left-edge bottom-edge width height
                set(gca,'DataAspectRatio', [1,1,1]);
                box('off');
                hold('on');
                % specify the "paper size"
                set(gcf, 'PaperUnits', 'inches', ...
                         'PaperSize', [PaperPrintWidth PaperPrintWidth], ...
                         'PaperPositionMode', 'manual', ...
                         'PaperPosition', [0 0 PaperPrintWidth PaperPrintWidth], ...
                         'Visible','off');
                %plot the cluster contour map
                [~,ContourMap] = contourf(gridX,gridY,map,100,'LineColor','none', 'Fill','on');
                caxis([0 ProcSet.GridColMapMax]);
                % fix and tidy the axes
                axis([strict_region_xmin, strict_region_xmax, strict_region_ymin, strict_region_ymax]);   
                axis square image tight
                set(gca, 'Visible','off');

                %Add the xy points
                PlotPoints = plot(data_region_ch_GF(:,ProcSet.xCoordsColumn),data_region_ch_GF(:,ProcSet.yCoordsColumn),'Marker','.','MarkerSize',4,'LineStyle','none','Color',[0 0 0]);

                %Save GRID FIG
                if ProcSet.UseFolders==true
                    hgsave(fullfile('FIGs/Grid-maps', strcat(ImgFileName,' colourmap-GRID.fig')));
                else
                    hgsave(strcat(ImgFileName, ' colourmap-GRID.fig'));
                end

                %Save GRID colourmap               
                if ProcSet.UseFolders==true
                    print('-dpng',strcat('-r',num2str(ProcSet.xRegionLength/10)),fullfile('Colour/Grid-maps',strcat(ImgFileName,' colourmap-GRID.png')));
                else
                    print('-dpng',strcat('-r',num2str(ProcSet.xRegionLength/10)),strcat(ImgFileName,' colourmap-GRID.png'));
                end

                % Hide the molecules for the following figures
                set(PlotPoints,'Visible','off');

                %change the colourmap for clusters and save the PNG
                %Colormap 'c' for clusters
                black=ceil((64/max(gridXY(:,3))*ProcSet.GridBinChangeHIGH));%Find the internal colormap index that matches the cluster threshold.
                a=zeros(black,3); %Black for indices 0 to the threshold point
                b=ones((64-black),3); %White for indicies beyond the threshold point
                c=vertcat(a,b);
                clear a b black
                colormap(c);
                if ProcSet.UseFolders==true
                    print('-dpng',strcat('-r',num2str(ProcSet.xRegionLength/10)),fullfile('Thr-Clusters/Grid-maps',strcat(ImgFileName,' clusters-GRID.png')));
                else
                    print('-dpng',strcat('-r',num2str(ProcSet.xRegionLength/10)),strcat(ImgFileName,' clusters-GRID.png'));
                end

                % Same again for the 'holes' maps, colourmap 'c2' for holes
                black2=ceil((64/max(gridXY(:,3))*ProcSet.GridBinChangeLOW));
                a2=ones(black2,3);
                b2=zeros((64-black2),3);
                c2=vertcat(a2,b2);
                clear a2 b2 black2        
                colormap(c2);
                if ProcSet.UseFolders==true
                    print('-dpng',strcat('-r',num2str(ProcSet.xRegionLength/10)),fullfile('Thr-Holes/Grid-maps',strcat(ImgFileName,' holes-GRID.png')));
                else
                    print('-dpng',strcat('-r',num2str(ProcSet.xRegionLength/10)),strcat(ImgFileName,' holes-GRID.png'));
                end

                %change the colourmap for greyscale and save the PNG
                colormap(gray);
                if ProcSet.UseFolders==true
                    print('-dpng',strcat('-r',num2str(ProcSet.xRegionLength/10)),fullfile('Greyscale/Grid-maps',strcat(ImgFileName,' greyscale-GRID.png')));
                else
                    print('-dpng',strcat('-r',num2str(ProcSet.xRegionLength/10)),strcat(ImgFileName,' greyscale-GRID.png'));
                end

                close(gcf);
            end
            
            if ProcSet.VerboseUpdates
                ShowInfoMessage('Finished clusters by GRID.');
            end
        %END grid-based cluster map  
        end

        %% Interpolate maps
        if ProcSet.SaveImages

        % for the current channel    
            clusmap_data=horzcat(data_region_ch_GF(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn),data_region_ch_GF(:,Main_Ch_GFCol));
            MakeImages(clusmap_data,ImgFileName,[strict_region_xmin strict_region_xmax strict_region_ymin strict_region_ymax],ProcSet);

        %for other channels    
            if exist('data_GF_Ch1','var')
                if ProcSet.SaveImages
                    clusmap_data=horzcat(data_region_ch_GF(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn),data_region_ch_GF(:,GF_Ch1_Col));
                    MakeImages(clusmap_data,strcat(ImgFileName,'vsCh1'),[strict_region_xmin,strict_region_xmax,strict_region_ymin,strict_region_ymax],ProcSet);
                end
                TXTFileName = strcat('T',num2str(CurrentTableID),'R',num2str(CurrentRegionID),'Ch',num2str(ChannelID),'vsCh1.txt');
                SaveClusterResults('txt',TXTFileName,[CurrentTableID CurrentRegionID ChannelID],data_region_ch_GF,GF_Ch1_Col,ProcSet,ExcelHeaders2);
            end

            if exist('data_GF_Ch2','var')
                if ProcSet.SaveImages
                    clusmap_data=horzcat(data_region_ch_GF(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn),data_region_ch_GF(:,GF_Ch2_Col));
                    MakeImages(clusmap_data,strcat(ImgFileName,'vsCh2'),[strict_region_xmin,strict_region_xmax,strict_region_ymin,strict_region_ymax],ProcSet);
                end
                TXTFileName = strcat('T',num2str(CurrentTableID),'R',num2str(CurrentRegionID),'Ch',num2str(ChannelID),'vsCh2.txt');
                SaveClusterResults('txt',TXTFileName,[CurrentTableID CurrentRegionID ChannelID],data_region_ch_GF,GF_Ch2_Col,ProcSet,ExcelHeaders2);
            end

            if exist('data_GF_Ch3','var')
                if ProcSet.SaveImages
                    clusmap_data=horzcat(data_region_ch_GF(:,ProcSet.xCoordsColumn:ProcSet.yCoordsColumn),data_region_ch_GF(:,GF_Ch3_Col));
                    MakeImages(clusmap_data,strcat(ImgFileName,'vsCh3'),[strict_region_xmin,strict_region_xmax,strict_region_ymin,strict_region_ymax],ProcSet);
                end
                TXTFileName = strcat('T',num2str(CurrentTableID),'R',num2str(CurrentRegionID),'Ch',num2str(ChannelID),'vsCh3.txt');
                SaveClusterResults('txt',TXTFileName,[CurrentTableID CurrentRegionID ChannelID],data_region_ch_GF,GF_Ch3_Col,ProcSet,ExcelHeaders2);
            end
		end
    
            % clear tables for the next channel
            % clear data_GF data_region_ch_GF data_GF_Ch1 data_GF_Ch2 data_GF_Ch3 data_region_ch data_region_Ch1 data_region_Ch2 data_region_Ch3 GF_Ch1_Col GF_Ch2_Col GF_Ch3_Col clusmap_data
            
            if NumberOfChannels > 1
                InfoMessage =  [datestr(fix(clock),'HH:MM:SS'),9,'Completed channel ', num2str(ChannelID), ' (of ',num2str(NumberOfChannels),') from Table ',num2str(CurrentTableID),', Region ',num2str(CurrentRegionID),'.'];
                disp(InfoMessage);
            end

            clear clusmap_data data_GF data_GF_Ch1 data_GF_Ch2 data_GF_Ch3 Main_Ch_GFCol GF_Ch1_Col GF_Ch2_Col GF_Ch3_Col ExcelHeaders2 ImgFileName
            clear testfn gridXY gridX gridY map px
            clear data_region_ch data_region_ch_GF data_region_Ch1 data_region_Ch2
        end % ChannelID loop
        
        %Display at completion of all channels in a region
        ThisRegionTimestamp = toc;

        InfoMessage =  [datestr(fix(clock),'HH:MM:SS'),9,'Done Table ',num2str(CurrentTableID),', Region ',num2str(CurrentRegionID),' (Coords line: ', num2str(RegionCounter + ProcSet.SkipToRegionNumber - 1), ').'];
        disp(InfoMessage);
        
        InfoMessage =  [9,9,9,sprintf('%0.2f',((ThisRegionTimestamp - PreviousRegionTimestamp)/60)),' minutes, ',num2str(total_events_region),' events, ',num2str(floor(total_events_region/(ThisRegionTimestamp - PreviousRegionTimestamp))),' events per second.'];
        disp(InfoMessage);
        
        InfoMessage = [9,9,9,num2str(round(RegionCounter / (NumberOfRegions - ProcSet.SkipToRegionNumber + 1) * 100)) '% processed.'];
        disp(InfoMessage);
        
        disp('---------------------------------------------------------');
        
        % Update the tracking info to reflect the newly finished region
        RegionCounter = RegionCounter + 1;
        PreviousRegionTimestamp = ThisRegionTimestamp;
    end
end

%% Finish up

ExecTime=toc;

% Clean up the Excel file to remove empty worksheets
if ProcSet.SaveXLS == true
    excelFileName = strcat(XLSFileName,'.xls');
    excelFilePath = cd; % Current directory.
    % Open Excel file.
    excelObj = actxserver('Excel.Application'); 
    excelWorkbook = excelObj.workbooks.Open(fullfile(excelFilePath, excelFileName));  % Full path is necessary!
    worksheets = excelObj.sheets; 
    sheetIdx = 1; 
    sheetIdx2 = 1; 
    numSheets = worksheets.Count;
    excelObj.EnableSound = false; % Prevent beeps from sounding if we try to delete a non-empty worksheet.
    e.Application.DisplayAlerts = false; % disable alert popups
    
    % Loop over all sheets 
    while sheetIdx2 <= numSheets 
        % Saves the current number of sheets in the workbook 
        temp = worksheets.count; 
        % Check whether the current worksheet is the last one. As there always 
        % need to be at least one worksheet in an xls-file the last sheet must 
        % not be deleted. 
        if sheetIdx > 1 || numSheets-sheetIdx2 > 0
            if worksheets.Item(sheetIdx).UsedRange.Count == 1 % Empty sheet
                worksheets.Item(sheetIdx).Delete; 
            end
        end 

        if temp == worksheets.count; 
            sheetIdx = sheetIdx + 1; 
        end

        sheetIdx2 = sheetIdx2 + 1;
    end

    excelObj.EnableSound = true;
    e.Application.DisplayAlerts = true; % enable alert popups
    excelWorkbook.Save; 
    excelWorkbook.Close(false); 
    excelObj.Quit; 
    delete(excelObj);
    clear worksheets
end

InfoMessage=[datestr(fix(clock),'HH:MM:SS'),9,'Finished processing ' num2str(NumberOfRegions - ProcSet.SkipToRegionNumber + 1) ' regions across ' num2str(TotalNumberofDataTables - StartingTable + 1) ' data tables.'];
disp(InfoMessage);

InfoMessage=[9,9,9,'Total time: ' sprintf('%0.2f',(ExecTime/60)) ' minutes.'];
disp(InfoMessage);

InfoMessage=[9,9,9,'Average time: ' sprintf('%0.2f',(ExecTime/60)/(NumberOfRegions - ProcSet.SkipToRegionNumber + 1)) ' minutes per region.'];
disp(InfoMessage);

disp('---------------------------------------------------------');

clear InfoMessage

% Email the user
if isfield(ProcSet,'EmailMeAt') && ~strcmp(ProcSet.EmailMeAt,'')
    ProcessingDone(ProcSet.EmailMeAt,'Processing Complete!','Your cluster analysis processing has completed. Do not reply to this email because Dave won''t care.')
end

if ~ProcSet.IAmBoring
    %Play a triumphant sound at completion
    MonkeyLuck = randi(10,1);
    if MonkeyLuck == 1
        AllDoneSoundFileName='tada2.wav';
    else
        AllDoneSoundFileName='tada.wav';
    end
    [AllDoneSnd,AllDoneSndfs] = audioread(AllDoneSoundFileName);
    sound(AllDoneSnd,AllDoneSndfs);
    clear MonkeyLuck
    hellokitten()
end