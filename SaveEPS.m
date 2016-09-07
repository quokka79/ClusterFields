function SaveEPS(OutputFolder,FileName,UseFolders) 

    if UseFolders==true
        print('-depsc2','-loose',fullfile(OutputFolder, strcat(FileName, '.eps')));
    else
        print('-depsc2','-loose',strcat(FileName, '.eps'));
    end
    
end