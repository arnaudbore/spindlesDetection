function [ o_SS, o_Info ] = ld_removeSpindlesDuringBadMarkers( i_SS, i_Info, i_markers)
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
% 2 Mars 2016
%       - ~isempty(i_SS(iSp).Ref_Region(curChannel))) was ...
%       - i_SS(iSp).Ref_Region(curChannel)>0)
% 
if nargin < 3
    % Load marker file
    [FileName,PathName] = uigetfile('*.Markers','Select marker file');
    markerFile = fopen([PathName, FileName],'r');
else
    if ischar(i_markers)
        if strfind(i_markers,'.Markers')
            markerFile = fopen(i_markers,'r');
        
            % Markers Bad Interval
            markersBI = textscan(markerFile,'%s','Delimiter','\n'); % Read File
            fclose(markerFile); % Close file

            markersBI = markersBI{1,1}(3:end,1); % remove header

            markersBI = regexp(markersBI,', ','split'); % split cells
            markersBI = vertcat(markersBI{:}); % Convert cell n*1*5 into cell n*5

            Bad_Interval = struct('type',{},'description',{},'position',{},'length',{},'channel',{});
        
            for nBM=1:length(markersBI)
                newmark = struct('type','Bad Interval', ...
                        'description',' Bad Min-Max', ...
                        'position',markersBI{nBM,4}, ...
                        'length',markersBI{nBM,3}, ...
                        'channel',convertChannel2Num(i_Info, markersBI{nBM,5}));
                Bad_Interval = [Bad_Interval newmark];
            end
        
            i_Info.markers.Bad_Interval = Bad_Interval;
        
            clear markers colHeadings
        else
            disp('This format is not supported yet')
        end
    elseif isstruct(i_markers) && ...
            isfield(i_markers,'Bad_Interval')
        markers = i_markers.Bad_Interval;
        errorMk = {markers.type}';
        typeMk = {markers.description}';
        startMk = strread(num2str([markers.position]),'%s');
        lengthMk = strread(num2str([markers.length]),'%s');
        
        if isfield(markers,'channelNumber')  % Check if field exist
            channelNumber = [markers.channelNumber];
        elseif isfield(markers,'channel')
            channelNumber = [markers.channel];
        end
        
        if any(channelNumber~=0)
            disp('@TODO convert number to electrode names')
            return
        else
            channelMk=cell(size(errorMk));
            channelMk(:) = {'All'};
        end
        markersBI = vertcat(errorMk, ...
                            typeMk, ...
                            startMk, ...
                            lengthMk, ...
                            channelMk);
        markersBI = reshape(markersBI,size(errorMk,1),5);
        
        clear errorMk typeMk startMk lengthMk channelMk markers
    else
        disp('Wrong BadMinMax file, format files allowed .Markers and .mat');
        return
    end
end


colHeadings = {'error','type','start','length','channel'}; % Structure
structMarkersBI = cell2struct(markersBI, colHeadings, 2); % Conversion

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
%     disp(['iSp: ' num2str(iSp)]);
    if InfoSp(iSp,1) == 680329
        disp('toto')
    end
    in_out = (InfoSp(iSp,2)    - InfoMarkersBI(:,1)) ./ ... %BI1 bf Sp2 
             (InfoMarkersBI(:,2) - InfoSp(iSp,1));  %Sp2 after BI1
    
    indMarker = find(in_out>0,1); % Empty if no Bad Interval
    if ~isempty(indMarker)
        try % Find wrong channel in Bad Interval if specific channel
            curChannel = strcmp({i_Info.Electrodes.labels}, structMarkersBI(indMarker).channel);
        %         disp(['CurChannel: ' num2str(curChannel)]);
        catch
            continue
        end
    end
    
    if ~isempty(indMarker) && strcmp(structMarkersBI(indMarker).error,'Bad Interval') ...
            && (strcmp(structMarkersBI(indMarker).channel,'All') ...
            || ~isempty(i_SS(iSp).Ref_Region(curChannel))) 
        
        removeSp(end+1) = iSp; %#ok<AGROW>
    end
end

% Return Info if BadMarker file update Info with Bad_Interval
o_Info = i_Info;

disp(['Number of spindles before BadInterval removal: ' num2str(length(i_SS))])

o_SS = i_SS;

for rSp=length(removeSp):-1:1
    o_SS(removeSp(rSp)) = [];
end

disp(['Number of spindles after BadInterval removal: ' num2str(length(o_SS))])

end

