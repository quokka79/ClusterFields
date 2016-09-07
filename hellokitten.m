function hellokitten()
    fileID = fopen('cfields.dat');
    param = textscan(fileID,'%s','delimiter','\n','whitespace','');
    fclose(fileID);
    clear fileID ;

    k = 1;
    kadj = 0;
    karray = cell(1,1);
    for p = 1:length(param{1,1})
        if ~strcmp(param{1,1}(p,1),'#')
            karray{1,k}(p-kadj,1) = param{1,1}(p,1);
        else
            kadj = kadj + length(karray{1,k}) + 1;
            k = k + 1;
        end
    end

    datetmp = strsplit(date,'-');
    
    if strcmpi(datetmp{2},'Aug') && strcmpi(datetmp{1},'27')
        % pick a special kitty
        str = karray{end};
    else
        % pick a random kitty
        str = karray{randi(length(karray)-1,1)};
    end
    
    disp(' ');
    
    for kline = 1:length(str)
        str2 = str{kline};
        disp(str2);
    end
    
    disp(' ');
end
