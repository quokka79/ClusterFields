%%
%{

Reprocess MATLAB cluster map FIG files to adjust threshold and cmap max
without reanalysing the entire set of raw data from scratch.

%}

%% Begin!

% Select the coords file
    [FileNameCoords,dirName] = uigetfile({'*coords*.txt*';'*.txt*';'*.*'},'Choose your coordinates file');

if dirName ~=0

    cd(dirName);
    coordinates=dlmread(FileNameCoords, '\t', 0,1); %read in the file, tab-delimited, ignoring the first column (which contains user notes and comments)

% open the file containing procsettings
    if exist(fullfile(cd, 'ProcSettings.txt'), 'file') == 0
        error('Cannot find ''ProcSettings.txt'' file for your data. You''ll need one to proceed. Example files are in the ''Templates'' folder.');
    else
        ProcSettings = LoadProcSettings;
    end

    % Get list of data table files
    if isdir([dirName,'/Numbers/RegionTables'])
        cd('Numbers/RegionTables')
        TXTFileExt = {'.txt'};
        % get list of txt files
        dirData = dir;                              % Get the data for the current directory
        dirIndex = [dirData.isdir];                 % Find the index for directories
        TXTfileList = {dirData(~dirIndex).name}';   % Get a list of the files

        badFiles = [];                              % Make a list of 'bad' files
        for f = 1:length(TXTfileList)
            [~, fname, ext] = fileparts(TXTfileList{f,1});
            if ~strcmp(ext,TXTFileExt{1,1})
                badFiles(end+1,1) = f;
            end
            if ~isempty(strfind(fname,'Centroids')) || ~isempty(strfind(fname,'Summary')) || ~isempty(strfind(fname,'vsCh')) || ~isempty(strfind(fname,'RegionCropped'))
                badFiles(end+1,1) = f;
            end
        end
        TXTfileList(badFiles) = [];
        clear TXTFileExt badFiles dirData dirIndex ext f fname
        cd(dirName)
    else
        errordlg('This folder doesn''t contain a ''Numbers'' folder!');
    end
    
    NumberOfRegions=size(coordinates,1); 
        
else
    error('Cancelled?! So rude.');
end

%%    
%     % Get list of FIG files
%     if isdir([dirName,'/FIGs'])
%         cd('FIGs')
%         FIGFileExt = {'.fig'};
%         % get list of FIG files
%         dirData = dir;                              % Get the data for the current directory
%         dirIndex = [dirData.isdir];                 % Find the index for directories
%         FIGfileList = {dirData(~dirIndex).name}';   % Get a list of the files
% 
%         badFiles = [];                              % Make a list of 'bad' files
%         for f = 1:length(FIGfileList)
%             [~, fname, ext] = fileparts(FIGfileList{f,1});
%             if ~strcmp(ext,FIGFileExt{1,1})
%                 badFiles(end+1,1) = f;
%             end
%             if ~isempty(strfind(fname,'GRID')) || ~isempty(strfind(fname,'3D Contours')) || ~isempty(strfind(fname,'G&F'))
%                 badFiles(end+1,1) = f;
%             end
%         end
%         FIGfileList(badFiles) = [];
%         clear FIGFileExt badFiles dirData dirIndex ext f fname
%         cd(dirName)
%     else
%         errordlg('This folder doesn''t contain a FIGs folder!');
%     end
    

NewColMapMax = ProcSettings.ColMapMax;
NewThresholdHIGH = ProcSettings.BinaryChangeHIGH;
NewThresholdLOW = ProcSettings.BinaryChangeLOW;
GFcol = 11;
ThresholdMap_Bright = [0,0,0];
ThresholdMap_Dark = [1,1,1];
ThresholdImageBG = [0,0,1];
% NewColourmap = jet;

prompt = {'Colourmap Max:','Threshold (Clusters):','Threshold (Holes):','G&F L(r) Values in Column:','Above Threshold Colour (RGB):','Below Threshold Colour (RGB):','Threshold Background (RGB):'};
dlg_title = 'Enter the NEW settings to apply...';
num_lines = 1;
defaults = {num2str(NewColMapMax),num2str(NewThresholdHIGH),num2str(NewThresholdLOW),num2str(GFcol),num2str(ThresholdMap_Bright),num2str(ThresholdMap_Dark),num2str(ThresholdImageBG)};
answer = inputdlg(prompt,dlg_title,num_lines,defaults);

if ~isempty(answer)
    NewColMapMax = str2double(answer(1,1));
    NewThresholdHIGH = str2double(answer(2,1));
    NewThresholdLOW = str2double(answer(3,1));
    GFcol = str2double(answer(4,1));
    ThresholdMap_Dark = str2num([answer{5,1}]);
    ThresholdMap_Bright = str2num([answer{6,1}]);
    ThresholdImageBG = str2num([answer{7,1}]);
