function SavePNG(OutputFolder,FileName,UseFolders) 

    %Get the width of the plot to mangle for 1 px/nm
    PlotWidth = get(gca,'XLim');
    PlotWidth = PlotWidth(2)-PlotWidth(1);
        
    SaveHighDPI = strcat('-r',num2str(PlotWidth / 10));

    if UseFolders==true
        print('-dpng',SaveHighDPI,fullfile(OutputFolder, strcat(FileName, '.png')));
    else
        print('-dpng',SaveHighDPI,strcat(FileName, '.png'));
    end
    
end