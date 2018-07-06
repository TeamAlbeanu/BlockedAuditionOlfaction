    %General Parameters
    S.maxTrials = 500;
    S.trialsPerBlock = 50;
    S.startingBlock = 1; %1, or 2
    S.modality = 2; %0 = odor and sound, 1 = odor, 2 = sound
    S.modalityProb = 0; %Probability of odor trial (0 to 1)

    %General GUI
    S.GUI.freeWater = 1;
    S.GUIMeta.freeWater.Style = 'checkbox';
    S.GUI.ITI = 2; %Inter-trial interval in seconds
    S.GUI.fillPeriod = 6; %Time odor valve is open (tubes filling) before odor presentation
    S.GUI.delayPeriod = .25; %Post-stim delay period
    S.GUI.responsePeriod = 3; %Response window
    S.GUI.timeoutDuration = 6; %Punishment timeout 
    S.GUI.stimulusDuration = 300; %In ms
    S.GUI.rewardAmount = 2; %In uL
        
    %Odor parameters
    S.GUI.rewardedOdor = 1; %For odor-only session types
    S.useOdor1 = 0;
    S.pOdor1 = 0;
    S.useOdor2 = 0;
    S.pOdor2 = 0;
    S.useOdor3 = 0;
    S.pOdor3 = 0;
    S.useOdor4 = 0;
    S.pOdor4 = 0;

    %Sound parameters
    S.GUI.rewardedSound = 1; %For sound-only session types
    S.useSound1 = 1;
    S.pSound1 = 0.5;
    S.useSound2 = 0;
    S.pSound2 = 0;
    S.useSound3 = 1;
    S.pSound3 = 0.5;
    S.useSound4 = 0;
    S.pSound4 = 0;

    S.GUIPanels.Parameters = {'freeWater', 'ITI', 'fillPeriod', 'delayPeriod', 'responsePeriod', 'timeoutDuration',...
        'stimulusDuration', 'rewardAmount', 'rewardedSound', 'rewardedOdor'};
