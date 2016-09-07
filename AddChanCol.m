%% AddChanCol - v1.1

% Variables you can edit:

    IgnoreFilesNamedWith = {'RegionCropped','Centroids','Summary','vsCh'};
    TargetFileExt = {'.txt','.csv'};

    CleanUpNames = true;    % remove channel IDs (e.g. 'C=0') and file-format names (e.g. '.nd2') from the saved files' names.

    LetMePickOutputFolder = true;            % You will be asked to pick a third folder to save the combined tables. Set to false to auto-create an output folder inside the current folder.
    AutoOutputFolderName = 'CombinedTables'; % What should the auto-created output folder be called?

    PrepForCF = true;

%% Select Channel 1 Folder
dirNameCh1 = uigetdir(pwd,'Choose the folder containing the first channel data tables');

if dirNameCh1 ~=0
    cd(dirNameCh1);
        % get list of txt files
        dirData = dir;                              % Get the data for the current directory
        dirIndex = [dirData.isdir];                 % Find the index for directories
        Ch1FileList = {dirData(~dirIndex).name}';   % Get a list of the files
       
        IgnoredFiles = [];                              % Make a list of 'bad' files
        for f = 1:length(Ch1FileList)
            [~, fname, ext] = fileparts(Ch1FileList{f,1});
            
            if isempty(find(ismember(TargetFileExt,ext),1));
                IgnoredFiles(end+1,1) = f;
            end
            
            for badname = 1:size(IgnoreFilesNamedWith,2)
                if ~isempty(strfind(fname,IgnoreFilesNamedWith{badname}))
                    IgnoredFiles(end+1,1) = f;
                    break
                end
            end
        end
        Ch1FileList(IgnoredFiles) = [];
        Ch1FileList = sort_nat(Ch1FileList);
        % Add a check for 'purity'?
        clear TXTFileExt badFiles dirData dirIndex ext f fname
        cd('..')
else
    error('Cancelled?! So rude.');
end

%% Select Channel 2 Folder
dirNameCh2 = uigetdir(pwd,'Choose the folder containing the second channel data tables');

if dirNameCh2 ~=0
    cd(dirNameCh2);
        % get list of txt files
        dirData = dir;                              % Get the data for the current directory
        dirIndex = [dirData.isdir];                 % Find the index for directories
        Ch2FileList = {dirData(~dirIndex).name}';   % Get a list of the files
       
        IgnoredFiles = [];                              % Make a list of 'bad' files
        for f = 1:length(Ch2FileList)
            [~, fname, ext] = fileparts(Ch2FileList{f,1});
            
            if isempty(find(ismember(TargetFileExt,ext),1));
                IgnoredFiles(end+1,1) = f;
            end
            
            for badname = 1:size(IgnoreFilesNamedWith,2)
                if ~isempty(strfind(fname,IgnoreFilesNamedWith{badname}))
                    IgnoredFiles(end+1,1) = f;
                    break
                end
            end
        end
        Ch2FileList(IgnoredFiles) = [];
        Ch2FileList = sort_nat(Ch2FileList);
        % Add a check for 'purity'?
        clear TXTFileExt badFiles dirData dirIndex ext f fname
        cd('..')
else
    error('Cancelled?! So rude.');
end

if size(Ch1FileList,1)~=size(Ch2FileList,1)
    error('You seem to have more files in one folder than the other. Please remove unnecessary files.');
end

    InfoMsg = ['Channel ID columns will be added to ',num2str(2*size(Ch1FileList,1)),' files.'];
    disp(InfoMsg);

%% Select Output Folder
if LetMePickOutputFolder
    dirNameOutput = uigetdir(pwd,'Choose the folder where you would like to save the output data tables...');
else
    if ~isdir(AutoOutputFolderName)
        mkdir(AutoOutputFolderName);
    end
    dirNameOutput = fullfile(cd,AutoOutputFolderName);
end
    
    InfoMsg = ['New files will be saved to ',dirNameOutput];
    disp(InfoMsg);

%% Process each file with its partner from the other folder

