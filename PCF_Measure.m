function PCF_data = PCF_Measure(Region1,Radius,deltaRadius,SizeX,SizeY,Region2)

% If a second region isn't supplied then do a Univariate analysis
if nargin < 6
    bivariatedata = false;
    Region2 = Region1;
else
    bivariatedata = true;
end

EventCount_Ch1 = size(Region1,1);
EventCount_Ch2 = size(Region2,1);

xCoordsColumn = 1;
yCoordsColumn = 2;

OuterRadius = Radius + deltaRadius;

LocalRegionOffset = OuterRadius * 1.5; % look for molecules nearby within this radius; should be greater than sqrt(2) to make a square that contains the search circle

PCF_data = nan(EventCount_Ch1,1);

%% Calculate the distances from each point to every other point within 2xRadius distance (to reduce memory)

    for event_ID1=1:EventCount_Ch1

        event_X1 = Region1(event_ID1,xCoordsColumn);
        event_Y1 =  Region1(event_ID1,yCoordsColumn);

        LocalRegion = [event_X1-LocalRegionOffset event_X1+LocalRegionOffset event_Y1-LocalRegionOffset event_Y1+LocalRegionOffset];
        Region2LocalCrop = RegionCropper(Region2,LocalRegion,[xCoordsColumn yCoordsColumn]);

        LocalCount_Ch2 = size(Region2LocalCrop,1);

        EventDistancesTmp = zeros(1,LocalCount_Ch2)';

        for event_ID2 = 1:LocalCount_Ch2

            event_X2 = Region2LocalCrop(event_ID2,xCoordsColumn);
            event_Y2 =  Region2LocalCrop(event_ID2,yCoordsColumn);

            EventDistancesTmp(event_ID2,1) = sqrt((event_X1-event_X2)^2+(event_Y1-event_Y2)^2);

        end
        
        EventsOuter = (length(find(EventDistancesTmp(:,1)<OuterRadius & EventDistancesTmp(:,1)>=0)));
        EventsInner = (length(find(EventDistancesTmp(:,1)<Radius & EventDistancesTmp(:,1)>=0)));
        PCF_data(event_ID1,1) = EventsOuter - EventsInner; % events within the ring
    end


%% Calculate PCF values from the distances

    % PCF = ((EventsInRange / TotalEvents) / AreaOfRange) / RegionDensity

    AreaAnnulus = pi*((OuterRadius*OuterRadius)-(Radius*Radius));
    RegionDensity = EventCount_Ch1 / (SizeX * SizeY);
    ExpectedEvents = AreaAnnulus * RegionDensity;
%     PCF_data = ((PCF_data / EventCount_Ch1)/ AreaAnnulus) / RegionDensity; % actual PCF
     PCF_data(:,2) = sqrt(PCF_data(:,1) / ExpectedEvents); % simple PCF as ratio of actual/expected

end