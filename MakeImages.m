function MakeImages(clusmap_data,FileName,RegionBounds,ProcSet)

    strict_region_xmin = RegionBounds(1);
    strict_region_xmax = RegionBounds(2);
    strict_region_ymin = RegionBounds(3);
    strict_region_ymax = RegionBounds(4);

    SaveGFPointsAsEPS = false;

    if ischar(ProcSet.ColMapMax)
        if strcmpi(ProcSet.ColMapMax,'max')
            ProcSet.ColMapMax = max(clusmap_data(:,3));
        else
            CMaxPercent = str2double(ProcSet.ColMapMax(1,4:end));
            if CMaxPercent > 100
                ProcSet.ColMapMax = (CMaxPercent/100) * max(clusmap_data(:,3));
            else
                CMaxSorted = sort(clusmap_data(:,3));
                CMaxCount = numel(find(CMaxSorted>0));
                CMaxTop = ceil(((1-(CMaxPercent/100))*CMaxCount));
                ProcSet.ColMapMax = CMaxSorted(length(CMaxSorted)-CMaxTop,1);
            end
            clear CMaxPercent CMaxSorted CMaxCount CMaxTop
        end
    end

    PaperPrintWidth = 10; % inches
    PlotPrintWidth = 10; % inches
    
    PlotPointSize = 5; % size of the spots for Points and GFPoints images

    %% Clean the input data to trim away out-of-bounds points
    if (min(clusmap_data(:,1)) < strict_region_xmin) || (max(clusmap_data(:,1)) > strict_region_xmax) || (min(clusmap_data(:,2)) < strict_region_ymin) || (max(clusmap_data(:,2)) > strict_region_ymax)
        clusmap_data = RegionCropper(clusmap_data, RegionBounds, [1 2]);
    end

    %% Generates interpolated maps and apply L(r) threshold LUT for the binary 'cluster' images

    if ProcSet.DoInterpMaps

        if ProcSet.VerboseUpdates
            ShowInfoMessage('Starting colourmap interpolation...');
        end
        % Make a binary threshold colourmap for 'clusters'
        black=round(64/ProcSet.ColMapMax*ProcSet.BinaryChangeHIGH);
        a=zeros(black,3);
        b=ones((64-black),3);
        c=vertcat(a,b);

        % Same again for the 'holes' maps
        black2=round(64/ProcSet.ColMapMax*ProcSet.BinaryChangeLOW);
        a2=ones(black2,3);
        b2=zeros((64-black2),3);
        c2=vertcat(a2,b2);

        %Interpolated Cluster Map
        tx=(strict_region_xmin:ProcSet.GDInterpSpacing:strict_region_xmax);
        ty=(strict_region_ymin:ProcSet.GDInterpSpacing:strict_region_ymax);
        [XI, YI] = meshgrid(tx, ty);

        if ProcSet.UseGriddata == true
            % Interpolate the cluster map surface
            ZI = griddata(clusmap_data(:,1), clusmap_data(:,2), clusmap_data(:,3), XI, YI, 'v4');
        else
            % Alternate Inerpolation (much faster than griddata)
            F = scatteredInterpolant(clusmap_data(:,1), clusmap_data(:,2), clusmap_data(:,3),'natural');
            ZI = F(XI,YI);
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
        
        % fix and tidy the axes
        axis(RegionBounds);    
        axis square image tight
        set(gca, 'Visible','off');
        
        %plot the cluster contour map
        [ContourArray,ContourMap] = contourf(XI,YI,ZI,100,'LineColor','none', 'Fill','on');
        caxis([0 ProcSet.ColMapMax]);
        
        %Save the 2D Contour Array for later processing
        save(fullfile('FIGs', strcat(FileName,' 2D Contour Array.mat')),'ContourArray');

        %plot points onto the colourmap
        PlotPoints = plot(clusmap_data(:,1), clusmap_data(:,2), 'Marker','.','MarkerSize',4,'LineStyle','none','Color',[0 0 0]);

        %save colourmap FIG
        if ProcSet.UseFolders==true
            hgsave(fullfile('FIGs', strcat(FileName,' colourmap.fig')));
        else
            hgsave(strcat(FileName, ' colourmap.fig'));
        end

        %save colourmap PNG with points
        SavePNG('Colour',strcat(FileName,' Colourmap'),ProcSet.UseFolders) 

        set(PlotPoints,'Visible','off');  % Hide the points

        % don't bother saving contour maps for the bivariate channels
        if isempty(strfind(FileName, 'vsCh'))

            %change the colourmap for clusters and save the PNG
            colormap(c);
            SavePNG('Thr-Clusters',strcat(FileName,' Clusters'),ProcSet.UseFolders)  ;           

            %change the colourmap for holes and save the PNG
            colormap(c2);
            SavePNG('Thr-Holes',strcat(FileName,' Holes'),ProcSet.UseFolders) ;

            %change the colourmap for greyscale and save the PNG
            colormap(gray);
            SavePNG('Greyscale',strcat(FileName,' Greyscale'),ProcSet.UseFolders);

        end
        hold off;
        close(gcf); 

        % Save 3D Contour plot for Mountaineering

        if ProcSet.Save3DContours

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

            % fix and tidy the axes
            axis(RegionBounds);    
            axis square image tight
            set(gca, 'Visible','off');
        
            %plot the cluster contour map
            [ContourArray,ContourMap] = contour3(XI,YI,ZI,100);
            caxis([0 ProcSet.ColMapMax]);

            %Save the 3D Contour Array for later processing
            save(fullfile('FIGs', strcat(FileName,' 3D Contour Array.mat')),'ContourArray');

            %save 3D contour colourmap FIG
            if ProcSet.UseFolders==true
                hgsave(fullfile('FIGs', strcat(FileName,' 3D Contours.fig')));
            else
                hgsave(strcat(FileName, '  3D Contours.fig'));
            end
            close(gcf);

        end
        if ProcSet.VerboseUpdates
            ShowInfoMessage('Finished colourmap interpolation.');
        end
    end

    %% Save a plot with only the points in the region shown

    if ProcSet.SavePointPlots
        
        if ProcSet.VerboseUpdates
            ShowInfoMessage('Saving Plot Points...');
        end
        
        PaperPrintWidth = 12; % inches
        
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
        
        % plot the data points
        scatter(clusmap_data(:,1), clusmap_data(:,2),PlotPointSize,'o','fill');
        
        % fix and tidy the axes
        axis(RegionBounds);    
        axis square image tight
        set(gca, 'Visible','off');

        %Get the width of the plot to mangle for 1 px/nm
        PlotWidth = strict_region_xmax - strict_region_xmin;

        SaveHighDPI = strcat('-r',num2str(PlotWidth / 10));

        %write to a temp image
        print('-dpng',SaveHighDPI,'tmp_precrop_Points.png');

        %load the temp image
        PointsTMP = imread('tmp_precrop_Points.png');

        %crop the temp image
        CropStripWidth = PlotWidth / 10;
        CroppedPointsTMP = PointsTMP(1+CropStripWidth:(end-CropStripWidth),1+CropStripWidth:(end-CropStripWidth),:);

        if ProcSet.UseFolders==true
            imwrite(CroppedPointsTMP,fullfile('Points', strcat(FileName, ' Points.png')),'png');
        else
            imwrite(CroppedPointsTMP,strcat(FileName, ' Points.png'),'png');
        end

        delete('tmp_precrop_Points.png');
        close(gcf);

    end

    %% Save a plot with the points coloured by their G&F value
    if ProcSet.SaveGFPlots

        if ProcSet.VerboseUpdates
            ShowInfoMessage('Saving G&F Plot Points...');
        end
        
        PaperPrintWidth = 12; % inches
        
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
        
        % plot the data points
        scatter(clusmap_data(:,1), clusmap_data(:,2),PlotPointSize, clusmap_data(:,3),'filled');
        caxis([0 ProcSet.ColMapMax]);
        
        % fix and tidy the axes
        axis(RegionBounds);    
        axis square image tight
        set(gca, 'Visible','off');

        if SaveGFPointsAsEPS
            SaveEPS('GF-Points',strcat(FileName,' G&F Points'),ProcSet.UseFolders);
        end

        %save GF points FIG
        if ProcSet.UseFolders==true
            hgsave(fullfile('FIGs', strcat(FileName,' G&F Points.fig')));
        else
            hgsave(strcat(FileName, ' G&F Points.fig'));
        end
        
        %Get the width of the plot to mangle for 1 px/nm
        PlotWidth = strict_region_xmax - strict_region_xmin;

        SaveHighDPI = strcat('-r',num2str(PlotWidth / 10));

        %write to a temp image
        print('-dpng',SaveHighDPI,'tmp_precrop_GF.png');

        %load the temp image
        PointsTMP = imread('tmp_precrop_GF.png');

        %crop the temp image
        CropStripWidth = PlotWidth / 10;
        CroppedPointsTMP = PointsTMP(1+CropStripWidth:(end-CropStripWidth),1+CropStripWidth:(end-CropStripWidth),:);

        if ProcSet.UseFolders==true
            imwrite(CroppedPointsTMP,fullfile('GF-Points', strcat(FileName, ' G&F Points.png')),'png');
        else
            imwrite(CroppedPointsTMP,strcat(FileName, ' G&F Points.png'),'png');
        end

        delete('tmp_precrop_GF.png');
        close(gcf);

    end

end