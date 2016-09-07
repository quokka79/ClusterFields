% Randomise Regions
rng('shuffle')  % set the random seed

% Default number of repeats
CSRRepeats = 1;

% Select the coords file
[FileNameCoords,dirName] = uigetfile({'*coords*.txt*';'*.txt*';'*.*'},'Choose your coordinates file');
if dirName ~=0
    cd(dirName);
    coordinates=dlmread(FileNameCoords, '\t', 0,1); %read in the file, tab-delimited, ignoring the first column (which contains user notes and comments)

    % open the file containing ProcSettings
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
        TXTfileList = sort_nat(TXTfileList);
        clear TXTFileExt badFiles dirData dirIndex ext f fname
        cd(dirName)
    else
        error('This folder doesn''t contain a ''Numbers'' folder!');
    end
    
    % find number of channels
    for f = 1:length(TXTfileList)
        FilesTmp(f,:) = str2double(strsplit(TXTfileList{f,1},{'T','R','Ch','.txt'},'CollapseDelimiters',true));
    end
    
    TotalSourceImages = max(FilesTmp(:,2));
    TotalSourceRegions = size(coordinates,1);
    NumChannels = max(FilesTmp(:,4));
    TotalRegions=TotalSourceRegions*NumChannels;
    
    if NumChannels > 1
%         coords2 = zeros(TotalRegions,size(coordinates,2));
%         for ch = 1:NumChannels
%             coords2(ch:NumChannels:TotalRegions,:) = coordinates;
%         end
%         coordinates = coords2;
        SamplingRadius = ProcSettings.BiVarSamplingRadius;
    else
        SamplingRadius = ProcSettings.SamplingRadius;
    end
    
    clear f ch coords2
    
else
    error('Cancelled?! So rude.');
end

% % Double-check settings
% prompt = {'CSR Repeats:'};
% dlg_title = 'Enter the settings to use...';
% num_lines = 1;
% def = {num2str(CSRRepeats)};
% answer = inputdlg(prompt,dlg_title,num_lines,def);
% 
% if ~isempty(answer)
%     CSRRepeats = str2double(answer(1,1));
% else
%     error('Cancelled?! So rude.');
% end

% fix any scaling issues
if ProcSettings.CoordsTableScale ~= 1
    coordinates(:,2:3) = round(coordinates(:,2:3) * ProcSettings.CoordsTableScale);
end

%Build output dirs
rand_dirname = ['v2-Randomised-',datestr(fix(clock),'yyyymmdd@HHMMSS')];

% alphanums = ['a':'z' 'A':'Z' '0':'9'];
% randname = alphanums(randi(numel(alphanums),[1 5]));
% foldername = ['v2-Randomised (x',num2str(CSRRepeats),')_',randname];
mkdir(fullfile(dirName,rand_dirname));
% cd(fullfile(dirName,rand_dirname));


% Do the randomising, recombining each region into a new 'big' table
cd(fullfile(dirName,'Numbers/RegionTables'));

for s=1:TotalSourceImages
    CurrentTextStr = ['Randomising: ',num2str(s),' of ',num2str(TotalSourceImages),'.']; % , round ',num2str(r),' of ',num2str(CSRRepeats),').'];
    disp(CurrentTextStr);

    SourceCoords = coordinates(coordinates(:,1)==s,2:3);

    for n = 1:NumChannels
        SourceFiles(:,n) = TXTfileList((FilesTmp(:,2)==s & FilesTmp(:,4)==n));
    end

    TableOutFileName = [num2str(s),'.txt'];

    RandTableOut_Collector = [];
    
    for r=1:size(SourceFiles,1)
        
        region_xmin = SourceCoords(r,1) - (ProcSettings.xRegionLength / 2);
        region_xmax = SourceCoords(r,1) + (ProcSettings.xRegionLength / 2);
        region_ymin = SourceCoords(r,2) - (ProcSettings.yRegionLength / 2);
        region_ymax = SourceCoords(r,2) + (ProcSettings.yRegionLength / 2);
        
        switch NumChannels
            case 1
                data_region_ch1 = importdata(SourceFiles{r,1});
                
            case 2
                data_region_ch1 = importdata(SourceFiles{r,1});
                data_region_ch2 = importdata(SourceFiles{r,2});
                
                randomised_Ch1 = MessMeUp(data_region_ch1.data, [region_xmin region_xmax region_ymin region_ymax], SamplingRadius, ProcSettings);
                randomised_Ch2 = MessMeUp(data_region_ch2.data, [region_xmin region_xmax region_ymin region_ymax], SamplingRadius, ProcSettings);
                
                RandTableOut_Collector = vertcat(RandTableOut_Collector,randomised_Ch1,randomised_Ch2);
            
            case 3
                data_region_ch1 = importdata(SourceFiles{r,1});
                data_region_ch2 = importdata(SourceFiles{r,2});
                data_region_ch3 = importdata(SourceFiles{r,3});
                
                randomised_Ch1 = MessMeUp(data_region_ch1.data, [region_xmin region_xmax region_ymin region_ymax], SamplingRadius, ProcSettings);
                randomised_Ch2 = MessMeUp(data_region_ch2.data, [region_xmin region_xmax region_ymin region_ymax], SamplingRadius, ProcSettings);
                randomised_Ch3 = MessMeUp(data_region_ch3.data, [region_xmin region_xmax region_ymin region_ymax], SamplingRadius, ProcSettings);
                
                RandTableOut_Collector = vertcat(RandTableOut_Collector,randomised_Ch1,randomised_Ch2,randomised_Ch3);

            otherwise
                disp('too many channels!');
        end

    end
    clear SourceFiles SourceCoords
    % Save the randomised data table    
    OutputName = fullfile(dirName,rand_dirname,TableOutFileName);
    fid = fopen(OutputName,'w');
    HeaderLength = size(data_region_ch1.colheaders,2);
    HeaderFormat = '%s\t';
    for h=1:HeaderLength-1
        HeaderFormat = [HeaderFormat,'%s\t'];
    end
    fprintf(fid,[HeaderFormat,'\r\n'],data_region_ch1.colheaders{:});
    fclose(fid);
    dlmwrite(OutputName,RandTableOut_Collector,'-append','delimiter','\t','precision','%.1f');

end

copyfile(fullfile(dirName,FileNameCoords),fullfile(dirName,rand_dirname,FileNameCoords));
copyfile(fullfile(dirName,'ProcSettings.txt'),fullfile(dirName,rand_dirname,'ProcSettings.txt'));


%     for r = 1:CSRRepeats
%         
%     
%         RandomisedTXTFileName = fullfile('Numbers', strcat(SaveTXTFileName{1,1}, ' - Randomised-',num2str(r),'.txt'));      

cd(fullfile(dirName,rand_dirname));
AllDoneMsg = 'All done! Don''t forget to update ProcSettings with values to match the new data...';
disp(AllDoneMsg);