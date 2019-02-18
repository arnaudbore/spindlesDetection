%% -- Workflow and Plots for Spindle Analysis -- %%

%%% Detection of sleep spindles %%%
% Create "raw" and "output" folders
% The raw folder includes eeg files (.eeg, .vmrk, .vhdr) and scoring files (with suffix '_gca_cica_mx.mat')
% Run "ld_CoRe_swa_SS.m" and then run "ld_patterns_extraction.m" to extract spindle features
%%%

clc
clear
tic

maindir = 'G:\Research Arnaud\CRIUGM\Sleep & Reconsolidation\CoRe\05 EEG-fMRI\Detection spindles';
cd(maindir)

% Load eeglab
addpath('C:\Program Files\MATLAB\R2015b\toolbox\eeglab13_5_4b');
addpath(genpath('E:\Documents\Research_Arnaud\CRIUGM\Sleep_Reconsolidation\BrainVision\spindles_detection'));
addpath(genpath('E:\Documents\Research_Arnaud\CRIUGM\Sleep_Reconsolidation\BrainVision\spindles_detection\swa-matlab'));

eeglab
close(gcf)
clc

load('channelsInfos.mat');

eegFolder = [maindir filesep 'raw' filesep];
outputeegFolder = [maindir filesep 'output' filesep];
allFiles = dir([ eegFolder '*.eeg']);

% Spindle Detection %
% ----------------- %
for iFile=1:length(allFiles)
    
    o_name = allFiles(iFile).name;
    eeg_name = [eegFolder allFiles(iFile).name];
    vhdr_name = [allFiles(iFile).name(1:end-3) 'vhdr'];
    vmrk_name = [allFiles(iFile).name(1:end-3) 'vmrk'];
    
    out_name = ['o_' strrep(o_name,'.eeg','.mat')];
    
    disp(['Subject: ' num2str(iFile)])
    
    % Reset channels info for each participant
    clear currentChanInfos
    
    if exist([outputeegFolder out_name],'file')
        disp(['Already done : ' out_name]);
        load([outputeegFolder out_name])
    else
%         try
            disp(['Analysis: ' allFiles(iFile).name]);
	        EEG = pop_loadbv(eegFolder, vhdr_name, [], []); % specify channels to load 
            
            for nCh=1:length(EEG.chanlocs)
                disp(['Channel : ' EEG.chanlocs(nCh).labels]);
            end

            % Info initialization
	        Info.Recording.dataDim = size(EEG.data);
	        Info.Recording.sRate = EEG.srate;

	        % get the default settings for spindle detection
            try
                Info = swa_getInfoDefaults(Info, 'SS');
                
                %  CoRe Project Modification Filter - spindles range from 10Hz to 16Hz
                Info.Parameters.Filter_hPass = [11.0 13.0]; % slow spindles
                Info.Parameters.Filter_lPass = [13.0 16.0]; % fast spindles
            catch
                disp(['Error swa_getInfoDefaults function: ' allFiles(iFile).name])
            end


            
        	for nChan = 1:length(EEG.chanlocs)  % number of channels
	            Ind = find(strcmp({ChanInfos.labels},EEG.chanlocs(nChan).labels));
	            if isempty(Ind)
	                currentChanInfos(1,nChan).labels = EEG.chanlocs(nChan).labels;
	            else
	                currentChanInfos(1,nChan) = ChanInfos(Ind);
	            end
            end

            
            Info.Electrodes = currentChanInfos;
            [~,sortElec] = sort({Info.Electrodes(:).labels});
            Info.Electrodes = Info.Electrodes(sortElec);
            
            Data.SSRef = EEG.data(sortElec,:);
            
            
%             try % Detection Spindle Mensen script
                [Data, Info, ~, SS_Core] = ld_swa_FindSSRef(Data, Info);
%             catch
%                 disp(['Error ld_swa_FindSSRef function: ' allFiles(iFile).name])
%             end
 	        
            try % Read VMRK
                i_scoringFile = [eegFolder, vmrk_name(1:end-5) '_gca_cica_mx.mat']; % scoring file suffix
                [markers, hdr, sleepStageFile] = ld_readVMRK([eegFolder, vmrk_name], Info, true, i_scoringFile);
                Info.markers = markers;
            catch
                disp(['Error ld_readVMRK function: ' allFiles(iFile).name])
            end
            
            try % Remove spindles during Bad Markers
                [SS_Core, ~] = ld_removeSpindlesDuringBadMarkers(SS_Core, Info, markers);
            catch
                disp(['Error ld_removeSpindlesDuringBadMarkers function: ' allFiles(iFile).name])                
            end

            try % Filter spindles depending on stage scoring
                SS = ld_addSleepStage2spindles(SS_Core, Info, sleepStageFile, 0);
            catch
                disp(['Error ld_addSleepStage2spindles function: ' allFiles(iFile).name])                
            end
            
            try % Save output
                swa_saveOutput(Data, Info, SS, [outputeegFolder out_name], 0, 0);
                disp(['Save ' out_name]);
            catch
                disp(['Error swa_saveOutput function: ' allFiles(iFile).name])                
            end
            
%         catch
%             disp('#########################')		        
%             disp(['Analysis: ' allFiles(iFile).name ' FAILED'])
% 	        disp('#########################')
%         end
        
        clear Data EEG SS SS_Core Info Info_input Ind o_name i_marker name i_struct_marker currentChanInfos
    end
    
    
%     try
        if ~exist('sleepStageFile','var')
            sleepStageFile = strrep([eegFolder, vmrk_name],'.vmrk','_sleepStageScoring.mat');
        end
        
        if ~exist('Info','var')
            load([outputeegFolder out_name],'Info');
        end
        
        if ~exist([outputeegFolder, vmrk_name], 'file')
            
%            %%% Temporary: write sleep stages only into the vmrk
%             spFile = load([outputeegFolder out_name]);
%             spFile.SS = [];
%             swa_saveOutput(spFile.Data, spFile.Info, spFile.SS, [outputeegFolder out_name], 0, 0);
%             clearvars spFile
%            %%% Temporary 
           
            ld_exportSpindlesAndScoring2vmrk([outputeegFolder out_name], ...
                                         sleepStageFile, ...
                                         [3 4 5], ... % NREM2, NREM3, NREM4
                                         'All', ...
                                         Info.markers.Bad_Interval, ...
                                         [outputeegFolder, vmrk_name]);
        else
           disp([outputeegFolder, vmrk_name, ' already exists']);
        end
%     catch
%         disp(['Error ld_exportSpindlesAndScoring2vmrk function: ' allFiles(iFile).name])
%     end
    clear Data Info SS SS_Core
end
toc