for t = 1:size(Ch1FileList,1)
    % Open Ch 1
    CurrentCh1file  = Ch1FileList{t,1};
    Ch1_import = importdata(fullfile(dirNameCh1,CurrentCh1file));
    
    if ~isstruct(Ch1_import)
        Ch1_import_tmp = struct;
        Ch1_import_tmp.data = Ch1_import;
        Ch1_import_tmp.colheaders = cell(1,size(Ch1_import,2));
        Ch1_import_tmp.colheaders(1,1:end) = {'data'};
        Ch1_import = Ch1_import_tmp;
        clear Ch1_import_tmp
    end
   
    
    Ch1_import.data(:,end+1) = 1;
    Ch1_import.colheaders{1,end+1} = 'ChannelID';
    
    CurrentCh2file  = Ch2FileList{t,1};
    Ch2_import = importdata(fullfile(dirNameCh2,CurrentCh2file));
    if ~isstruct(Ch2_import)
        Ch2_import_tmp = struct;
        Ch2_import_tmp.data = Ch2_import;
        Ch2_import_tmp.colheaders = cell(1,size(Ch2_import,2));
        Ch2_import_tmp.colheaders(1,1:end) = {'data'};
        Ch2_import = Ch2_import_tmp;
        clear Ch2_import_tmp
    end
    Ch2_import.data(:,end+1) = 2;
    Ch2_import.colheaders{1,end+1} = 'ChannelID';
    
    data_concat = vertcat(Ch1_import.data,Ch2_import.data);
    
    InfoMsg = ['Stacking channel-pair ',num2str(t),' of ',num2str(size(Ch1FileList,1))];
    disp(InfoMsg);
    
    % Determine names of things
    [~, SaveTXTFileName, SaveTXTFileExt] = fileparts(CurrentCh1file);
    
    % delete channel identifiers from the file name
    % Removes 'C=0','Ch1', 'Ch 2', and unnecessary format extensions from
    % the file name
    if CleanUpNames
        CleanedFileName = regexprep(SaveTXTFileName,'(C(.?=.?[0-9]|h.?[0-9]).?)|\.(nd2|las|csv|txt|tif)','','ignorecase');
    else
        CleanedFileName = SaveTXTFileName;
    end
    if PrepForCF
        SaveFileName = [num2str(t),SaveTXTFileExt];
    else
        SaveFileName = [CleanedFileName,' - with ChanIDs',SaveTXTFileExt];
    end
    InfoMsg = [9,'Saving to new file: ''',SaveFileName,'''...'];
    disp(InfoMsg);
    
    % open the text file
    fid = fopen(fullfile(dirNameOutput,SaveFileName),'w');

    % build strings to match the format of the output headers and data
        HeaderFormat = '%s';
        DataFormat = '%f'; % data as floating to 6 decimal places %06.0f

        for g = 1:(size(Ch1_import.data,2)-1)
            if strcmp(SaveTXTFileExt,'.txt')
                HeaderFormat = strcat(HeaderFormat,'\t%s'); % replace \t with a comma for csv
                DataFormat = strcat(DataFormat,'\t%f');
            elseif strcmp(SaveTXTFileExt,'.csv')
                HeaderFormat = strcat(HeaderFormat,',%s'); % replace \t with a comma for csv
                DataFormat = strcat(DataFormat,',%f');
            end

        end

        %last column is always ChanID and should be an integer
        if strcmp(SaveTXTFileExt,'.txt')
            DataFormat = strcat(DataFormat,'\t%d'); 
        elseif strcmp(SaveTXTFileExt,'.csv')
            DataFormat = strcat(DataFormat,',%d');
        end
    
    % build the output headers
    if isfield(Ch1_import,'colheaders')
      
        OutputHeaders = Ch1_import.colheaders;

    else % Table is missing header information so we will create default headers to match the expectations of downstream functions.
        disp('[ ! ] You are missing headers or have a different number of headers than data columns; using default headers for pooled tables.');
        HeaderLength = size(Ch1_import.data,2);
        OutputHeaders = cell(1,HeaderLength);
        OutputHeaders(:) = {'Data'};
    end
    
    % write the headers and newline to the output file
    fprintf(fid,HeaderFormat,OutputHeaders{:});
    fprintf(fid,'\r\n');

%     % append the data table
%     
%     if strcmp(SaveTXTFileExt,'.txt')
%        dlmwrite(fullfile(dirNameOutput,SaveFileName),data_concat,'-append','delimiter','\t');
%     elseif strcmp(SaveTXTFileExt,'.csv')
%        dlmwrite(fullfile(dirNameOutput,SaveFileName),data_concat,'-append','delimiter',',');
%     end
%     
%     clear data_concat

    for d = 1:size(data_concat,1)
        fprintf(fid,DataFormat,data_concat(d,:));
        fprintf(fid,'\r\n');
    end
    fid = fclose(fid);

    ChanColInfoMsg = [9,'File saved. The channel ID for this file is in column ',num2str(size(Ch1_import.colheaders,2)),'.'];
    disp(ChanColInfoMsg);
     
end

% Finished!
disp('');
InfoMsg = ['[ Done! ]'];
disp(InfoMsg);