% Randomise Regions
rng('shuffle')  % set the random seed

% Default number of repeats
CSRRepeats = 2;

% Select the coords file
[FileNameCoords,dirName] = uigetfile({'*.txt*';'*.*'},'Choose your coordinates file');
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
    if isdir([dirName,'/Numbers'])
        cd('Numbers')
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
            if ~isempty(strfind(fname,'Centroids')) || ~isempty(strfind(fname,'Summary')) || ~isempty(strfind(fname,'vsCh'))
                badFiles(end+1,1) = f;
            end
        end
        TXTfileList(badFiles) = [];
        TXTfileList = sort_nat(TXTfileList);
        clear TXTFileExt badFiles dirData dirIndex ext f fname
        cd('..')
    else
        error('This folder doesn''t contain a Numbers folder!');
    end
    
    NumberOfRegions=size(coordinates,1); 
        
else
    error('Cancelled?! So rude.');
end

prompt = {'CSR Repeats:'};
dlg_title = 'Enter the settings to use...';
num_lines = 1;
def = {num2str(CSRRepeats)};
answer = inputdlg(prompt,dlg_title,num_lines,def);

if ~isempty(answer)
    CSRRepeats = str2double(answer(1,1));
else
error('Cancelled?! So rude.');
end

if ProcSettings.CoordsTableScale ~= 1
    coordinates(:,2:3) = round(coordinates(:,2:3) * ProcSettings.CoordsTableScale);
end

% All good, build output dirs
rand_dirname = ['Randomised-',datestr(fix(clock),'yyyymmdd@HHMMSS')];

alphanums = ['a':'z' 'A':'Z' '0':'9'];
randname = alphanums(randi(numel(alphanums),[1 5]));
foldername = ['Randomised (x',num2str(CSRRepeats),')_',randname];
mkdir(fullfile(dirName,rand_dirname));
cd(fullfile(dirName,rand_dirname));
mkdir('Thr-Clusters');
mkdir('Thr-Holes');
mkdir('Colour');
mkdir('FIGs');
mkdir('Numbers');
mkdir('Greyscale');
mkdir('Points');
mkdir('GF-Points');

if ProcSettings.DoClustersByBlobs
    mkdir('Thr-Clusters\blobs');
    mkdir('Numbers\Centroids');
end

