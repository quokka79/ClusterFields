% Randomise Regions
rng('shuffle')  % set the random seed

% Default number of repeats
CSRRepeats = 2;
DoGFStuff = false;

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
    NumChannels = max(FilesTmp(:,4));
    NumberOfRegions=size(coordinates,1)*NumChannels;
    coords2 = zeros(NumberOfRegions,size(coordinates,2));
    if NumberOfRegions > 1
        for ch = 1:NumChannels
            coords2(ch:NumChannels:NumberOfRegions,:) = coordinates;
        end
        coordinates = coords2;
        SamplingRadius = ProcSettings.BiVarSamplingRadius;
    else
        SamplingRadius = ProcSettings.SamplingRadius;
    end
    
    clear FilesTmp f
        
else
    error('Cancelled?! So rude.');
end

prompt = {'CSR Repeats:','Do G&F Stuff? (0=faster, no images)'};
dlg_title = 'Enter the settings to use...';
num_lines = 1;
def = {num2str(CSRRepeats),num2str(DoGFStuff)};
answer = inputdlg(prompt,dlg_title,num_lines,def);

if ~isempty(answer)
    CSRRepeats = str2double(answer(1,1));
    DoGFStuff = str2double(answer(2,1));
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
if DoGFStuff
    mkdir('Thr-Clusters');
    mkdir('Thr-Holes');
    mkdir('Colour');
    mkdir('FIGs');
    mkdir('Greyscale');
    mkdir('Numbers');
    mkdir('Points');
    mkdir('GF-Points');
    if ProcSettings.DoClustersByBlobs
        mkdir('Thr-Clusters\Blobs');
        mkdir('Numbers\Centroids');
        mkdir('Thr-Clusters\Blobs\LabelledMaps');
    end
    if ProcSettings.DoGridMaps
        mkdir('Thr-Clusters\Grid-maps');
        mkdir('Thr-Holes\Grid-maps');
        mkdir('FIGs\Grid-maps');
        mkdir('Colour\Grid-maps');
        mkdir('Greyscale\Grid-maps');
    end
else
    for ch = 1:NumChannels
        mkdir(fullfile(dirName,rand_dirname,num2str(ch)));
    end
end