else
error('Cancelled?! So rude.');
end

% Create a new unique folder to save the reprocessed output files.
timestamp = ['REPROC-CMax',num2str(NewColMapMax),'-Thr',num2str(NewThresholdHIGH),'-',datestr(fix(clock),'yyyymmdd@HHMMSS')];

mkdir(timestamp);
cd(timestamp);
mkdir('Thr-Clusters');
mkdir('Thr-Holes');
mkdir('Colour');
mkdir('FIGs');
mkdir('Numbers');
mkdir('Thr-Points');

data_import = struct;
fig_zdata = cell(1,size(TXTfileList,1));

% Reprocess text files first
if size(TXTfileList,1) > 0
    for t = 1:size(TXTfileList,1)
        CurrentTXTfile  = TXTfileList{t,1};
        SaveTXTFileName = strsplit(CurrentTXTfile,'.txt');
        CurrentTextStr = ['Recalculating summary for: ',SaveTXTFileName{1,1},' (',num2str(t),' of ',num2str(size(TXTfileList,1)),').'];
        disp(CurrentTextStr);

        SaveTXTFileName = fullfile('Numbers', strcat(SaveTXTFileName{1,1}, '-Summary_reproc.txt'));

        % [data_import.data,data_import.delimiter,data_import.headers] = importdata(['../Numbers/RegionTables',CurrentTXTfile]);
        cd(dirName)
        data_import = importdata(fullfile('Numbers/RegionTables/',CurrentTXTfile));
        cd(timestamp);

        fig_zdata{:,t} = data_import.data(:,GFcol);

        abovethresh=sum(data_import.data(:,GFcol)>=NewThresholdHIGH);
        numtotal=size(data_import.data,1);
        percentabove=abovethresh/numtotal*100;

        results=[{'Data Reprocessed from:'},dirName;
            {''},{''};
            {'Events in clusters'},num2str(abovethresh);
            {'Total number of events'},num2str(numtotal);
            {'Percent of events in clusters'},num2str(percentabove);
            {'Max colour scale'},num2str(NewColMapMax);
            {'Reprocessed Binary change value high'},num2str(NewThresholdHIGH)];

        fid = fopen(SaveTXTFileName,'w');
        for row = 1:size(results,1)
            fprintf(fid,'%s\t%s\r\n',results{row,:});
        end
        fid = fclose(fid);
    end

else
    disp('There were no useable text files found. Text file processing will be skipped.');
end

