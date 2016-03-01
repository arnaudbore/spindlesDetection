function [ o_SS ] = ld_removeSpindlesDuringBadMarkers( i_SS, i_Info, i_markers)
%
%   [ o_SS ] = ld_removeSpindlesDuringBadMarkers( i_SS, i_markers)
%
%   Sp1 => Begining of the spindle
%   Sp2 => End of the spindle
%
%   BI1 => Begining bad interval
%   BI2 => End bad interval
%   
%   Condition Sp while BI if
%       (Sp2-BI1) / (BI2-Sp1) > 0
%   
%   i_SS: Structure of spindles (Mensen format)
%   i_markers: Markers of BadInterval
% 
% 29 Fev 2016: 
%       - Creation and debug
% 

if nargin < 3
    % Load marker file
    [FileName,PathName] = uigetfile('*.Markers','Select marker file');
    markerFile = fopen([PathName, FileName],'r');
else
    markerFile = fopen(i_markers,'r');
end


% Markers Bad Interval
markersBI = textscan(markerFile,'%s','Delimiter','\n'); % Read File
fclose(markerFile); % Close file

markersBI = markersBI{1,1}(3:end,1); % remove header

markersBI = regexp(markersBI,', ','split'); % split cells
markersBI = vertcat(markersBI{:}); % Convert cell n*1*5 into cell n*5

colHeadings = {'error','type','start','length','channel'}; % Structure
structMarkersBI = cell2struct(markersBI, colHeadings, 2); % Conversion

clear markers colHeadings

% Get Info start, stop
InfoMarkersBI = [str2double({structMarkersBI.start}'), ...
    str2double({structMarkersBI.start}')+ str2double({structMarkersBI.length}')];

numElec = length(i_Info.Electrodes);
numSp = length(i_SS);


spStart = reshape(cell2mat({i_SS.Ref_Start}),numElec,numSp)';
spStart(spStart==0)=NaN;
spStart = min(spStart,[],2);

spStop = reshape(cell2mat({i_SS.Ref_End}),numElec,numSp)';
spStop(spStop==0)=NaN;
spStop = min(spStop,[],2);

InfoSp = [spStart, spStop];

removeSp = [];


for iSp = 1:length(i_SS) % Loop on spindles
    
    in_out = (InfoSp(iSp,2)    - InfoMarkersBI(:,1)) ./ ... %BI1 bf Sp2 
             (InfoMarkersBI(:,2) - InfoSp(iSp,1));  %Sp2 after BI1
    
    indMarker = find(in_out>0,1); % Empty if no Bad Interval
    
    try % Find wrong channel in Bad Interval if specific channel
        curChannel = strcmp({i_Info.Electrodes.labels}, structMarkersBI(indMarker).channel);
    catch
        continue
    end
    
    if ~isempty(indMarker) && strcmp(structMarkersBI(indMarker).error,'Bad Interval') ...
            && (strcmp(structMarkersBI(indMarker).channel,'All') ...
            || i_SS(iSp).Ref_Region(curChannel)>0) 
        
        removeSp(end+1) = iSp; %#ok<AGROW>
    end
end

disp(['Number of spindles before BadInterval removal: ' num2str(length(i_SS))])

for rSp=length(removeSp):-1:1
    i_SS(rSp) = [];
end

disp(['Number of spindles after BadInterval removal: ' num2str(length(i_SS))])

o_SS = i_SS;

end