for t = 1:NumberOfRegions
    CurrentTXTfile  = TXTfileList{t,1};
    SaveTXTFileName = strsplit(CurrentTXTfile,'.txt');
    
    region_xmin = coordinates(t,2) - (ProcSettings.xRegionLength / 2);
    region_xmax = coordinates(t,2) + (ProcSettings.xRegionLength / 2);
    region_ymin = coordinates(t,3) - (ProcSettings.yRegionLength / 2);
    region_ymax = coordinates(t,3) + (ProcSettings.yRegionLength / 2);
    
    areaX_padded=(ProcSettings.xRegionLength/2)+SamplingRadius;
    areaY_padded=(ProcSettings.yRegionLength/2)+SamplingRadius;
    padded_region_xmin = ceil(coordinates(t,2)-areaX_padded);
    padded_region_xmax = floor(padded_region_xmin + 2 * areaX_padded);
    if ProcSettings.InvertyAxis==true; % Zeiss y-axis direction
        padded_region_ymin = ceil(ProcSettings.ImageSize-coordinates(t,3)-areaY_padded);
        padded_region_ymax = floor(padded_region_ymin + 2 * areaY_padded);
    else % normal y-axis direction
        padded_region_ymin = ceil(coordinates(t,3)-areaY_padded);
        padded_region_ymax = floor(padded_region_ymin + 2 * areaY_padded);
    end
    
    data_region_ch = importdata(fullfile(dirName,'Numbers/RegionTables',CurrentTXTfile));
    
    for r = 1:CSRRepeats
        
        CurrentTextStr = ['Randomising: ',SaveTXTFileName{1,1},' (Region ',num2str(t),' of ',num2str(size(TXTfileList,1)),', round ',num2str(r),' of ',num2str(CSRRepeats),').'];
        disp(CurrentTextStr);
    
        RandomisedTXTFileName = fullfile('Numbers', strcat(SaveTXTFileName{1,1}, ' - Randomised-',num2str(r),'.txt'));      
        
    %% Make randomised data from original region
        data_random_ch = data_region_ch.data;
        TotalPoints = size(data_random_ch,1);
        
        new_rand_xoords = randi([region_xmin region_xmax]*10,[length(data_random_ch),1])/10; % randomise x to nearest 10th nm
        new_rand_yoords = randi([region_ymin region_ymax]*10,[length(data_random_ch),1])/10; % randomise y to nearest 10th nm
        data_random_ch(:,ProcSettings.xCoordsColumn) = new_rand_xoords;
        data_random_ch(:,ProcSettings.yCoordsColumn) = new_rand_yoords;
        
        RegionBounds = [region_xmin region_xmin+SamplingRadius region_ymax-SamplingRadius region_ymax];
        TLcorner = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        TLcorner(:,ProcSettings.xCoordsColumn) = TLcorner(:,ProcSettings.xCoordsColumn) + ProcSettings.xRegionLength + 1;
        TLcorner(:,ProcSettings.yCoordsColumn) = TLcorner(:,ProcSettings.yCoordsColumn) - ProcSettings.yRegionLength - 1;
        
        RegionBounds = [region_xmax-SamplingRadius region_xmax region_ymax-SamplingRadius region_ymax];
        TRcorner = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        TRcorner(:,ProcSettings.xCoordsColumn) = TRcorner(:,ProcSettings.xCoordsColumn) - ProcSettings.xRegionLength - 1;
        TRcorner(:,ProcSettings.yCoordsColumn) = TRcorner(:,ProcSettings.yCoordsColumn) - ProcSettings.yRegionLength - 1;
        
        RegionBounds = [region_xmin region_xmin+SamplingRadius region_ymin region_ymin+SamplingRadius];
        BLcorner = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        BLcorner(:,ProcSettings.xCoordsColumn) = BLcorner(:,ProcSettings.xCoordsColumn) + ProcSettings.xRegionLength + 1;
        BLcorner(:,ProcSettings.yCoordsColumn) = BLcorner(:,ProcSettings.yCoordsColumn) + ProcSettings.yRegionLength + 1;
        
        RegionBounds = [region_xmax-SamplingRadius region_xmax region_ymin region_ymin+SamplingRadius];
        BRcorner = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        BRcorner(:,ProcSettings.xCoordsColumn) = BRcorner(:,ProcSettings.xCoordsColumn) - ProcSettings.xRegionLength - 1;
        BRcorner(:,ProcSettings.yCoordsColumn) = BRcorner(:,ProcSettings.yCoordsColumn) + ProcSettings.yRegionLength + 1;
              
        RegionBounds = [region_xmin+SamplingRadius region_xmax-SamplingRadius region_ymax-SamplingRadius region_ymax];
        Tstrip = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        Tstrip(:,ProcSettings.yCoordsColumn) = Tstrip(:,ProcSettings.yCoordsColumn) - ProcSettings.yRegionLength - 1;

        RegionBounds = [region_xmin+SamplingRadius region_xmax-SamplingRadius region_ymin region_ymin+SamplingRadius];
        Bstrip = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        Bstrip(:,ProcSettings.yCoordsColumn) = Bstrip(:,ProcSettings.yCoordsColumn) + ProcSettings.yRegionLength + 1;
        
        RegionBounds = [region_xmin region_xmin+SamplingRadius region_ymin+SamplingRadius region_ymax-SamplingRadius];
        Lstrip = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        Lstrip(:,ProcSettings.xCoordsColumn) = Lstrip(:,ProcSettings.xCoordsColumn) + ProcSettings.xRegionLength + 1;

        RegionBounds = [region_xmax-SamplingRadius region_xmax region_ymin+SamplingRadius region_ymax-SamplingRadius];
        Rstrip = RegionCropper(data_random_ch,RegionBounds,[ProcSettings.xCoordsColumn ProcSettings.yCoordsColumn]);
        Rstrip(:,ProcSettings.xCoordsColumn) = Rstrip(:,ProcSettings.xCoordsColumn) - ProcSettings.xRegionLength - 1;

        % add the padding points beneath the original points
        data_random_ch = vertcat(data_random_ch,TLcorner,TRcorner,BLcorner,BRcorner,Tstrip,Bstrip,Lstrip,Rstrip);