for t = 1:NumberOfRegions
    CurrentTXTfile  = TXTfileList{t,1};
    SaveTXTFileName = strsplit(CurrentTXTfile,'.txt');
    
    region_xmin = coordinates(t,2) - (ProcSettings.xRegionLength / 2);
    region_xmax = coordinates(t,2) + (ProcSettings.xRegionLength / 2);
    region_ymin = coordinates(t,3) - (ProcSettings.yRegionLength / 2);
    region_ymax = coordinates(t,3) + (ProcSettings.yRegionLength / 2);
    
    data_region_ch = importdata(['../Numbers/',CurrentTXTfile]);
    
    for r = 1:CSRRepeats
        
        CurrentTextStr = ['Randomising: ',SaveTXTFileName{1,1},' (Region ',num2str(t),' of ',num2str(size(TXTfileList,1)),', round ',num2str(r),' of ',num2str(CSRRepeats),').'];
        disp(CurrentTextStr);
    
        RandomisedTXTFileName = fullfile('Numbers', strcat(SaveTXTFileName{1,1}, ' - Randomised-',num2str(r),'.txt'));      
        
        data_random_ch = data_region_ch.data;
        TotalPoints = size(data_random_ch,1);
        
        new_rand_xoords = randi([region_xmin region_xmax],[length(data_random_ch),1]);
        new_rand_yoords = randi([region_ymin region_ymax],[length(data_random_ch),1]);
        data_random_ch(:,ProcSettings.xCoordsColumn) = new_rand_xoords;
        data_random_ch(:,ProcSettings.yCoordsColumn) = new_rand_yoords;
        
        RegionBounds = [region_xmin region_xmin+ProcSettings.SamplingRadius region_ymax-ProcSettings.SamplingRadius region_ymax];
        TLcorner = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        TLcorner(:,ProcSettings.xCoordsColumn) = TLcorner(:,ProcSettings.xCoordsColumn) + ProcSettings.xRegionLength + 1;
        TLcorner(:,ProcSettings.yCoordsColumn) = TLcorner(:,ProcSettings.yCoordsColumn) - ProcSettings.yRegionLength - 1;
        
        RegionBounds = [region_xmax-ProcSettings.SamplingRadius region_xmax region_ymax-ProcSettings.SamplingRadius region_ymax];
        TRcorner = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        TRcorner(:,ProcSettings.xCoordsColumn) = TRcorner(:,ProcSettings.xCoordsColumn) - ProcSettings.xRegionLength - 1;
        TRcorner(:,ProcSettings.yCoordsColumn) = TRcorner(:,ProcSettings.yCoordsColumn) - ProcSettings.yRegionLength - 1;
        
        RegionBounds = [region_xmin region_xmin+ProcSettings.SamplingRadius region_ymin region_ymin+ProcSettings.SamplingRadius];
        BLcorner = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        BLcorner(:,ProcSettings.xCoordsColumn) = BLcorner(:,ProcSettings.xCoordsColumn) + ProcSettings.xRegionLength + 1;
        BLcorner(:,ProcSettings.yCoordsColumn) = BLcorner(:,ProcSettings.yCoordsColumn) + ProcSettings.yRegionLength + 1;
        
        RegionBounds = [region_xmax-ProcSettings.SamplingRadius region_xmax region_ymin region_ymin+ProcSettings.SamplingRadius];
        BRcorner = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        BRcorner(:,ProcSettings.xCoordsColumn) = BRcorner(:,ProcSettings.xCoordsColumn) - ProcSettings.xRegionLength - 1;
        BRcorner(:,ProcSettings.yCoordsColumn) = BRcorner(:,ProcSettings.yCoordsColumn) + ProcSettings.yRegionLength + 1;
              
        RegionBounds = [region_xmin+ProcSettings.SamplingRadius region_xmax-ProcSettings.SamplingRadius region_ymax-ProcSettings.SamplingRadius region_ymax];
        Tstrip = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        Tstrip(:,ProcSettings.yCoordsColumn) = Tstrip(:,ProcSettings.yCoordsColumn) - ProcSettings.yRegionLength - 1;

        RegionBounds = [region_xmin+ProcSettings.SamplingRadius region_xmax-ProcSettings.SamplingRadius region_ymin region_ymin+ProcSettings.SamplingRadius];
        Bstrip = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        Bstrip(:,ProcSettings.yCoordsColumn) = Bstrip(:,ProcSettings.yCoordsColumn) + ProcSettings.yRegionLength + 1;
        
        RegionBounds = [region_xmin region_xmin+ProcSettings.SamplingRadius region_ymin+ProcSettings.SamplingRadius region_ymax-ProcSettings.SamplingRadius];
        Lstrip = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        Lstrip(:,ProcSettings.xCoordsColumn) = Lstrip(:,ProcSettings.xCoordsColumn) + ProcSettings.xRegionLength + 1;

        RegionBounds = [region_xmax-ProcSettings.SamplingRadius region_xmax region_ymin+ProcSettings.SamplingRadius region_ymax-ProcSettings.SamplingRadius];
        Rstrip = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        Rstrip(:,ProcSettings.xCoordsColumn) = Rstrip(:,ProcSettings.xCoordsColumn) - ProcSettings.xRegionLength - 1;

        % add the padding points beneath the original points
        data_random_ch = vertcat(data_random_ch,TLcorner,TRcorner,BLcorner,BRcorner,Tstrip,Bstrip,Lstrip,Rstrip);

        data_random_GF = GF_Measure(data_random_ch(:,ProcSettings.xCoordsColumn:ProcSettings.yCoordsColumn),ProcSettings.SamplingRadius,(ProcSettings.xRegionLength+ProcSettings.SamplingRadius+ProcSettings.SamplingRadius),(ProcSettings.yRegionLength+ProcSettings.SamplingRadius+ProcSettings.SamplingRadius));
        data_random_ch_GF = horzcat(data_random_ch,data_random_GF);
        Rand_Ch_GFCol = size(data_random_ch_GF,2);
        
        % Delete the added padding points from beneath the original points
        data_random_ch_GF(TotalPoints+1:end,:) = [];

        ImgFileNameA = strcat('RANDOM_',num2str(r),' - ',SaveTXTFileName{1,1});
        clusmap_data_random=horzcat(data_random_ch_GF(:,ProcSettings.xCoordsColumn:ProcSettings.yCoordsColumn),data_random_ch_GF(:,Rand_Ch_GFCol));
        MakeImages(clusmap_data_random,ImgFileNameA,[region_xmin,region_xmax,region_ymin,region_ymax],ProcSettings);               
        
        if ProcSettings.DoClustersByBlobs

            % create new table containing only the clustered molecules
                IndexAboveThreshold = find(data_random_ch_GF(:,Rand_Ch_GFCol) >= ProcSettings.BinaryChangeHIGH);
                ClusteredData = horzcat(IndexAboveThreshold,data_random_ch_GF(IndexAboveThreshold,ProcSettings.xCoordsColumn),data_random_ch_GF(IndexAboveThreshold,ProcSettings.yCoordsColumn),data_random_ch_GF(IndexAboveThreshold,Rand_Ch_GFCol));
            %plot the points as 1 px each, save, close
                figure('Color',[1 1 1], 'Visible', 'off', 'Renderer', 'OpenGL', 'Units', 'inches');
                axes('Parent',figure,'Layer','top', 'YTick',zeros(1,0),'XTick',zeros(1,0),'DataAspectRatio', [1,1,1],'position',[0,0,1,1]);            
                box('off');
            %define the 'paper' dimensions
                set(gcf, 'PaperUnits', 'inches', 'PaperSize', [10 10], 'PaperPositionMode', 'manual', 'PaperPosition', [0 0 10 10],'Visible','off');

                scatter(ClusteredData(:,2),ClusteredData(:,3),1,'k.');
                axis([region_xmin region_xmax region_ymin region_ymax])
                set(gca, 'Visible', 'off'); %hide the axes
                axis square
            % to create a 1px/nm image
                SaveHighDPI = strcat('-r',num2str(ProcSettings.xRegionLength / 10));
                print('-dpng',SaveHighDPI,'ClusMaskTmp.png');
                close(gcf);

            % Create a disk scaling image
            if exist('Thr-Clusters\blobs\Blob Standard - Disk - Size 1-100.png','file') == 0