%% Reprocess images based on coords list
for c = 1:size(coordinates,1)
    
    %Do normal colourmaps
    if ProcSettings.DoInterpMaps
        
    end
    
    %Do GRID colourmaps
    if ProcSettings.DoGridMaps
        %Get GRID Figs
        subfolderName = '/FIGs/Grid-Maps';
        
        if isdir([dirName,subfolderName])
            cd([dirName,subfolderName])
            FIGFileExt = {'.fig'};
            % get list of FIG files
            dirData = dir;                              % Get the data for the current directory
            dirIndex = [dirData.isdir];                 % Find the index for directories
            FIGfileList = {dirData(~dirIndex).name}';   % Get a list of the files

            badFiles = [];                              % Make a list of 'bad' files
            for f = 1:length(FIGfileList)
                [~, fname, ext] = fileparts(FIGfileList{f,1});
                if ~strcmp(ext,FIGFileExt{1,1})
                    badFiles(end+1,1) = f;
                end
                if ~isempty(strfind(fname,'3D Contours')) || ~isempty(strfind(fname,'G&F'))
                    badFiles(end+1,1) = f;
                end
            end
            FIGfileList(badFiles) = [];
            clear FIGFileExt badFiles dirData dirIndex ext f fname
            cd(dirName)
        else
            errordlg('This folder doesn''t contain a FIGs folder!');
        end
        
        for f = 1:size(FIGfileList,1)
            
            %open the file
            CurrentFIGfile  = FIGfileList{f,1};
            inputFIG = open(fullfile(dirName,subfolderName,CurrentFIGfile));
            set(gcf,'Visible','on');
            
            % Get information
            SaveFileNameParts = strsplit(CurrentFIGfile,{' colourmap','-','.fig'},'CollapseDelimiters',true);
            AxisLimits = [coordinates(f,2)-(ProcSettings.xRegionLength/2)...
                          coordinates(f,2)+(ProcSettings.xRegionLength/2)...
                          coordinates(f,3)-(ProcSettings.yRegionLength/2)...
                          coordinates(f,3)+(ProcSettings.yRegionLength/2)];
            SaveHighDPI = strcat('-r',num2str(ProcSettings.xRegionLength / 10));
            
            CurrentImageStr = ['Applying new threshold to GRID data for: ',SaveFileNameParts{1,1},' (',num2str(f),' of ',num2str(size(FIGfileList,1)),').'];
            disp(CurrentImageStr);

            % Apply the new Colour Map Max
            caxis([0 NewColMapMax]);

            % Save the file
            if size(SaveFileNameParts,2) == 3
                ColourFileName = [SaveFileNameParts{1,1},' colourmap-',SaveFileNameParts{1,2}];
            else
                ColourFileName = [SaveFileNameParts{1,1},' colourmap'];
            end
            hgsave(fullfile('FIGs', strcat(ColourFileName,'_reproc.fig')));
            print('-dpng',SaveHighDPI,fullfile('Colour', strcat(ColourFileName, '_reproc.png')));
            
            % Get handles
            inputFIGcontours = findobj(inputFIG,'Type','patch'); %find the points (lineseries data type) in the figure file.
            inputFIGpoints = findobj(inputFIG,'Type','line'); %find the points (lineseries data type) in the figure file.
            
        % Change the threshold
            
            % Hide points
            if ~isempty(inputFIGpoints)
                set(inputFIGpoints,'visible','off');
            end

            % Show contours
            if ~isempty(inputFIGcontours)
                set(inputFIGcontours,'visible','on');
            end
           
            % Calc new threshold value
            NewThresholdHIGHMap = zeros(64,3);
            CMapThresholdIdx = round(64 * (NewThresholdHIGH / NewColMapMax));

            for c_ind = 1:CMapThresholdIdx
                NewThresholdHIGHMap(c_ind,:) = ThresholdMap_Dark;
            end

            for c_ind2 = CMapThresholdIdx+1:64
                NewThresholdHIGHMap(c_ind2,:) = ThresholdMap_Bright;
            end

            colormap(NewThresholdHIGHMap);

            %Save New Threshold HIGH Image
            if size(SaveFileNameParts,2) == 3
                ThrFileName = [SaveFileNameParts{1,1},' Clusters-',SaveFileNameParts{1,2}];
            else
                ThrFileName = [SaveFileNameParts{1,1},' Clusters'];
            end
            print('-dpng',SaveHighDPI,fullfile('Thr-Clusters', strcat(ThrFileName, '_reproc.png')));

            
        end
        
        
        
    end
    
    
    %Do Blobs maps
    if ProcSettings.DoClustersByBlobs
        
    end
    
end


%% Reprocess the images using the FIG files
if size(FIGfileList,1) > 0
    for f = 1:size(FIGfileList,1)
        CurrentFIGfile  = FIGfileList{f,1};
        inputFIG = open(['../FIGs/',CurrentFIGfile]);
        set(gcf,'Visible','on');

    % Get information
        SaveFileNameParts = strsplit(CurrentFIGfile,{' colourmap','-','.fig'},'CollapseDelimiters',true);
        AxisLimits = [get(gca,'XLim') get(gca,'YLim')];

        CurrentImageStr = ['Applying new threshold to: ',SaveFileNameParts{1,1},SaveFileNameParts{1,2},' (',num2str(f),' of ',num2str(size(FIGfileList,1)),').'];
        disp(CurrentImageStr);

        %Get the width to the nearest 1000th of the plot to mangle for 1 px/nm
