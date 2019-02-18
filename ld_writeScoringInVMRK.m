function ld_writeScoringInVMRK(i_scoringFile, sRate, o_vmrkFileName)
% 
% 
% i_scoringFile = scoring file _gca_cica_mx.mat (D.other)
% sRate = frequency acquisition
% 

stageScoringName = {'wake','NREM1','NREM2','NREM3','NREM4','REM','movement','unscored'}; % Sleep stages Olfacto

scoring = load(i_scoringFile);

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
