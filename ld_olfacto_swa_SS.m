%% -- Workflow and Plots for Spindle Analysis -- %%

% Load eeglab
addpath('/home/borear/Documents/Research/Source/matlab_toolboxes/eeglab');
addpath('/media/Data/softs/spindlesDetection');
addpath(genpath('/home/borear/Documents/Research/Source/matlab_toolboxes/swa-matlab/'))

eeglab 
close(gcf)
clc
clear all

maindir = '/media/borear/Projects/olfacto_spindles_detection';
cd(maindir)
load('channelsInfos.mat');

eegFolder = [maindir filesep 'eeg_files_export' filesep];
scoringFolder = [maindir filesep 'Scoring_files' filesep];
badintervalsFolder = [maindir filesep 'BadInterval_Markers' filesep];
outputeegFolder = [maindir filesep 'Output_eeg_files' filesep];

allFiles = dir([ eegFolder 'Olfacto*.dat']);

% Spindle Detection %
% ----------------- %
for iFile=1:length(allFiles)
    
    o_name = strsplit(allFiles(iFile).name,'_');
    o_name = char(o_name(2));
    out_name = ['o_' o_name '.mat'];
    
    eeg_name = [eegFolder allFiles(iFile).name];
    vhdr_name = [allFiles(iFile).name(1:end-3) 'vhdr'];
    badinterval_name = [badintervalsFolder 'OlfactoSleep_' o_name '_ExpRawData_RDI - Bad Channel Markers.Markers'];
    sleepStageFile = [scoringFolder 'OlfactoSleep_' o_name '_ExpRaw_Data.mat'];
    
    disp(['Subject: ' num2str(iFile)])
    
    if exist([outputeegFolder out_name],'file')
        disp(['Already done : ' out_name]);
    elseif ~exist(badinterval_name,'file') || ~exist(sleepStageFile,'file')
        disp('#########################')
        disp(allFiles(iFile).name)
        disp('Some files don''t exist')
        disp('#########################')
    else
    	try %#ok<ALIGN>
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

            Data.Raw = EEG.data;
            
%             if strcmp(o_name,'033CR') % 033CR
%                 Data.SSRef = Data.Raw([1 2 3 5 6 7 8 9 10],:);
%                 currentChanInfos(4) = [];
%             elseif strcmp(o_name,'309TJ') %309TJ
%       	        Data.SSRef = Data.Raw([1 2 3 4 5 6 8 9 10],:);
%      	        currentChanInfos(7) = [];
%             elseif strcmp(o_name,'455CW') %455CW
%                 Data.SSRef = Data.Raw([1 3 8 9 10],:);
%                 currentChanInfos(7) = [];
%                 currentChanInfos(6) = [];
%                 currentChanInfos(5) = [];
%                 currentChanInfos(4) = [];
%                 currentChanInfos(2) = [];
%             elseif strcmp(o_name,'409RD') %409RD
%       	        Data.SSRef = Data.Raw([1 2 3 4 5 6 8 9 10],:);
%                 currentChanInfos(7) = [];
% %             elseif strcmp(o_name,'430PL') %430PL
% %       	        Data.SSRef = Data.Raw([1 2 3 4 5 6 7 9 10],:);
% %                 currentChanInfos(8) = [];
%             else
%                 
%             end
            
            Data.SSRef = Data.Raw;
            
            
            Info.Electrodes = currentChanInfos;
            
            try % Detection Spindle Mensen script
                [Data, Info, ~, SS_Core] = ld_swa_FindSSRef(Data, Info);
	        catch
                disp(['Error ld_swa_FindSSRef function: ' allFiles(iFile).name])
            end
            
            try % Remove spindles during Bad Markers
                [SS_Core, Info] = ld_removeSpindlesDuringBadMarkers(SS_Core, Info, badinterval_name);
            catch
                disp(['Error ld_removeSpindlesDuringBadMarkers function: ' allFiles(iFile).name])                
            end
            
            try % Filter spindles depending on stage scoring
                SS = ld_addSleepStage2spindles(SS_Core, Info, sleepStageFile, 0);
            catch
                disp(['Error ld_addSleepStage2spindles function: ' allFiles(iFile).name])                
            end
        
	        
            try % Save output
    	        disp(['Save ' out_name]);
                swa_saveOutput(Data, Info, SS, [outputeegFolder out_name], 0, 0)
            catch
                disp(['Error swa_saveOutput function: ' allFiles(iFile).name])                
            end
                
            clear Data EEG SS SS_Core Info Info_input Ind o_name i_marker name i_struct_marker
        catch
	        disp('#########################')		        
            disp(['Analysis: ' allFiles(iFile).name ' FAILED !!!!!!'])
	        disp('#########################')
	        clear Data EEG SS SS_Core Info Info_input Ind o_name i_marker name i_struct_marker
        end
        
        try 
            vmrk_name = [outputeegFolder allFiles(iFile).name(1:end-3) 'vmrk'];
 
            if ~exist('Info','var')
                load([outputeegFolder out_name],'Info');
            end
            
            ld_exportSpindlesAndScoring2vmrk([outputeegFolder out_name], ...
                    sleepStageFile, ...
                    [3 4 5], ... % NREM2, NREM3, NREM4
                    'All', ... % All channels
                    Info.markers.Bad_Interval, ...
                    vmrk_name);
               
        catch
            disp(['Error ld_exportSpindlesAndScoring2vmrk function: ' allFiles(iFile).name])
        end
    end
end

