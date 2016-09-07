function GF_K_data = GF_Measure(Region1,Radius,SizeX,SizeY,Region2)

% If a second region isn't supplied then do a Univariate analysis
if nargin < 5
    bivariatedata = false;
    Region2 = Region1;
else
    bivariatedata = true;
end

EventCount_Ch1 = size(Region1,1);
EventCount_Ch2 = size(Region2,1);

%fix these
xCoordsColumn = 1;
yCoordsColumn = 2;

LocalRegionOffset = Radius * 1.5; % look for molecules nearby within this radius; should be greater than sqrt(2) to make a square that contains the search circle

% init GF values array
GF_K_data = nan(EventCount_Ch1,1);

% Distances by pdist ... fails with large datasets.
%      RegionDistancesTmp2 = sort(pdist2(Region2(:,xCoordsColumn:yCoordsColumn),Region1(:,xCoordsColumn:yCoordsColumn)));

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

        % If you want a list of the distances, then use this line. Large
        % data sets (>30k events) will cause memory errors at this stage though.
%         RegionDistancesTmp(1:size(EventDistancesTmp,1),event_ID1) = EventDistancesTmp;
        
        if ~bivariatedata
            % count all the events within range and subtract one for the distance-to-self value (zero)
            GF_K_data(event_ID1) = length(find(EventDistancesTmp(:,1)<Radius & EventDistancesTmp(:,1)>=0)) - 1;
        else
            % bivar, will never include self-event, so count all events within range.
            GF_K_data(event_ID1) = length(find(EventDistancesTmp(:,1)<Radius & EventDistancesTmp(:,1)>=0));
        end

    end


%% Calculate G&F values from the distances

    % G&F is the Ripley L function at a single r
    % L(r) = sqrt( (TotalArea * EventCountWithin_r) / (pi*(TotalEvents - 1))
    % Getis, A., Franklin, J. (1987) Second-Order Neighborhood Analysis of Mapped Point Patterns. Ecology 68:473-477
   
    if ~bivariatedata
        % Normalise to expected events, accounting for self
        GF_K_data = sqrt(((SizeX * SizeY) * GF_K_data) / ((EventCount_Ch1 - 1) * pi));
    else
        % Normalise to all expected events
        GF_K_data = sqrt(((SizeX * SizeY) * GF_K_data) / ((EventCount_Ch2) * pi));     
    end
end