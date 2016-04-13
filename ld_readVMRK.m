function [ o_markers, o_hdr, o_MarkerFilename ] = ld_readVMRK( i_markerFile, saveMatFormat)
% 
% Purpose: Read VMRK file and extract header and information
% 
% function [ output_args ] = ld_readVMRK( input_args )
% 
% i_markerFile: vmrk file
% keepScoring: store only sleep stages scoring markers
% saveMatFormat: Save sleep stages scoring markers as D.other.CRC.score 
% 
% o_marker: Marker Structure  
% 
% - > o_marker.Bad_Interval
% - > o_marker.New_Segment
% - > o_marker.QRS
% - > o_marker.Volumes
% - > o_marker.Stimulus etc..
% 
% o_hdr: Header
% 
% abore: 13 avril 2016
%   - creation of ld_readVMRK
% 

o_markers = []; % Set outputs 
o_hdr = []; % Set outputs 
o_SleepStageScoring = '';

if nargin<2
    saveMatFormat = false;
end

if nargin<1 % GUI interface
    [FileName,PathName] = uigetfile('*.vmrk','Select VMRK file');
    if FileName~=0
        markerFileId = fopen([PathName,FileName]);
    else
        disp('No VMRK file provided')
        return
    end
elseif exist(i_markerFile,'file') % Check if file exists
    markerFileId = fopen(i_markerFile); % @TODO - We should check if real vmrk file before
else
    disp([i_markerFile ' doesn''t exist']);
    return
end


tline = fgetl(markerFileId); % Get first line

o_hdr.hdr = tline;
o_tmpMarkers = struct([]);

while ischar(tline)
    if ~isempty(tline)
        if strcmp(tline(1),';') % Commentary
            % Nothing
        elseif strcmp(tline(1),'[') %             disp('ligne de subdir')
            % Nothing
%           @TODO clearly
%             subdir = tline(2:(end-1));
%             if ~strcmp(subdir,'Marker Infos')
%                 hdr.(rec(subdir)) = struct;
%             end
        elseif strcmp(tline(1:2),'Mk') % Read marker
            markerLine = strsplit(tline,'=');
            numMk = str2double(markerLine{1}(3:end));

%             disp(['Num marker: ' num2str(numMk)]);
            
            markerLine = strrep(char(markerLine(2)), ',', ', ');
            markerInfos = strsplit(markerLine,',');
            
            o_tmpMarkers(numMk).type = markerInfos{1}; % Store information
            o_tmpMarkers(numMk).description = markerInfos{2};
            o_tmpMarkers(numMk).position = str2double(markerInfos{3});
            o_tmpMarkers(numMk).length = str2double(markerInfos{4});
            o_tmpMarkers(numMk).channelNumber = str2double(markerInfos{5});
        end
    end
   tline = fgetl(markerFileId); % New line to read
end

mkType = unique({o_tmpMarkers.type});
for nType=1:length(mkType)     % Remove duplicate
    typeName = strrep(mkType{nType},' ','_');
    o_markers.(typeName) = o_tmpMarkers(strcmp({o_tmpMarkers.type},mkType(nType)));
    [~,idx] = unique([o_markers.(typeName).position]);
    o_markers.(typeName) = o_markers.(typeName)(idx);
end

if saveMatFormat % save D.other.CRC 

	o_SleepStageScoring = ld_convertScoring2Num( {o_markers.Scoring.description} );
    D.other.CRC.score{1,1} = o_SleepStageScoring;       
    o_MarkerFilename = strrep(i_markerFile,'.vmrk','_sleepStageScoring.mat');
    save(o_MarkerFilename,'D');
    disp('Only Sleep stages scoring have been extracted')
    disp('Markers have been saved using D.other.CRC format')

end
end