%                 TestImg = repmat([0],300);
%                PaddingStripe = ones(300,1);
%                 TestImg = horzcat(TestImg,PaddingStripe);
                TestImg = [];
                TestImg2 = zeros(3000,3000);
                for d = 1:100
                    DiskArray = repmat(0,300);
                    DiskArray(150,150) = 1;
                    StructElement = strel('disk',d,8);
                    DemoClusterMask = imdilate(DiskArray,StructElement);
%                     DemoClusterMask(:,end) = 1;
%                     DemoClusterMask(end,:) = 1;
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
%                 figure('Visible','off');
%                 imshow(TestImg,'InitialMagnification',20);
%                 set(gcf,'Visible','off');
                imwrite(TestImg2,fullfile('Thr-Clusters\blobs',strcat('Blob Standard - Disk - Size 1-100.png')),'png');
                clear TestImg TestImg2 DemoClusterMask d StructElement DiskArray
            end

            % Reopen as image data, dilate points by 50 nm disk
                ClusterMask = imread('ClusMaskTmp.png');
                ClusterMask = im2bw(ClusterMask,0.5);
                ClusterMask = ~ClusterMask;%invert
                se2 = strel('disk',ProcSettings.RenderBlobsDiskSize,8); % 23 is good for 50 nm diameter disk
                ClusterMask2 = imdilate(ClusterMask,se2);

            % render cluster image and save
