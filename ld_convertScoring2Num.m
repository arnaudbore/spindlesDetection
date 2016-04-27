function [ o_SleepStageScoring ] = ld_convertScoring2Num( i_SleepStageScoring )
%LD_CONVERTSCORING2NUM Summary of this function goes here
%   Detailed explanation goes here

o_SleepStageScoring = zeros(size(i_SleepStageScoring));

for iSc=1:length(o_SleepStageScoring)
    switch strrep(i_SleepStageScoring{iSc},' ','')
        
        case 'NREM1'
            o_SleepStageScoring(iSc) = 1;
        case 'NREM2'
            o_SleepStageScoring(iSc) = 2;
        case 'NREM3'
            o_SleepStageScoring(iSc) = 3;
        case 'NREM4'
            o_SleepStageScoring(iSc) = 4;
        case 'REM'
            o_SleepStageScoring(iSc) = 5;            
        case 'movement'
            o_SleepStageScoring(iSc) = 6;
        case 'unscored'
            o_SleepStageScoring(iSc) = 8;            
    end
end

end

