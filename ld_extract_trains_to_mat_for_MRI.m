clear all
clc

iFolder = '/media/bore/Projects2016/CoRe/';
oFolder = '/media/bore/Projects2016/CoRe/o/';

samplingRate = 250;

for nNight=1:2
    iTrainsFolder =  fullfile(iFolder,['CoRe_Night', num2str(nNight)], 'trains');
    for nRem=2:3
        iTrains = fullfile(iTrainsFolder,['out_analysis_Night', num2str(nNight), '_nrem' , num2str(nRem), '.mat']);
        disp(iTrains)
        load(iTrains)
        
        for nAcq=1:length(o_vars.subjects)
            currentTrainInfo = o_vars.subjects{nAcq};
            
            trains.onsets = [];

            
            % corresponding vmrk
            currVMRK = fullfile(iFolder,['CoRe_Night', num2str(nNight)],'grouped_isolated',['spNREM', num2str(nRem)],'vmrk', strrep(currentTrainInfo.filename,'mat','vmrk'));
            
            if ~exist(currVMRK,'file')
                disp([currVMRK, ' does not exist, check if it is normal'])
            else
                disp(currVMRK)
                t = 1;
                markers = ld_readVMRK(currVMRK);
                
                grouped.onsets = [];
                grouped.durations = [];
                grouped.nb = [];
                isolated.onsets = [];
                isolated.durations = [];
                
                % Validation nb spindles grouped
                if sum([currentTrainInfo.spGroup.nb]) == length(markers.SpGrouped)

                    % Loop through trains
                    for nTr=1:length(currentTrainInfo.spGroup)
                        nbSpindles = currentTrainInfo.spGroup(nTr).nb;
                        grouped.onsets(end+1) = markers.SpGrouped(1).position/250;
                        grouped.nb(end+1) = nbSpindles;
                        grouped.durations(end+1) = currentTrainInfo.spGroup(nTr).length;
                        markers.SpGrouped(1:nbSpindles) = [];
                    end
                    
                    % Isolated spindles
                    isolated.onsets = [markers.SpNotGrouped.position]'/250;
                    isolated.durations = [markers.SpNotGrouped.length]'/250;
                    
                    save(fullfile(oFolder,strrep(currentTrainInfo.filename(3:end),'.mat',['_Pz_NRem_' ,num2str(nRem), '.mat'])), 'isolated', 'grouped');
                else
                    disp('ERRROOOOOOOOOOOOOOOOOOOR')
                end
            end
        end
    end
end
