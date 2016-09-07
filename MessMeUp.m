function randomised_table = MessMeUp(data_random_ch, Boundaries, SamplingRadius, ProcSettings)
       
        region_xmin = Boundaries(1);
        region_xmax = Boundaries(2);
        region_ymin = Boundaries(3);
        region_ymax = Boundaries(4);

        new_rand_xoords = randi([region_xmin region_xmax]*10,[length(data_random_ch),1])/10; % randomise x to nearest 10th nm
        new_rand_yoords = randi([region_ymin region_ymax]*10,[length(data_random_ch),1])/10; % randomise y to nearest 10th nm
        data_random_ch(:,ProcSettings.xCoordsColumn) = new_rand_xoords;
        data_random_ch(:,ProcSettings.yCoordsColumn) = new_rand_yoords;
        
        % Wrap edges        
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
        randomised_table = vertcat(data_random_ch,TLcorner,TRcorner,BLcorner,BRcorner,Tstrip,Bstrip,Lstrip,Rstrip);

end
