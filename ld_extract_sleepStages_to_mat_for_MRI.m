clear all
clc
mainFolder = '/home/bore/Downloads/core/vmrk_night_day1_day2/';
iFile = '/home/bore/Downloads/core/vmrk_night_day1_day2/day1/CoRe_001_Day1_Night_01.vmrk';

for nDay=1:2 % For each day/nigth
    iFolder = fullfile(mainFolder, ['day', num2str(nDay)]);
    fileList = dir(fullfile(iFolder, '*.vmrk'));
    for iFile=1:length(fileList) % loop files
        disp(fileList(iFile).name)
        
        % Cell of sleep stages found for this subject
        varExist = {}; 
        
        % Var to be able to compare sleep stages
        previousDescription = '';
        
        % clear previous sleep stages found
        clear wake NREM1 NREM2 NREM3 REM 
        
        % Current VMRK File
        currFile = fullfile(fileList(iFile).folder,fileList(iFile).name); 
        
        % Read VMRK
        [ o_markers, o_hdr, o_MarkerFilename ] = ld_readVMRK(currFile);
        
        % Output filename
        oFile = strrep(currFile,'.vmrk','.mat');
        
        % For all scoring files        
        for iScoring=1:length(o_markers.Scoring)
            nScoring = o_markers.Scoring(iScoring);
            currDescription = strrep(nScoring.description,' ','');
            
            % check if sleep stage already exists
            if ~exist(currDescription,'var') 
                %% Sleep stage does not exist
                varExist{end+1} = ['"',currDescription,'"']; %#ok<SAGROW>
                eval([currDescription, '= [];'])
                eval([currDescription,'(1).onset = nScoring.position/250;']);
                eval([currDescription,'(1).duration = 30;']);        
            elseif ~strcmp(previousDescription, nScoring.description)
                %% Sleep stage exist but diffente from previous
                eval([currDescription,'(end+1).onset = nScoring.position/250;']);
                eval([currDescription,'(end).duration = 30;']);
            else
                %% Same sleep stage as previously
                eval([currDescription,'(end).duration =' currDescription,'(end).duration +30;']);     
            end
            previousDescription = nScoring.description;
        end
        eval(['save(oFile,', strjoin(varExist,','),');'])
    end
end
