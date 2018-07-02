function [trialInfo, blockInfo] = getTrialInfo(maxTrials, trialsPerBlock, modality, startingBlock, modalityProb,... 
    odorProbs, numOdors, soundProbs, numSounds)

%Get number of blocks, which block to start, and interleave
numBlocks = floor(maxTrials/trialsPerBlock);
blockIdent = ones(1, numBlocks);
switch startingBlock
    case 1
        blockIdent(2:2:numBlocks) = 2;
    case 2
        blockIdent(1:2:numBlocks) = 2;
end

blockInfo = ones(1,(numBlocks*trialsPerBlock));
blockIndex = 1;
for ii = 1:length(blockIdent-1)
    blockInfo(1,blockIndex:(blockIndex+trialsPerBlock)) = blockIdent(ii);
    blockIndex = blockIndex+trialsPerBlock;
end

%Get info for individual trials
trialInfo = ones(1,maxTrials);
rng('shuffle');
roll = rand;

for ii = 1:length(blockInfo-1)
    
    probIndex = 0;
    
    if modalityProb >= roll || modality == 1 %Odor
        
        rng('shuffle');
        roll = rand;
        
            switch(numOdors)
                case 1
                    probIndex = find(odorProbs);
                    trialInfo(1,ii) = probIndex;
                case 2
                    probIndex = odorProbs;
                    [p,i] = max(probIndex);
                    if p >= roll
                        trialInfo(1,ii) = i;
                    else
                        probIndex(1,i) = -Inf;
                        [p,i] = max(probIndex);
                        trialInfo(1,ii) = i;
                    end
                case 3
                    probIndex = odorProbs;
                    [p,i] = max(probIndex);
                    if p >= roll
                        trialInfo(1,ii) = i;
                    else
                        probIndex(1,i) = -Inf;
                        [q,i] = max(probIndex);
                        p = p+q;
                        if p >= roll
                            trialInfo(1,ii) = i;
                        else
                            probIndex(1,i) = -Inf;
                            [p,i] = max(probIndex);
                            trialInfo(1,ii) = i;
                        end
                    end
                case 4
                    probIndex = odorProbs;
                    [p,i] = max(probIndex);
                    if p >= roll
                        trialInfo(1,ii) = i;
                    else
                        probIndex(1,i) = -Inf;
                        [q,i] = max(probIndex);
                        p = p+q;
                        if p >= roll
                            trialInfo(1,ii) = i;
                        else
                            probIndex(1,i) = -Inf;
                            [r,i] = max(probIndex);
                            p = p+q+r;
                            if p >= roll
                                trialInfo(1,ii) = i;
                            else
                                probIndex(1,i) = -Inf;
                                [p,i] = max(probIndex);
                                trialInfo(1,ii) = i;
                            end
                        end
                    end
            end
    elseif modalityProb < roll || modality == 2 %Sound
        
        rng('shuffle');
        roll = rand;
        
            switch(numSounds)
                case 1
                    probIndex = find(soundProbs);
                    trialInfo(1,ii) = probIndex+4;
                case 2
                    probIndex = soundProbs;
                    [p,i] = max(probIndex);
                    if p >= roll
                        trialInfo(1,ii) = i+4;
                    else
                        probIndex(1,i) = -Inf;
                        [p,i] = max(probIndex);
                        trialInfo(1,ii) = i+4;
                    end
                case 3
                    probIndex = soundProbs;
                    [p,i] = max(probIndex);
                    if p >= roll
                        trialInfo(1,ii) = i+4;
                    else
                        probIndex(1,i) = -Inf;
                        [q,i] = max(probIndex);
                        p = p+q;
                        if p >= roll
                            trialInfo(1,ii) = i+4;
                        else
                            probIndex(1,i) = -Inf;
                            [p,i] = max(probIndex);
                            trialInfo(1,ii) = i+4;
                        end
                    end
                case 4
                    probIndex = soundProbs;
                    [p,i] = max(probIndex);
                    if p >= roll
                        trialInfo(1,ii) = i+4;
                    else
                        probIndex(1,i) = -Inf;
                        [q,i] = max(probIndex);
                        p = p+q;
                        if p >= roll
                            trialInfo(1,ii) = i+4;
                        else
                            probIndex(1,i) = -Inf;
                            [r,i] = max(probIndex);
                            p = p+q+r;
                            if p >= roll
                                trialInfo(1,ii) = i+4;
                            else
                                probIndex(1,i) = -Inf;
                                [p,i] = max(probIndex);
                                trialInfo(1,ii) = i+4;
                            end
                        end
                    end
            end
      end
end  
end