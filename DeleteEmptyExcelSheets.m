function DeleteEmptyExcelSheets(fileName)

% Check whether the file exists 
if ~exist(fileName,'file') 
    error([fileName ' does not exist!']); 
else 
    % Check whether it is an Excel file 
    typ = xlsfinfo(fileName); 
    if ~strcmp(typ,'Microsoft Excel Spreadsheet') 
        error([fileName ' is not an Excel file.']); 
    end 
end 

% Full path is required for "excelObj.workbooks.Open(fileName)" to work.
if isempty(strfind(fileName,'\')) 
    fileName = [cd '\' fileName]; 
end 

excelObj = actxserver('Excel.Application'); 
excelWorkbook = excelObj.workbooks.Open(fileName); 
worksheets = excelObj.sheets; 
sheetIdx = 1; 
sheetIdx2 = 1; 
numSheets = worksheets.Count;
excelObj.EnableSound = false; % Prevent beeps from sounding if we try to delete a non-empty worksheet.
e.Application.DisplayAlerts = false; % disable alert popups

% Loop over all sheets 
while sheetIdx2 <= numSheets 
    % Saves the current number of sheets in the workbook 
    temp = worksheets.count; 
    % Check whether the current worksheet is the last one. As there always 
    % need to be at least one worksheet in an xls-file the last sheet must 
    % not be deleted. 
    if or(sheetIdx>1,numSheets-sheetIdx2>0)
        if worksheets.Item(sheetIdx).UsedRange.Count == 1 % Empty sheet
            worksheets.Item(sheetIdx).Delete; 
        end
    end 

    if temp == worksheets.count; 
        sheetIdx = sheetIdx + 1; 
    end
    
    sheetIdx2 = sheetIdx2 + 1;
end

excelObj.EnableSound = true;
e.Application.DisplayAlerts = true; % enable alert popups
excelWorkbook.Save; 
excelWorkbook.Close(false); 
excelObj.Quit; 
delete(excelObj);

return;