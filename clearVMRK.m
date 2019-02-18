function clearVMRK(iScoring, oName)

load(iScoring)

for TE=1:length(TimeEvent)
    currTimeEvent = TimeEvent{1,TE};
    indexTimeEvent = [];
    if length(currTimeEvent) ~= 1
        last = currTimeEvent(end);
        for eachTime=length(currTimeEvent)-1:-1:1
            if currTimeEvent(eachTime) == last
                indexTimeEvent(end+1) = eachTime; %#ok<AGROW>
            end
            last = currTimeEvent(eachTime);
        end
    end
    
    if ~isempty(indexTimeEvent)
        disp(['Multiple events found in : ' NameEvent{TE} ])
        currentDescription = Description{1,TE};
        for currIndex=1:length(indexTimeEvent)
            currTimeEvent(currIndex) = [];
            currentDescription(currIndex) = [];
        end
        
        TimeEvent{1,TE} = currTimeEvent;
        Description{1,TE} = currentDescription;
        
    end
end

save(oName,'TimeEvent','NameEvent','Description','Event');