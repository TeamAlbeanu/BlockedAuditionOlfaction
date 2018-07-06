%% Parsing Data from Odor-Sound task | Bpod recorded data with Devon's code
% Diego v1.0
% Modified from Priyanka's 'ParseBehaviorDataE.m'

%% Function assignment
function [HitRate, MissRate, RejectionRate, FalseAlarmRate, EarlyLickRate, CorrectResponseRate, block_indices] = ParseBehaviorData(filename,pathname,plot_figure) 

if nargin < 3    
    plot_figure = 1; % Default is to plot the figure
end

if nargin < 2
    filename = [];
    pathname = [];
end

if isempty(filename) || isempty(pathname)
    [filename,pathname] = uigetfile('.mat','Select the behavioral session to use');
    if isequal(filename,0)
        disp('User selected Cancel')
    else
        disp(['User selected',fullfile(pathname,filename)])
    end
else
    disp(['User provided',fullfile(pathname, filename)])
end

%% Loading an example file

SessionData = load(fullfile(pathname,filename));
SessionData = SessionData.SessionData;

%% nTrials = Number of trials for each session
total_trials = SessionData.nTrials;
    
%% Response classification
    if total_trials < 100
    %% Low trial session error
        disp(['Error> only', num2str(total_trials),'trials-skipping file']);
        HitRate = [];
        MissRate = [];
        RejectionRate = [];
        FalseAlarmRate = [];
        EarlyLickRate = [];
        CorrectResponseRate = [];
        block_indices = [];
        % num2str Convert numbers to character representation
        % generate message "Error> onlyXXXtrials-skippingfilex
        % XXX = value of "total_trials"
        % HitRate = []; and other similar generate empty matrices for each of those variables   
        
    %% Data matrix construction
    else
        %% Data matrix with NaN    
        Data = NaN(total_trials,13);
        Licks = NaN(total_trials,1);
        startresponse = NaN(total_trials,1);
        endITI = NaN(total_trials,1);
        % "NaN" Not a number object
        % "NaN*(M,N)" Fill M*N matrix with NaN objects
    
        %% Number of trials
        for i = (1:total_trials);
            %% Column identity
            % col1 = Odor(1) or Sound(5);
            % col2 = Go(1) or NoGo(0);
            % col3-6 = Outcome actegory - Hit, correct rejection, Miss or error -
            % relevant column gets 1, rest get NaN;
            % col7 = Early lick
            % col8 = Outcome : Correct(1), Incorrect(0) or Early Lick(NaN) -
            %           There are not Early Lick NaNs in Devon's BPod structs
            % col9 = reaction time
            % col10 = background duration (ms)
            % col11 = light stimulation(1), 0 = no light
            % col12 = block type : odor-go-sound-no-go(0), sound-go-odor-no-go(1)
            % col13 = stimulus type : 9 Khz(1) or 12 Khz(0), odor A(1) or odor B(0)

            %% Trial types
            Data(i,1) = SessionData.TrialTypes(1,i);
            % Odor stimulus = 1 ; Sound stimulus = 5

            %% Block types
            Data(i,12) = SessionData.BlockTypes(1,i);
            % Odor block = 1 ; Sound Block = 2

            %% Go-NoGo trials
            switch (Data(i,1) + 10*Data(i,12))
                case {11,25}
                       Data(i,2) = 1; % Go trial
                case {15,21}
                       Data(i,2) = 0; % NoGo trial
            end

            %% Early licking detection for eacth trial
            Licks(i,1) = isfield(SessionData.RawEvents.Trial{1,i}.Events,'Port1In');
            % 0 = no Port1In recorded data (No licking)
            % 1 = existence of Port1In recorded data (Licking)

            switch Data(i,1)
                case 1 % Odor trial
                    endITI(i,1) = SessionData.RawEvents.Trial{1,i}.States.odorITI(1,2);
                case 5 % Sound trial
                    endITI(i,1) = SessionData.RawEvents.Trial{1,i}.States.soundITI(1,2);
            end    

            startresponse(i,1) = SessionData.RawEvents.Trial{1,i}.States.response(1,1); 

            switch Licks(i,1)
                case 0 % No licking
                    ELicks(i,1) = NaN;
                case 1 % Licking
                    if (SessionData.RawEvents.Trial{1,i}.Events.Port1In(1,:) > endITI & SessionData.RawEvents.Trial{1,i}.Events.Port1In(1,:) <= startresponse) 
                        ELicks(i,1) = 1; % Early-licking
                    else 
                        ELicks(i,1) = 0; % Correct-licking
                    end
            end

            if ELicks(i,1) == 1 
                Data(i,7) = 1 % Early lick
            else
                Data(i,7) = 0 % No early lick
            end

            %% Response type
            switch Data(i,2)
                case 1 % Go trials
                    if ~isnan(SessionData.RawEvents.Trial{1,i}.States.reward)
                        Data(i,3) = 1; % Hits
                        Data(i,8) = 1; % Correct responses
                    elseif Data(i,7) == 1
                        Data(i,8) = -1 % Early lick - ignore trial
                    else
                        Data(i,5) = 1; % Misses
                        Data(i,8) = 0; % Incorrect responses
                    end

                case 0 % NoGo trials
                    if ~isnan(SessionData.RawEvents.Trial{1,i}.States.punish)
                        Data(i,6) = 1; % Errors
                        Data(i,8) = 0; % Incorrect responses
                    else
                        Data(i,4) = 1; % Correct rejections
                        Data(i,8) = 1; % Correct responses
                    end
            end
    end
        
    %% Block wise evaluation
    block_indices = [[1;1 + find(diff(Data(:,12))~=0)] [find(diff(Data(:,12))~=0);total_trials] ];
    block_indices(:,3) = 1 + (block_indices(:,2) - block_indices(:,1));
    block_indices(:,4) = Data(block_indices(:,1),12);
    % Find block start and end indices
        % col1: number of first trial friom each block
        % col2: total cumulative trials
        % col3: number of trials for each block
        % col4: block clasification number - sound(2) - odor(1)

    block_indices(find(block_indices(:,3)<20),:) = [];
    % Ignore blocks with less than 20 trials

    for ii = 1:size(block_indices,1) % for each block
        blocktype = block_indices(ii,4);
        clear MyTrials EarlyLicks
        MyTrials = Data(block_indices(ii,1):block_indices(ii,2),:);
        % For each block

        EarlyLicks = find(MyTrials(:,8)<0);
        MyTrials(EarlyLicks,:) = [];
        EarlyLickRate(ii) = size(EarlyLicks,1)/block_indices(ii,3);
        % Fraction of trials with early licks

        % Full block
        [HitRate(ii,1), MissRate(ii,1), RejectionRate(ii,1), FalseAlarmRate(ii,1), CorrectResponseRate(ii,1)] = ...
            CalculatePerformance(MyTrials);

        blocklength = floor(size(MyTrials,1)/2);

        % First half block
        [HitRate(ii,2), MissRate(ii,2), RejectionRate(ii,2), FalseAlarmRate(ii,2), CorrectResponseRate(ii,2)] = ...
            CalculatePerformance(MyTrials(1:blocklength,:));

        % Second half block
        [HitRate(ii,3), MissRate(ii,3), RejectionRate(ii,3), FalseAlarmRate(ii,3), CorrectResponseRate(ii,3)] = ...
            CalculatePerformance(MyTrials(blocklength+1:end,:)); 

    end

    %% Session Average
     MyTrials = Data;
        EarlyLicks = find(MyTrials(:,8)<0);
        MyTrials(EarlyLicks,:) = [];
        EarlyLickRate(ii+1) = size(EarlyLicks,1)/size(Data,1); % fraction of trials with early licks
        [HitRate(ii+1,1), MissRate(ii+1,1), RejectionRate(ii+1,1), FalseAlarmRate(ii+1,1), CorrectResponseRate(ii+1,1)] =  ...
            CalculatePerformance(MyTrials);

        BlockWeights = ((1-EarlyLickRate(1:ii)').*block_indices(:,3))/(total_trials-numel(EarlyLicks));
        %first half vs. second half
        for b = 2:3
            HitRate(ii+1,b) = sum(HitRate(1:ii,b).*BlockWeights);
            MissRate(ii+1,b) = sum(MissRate(1:ii,b).*BlockWeights);
            RejectionRate(ii+1,b) = sum(RejectionRate(1:ii,b).*BlockWeights);
            FalseAlarmRate(ii+1,b) = sum(FalseAlarmRate(1:ii,b).*BlockWeights);
            CorrectResponseRate(ii+1,b) = sum(CorrectResponseRate(1:ii,b).*BlockWeights);
            HitRate(ii+2,b) = std(HitRate(1:ii,b).*BlockWeights);
            MissRate(ii+2,b) = std(MissRate(1:ii,b).*BlockWeights);
            RejectionRate(ii+2,b) = std(RejectionRate(1:ii,b).*BlockWeights);
            FalseAlarmRate(ii+2,b) = std(FalseAlarmRate(1:ii,b).*BlockWeights);
            CorrectResponseRate(ii+2,b) = std(CorrectResponseRate(1:ii,b).*BlockWeights);
        end

        if plot_figure
            figure;
            % Plot the performance
            num_plots = 2;
            for iii = 1:size(block_indices,1) % for each block
                for j = 1:num_plots
                    subplot(num_plots,1,j);
                    switch block_indices(iii,4)
                        %if block_indices(i,4)
                        case 1
                            rectangle('Position',[(iii-0.5) 0 1 1],'FaceColor',[0.75 0.75 0.75],'EdgeColor','none');
                            hold on
                            % fake marker in grey to denote blocks
                            if iii == 1
                                % fake marker in blue to denote full session
                                plot(iii+2,0.2,'s','color',[0.87 0.92 0.98],'MarkerFaceColor',[0.87 0.92 0.98],'MarkerSize',12);
                                plot(iii,0.2,'s','color',[0.75 0.75 0.75],'MarkerFaceColor',[0.75 0.75 0.75],'MarkerSize',12);
                            end
                        case 2
                            rectangle('Position',[(iii-0.5) 0 1 1],'FaceColor',[0.5 0.75 0.75],'EdgeColor','none');
                            hold on
                            % fake marker in grey to denote blocks
                            if iii == 1
                                % fake marker in blue to denote full session
                                plot(iii+2,0.2,'s','color',[0.87 0.92 0.98],'MarkerFaceColor',[0.87 0.92 0.98],'MarkerSize',12);
                                plot(iii,0.2,'s','color',[0.75 0.75 0.75],'MarkerFaceColor',[0.75 0.75 0.75],'MarkerSize',12);
                            end
                    end

                    switch j
                        case 1 % early lick plot
                            plot(iii,EarlyLickRate(iii),'ob','MarkerFaceColor','b');
                            hold on
                            plot(iii,HitRate(iii,1),'og','MarkerFaceColor','g');
                            plot(iii,FalseAlarmRate(iii,1),'or','MarkerFaceColor','r');
                            plot(iii,CorrectResponseRate(iii,1),'ok','MarkerFaceColor','k');
                        case 2 % Hit Rate and Miss Rate - Early vs. Late Block
                            plot(iii-0.25,HitRate(iii,2),'og','MarkerFaceColor','none');
                            hold on
                            plot(iii-0.25,FalseAlarmRate(iii,2),'or','MarkerFaceColor','none');
                            plot(iii-0.25,CorrectResponseRate(iii,2),'ok','MarkerFaceColor','none');
                            plot(iii+0.25,HitRate(iii,3),'og','MarkerFaceColor','g');
                            plot(iii+0.25,FalseAlarmRate(iii,3),'or','MarkerFaceColor','r');
                            plot(iii+0.25,CorrectResponseRate(iii,3),'ok','MarkerFaceColor','k');
                            line([iii-0.25 iii+0.25],HitRate(iii,2:3),'color','g');
                            line([iii-0.25 iii+0.25],FalseAlarmRate(iii,2:3),'color','r');
                            line([iii-0.25 iii+0.25],CorrectResponseRate(iii,2:3),'color','k');
                    end
                end
            end

            % plot the connecting lines
            subplot(num_plots,1,1);
            plot(1:iii, EarlyLickRate(1:iii),'b');
            plot(1:iii, HitRate(1:iii,1),'g');
            plot(1:iii, FalseAlarmRate(1:iii,1),'r');
            plot(1:iii,CorrectResponseRate(1:iii,1),'k');

            % Plot session averages
            subplot(num_plots,1,1);
            rectangle('Position',[(iii+2-0.5) 0 1 1],'FaceColor',[0.87 0.92 0.98],'EdgeColor','none');
            plot(iii+2,EarlyLickRate(iii+1),'ob','MarkerFaceColor','b');
            hold on
            plot(iii+2,HitRate(iii+1,1),'og','MarkerFaceColor','g');
            plot(iii+2,FalseAlarmRate(iii+1,1),'or','MarkerFaceColor','r');
            plot(iii+2,CorrectResponseRate(iii+1,1),'ok','MarkerFaceColor','k');
            line([0 iii+3],[0.25 0.25],'LineStyle',':','color','k');
            line([0 iii+3],[0.5 0.5],'LineStyle',':','color','k');
            line([0 iii+3],[0.75 0.75],'LineStyle',':','color','k');
            xlabel('block index');
            ylabel('fraction of trials');
            legend('FullSession','SoundBlock','EarlyLicks','Hits','FalseAlarms','Performance','Location','northoutside','Orientation','horizontal')


            subplot(num_plots,1,2);
            rectangle('Position',[(iii+2-0.5) 0 1 1],'FaceColor',[0.87 0.92 0.98],'EdgeColor','none');
            errorbar(iii+1.75,HitRate(iii+1,2),HitRate(iii+2,2),'g'); % first half
            hold on
            errorbar(iii+2.25,HitRate(iii+1,3),HitRate(iii+2,3),'g'); % second half
            errorbar(iii+1.75,FalseAlarmRate(iii+1,2),FalseAlarmRate(iii+2,2),'r');
            errorbar(iii+2.25,FalseAlarmRate(iii+1,3),FalseAlarmRate(iii+2,3),'r');
            errorbar(iii+1.75,CorrectResponseRate(iii+1,2),CorrectResponseRate(iii+2,2),'k');
            errorbar(iii+2.25,CorrectResponseRate(iii+1,3),CorrectResponseRate(iii+2,3),'k');
            line([0 iii+3],[0.25 0.25],'LineStyle',':','color','k');
            line([0 iii+3],[0.5 0.5],'LineStyle',':','color','k');
            line([0 iii+3],[0.75 0.75],'LineStyle',':','color','k');
            %line([i+2 i+2],[0 1],'LineStyle',':','color','k');
            xlabel('block index');
            ylabel('fraction of trials');
            title([char(filename),' : ',num2str(total_trials),' trials : ',num2str(mode(block_indices(:,3))),' trials/block'],'Interpreter', 'none');

        end
    end
    
    %% Assigning final values
        function [HitRate, MissRate, RejectionRate, FalseAlarmRate, CorrectResponseRate] = CalculatePerformance(MyTrials)
        Hits = numel(find(MyTrials(:,3)==1));
        Misses = numel(find(MyTrials(:,2)==1)) - Hits;
        CRs = numel(find(MyTrials(:,4)==1));
        Errors = numel(find(MyTrials(:,2)==0)) - CRs;
        HitRate = Hits/(Hits+Misses);
        MissRate = Misses/(Hits+Misses);
        RejectionRate = CRs/(CRs+Errors);
        FalseAlarmRate = Errors/(CRs+Errors);
        CorrectResponseRate = (Hits+CRs)/size(MyTrials,1);
        end
end
