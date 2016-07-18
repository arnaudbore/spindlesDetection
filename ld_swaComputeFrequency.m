function o_SS = ld_swaComputeFrequency(i_SS, i_Info)

posSign = [1, 1];
negSign = [-1, -1];

o_SS = i_SS;

for nSp=1:length(o_SS)
    o_SS(nSp).Ref_Frequency = zeros(1,size(i_Info.Electrodes,2));
    electrodes = find(o_SS(nSp).Ref_Region);
    for nElec=1:length(electrodes)
        tempSpindle = [];
        amplitudes = o_SS(nSp).Ref_PeaksAmplitude(:,electrodes(nElec));
        amplitudes(amplitudes==0) = [];
        
        tempAmplitude = amplitudes;
        
        isValid = false;
        while ~isValid
            stillWrong = false;
            for index=1:length(tempAmplitude)-1
                currentSign = sign(tempAmplitude(index:index+1));
                if sum(currentSign' == posSign)==2 || sum(currentSign' == negSign)==2
                    tempAmplitude(index) = [];
                    stillWrong = true;
                    break
                end
            end
            if ~stillWrong
                isValid = true;
            end
        end
        
        currentFreq = (length(tempAmplitude)/2) / (o_SS(nSp).Ref_Length(electrodes(nElec))/250);
        
        o_SS(nSp).Ref_Frequency(electrodes(nElec)) = currentFreq;
        
        if currentFreq > i_Info.Parameters.Filter_lPass(2) || currentFreq < i_Info.Parameters.Filter_hPass(1)

            o_SS(nSp).Ref_Frequency(electrodes(nElec)) = 0;
            o_SS(nSp).Ref_Region(electrodes(nElec))              =      0;
            o_SS(nSp).Ref_PeaksAmplitude(:, electrodes(nElec))   =      0;
            o_SS(nSp).Ref_PeaksIndice(:, electrodes(nElec))      =     0;
            o_SS(nSp).Ref_NegativePeak(electrodes(nElec))    =      0;
            o_SS(nSp).Ref_PositivePeak(electrodes(nElec))    =      0;
            o_SS(nSp).Ref_Peak2Peak(electrodes(nElec))       =      0;
            o_SS(nSp).Ref_Type(electrodes(nElec))            =      0;
            o_SS(nSp).Ref_TypeName{electrodes(nElec)}        =      [];
            o_SS(nSp).Ref_Start(electrodes(nElec))           =      0;
            o_SS(nSp).Ref_End(electrodes(nElec))             =      0;
            o_SS(nSp).Ref_Length(electrodes(nElec))          =      0;
            o_SS(nSp).Ref_NumberOfWaves(electrodes(nElec))   =      0;
            o_SS(nSp).Ref_Symmetry(electrodes(nElec))        =      0;
            
        end
    end
end

