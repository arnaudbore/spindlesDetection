function ld_exportSpindlesAndScoring2vmrk(i_extractSpindleFile, ...
                                          i_scoringFile, ...
                                          i_selectedStageScoring, ...
                                          i_selectedElectrodes, ...
                                          i_BadInterval, ...
                                          o_vmrkFileName)
% 
% function exportSpindles2vmrk()
% 
% 
% 
% 
% Arnaud Bore: 23 novembre 2015
%       Creation exportSpindlesAndScoring2vmrk

stageScoringName = {'wake','NREM1','NREM2','NREM3','NREM4','REM','movement','unscored'}; % Sleep stages Olfacto



if nargin < 1
    % Load spindle file
    [FileName,PathName] = uigetfile('*.mat','Select extraction spindles file');
    extractSpindles = load([PathName,FileName]);
else
    extractSpindles = load(i_extractSpindleFile);
end

if nargin < 2
    % Load Scoring file
    [FileName,PathName] = uigetfile('*.mat','Select scoring file');
    scoring = load([PathName,FileName]);
else
    scoring = load(i_scoringFile);
end

% Get frequency acquisition
sRate = extractSpindles.Info.Recording.sRate;

% Get length of each scoring epoch
epoch = scoring.D.other.CRC.score{3,1};

% Structure of a marker
Marker = struct('type',{},'description',{},'position',{},'length',{},'channel',{});


for nSl=1:length(scoring.D.other.CRC.score{1,1}) % Loop sleep scoring
    if isnan(scoring.D.other.CRC.score{1,1}(nSl)+1) || ... % Check if scoring is correct
        scoring.D.other.CRC.score{1,1}(nSl)+1 > 6
        
        currentSleepStage = stageScoringName(8);
    else
        currentSleepStage = stageScoringName(scoring.D.other.CRC.score{1,1}(nSl)+1);
    end
    newmark = struct('type','Scoring', ...
                    'description',currentSleepStage, ...
                    'position',(nSl-1)*epoch*sRate, ...
                    'length',0, ...
                    'channel',0);
    Marker = [Marker newmark];
end

if nargin < 3
    % Get unique sleep stages
    stageScoring = unique(scoring.D.other.CRC.score{1,1}); 

    if any(isnan(stageScoring(:)))
        stageScoring(isnan(stageScoring))=[];
        stageScoring(end+1) = 7;
    end

    stageScoring2Select = cell(size(stageScoring));

    for i=stageScoring
        stageScoring2Select{i+1} = stageScoringName{i+1};
    end

    % Remove stage scoring not used (empty)
    stageScoring2Select = stageScoring2Select(~cellfun('isempty',stageScoring2Select));

    [selectedStageScoring,~] = listdlg('PromptString','Select Stage scoring:',...
                    'SelectionMode','multiple',...
                    'ListString',stageScoring2Select);
else
    selectedStageScoring = i_selectedStageScoring;
end

selectedStageScoringName = cell(1,size(selectedStageScoring,2));

tempInd = 1;
for i=selectedStageScoring
    selectedStageScoringName{tempInd} = stageScoringName{i};
    tempInd=tempInd+1;
end
clear ind

% To keep good relative index
selectedStageScoring = selectedStageScoring-1;

disp(['Sleep stages selected: ',selectedStageScoringName]);


if nargin < 4
    [selectedElectrodes,~] = listdlg('PromptString','Select electrodes:',...
                    'SelectionMode','multiple',...
                    'ListString',{extractSpindles.Info.Electrodes.labels});
else
    if strcmp(char(i_selectedElectrodes),'All') % If all electrodes
        selectedElectrodes = 1:length(extractSpindles.Info.Electrodes);
    else % Specific electrodes
        selectedElectrodes = i_selectedElectrodes;
    end
end

selectedElectrodesNames = cell(1,size(selectedElectrodes,2));

for i=selectedElectrodes
    selectedElectrodesNames{i} = extractSpindles.Info.Electrodes(i).labels;
end

disp(['Electrodes selected: ',selectedElectrodesNames]);

isRed = 0;

