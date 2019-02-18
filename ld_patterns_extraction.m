% Arnaud Boutin - March 27th 2017
% frequency, amplitude, and duration of spindles for sleep stages NREM2, NREM3, NREM4, NREM34 and NREM234
% get the output "o_*.mat" files after running "ld_CoRe_swa_SS.m"
% select your spindle range 
% saving results in .mat and .xls files (NREM2, NREM2, NREM3 and NREM234 folders shoud be created)

clear; clc;
root = 'G:\eranet\EEG analysis\Spindles\output\';
cd ([root]);
files = dir('*.mat');
tic;
for sleep_stage=1:5 % NREM2, NREM3, NREM4, NREM34 and NREM234
    switch sleep_stage
        case 1
            sleep_stage2 = 2; sleep_stage3 = 2; sleep_stage4 = 2; idx_ss=2;
        case 2
            sleep_stage2 = 3; sleep_stage3 = 3; sleep_stage4 = 3; idx_ss=3;
        case 3
            sleep_stage2 = 4; sleep_stage3 = 4; sleep_stage4 = 4; idx_ss=4;
        case 4
            sleep_stage2 = 3; sleep_stage3 = 3; sleep_stage4 = 4; idx_ss=34;
        case 5
            sleep_stage2 = 2; sleep_stage3 = 3; sleep_stage4 = 4; idx_ss=234;
    end
    disp(['NREM' num2str(idx_ss)]);
    
    for i=1:length(files)
    eval(['load ' files(i).name]);
    idx=files(i).name(3:end-4);
    filename = [idx '_NREM' num2str(idx_ss)];


        for nElec=1:length(Info.Electrodes)
            infoElec(nElec,:) = {Info.Electrodes(nElec).labels};
        end

        for nSp=1:length(SS)  % Loop on spindles

            currSS = SS(nSp).scoring;
        
            try    
            if max(currSS == sleep_stage2) || max(currSS == sleep_stage3) || max(currSS == sleep_stage4)
                currentFreq = SS(nSp).Ref_Frequency;
                while size(currentFreq,2) ~= size(Info.Electrodes,2)
                    currentFreq(length(Info.Electrodes)) = 0;
                end
                currFreq(nSp,:) = currentFreq;
                currLength(nSp,:) = SS(nSp).Ref_Length;
                currAmplitude(nSp,:) = SS(nSp).Ref_Peak2Peak;
            end
            currFreq(currFreq<=10 | currFreq>=16) = 0; % spindle range 10-16Hz
            currLength(currFreq==0) = 0;
            currAmplitude(currFreq==0) = 0;
            den = sum(currAmplitude~=0);
            number = den;
            mean_freq = bsxfun(@rdivide, sum(currFreq), den);
            mean_amp = bsxfun(@rdivide, sum(currAmplitude), den);
            mean_length = bsxfun(@rdivide, (sum(currLength)/250), den);
               
            catch
            number = [];
            mean_freq = [];
            mean_amp = [];
            mean_length = [];
            end
        end
        
    % Summary
    s = struct('electrode',{},'number',[],'frequency',[],'amplitude',[],'duration',[]);
    s(1).electrode = [infoElec']; 
    s(1).number = [number];
    s(1).frequency = [mean_freq];
    s(1).amplitude = [mean_amp];
    s(1).duration = [mean_length];
    cat_temp = num2cell([number;mean_freq;mean_amp;mean_length]);
    header = {'number','frequency','amplitude','duration'}';
    cat = [header,cat_temp];

    evalc([idx '_NREM' num2str(idx_ss) ' = s;']);

    savdir = ([root 'NREM' num2str(idx_ss)]);
    save(fullfile(savdir,[filename]),[idx '_NREM' num2str(idx_ss)]);

    % saving
    evalc('xlswrite([''ERANET_NREM'' num2str(idx_ss)] ,cat, [num2str(idx)])');
    disp ([idx ' done']);
    clearvars -except i files idx_ss sleep_stage sleep_stage2 sleep_stage3 sleep_stage4 root
    end
    clearvars -except sleep_stage files root
    clc;
end
clc;
toc;
disp('All done!')