function blockedAuditionOlfaction

global BpodSystem
S = BpodSystem.ProtocolSettings;

%Individual probabilities of stimuli within modalities
odorProbs = [S.pOdor1, S.pOdor2, S.pOdor3, S.pOdor4];
numOdors = (S.useOdor1+S.useOdor2+S.useOdor3+S.useOdor4);

soundProbs = [S.pSound1, S.pSound2, S.pSound3, S.pSound4];
numSounds = (S.useSound1+S.useSound2+S.useSound3+S.useSound4);

%Initialize parameter GUI plugin
BpodParameterGUI('init', S);

%Get block/trial types
[trialInfo, blockInfo] = getTrialInfo(S.maxTrials, S.trialsPerBlock, S.modality, S.startingBlock, S.modalityProb,...
    odorProbs, numOdors, soundProbs, numSounds);

rewardedTrial = zeros(1,length(trialInfo)-1); %Index later used to determine which reinforcer to apply to response

%Initialize trial plotting
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Trial type outcome plot',...
    'numbertitle', 'off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]);
TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',trialInfo);

%%%%%% main loop start %%%%%%
for currentTrial = 1:S.maxTrials

    %Sync parameters from GUI
    S = BpodParameterGUI('sync', S);
    valveTime = GetValveTimes(S.GUI.rewardAmount, 1);

    %Only load new sound profiles to analog output module if it's the first trial, or the duration changes
    if currentTrial == 1
        lastDuration = 0;
    end
    stimulusDuration = S.GUI.stimulusDuration./1000;
    if stimulusDuration ~= lastDuration
        loadWaveforms(stimulusDuration); %Load sound waveforms into analog output module
        lastDuration = stimulusDuration;
    end 
    
    %Determine version of task, assign stimuli block-wise, and determine reinforcer for each stimulus
    switch S.modality
        case 0 %Odors and sounds
            switch blockInfo(currentTrial) %Determine if odor (0), or sound (1) block
                case 1 
                    if trialInfo(1,currentTrial) <= 4 %Odor trials = 1-4, Sound = 5-8
                        odorStimMatrix((S.GUI.fillPeriod*1000), S.GUI.stimulusDuration, (trialInfo(1,currentTrial))); %Send odor parameters to odor machine
                        rewardedTrial(currentTrial) = 1; 
                    else
                        LoadSerialMessages('AudioPlayer1', {['P' (trialInfo(1,currentTrial)-5)]}); %Send sound parameters to analog output module (sound # indexed at zero on output module)
                        rewardedTrial(currentTrial) = 2;
                    end
                case 2
                    if trialInfo(1,currentTrial) <= 4
                        odorStimMatrix((S.GUI.fillPeriod*1000), S.GUI.stimulusDuration, (trialInfo(1,currentTrial)));
                        rewardedTrial(currentTrial) = 2;
                    else
                        LoadSerialMessages('AudioPlayer1', {['P' (trialInfo(1,currentTrial)-5)]});
                        rewardedTrial(currentTrial) = 1;
                    end
            end
        case 1 %Odors only
            odorStimMatrix((S.GUI.fillPeriod*1000), S.GUI.stimulusDuration, (trialInfo(1,currentTrial))); %Send odor parameters to odor machine
            switch blockInfo(currentTrial) %Odors 1 & 2 will be used as block 1 stim, 3 & 4 will be block
                case 1 
                    if trialInfo(1,currentTrial) <= 2 
                        rewardedTrial(currentTrial) = 1; 
                    else
                        rewardedTrial(currentTrial) = 2;
                    end
                case 2
                    if trialInfo(1,currentTrial) <= 2
                        rewardedTrial(currentTrial) = 2;
                    else
                        rewardedTrial(currentTrial) = 1;
                    end
            end
        case 2 %Sounds only
            LoadSerialMessages('AudioPlayer1', {['P' (trialInfo(1,currentTrial)-5)]}); %Send sound parameters to analog output module
            switch blockInfo(currentTrial) %Sounds 1 & 2 will be used as block 1 stim, 3 & 4 will be block 2
                case 1 
                    if trialInfo(1,currentTrial) <= 6  
                        rewardedTrial(currentTrial) = 1; 
                    else
                        rewardedTrial(currentTrial) = 2;
                    end
                case 2
                    if trialInfo(1,currentTrial) <= 6
                        rewardedTrial(currentTrial) = 2;
                    else
                        rewardedTrial(currentTrial) = 1;
                    end
            end
    end
    
    switch rewardedTrial(currentTrial)
        case 1
            reinforcer = 'reward';
        case 2
            reinforcer = 'punish';
    end
    
    %State matrix
    sma = NewStateMatrix();
    
    if trialInfo(1,currentTrial)<=4 %If odor trial
        sma = AddState(sma, 'Name', 'ITI',... 
            'Timer', S.GUI.ITI,...
            'StateChangeConditions', {'Tup', 'OdorStim'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'OdorStim',... 
            'Timer', (S.GUI.fillPeriod./2),...%Scope triggers half-way through build-up 
            'StateChangeConditions', {'Tup', 'TriggerScope'},...
            'OutputActions', {'Wire1', 1}); %Trigger odor machine
        sma = AddState(sma, 'Name', 'TriggerScope',...
            'Timer', ((S.GUI.fillPeriod./2)+stimulusDuration),...
            'StateChangeConditions', {'Tup', 'delay'},...
            'OutputActions', {'BNC1', 1}); %Trigger microscope
    else %If sound trial
        sma = AddState(sma, 'Name', 'ITI',... 
            'Timer', S.GUI.ITI,...
            'StateChangeConditions', {'Tup', 'WaitForSound'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'WaitForSound',...
            'Timer', (S.GUI.fillPeriod./2),...%Scope triggers half-way through sound wait-time
            'StateChangeConditions', {'Tup', 'TriggerScope'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'TriggerScope',...
            'Timer', (S.GUI.fillPeriod./2),...
            'StateChangeConditions', {'Tup', 'SoundStim'},...
            'OutputActions', {'BNC1', 1}); %Trigger microscope
        sma = AddState(sma, 'Name', 'SoundStim',...
            'Timer', stimulusDuration,...
            'StateChangeConditions', {'Tup', 'delay'},...
            'OutputActions', {'AudioPlayer1', 1}); %Trigger sound
    end
    sma = AddState(sma, 'Name', 'delay',...
        'Timer', S.GUI.delayPeriod,...
        'StateChangeConditions', {'Tup', 'response'},...
        'OutputActions', {});
    if S.GUI.freeWater == 1 && rewardedTrial(currentTrial) == 1
        sma = AddState(sma, 'Name', 'response',...
            'Timer', S.GUI.responsePeriod,...
            'StateChangeConditions', {'Port1In', reinforcer, 'Tup', 'freeWater'},...
            'OutputAction', {});
    else  
        sma = AddState(sma, 'Name', 'response',...
            'Timer', S.GUI.responsePeriod,...
            'StateChangeConditions', {'Port1In', reinforcer, 'Tup', 'noResponse'},...
            'OutputAction', {});
    end
    sma = AddState(sma, 'Name', 'noResponse',...
        'Timer', 0,...
        'StateChangeCondition', {'Tup', 'exit'},...
        'OutputAction', {});
    sma = AddState(sma, 'Name', 'freeWater',...
        'Timer', valveTime,...
        'StateChangeConditions', {'Port1In', 'drinking', 'Tup', 'drinkingGrace'},...
        'OutputAction', {'ValveState', 1});
    sma = AddState(sma, 'Name', 'reward',...
        'Timer', valveTime,...
        'StateChangeConditions', {'Port1In', 'drinking', 'Tup', 'drinkingGrace'},...
        'OutputAction', {'ValveState', 1});
    sma = AddState(sma, 'Name', 'drinking', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port1Out', 'drinkingGrace'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'drinkingGrace',...
        'Timer', 0.5,...
        'StateChangeCondition', {'Tup', 'exit', 'Port1In', 'drinking'},...
        'OutputAction', {});
    sma = AddState(sma, 'Name', 'punish',...
        'Timer', 0.2,...
        'StateChangeCondition', {'Tup', 'timeout'},...
        'OutputAction', {'ValveState', 2});
    sma = AddState(sma, 'Name', 'timeout',...
        'Timer', S.GUI.timeoutDuration,...
        'StateChangeCondition', {'Tup', 'exit'},...
        'OutputAction', {});
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    
    if ~isempty(fieldnames(RawEvents)) %If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); %Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; %Adds the settings used for the current trial to the Data struct
        BpodSystem.Data.TrialTypes(currentTrial) = trialInfo(currentTrial); %Adds the trial type of the current trial to data
        BpodSystem.Data.BlockTypes(currentTrial) = blockInfo(currentTrial); %Adds the block type of the current trial to data
        
        
        Outcomes = zeros(1,BpodSystem.Data.nTrials);
        for x = 1:BpodSystem.Data.nTrials
            if ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.reward(1))
                Outcomes(x) = 1;
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.punish(1))
                Outcomes(x) = 0;
            else
                Outcomes(x) = 3;
            end
        end
        
        TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'update',(currentTrial+1),trialInfo,Outcomes) %Update trial outcome plot
        SaveBpodSessionData; %Saves the field BpodSystem.Data to the current data file
    end
    HandlePauseCondition; 
end
end