for nSp=1:length(extractSpindles.SS)  % Loop spindles
    if isRed
        isRed = 0;
    else
        isRed = 1;
    end
    for nRef=selectedElectrodes % Electrodes selected
        currentStageScoring = isempty(find(extractSpindles.SS(nSp).scoring(nRef)==selectedStageScoring, 1));
        notAlone = nnz(extractSpindles.SS(nSp).Ref_Region)>1;
        if extractSpindles.SS(nSp).Ref_Region(nRef)~=0 && ~currentStageScoring && notAlone && isRed
            newmark = struct('type','Stimulus', ...
                    'description',['Sp_' extractSpindles.SS(nSp).Ref_TypeName{nRef} '_' extractSpindles.Info.Electrodes(nRef).labels '_NREM' num2str(extractSpindles.SS(nSp).scoring(nRef))], ...
                    'position',extractSpindles.SS(nSp).Ref_Start(nRef), ...
                    'length',extractSpindles.SS(nSp).Ref_Length(nRef), ...
                    'channel',nRef);
            Marker = [Marker newmark];    
        elseif extractSpindles.SS(nSp).Ref_Region(nRef)~=0 && ~currentStageScoring && notAlone && ~isRed
            newmark = struct('type','Response', ...
                    'description',['Sp_' extractSpindles.SS(nSp).Ref_TypeName{nRef} '_' extractSpindles.Info.Electrodes(nRef).labels '_NREM' num2str(extractSpindles.SS(nSp).scoring(nRef))], ...
                    'position',extractSpindles.SS(nSp).Ref_Start(nRef), ...
                    'length',extractSpindles.SS(nSp).Ref_Length(nRef), ...
                    'channel',nRef);
            Marker = [Marker newmark];    
        elseif extractSpindles.SS(nSp).Ref_Region(nRef)~=0 && ~currentStageScoring && ~notAlone
            if isRed
                isRed = 0;
            else
                isRed = 1;
            end
            newmark = struct('type','Threshold', ...
                    'description',['Sp_' extractSpindles.SS(nSp).Ref_TypeName{nRef} '_' extractSpindles.Info.Electrodes(nRef).labels '_NREM' num2str(extractSpindles.SS(nSp).scoring(nRef))], ...
                    'position',extractSpindles.SS(nSp).Ref_Start(nRef), ...
                    'length',extractSpindles.SS(nSp).Ref_Length(nRef), ...
                    'channel',nRef);
            Marker = [Marker newmark];
        end
    end
end

if exist('i_BadInterval','var') % Store Bad Markers
    for nBM=1:length(i_BadInterval)
         newmark = struct('type','Bad Interval', ...
                    'description','Bad Min-Max', ...
                    'position',i_BadInterval(nBM).position, ...
                    'length',i_BadInterval(nBM).length, ...
                    'channel',i_BadInterval(nBM).channel);
         Marker = [Marker newmark];
    end
end

% Get VMRK EEG file
if nargin < 6 
    [vmrk_FileName,PathName] = uigetfile('*.vmrk','Select EEG file');
    vmrkFileName = [PathName,vmrk_FileName];
else
    vmrkFileName = o_vmrkFileName;
end

if exist(vmrkFileName,'file')
    fid = fopen(vmrkFileName ,'a');
else
    fid = fopen(vmrkFileName ,'w');
    fprintf(fid,'%s\n\n','Brain Vision Data Exchange Marker File, Version 2.0'...
        ,'; Data created from history path:'...
        ,'; The channel numbers are related to the channels in the exported file.');

    fprintf(fid,'%s\n','[Common Infos]', ...
               'Codepage=UTF-8');
    
    datFileName = strsplit(vmrkFileName,filesep);
    datFileName = datFileName{end};
    datFileName = strrep(datFileName, '.dat', '.vmrk');
    fprintf(fid,'%s\n\n',['DataFile=',datFileName]);
end
   

    fprintf(fid,'%s\n','[Marker Infos]'...
,'; Each entry: Mk<Marker number>=<Type>,<Description>,<Position in data points>,'...
,'; <Size in data points>, <Channel number (0 = marker is related to all channels)>'...
,'; Fields are delimited by commas, some fields might be omitted (empty).'...
,'; Commas in type or description text are coded as');

    for i = 1:length(Marker)
        fprintf(fid,'%s\n',['Mk' num2str(i) '=' Marker(i).type ',' Marker(i).description ',' num2str(Marker(i).position) ',' num2str(Marker(i).length) ',' num2str(Marker(i).channel)]);
    end


