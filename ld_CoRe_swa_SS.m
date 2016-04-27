%% -- Workflow and Plots for Spindle Analysis -- %%

clc
clear all


% Load eeglab
addpath('/home/borear/Documents/Research/Source/matlab_toolboxes/eeglab');
addpath('/media/Data/softs/spindlesDetection');
addpath(genpath('/home/borear/Documents/Research/Source/matlab_toolboxes/swa-matlab/'))

eeglab
close(gcf)
clc
% clear all

maindir = '/media/Data/Seafile/project_sleep_eeg_msl_spindles/dev_pipeline';

cd(maindir)
load('channelsInfos.mat');

eegFolder = [maindir filesep 'raw' filesep];
outputeegFolder = [maindir filesep 'output' filesep];

allFiles = dir([ eegFolder '*.dat']);



% Spindle Detection %
% ----------------- %
for iFile=3%1:length(allFiles)
    
    o_name = allFiles(iFile).name;
    eeg_name = [eegFolder allFiles(iFile).name];
    vhdr_name = [allFiles(iFile).name(1:end-3) 'vhdr'];
    vmrk_name = [allFiles(iFile).name(1:end-3) 'vmrk'];
    
    out_name = ['o_' strrep(o_name,'.dat','.mat')];
    
    disp(['Subject: ' num2str(iFile)])
    
    if exist([outputeegFolder out_name],'file')
        disp(['Already done : ' out_name]);
        load([outputeegFolder out_name])
    else
        try
            disp(['Analysis: ' allFiles(iFile).name]);
	        EEG = pop_loadbv(eegFolder, vhdr_name);    

            % Info initialization
	        Info.Recording.dataDim = size(EEG.data);
	        Info.Recording.sRate = EEG.srate;

	        % get the default settings for spindle detection
            try
                Info = swa_getInfoDefaults(Info, 'SS');
            catch
                disp(['Error swa_getInfoDefaults function: ' allFiles(iFile).name])
            end
            
            
        	for nChan = 1:length(EEG.chanlocs) %#ok<ALIGN>
	            Ind = find(strcmp({ChanInfos.labels},EEG.chanlocs(nChan).labels));
	            if isempty(Ind)
	                currentChanInfos(1,nChan).labels = EEG.chanlocs(nChan).labels;
	            else
	                currentChanInfos(1,nChan) = ChanInfos(Ind);
	            end
            end

            Data.SSRef = EEG.data;
            Info.Electrodes = currentChanInfos;
            
            try % Detection Spindle Mensen script
                [Data, Info, ~, SS_Core] = ld_swa_FindSSRef(Data, Info);
            catch
                disp(['Error ld_swa_FindSSRef function: ' allFiles(iFile).name])
            end
	        
            try % Read VMRK
                [markers, hdr, sleepStageFile] = ld_readVMRK([eegFolder, vmrk_name], Info, true);
                Info.markers = markers; 
            catch
                disp(['Error ld_swa_FindSSRef function: ' allFiles(iFile).name])
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
            
        catch
            disp('#########################')		        
            disp(['Analysis: ' allFiles(iFile).name ' FAILED'])
	        disp('#########################')
	        clear Data EEG SS SS_Core Info Info_input Ind o_name i_marker name i_struct_marker
        end
    end
       
    
    try
        if ~exist('sleepStageFile','var')
            sleepStageFile = strrep([eegFolder, vmrk_name],'.vmrk','_sleepStageScoring.mat');
        end
        
        if ~exist('Info','var')
            load([outputeegFolder out_name],'Info');
        end
        ld_exportSpindlesAndScoring2vmrk([outputeegFolder out_name], ...
                                     sleepStageFile, ...
                                     [3 4 5], ... % NREM2, NREM3, NREM4
                                     'All', ...
                                     Info.markers.Bad_Interval, ...
                                     vmrk_name);
    catch
        disp(['Error ld_exportSpindlesAndScoring2vmrk function: ' allFiles(iFile).name])
    end
    
end