%         figure
%         scatter(data_random_ch(:,ProcSettings.xCoordsColumn),data_random_ch(:,ProcSettings.yCoordsColumn))
%         hold on
%         scatter(data_region_ch.data(:,ProcSettings.xCoordsColumn),data_region_ch.data(:,ProcSettings.yCoordsColumn),'.r')
%         axis image
        
    %% do the regular interpolated maps
        if DoGFStuff
            data_random_GF = GF_Measure(data_random_ch(:,ProcSettings.xCoordsColumn:ProcSettings.yCoordsColumn),ProcSettings.SamplingRadius,(ProcSettings.xRegionLength+ProcSettings.SamplingRadius+ProcSettings.SamplingRadius),(ProcSettings.yRegionLength+ProcSettings.SamplingRadius+ProcSettings.SamplingRadius));
            data_random_ch_GF = horzcat(data_random_ch,data_random_GF);
            Rand_Ch_GFCol = size(data_random_ch_GF,2);

            % Delete the added padding points from beneath the original points
            data_random_ch_GF(TotalPoints+1:end,:) = [];

            ImgFileNameA = strcat('RANDOM_',num2str(r),' - ',SaveTXTFileName{1,1});

            if ProcSettings.SaveImages
                clusmap_data_random=horzcat(data_random_ch_GF(:,ProcSettings.xCoordsColumn:ProcSettings.yCoordsColumn),data_random_ch_GF(:,Rand_Ch_GFCol));
                MakeImages(clusmap_data_random,ImgFileNameA,[region_xmin,region_xmax,region_ymin,region_ymax],ProcSettings);
            end


        %% do the grid-maps version
            if ProcSettings.DoGridMaps

                if ProcSettings.GridMapSpacing < 1
                    GridSpacing = ProcSettings.SamplingRadius * ProcSettings.GridMapSpacing;
                else
                    GridSpacing = ProcSettings.GridMapSpacing;
                end

                [gridX,gridY] = meshgrid(padded_region_xmin+(GridSpacing/2):GridSpacing:padded_region_xmax-(GridSpacing/2),padded_region_ymin+(GridSpacing/2):GridSpacing:padded_region_ymax-(GridSpacing/2));
                gridXY = [gridX(:), gridY(:)];

                testfn = GF_Measure(gridXY,ProcSettings.SamplingRadius,(2 * areaX_padded),(2 * areaY_padded),data_random_ch(:,ProcSettings.xCoordsColumn:ProcSettings.yCoordsColumn));

                % Normalise baseline to zero -- this removes cases where an isolated data point creates a 'mound' within the grid. 
                lowest_nonzerogf = min(testfn(isfinite(testfn)&(testfn~=0))); % ignores NaNs, Infs and zeros
                testfn(testfn~=0) = testfn(testfn~=0) - lowest_nonzerogf; %Values that are already zero are not modified.

                % combine GF values with grid xy coords
                gridXY(:,3) = testfn(:,1); 


    %             figure
    %             scatter(gridXY(:,1),gridXY(:,2),'.g')
    %             hold on
    %             scatter(data_random_ch(:,ProcSettings.xCoordsColumn),data_random_ch(:,ProcSettings.yCoordsColumn),'b')
    %             scatter(data_region_ch.data(:,ProcSettings.xCoordsColumn),data_region_ch.data(:,ProcSettings.yCoordsColumn),'.r')
    %             axis image

            %Readjust the grids to match the cropped area
                gridXY_nopad = RegionCropper(gridXY, [padded_region_xmin+ProcSettings.SamplingRadius padded_region_xmax-ProcSettings.SamplingRadius padded_region_ymin+ProcSettings.SamplingRadius padded_region_ymax-ProcSettings.SamplingRadius], [1 2]);
                gridX(:,find(gridX(1,:)<padded_region_xmin+ProcSettings.SamplingRadius | gridX(1,:)>padded_region_xmax-ProcSettings.SamplingRadius)) = [];
                gridY(find(gridY(:,1)<padded_region_ymin+ProcSettings.SamplingRadius | gridY(:,1)>padded_region_ymax-ProcSettings.SamplingRadius),:) = [];
                gridX(size(gridY,1)+1:end,:) = [];
                gridY(:,size(gridX,2)+1:end) = [];

                % plot gf of cropped points
    %             scatter(gridXY(:,1),gridXY(:,2), 5, gridXY(:,3),'filled');
    %             axis square
    %             axis([data_xmin data_xmin+ProcSettings.xRegionLength data_ymax-ProcSettings.yRegionLength data_ymax])
    %             set(gca, 'Visible', 'off'); %hide the axes
    %             SaveEPS('GF-Points','GFPoints_GRID',ProcSettings.UseFolders); 
    %             SavePNG('GF-Points','GFPoints_GRID',ProcSettings.UseFolders); 

            % transform grid array into a pixel map for contouring
                map = zeros(size(gridX,2),size(gridY,1));
                for px=1:numel(map)
                    map(px) = gridXY_nopad(px,3);
                end

                if ProcSettings.SaveImages

                    % 3D Contour Map
                    figure('Color',[1 1 1], 'visible', 'off', 'Renderer', 'OpenGL', 'Units', 'pixels');
                    axes('Parent',figure,'Layer','top', 'YTick',zeros(1,0),'XTick',zeros(1,0),'DataAspectRatio', [1,1,1],'position',[0,0,1,1]);            
                    box('off');
                    hold('on');
                    set(gcf, 'PaperUnits', 'inches', 'PaperSize', [10 10], 'PaperPositionMode', 'manual', 'PaperPosition', [0 0 10 10],'Visible','off');
                    %plot the 3D contour map
                    [ContourArray,ContourMap] = contour3(gridX,gridY,map,100);
                    caxis([0 ceil(max(gridXY_nopad(:,3)))]);
                    axis square tight
                    axis([region_xmin, region_xmax, region_ymin, region_ymax]);
                    set(gca, 'Visible','off');

                    %Save the 3D Contour Array for later processing
                    save(fullfile('FIGs/Grid-maps', strcat(ImgFileNameA,' 3D Contour Array - GRID.mat')),'ContourArray');

                    if ProcSettings.UseFolders==true
                        hgsave(fullfile('FIGs/Grid-maps', strcat(ImgFileNameA,' 3D Contours - GRID.fig')));
                    else
                        hgsave(strcat(ImgFileNameA, ' 3D Contours - GRID.fig'));
                    end
                    close(gcf)

                    %Grid-based cluster map

                    if ischar(ProcSettings.GridColMapMax)
                        if strcmpi(ProcSettings.GridColMapMax,'max')
                            ProcSettings.GridColMapMax = max(gridXY_nopad(:,3));
                        else
                            CMaxPercent = str2double(ProcSettings.ColMapMax(1,4:end));
                            if CMaxPercent > 100
                                ProcSettings.GridColMapMax = (CMaxPercent/100) * max(gridXY_nopad(:,3));
                            else
                                CMaxSorted = sort(gridXY_nopad(:,3));
                                CMaxCount = numel(find(CMaxSorted>0));
                                CMaxTop = ceil(((1-(CMaxPercent/100))*CMaxCount));
                                ProcSettings.GridColMapMax = CMaxSorted(length(CMaxSorted)-CMaxTop,1);
                            end
                            clear CMaxPercent CMaxSorted CMaxCount CMaxTop
                        end
                    end

                    figure('Color',[1 1 1], 'Visible', 'off', 'Renderer', 'OpenGL', 'Units', 'pixels');
                    axes('Parent',figure,'Layer','top', 'YTick',zeros(1,0),'XTick',zeros(1,0),'DataAspectRatio', [1,1,1],'position',[0,0,1,1]);            
                    box('off');
                    hold('on');
                    set(gcf, 'PaperUnits', 'inches', 'PaperSize', [10 10], 'PaperPositionMode', 'manual', 'PaperPosition', [0 0 10 10], 'Visible', 'off');

                    %plot the cluster contour map
                    [~,ContourMap] = contourf(gridX,gridY,map,100,'LineColor','none', 'Fill','on');
                    caxis([0 ProcSettings.GridColMapMax]);
                    axis square tight
                    set(gca, 'Visible','off');

                    %Add the xy points
                    PlotPoints = plot(data_random_ch_GF(:,ProcSettings.xCoordsColumn),data_random_ch_GF(:,ProcSettings.yCoordsColumn),'Marker','.','MarkerSize',5,'LineStyle','none','Color',[0 0 0]);

                    %Save GRID FIG
                    if ProcSettings.UseFolders==true
                        hgsave(fullfile('FIGs/Grid-maps', strcat(ImgFileNameA,' colourmap-GRID.fig')));
                    else
                        hgsave(strcat(ImgFileNameA, ' colourmap-GRID.fig'));
                    end

                    %Save GRID colourmap               
                    if ProcSettings.UseFolders==true
                        print('-dpng',strcat('-r',num2str(ProcSettings.xRegionLength/10)),fullfile('Colour/Grid-maps',strcat(ImgFileNameA,' colourmap-GRID.png')));
                    else
                        print('-dpng',strcat('-r',num2str(ProcSettings.xRegionLength/10)),strcat(ImgFileNameA,' colourmap-GRID.png'));
                    end

                    % Hide the molecules for the following figures
                    set(PlotPoints,'Visible','off');

                    %change the colourmap for clusters and save the PNG
                    %Colormap 'c' for clusters
                    black=ceil((64/max(gridXY_nopad(:,3))*ProcSettings.GridBinChangeHIGH));%Find the internal colormap index that matches the cluster threshold.
                    a=zeros(black,3); %Black for indices 0 to the threshold point
                    b=ones((64-black),3); %White for indicies beyond the threshold point
                    c=vertcat(a,b);
                    clear a b black
                    colormap(c);
                    if ProcSettings.UseFolders==true
                        print('-dpng',strcat('-r',num2str(ProcSettings.xRegionLength/10)),fullfile('Thr-Clusters/Grid-maps',strcat(ImgFileNameA,' clusters-GRID.png')));
                    else
                        print('-dpng',strcat('-r',num2str(ProcSettings.xRegionLength/10)),strcat(ImgFileNameA,' clusters-GRID.png'));
                    end

                    % Same again for the 'holes' maps, colourmap 'c2' for holes
                    black2=ceil((64/max(gridXY_nopad(:,3))*ProcSettings.GridBinChangeLOW));
                    a2=ones(black2,3);
                    b2=zeros((64-black2),3);
                    c2=vertcat(a2,b2);
                    clear a2 b2 black2        
                    colormap(c2);
                    if ProcSettings.UseFolders==true
                        print('-dpng',strcat('-r',num2str(ProcSettings.xRegionLength/10)),fullfile('Thr-Holes/Grid-maps',strcat(ImgFileNameA,' holes-GRID.png')));
                    else
                        print('-dpng',strcat('-r',num2str(ProcSettings.xRegionLength/10)),strcat(ImgFileNameA,' holes-GRID.png'));
                    end


                    %change the colourmap for greyscale and save the PNG
                    colormap(gray);
                    SavePNG('Greyscale/Grid-maps',strcat(ImgFileNameA,' greyscale-GRID'),ProcSettings.UseFolders);
                    if ProcSettings.UseFolders==true
                        print('-dpng',strcat('-r',num2str(ProcSettings.xRegionLength/10)),fullfile('Greyscale/Grid-maps',strcat(ImgFileNameA,' greyscale-GRID.png')));
                    else
                        print('-dpng',strcat('-r',num2str(ProcSettings.xRegionLength/10)),strcat(ImgFileNameA,' greyscale-GRID.png'));
                    end


                    close(gcf);
                end
            end
            % END grid-based cluster map  

            if ProcSettings.DoClustersByBlobs

                if ProcSettings.VerboseUpdates
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

                % Reopen as image data, dilate points by the Blobs disk
                    ClusterMask = imread('ClusMaskTmp.png');
                    ClusterMask = im2bw(ClusterMask,0.5);
                    ClusterMask = ~ClusterMask; %invert
                    se2 = strel('disk',ProcSettings.RenderBlobsDiskSize,8);
                    ClusterMask2 = imdilate(ClusterMask,se2);
                    ClusterMask2 = imfill(ClusterMask2,'holes'); % fill in holes

                % render cluster image and save
                    imwrite(ClusterMask2,fullfile('Thr-Clusters\Blobs',strcat(ImgFileNameA,' Clusters by Blobs.png')),'png');
                    % close(gcf);

                % do image proc and stats
                    islands = bwconncomp(ClusterMask2);
                    label_clusters = labelmatrix(islands);
                    stats = regionprops(label_clusters,'all');
                    clusmap_scale = ProcSettings.xRegionLength / size(label_clusters,1); % conversion factor to resize 

                    % total_clusters = max(max(label_clusters));% FYI length(stats) also equals the cluster count
                    % Export stats to text file?
                % export individual cluster images
    %             for u=1:size(stats,1)
    %                 imagesc(stats(u,1).Image);
    %             end
                    % imagesc(stats(36,1).Image); % display image of only cluster 36

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
                    SavePNG('Thr-Clusters\Blobs\LabelledMaps',strcat(ImgFileNameA,' Cluster ID Map'),ProcSettings.UseFolders);
                    close(gcf);


                    clear xMin xMax yMin yMax blob_id2 px_id blob2data blob_id blob_pixels blob_px
                    clear IndexAboveThreshold label_clusters label2 ClusterCentroids ClusteredData ClusterMask2 se2 islands ClusterMask
                    delete('ClusMaskTmp.png');
                    close all

                    if ProcSettings.VerboseUpdates
                        ShowInfoMessage('Finished clusters by blobs.');
                    end
            end

            % export the text files
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
        else
            % export the text files
            ChanID = strsplit(SaveTXTFileName{1,1},'Ch');
            TXTFileName = fullfile(num2str(ChanID{1,2}),strcat('RANDOM_',num2str(r),' - ',SaveTXTFileName{1,1},'.txt')); %replace .txt with .csv if needed
             % Save the randomised data table
            dlmwrite(TXTFileName,data_random_ch,'-append','delimiter','\t','precision','%.1f');
        end
    end

end
cd(dirName);
AllDoneMsg = 'All done!';
disp(AllDoneMsg);