%                 figure('Visible','off');
%                 imshow(ClusterMask2,'InitialMagnification',20);
%                 set(gcf,'Visible','off');
                imwrite(ClusterMask2,fullfile('Thr-Clusters\blobs',strcat(ImgFileNameA,' Clusters by blobs.png')),'png');
                close(gcf);

            % do image proc and stats
                islands = bwconncomp(ClusterMask2);
                label_clusters = labelmatrix(islands);
                stats = regionprops(label_clusters,'all');
                clusmap_scale = ProcSettings.xRegionLength / size(label_clusters,1); % conversion factor to resize 

                % total_clusters = max(max(label_clusters));% FYI length(stats) also equals the cluster count
                % Export stats to text file?
                % imagesc(stats(36,1).Image); % display image of only cluster 36 Loop to
                % export all cluster images.

            % Assign each clustered point a clusterID using the regionprops polygon
                ClusterIDCol = size(data_random_ch_GF,2)+1;
                if isempty(stats) % no clusters detected
                 data_random_ch_GF(:,ClusterIDCol) = 0;
                    fname = fullfile('.\Numbers\Centroids',strcat(ImgFileNameA,' Centroids List.txt'));
                    fid = fopen(fname,'w');
                    fprintf(fid,'%s','No clusters detected with your settings.');
                    fclose(fid);
                    clear fname
                else  % clusters detected ... generate a summary
                    for clusterID = 1:length(stats)
                        clusterpoly_tmp = (stats(clusterID,1).ConvexHull)*clusmap_scale;
                        clusterpoly_tmp(:,1) = clusterpoly_tmp(:,1) + region_xmin; % convert polygon image coords to datatable coords
                        clusterpoly_tmp(:,2) = region_ymax - clusterpoly_tmp(:,2); % because image origin is flipped on y axis to the data origin
                        mypoints = inpolygon(ClusteredData(:,2),ClusteredData(:,3),clusterpoly_tmp(:,1),clusterpoly_tmp(:,2));
                        data_random_ch_GF(ClusteredData(mypoints,1),ClusterIDCol) = clusterID;

                        %copy centroids for labelling purposes
                        ClusterCentroids(clusterID,1) = clusterID;
                        ClusterCentroids(clusterID,2:3) = stats(clusterID,1).Centroid ;
                    end
                    % Export ClusterCentroids
                    dlmwrite(fullfile('Numbers\Centroids',strcat(ImgFileNameA,' Centroids List.txt')),ClusterCentroids,'\t');
                end

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
                SavePNG('Thr-Clusters\blobs',strcat(ImgFileNameA,' Cluster ID Map'),ProcSettings.UseFolders);
                close(gcf);

                clear xMin xMax yMin yMax blob_id2 px_id blob2data blob_id blob_pixels blob_px
                clear IndexAboveThreshold label_clusters label2 ClusterCentroids ClusteredData ClusterMask2 se2 islands ClusterMask
                delete('ClusMaskTmp.png');
                close all
        end
        
        TXTFileName = fullfile('Numbers',strcat('RANDOM_',num2str(r),' - ',SaveTXTFileName{1,1},'.txt')); %replace .txt with .csv if needed
       
        abovethresh=sum(data_random_ch_GF(:,Rand_Ch_GFCol)>=ProcSettings.BinaryChangeHIGH);
        percentabove=abovethresh/TotalPoints*100;

        results=[{'Data Randomised from:'},dirName;
            {''},{''};
            {'Events in clusters'},num2str(abovethresh);
            {'Total number of events'},num2str(TotalPoints);
            {'Percent of events in clusters'},num2str(percentabove);
            {'Max colour scale'},num2str(ProcSettings.ColMapMax);
            {'Reprocessed Binary change value high'},num2str(ProcSettings.BinaryChangeHIGH)];
        
        % Save the randomised data table
        dlmwrite(TXTFileName,data_random_ch_GF,'-append','delimiter','\t');

        % Save the summary
        TXTFileName2 = strrep(TXTFileName, '.txt', '-Summary.txt');
        fid = fopen(TXTFileName2,'w');
        for row = 1:size(results,1)
            fprintf(fid,'%s\t%s\r\n',results{row,:});
        end
        fid = fclose(fid);

    end

end
cd('..');
AllDoneMsg = 'All done!';
disp(AllDoneMsg);