%          PlotWidth = round(((AxisLimits(2) - AxisLimits(1))/1000))*1000;
        SaveHighDPI = strcat('-r',num2str(ProcSettings.xRegionLength / 10));

    % Change colormap limits
        caxis([0 NewColMapMax]);
        if size(SaveFileNameParts,2) == 3
            ColourFileName = [SaveFileNameParts{1,1},' colourmap-',SaveFileNameParts{1,2}];
        else
            ColourFileName = [SaveFileNameParts{1,1},' colourmap'];
        end
        hgsave(fullfile('FIGs', strcat(ColourFileName,'_reproc.fig')));
        print('-dpng',SaveHighDPI,fullfile('Colour', strcat(ColourFileName, '_reproc.png')));

    % % Change colormap
    %     if exist('NewColourmap','var')
    %         colormap(NewColourmap)
    %     end

    %% Get handles
        inputFIGcontours = findobj(inputFIG,'Type','patch'); %find the points (lineseries data type) in the figure file.
        inputFIGpoints = findobj(inputFIG,'Type','line'); %find the points (lineseries data type) in the figure file.

    %% Change Threshold
        if ~isempty(inputFIGpoints)
            set(inputFIGpoints,'visible','off');
        end

        if ~isempty(inputFIGcontours)
            set(inputFIGcontours,'visible','on');
        end

    % Change Threshold for Clusters
        NewThresholdHIGHMap = zeros(64,3);
        CMapThresholdIdx = round(64 * (NewThresholdHIGH / NewColMapMax));

        for c_ind = 1:CMapThresholdIdx
            NewThresholdHIGHMap(c_ind,:) = ThresholdMap_Dark;
        end

        for c_ind2 = CMapThresholdIdx+1:64
            NewThresholdHIGHMap(c_ind2,:) = ThresholdMap_Bright;
        end

        colormap(NewThresholdHIGHMap);

    %Save New Threshold HIGH Image
        if size(SaveFileNameParts,2) == 3
            ThrFileName = [SaveFileNameParts{1,1},' Clusters-',SaveFileNameParts{1,2}];
        else
            ThrFileName = [SaveFileNameParts{1,1},' Clusters'];
        end
        print('-dpng',SaveHighDPI,fullfile('Thr-Clusters', strcat(ThrFileName, '_reproc.png')));

    % Change Threshold for Holes
        NewThresholdLOWMap = zeros(64,3);
        CMapThresholdIdx = round(64 * (NewThresholdLOW / NewColMapMax));

        for c_ind = 1:CMapThresholdIdx
            NewThresholdLOWMap(c_ind,:) = ThresholdMap_Bright;
        end

        for c_ind2 = CMapThresholdIdx+1:64
            NewThresholdLOWMap(c_ind2,:) = ThresholdMap_Dark;
        end

        colormap(NewThresholdLOWMap);

    %Save New Threshold LOW Image
        if size(SaveFileNameParts,2) == 3
            ThrFileName = [SaveFileNameParts{1,1},' Holes-',SaveFileNameParts{1,2}];
        else
            ThrFileName = [SaveFileNameParts{1,1},' Holes'];
        end
        print('-dpng',SaveHighDPI,fullfile('Thr-Holes', strcat(ThrFileName, '_reproc.png')));

    %% Colour points by threshold

    % Get source data for replotting
        if ~isempty(inputFIGpoints)
            fig_xaxis = get(inputFIGpoints,'XLim'); % get the x axis limits
            fig_xdata = get(inputFIGpoints,'XData')'; %copy the x coords
            fig_ydata = get(inputFIGpoints,'YData')'; %copy the y coords
    %         fig_zdata = get(inputFIGpoints,'ZData')'; %copy the z coords (G&F values)
        end

    % Done with this figure for now
        close(gcf);

        if size(fig_xdata,1) ~= size(fig_zdata{:,f},1)
            error('Data problemo. Make a sad face.');
        end

    % Do a scatterplot
    figure('Color','w', 'visible', 'on', 'Renderer', 'OpenGL', 'Units', 'pixels'); %painters?
    set(gca,'Units','inches');
    set(gca,'DataAspectRatio', [1,1,1],'Position', [1 1 10 10]);    
    box('off');
    hold('on');

    %define the 'paper' dimensions
    set(gcf, 'PaperUnits', 'inches', 'PaperSize', [12 12], 'PaperPositionMode', 'manual', 'PaperPosition', [0 0 12 12]);

    scatter(fig_xdata,fig_ydata,4,fig_zdata{:,f},'fill');
    axis(AxisLimits);
    axis square image tight
    set(gca,'color',ThresholdImageBG);
    set(gcf,'color',ThresholdImageBG);
    set(gca, 'Visible','off');
    caxis([0 NewColMapMax]);
    colormap(NewThresholdHIGHMap);
    set(gcf, 'InvertHardCopy', 'off'); % This stops MATLAB setting a white background

    %write to a temp image
    print('-dpng',SaveHighDPI,'tmp_precrop_Points.png');

    %load the temp image
    PointsTMP = imread('tmp_precrop_Points.png');

    %crop the temp image
    CropStripWidth = round(PlotWidth / 10);
    CroppedPointsTMP = PointsTMP(1+CropStripWidth:(end-CropStripWidth),1+CropStripWidth:(end-CropStripWidth),:);

    if size(SaveFileNameParts,2) == 3
        ThrPtsFileName = [SaveFileNameParts{1,1},' ThrPoints-',SaveFileNameParts{1,2}];
    else
        ThrPtsFileName = [SaveFileNameParts{1,1},' ThrPoints'];
    end

    imwrite(CroppedPointsTMP,fullfile('Thr-Points', strcat(ThrPtsFileName, '_reproc.png')),'png');

    delete('tmp_precrop_Points.png');
    close(gcf);


    end
else
    disp('No useable figure files found. Skipping.');
end

cd('..');
AllDoneMsg = 'All done!';
disp(AllDoneMsg);
