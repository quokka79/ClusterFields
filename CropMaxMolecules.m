function [CroppedRegion, MaxMolecules] = CropMaxMolecules(InputRegionArray,MaxMoleculesToProcess)

    NumberOfMolecuelsInRegion=size(InputRegionArray,1);
    
    if MaxMoleculesToProcess<NumberOfMolecuelsInRegion;
        InputRegionArray(MaxMoleculesToProcess+1:NumberOfMolecuelsInRegion,:)=[];
        CroppedRegion = InputRegionArray;
        MaxMolecules=size(CroppedRegion,1);
    else
        CroppedRegion = InputRegionArray;
        MaxMolecules=NumberOfMolecuelsInRegion;
    end

end