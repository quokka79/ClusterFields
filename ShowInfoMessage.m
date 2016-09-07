function ShowInfoMessage(DisplayString)
    InfoMessage =  [datestr(fix(clock),'HH:MM:SS'),9,DisplayString];
    disp(InfoMessage);
end