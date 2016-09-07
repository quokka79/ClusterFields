function UniqueCoordsRegion = DeleteDuplicatePoints(InputRegionArray,xCoordsColumn,yCoordsColumn)
    TestingArray(:,1) = InputRegionArray(:,xCoordsColumn);
    TestingArray(:,2) = InputRegionArray(:,yCoordsColumn);  
    
    [~,UniqueIdx,~] = unique(TestingArray,'rows');
    UniqueIdx = sort(UniqueIdx);
    
    UniqueCoordsRegion = InputRegionArray(UniqueIdx,:);
end

