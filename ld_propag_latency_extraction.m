% Arnaud Boutin - July 12th 2016
% latency and propagation of spindles for sleep stages NREM2, NREM3 and both

clear; clc;
cd ('E:\Documents\Research Arnaud\CRIUGM\Sleep & Reconsolidation\BrainVision\spindles_detection\output\Fz-Cz-Pz-Oz\MSL');
files = dir('*.mat');

for sleep_stage=1:3; % NREM2, NREM3 and both

switch sleep_stage
    case 1
        disp('NREM2')
        sleep_stage2 = 2; sleep_stage3 = 2; idx_ss=2;
    case 2
        disp('NREM3')
        sleep_stage2 = 3; sleep_stage3 = 3; idx_ss=3;
    case 3
        disp('NREM2 and NREM3')
        sleep_stage2 = 2; sleep_stage3 = 3; idx_ss=23;
end

for i=1:length(files)
eval(['load ' files(i).name]);
idx=files(i).name(16:19);
filename = ['propag_latency_' idx '_MSL_NREM' num2str(idx_ss)];

for nElec=1:length(Info.Electrodes)
    firstElectrode.(Info.Electrodes(nElec).labels) = [];
    infoElec(nElec,:) = {Info.Electrodes(nElec).labels};
end

iSp = 0;
propag = [];
latency = [];
latency_raw = [];
templateStringpattern = '';
pattern = [];
pattern_propag = [];
pattern_latency = [];
pattern_occurence = [];

for nSp=1:length(SS)  % Loop on spindles

    currStart = SS(nSp).Ref_Start;
    currRegion = SS(nSp).Ref_Region;
    currScoring = SS(nSp).scoring;
    
    if numel(currScoring(currScoring == sleep_stage2)>0) || numel(currScoring(currScoring == sleep_stage3)>0)
        
        indRealStart = find(currStart == min(currStart(currStart>0)));
        if length(indRealStart) > 1
            currPeak2Peak = SS(nSp).Ref_Peak2Peak(indRealStart);
            maxInd = find(currPeak2Peak == max(currPeak2Peak));
            indRealStart = indRealStart(maxInd);
        end
        firstElectrode.(Info.Electrodes(indRealStart).labels)(end+1) = nSp; 

        currStart=double(currStart); currStart(~currStart) = NaN; 
            if nansum(currStart)>0   % Loop for latency and direction of propagation
                iSp = iSp+1;
                [time,col] = sort(currStart);
                [~, col_nan] = find(isnan(time));
                propag(iSp,:) = col;
                latency_raw(iSp,:) = time;
                latency(iSp,:) = diff(time);
                    if sum(col_nan) > 0
                        for j = col_nan;
                            propag(iSp,j) = NaN;
                        end
                    else
                         propag(iSp,:) = col;
                    end
            end
    end
end

propag(isnan(propag)) = 0;
[C,ia,ic] = unique(propag,'rows','first');

for type = 1:length(ia)
    currentElectrodes = (ic==type);
    nbElectrode = sum(currentElectrodes);
    currentPropagation = propag(currentElectrodes,:);
    currentLatency = latency(currentElectrodes,:);
    pattern_latency(type,:) = mean(currentLatency,1);
    pattern_propag(type,:) = C(type,:);
    percent_occur = ((nbElectrode/(length(propag)))*100);
    pattern_occurence(type,:) = cat(1,nbElectrode,percent_occur);
end   

% Summary
s = struct('electrode',{},'propagation',[],'starting_time',[],'latency',[],'pattern_propag',[],'pattern_latency',[],'pattern_occurence',[]);
s(1).electrode = [infoElec]; 
s(1).propagation = [propag];
s(1).starting_time = [latency_raw];
s(1).latency = [latency];
s(1).pattern_propag = [pattern_propag];
s(1).pattern_latency = [pattern_latency];
s(1).pattern_occurence = [pattern_occurence];
evalc(['propag_latency_' idx '_MSL_NREM' num2str(idx_ss) ' = s;']);

savdir = (['E:\Documents\Research Arnaud\CRIUGM\Sleep & Reconsolidation\BrainVision\spindles_detection\output\Fz-Cz-Pz-Oz\MSL\NREM' num2str(idx_ss) '\propag_latency']);
save(fullfile(savdir,[filename]),['propag_latency_' idx '_MSL_NREM' num2str(idx_ss)]);
disp ([filename ' done!']);
clearvars -except choice i files idx_ss sleep_stage2 sleep_stage3;
end
clearvars -except sleep_stage files
end