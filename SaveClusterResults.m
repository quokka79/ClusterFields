function SaveClusterResults(FileType,FileName,RegionDesc,GFdata,Main_Ch_GFCol,ProcSettings,ExcelHeaders)

% binarychangeHIGH,binarychangeLOW,clusscale

    if (strcmp(FileType,'xls') || strcmp(FileType,'txt')) == false
        error(strcat('You can save as Excel or Text but not as ''',FileType,'''.'))
    end

    CurrentTableID = RegionDesc(1);
    CurrentRegionID = RegionDesc(2);
    ChannelID = RegionDesc(3);
    
    %Check if bivariate
    if isempty(strfind(FileName, 'vsCh'))
        SamplingRadius = ProcSettings.SamplingRadius;
        BinaryChangeHIGH = ProcSettings.BinaryChangeHIGH; 
        BinaryChangeLOW = ProcSettings.BinaryChangeLOW;
    else
        SamplingRadius = ProcSettings.BiVarSamplingRadius;
        BinaryChangeHIGH = ProcSettings.BiVarChangeHIGH; 
        BinaryChangeLOW = ProcSettings.BiVarChangeLOW;
    end
    
    abovethresh=sum(GFdata(:,Main_Ch_GFCol)>=BinaryChangeHIGH);
    belowthresh=sum(GFdata(:,Main_Ch_GFCol)<=BinaryChangeLOW);
    numtotal=size(GFdata,1);
    percentabove=abovethresh/numtotal*100;
    percentbelow=belowthresh/numtotal*100;

    results=[{'Events in clusters'},abovethresh;
        {'Total number of events'},numtotal;
        {'Percent of events in clusters'},percentabove;
        {'Events in holes'},belowthresh;
        {'Percent of events in holes'},percentbelow;
        {'Max colour scale'},ProcSettings.ColMapMax;
        {'Binary change value high'},BinaryChangeHIGH;
        {'Binary change value low'},BinaryChangeLOW;
        {'Precision crop'},ProcSettings.PrecisionCrop;
        {'Sample radius'},SamplingRadius];

    if strcmp(FileType,'xls')

        xlswrite(FileName,ExcelHeaders,strcat('table',num2str(CurrentTableID),' region',num2str(CurrentRegionID),' ch',num2str(ChannelID)),'A1');
        xlswrite(FileName,GFdata,strcat('table',num2str(CurrentTableID),' region',num2str(CurrentRegionID),' ch',num2str(ChannelID)),'A2');

        ExcelStatsDumpPoint = strcat(char((length(ExcelHeaders) + 2)+'A'),'1');
        xlswrite(FileName, results,strcat('table',num2str(CurrentTableID),' region',num2str(CurrentRegionID),' ch',num2str(ChannelID)),ExcelStatsDumpPoint);

    end
    
    if  strcmp(FileType,'txt')

        if isempty(strfind(FileName, 'vsCh')) % only save data tables for main channels
            if ProcSettings.UseFolders
                FileName2 = fullfile('Numbers\RegionTables\',FileName);
            else
                FileName2 = FileName;
            end
            fid = fopen(FileName2,'w');
            stringy = '%s';
            for g = 1:(length(ExcelHeaders)-1)
                stringy = strcat(stringy,'\t%s'); % replace \t with a comma for csv
            end
            fprintf(fid,stringy,ExcelHeaders{:});
            fprintf(fid,'\r\n');
            fid = fclose(fid);
            dlmwrite(FileName2,GFdata,'-append','delimiter','\t');
        end

        % Save Summary Files
        if ProcSettings.UseFolders
            FileName3 = fullfile('Numbers\Summaries\',strrep(FileName, '.txt', '-Summary.txt'));
        else
            FileName3 = strrep(FileName, '.txt', '-Summary.txt');
        end
        
        fid = fopen(FileName3,'w');
        for row = 1:size(results,1)
            fprintf(fid,'%s\t%d\r\n',results{row,:});
        end
        fid = fclose(fid);

    end

end