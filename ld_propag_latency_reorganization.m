% determine spindle propagation patterns and number of occurences

clear; clc;

for sleep_stage=[2 3 23]; % NREM2 (2), NREM3 (3) and both (23) stages loop
    cd (['E:\Documents\Research Arnaud\CRIUGM\Sleep & Reconsolidation\BrainVision\spindles_detection\output\Fz-Cz-Pz-Oz\MSL\NREM' num2str(sleep_stage) '\propag_latency']);
    files = dir('*.mat');
    
    value = [];
    row = [];
    percent = [];
    currentPropag = [];
    sorted_propag = [];
    curr_Elec = {};
    heading = {};
    propag = [];
        
    for i=1:length(files) % pattern extraction loop - all subjects for current sleep stage
        eval(['load ' files(i).name]);
        idx=files(i).name(16:19);
        filename = ['propag_latency_' idx '_MSL_NREM' num2str(sleep_stage)];
                    
        try
            evalc(['[value, row] = sort(' filename '.pattern_occurence(:,1))']);
            evalc(['[percent, ~] = sort(' filename '.pattern_occurence(:,2))']);
        catch
            continue
        end
        
        
        evalc(['curr_Elec = (' filename '.electrode)']);
        evalc(['sorted_propag = ' filename '.pattern_propag']);
        evalc(['pattern_latency = ' filename '.pattern_latency']);
        
        sorted_propag = sorted_propag(row,:);
        pattern_latency = pattern_latency(row,:);
        cat = [sorted_propag,value,percent,pattern_latency];
        
        propagNames = cell(size(sorted_propag));
        
        for propag=1:length(row) % patterns sorted depending of occurences, and replacing electrode numbers by actual electrode names
            currentPropag = sorted_propag(propag,:);
            currentPropag = currentPropag(currentPropag~=0);
            currentPropag = curr_Elec(currentPropag)';
            while length(currentPropag) ~= size(sorted_propag,2)
                currentPropag{end+1} = '';
            end
            propagNames(propag,:) = currentPropag;
        end
        
        % headers
        for iElec=1:length(curr_Elec)
            heading(iElec) = {['elec',num2str(iElec)]};
        end; 
        for j=1:(length(curr_Elec)-1)
            heading3(j) = {['mean latency elec' num2str(j) '->elec' num2str(j+1)]};
        end; 
        heading2 = {'nb_occurence', '%occurence'};
        heading_x = [heading,heading2,heading3,heading];
        cat = num2cell(cat);
        cat2 = [cat,propagNames];
        cat_final = [heading_x;cat2];
        
        % saving
        evalc('xlswrite([''propag_MSL_NREM'' num2str(sleep_stage)] ,cat_final, [num2str(idx)])');
        disp ([filename ' done!']);
        clearvars -except choice i files sleep_stage;
    end
    clearvars -except sleep_stage files
end










