clc; clear; close all;
% Input subject ID
subjectID = input('Enter Subject ID: ', 's');
if isempty(subjectID)
    disp('Task aborted. No Subject ID entered.');
    return;
end
% Suppress MATLAB from capturing key presses
ListenChar(2);

% Psychtoolbox setup
Screen('Preference', 'SkipSyncTests', 1);
AssertOpenGL;
PsychDefaultSetup(2);

% Open a new window
screenNumber = max(Screen('Screens'));
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, 0);

try  
    % Define screen parameters
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    xCenter = screenXpixels / 2;
    yCenter = screenYpixels / 2;
    baseRect = [0 0 200 300];
    numDecks = 4;   

    % Set positions for the card decks 
    deckXpos = linspace(screenXpixels * 0.2, screenXpixels * 0.8, numDecks);
    deckRects = nan(4, 4); 
    for i = 1:numDecks 
        deckRects(:, i) = CenterRectOnPointd(baseRect, deckXpos(i), yCenter);
    end

    % Define colors
    deckColor = [1 1 1]; % White
    selectedColor = [0 1 0]; % Green for positive or zero outcome
    negativeOutcomeColor = [1 0 0]; % Red for negative outcome
    barColor = [0 1 0]; % Green for the total money bar

    % Task parameters
    initialLoan = 2000;
    maxMoney = 5000; % Maximum money to scale the bar
    barWidth = screenXpixels * 0.8;
    barHeight = 20;
    barXPos = xCenter - barWidth / 2;
    barYPos = 50;

    numTrials = 2;
    winAmounts = [100, 100, 50, 50];
    loseAmounts = {
        [150, 250, 350],     % Deck A
        [1250, 0],           % Deck B
        [25, 50, 75],        % Deck C
        [250, 0]             % Deck D
    };
    deckProbabilities = [5, 9, 5, 9]; % Number of wins out of 10 trials

    maxResponseTime = 5; % Maximum time for each trial in seconds
    interTrialInterval = 0.3; % Time between trials in seconds

    % Initialize task variables
    totalMoney = initialLoan;
    results = zeros(numTrials, 7); % [Trial, Deck chosen, Net outcome, , trialStartTime, trialEndTime, Response time]
    lastOutcome = 0;
    
    % Load sounds
    InitializePsychSound;
    pahandle = [];
    errorPahandle = [];
  
    % Load positive or neutral outcome sound
    [soundData, freq] = audioread('sound.wav');
    soundData = soundData';
    nrchannels = size(soundData, 1);
    pahandle = PsychPortAudio('Open', [], [] , [], [], nrchannels);
    if ~isempty(pahandle)
        PsychPortAudio('FillBuffer', pahandle, soundData); 
    end
    
    % Load negative outcome sound
    [soundErrorData, errorFreq] = audioread('sound_error.wav');
    soundErrorData = soundErrorData';
    errorNrchannels = size(soundErrorData, 1);
    errorPahandle = PsychPortAudio('Open', [], [], [], [], errorNrchannels);
    if ~isempty(errorPahandle)
        PsychPortAudio('FillBuffer', errorPahandle, soundErrorData);
    end


    % Display instructions
    imagePath = 'img1.jpg'; % Path to your image file
    theImage = imread(imagePath); % Load the   image
    imageTexture = Screen('MakeTexture', window, theImage); % Make texture from the image
    [s1, s2, ~] = size(theImage);
    dstRect = CenterRectOnPointd([0 0 0.5*s2 0.5*s1], xCenter, yCenter);
    Screen('DrawTexture', window, imageTexture, [], dstRect);
    Screen('Flip', window);
    KbStrokeWait;
    
    tStart = tic;
    for trial = 1:numTrials
        % Draw the card decks
        for i = 1:numDecks
            Screen('FillRect', window, deckColor, deckRects(:, i));
        end

        % Draw the total money bar
        barRect = [barXPos, barYPos, barXPos + (totalMoney / maxMoney) * barWidth, barYPos + barHeight];
        Screen('FillRect', window, barColor, barRect);
        Screen('FrameRect', window, [1 1 1], [barXPos, barYPos, barXPos + barWidth, barYPos + barHeight]);
        grades = linspace(0, maxMoney, 6);
        for grade = grades
            gradeX = barXPos + (grade / maxMoney) * barWidth;
            DrawFormattedText(window, num2str(grade), gradeX, barYPos + barHeight + 5, WhiteIndex(window), [], [], [], [], [], [gradeX, barYPos + barHeight + 5, gradeX + 50, barYPos + barHeight + 30]);
        end

        % Display the total money and last outcome slightly lower on the screen
        moneyText = sprintf('Total Money: $%d\nLast Outcome: $%d', totalMoney, lastOutcome);
        DrawFormattedText(window, moneyText, barXPos, 200, WhiteIndex(window)); % Adjusted Y position to 50 pixels from the top

        Screen('Flip', window);

        % Wait for participant's response
        response = 0;
        startTime = GetSecs;
        trialStartTime = toc(tStart);
        while GetSecs - startTime < maxResponseTime
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('1')) || keyCode(KbName('1!'))
                response = 1;
            elseif keyCode(KbName('2')) || keyCode(KbName('2@'))
                response = 2;
            elseif keyCode(KbName('3')) || keyCode(KbName('3#'))
                response = 3;
            elseif keyCode(KbName('4')) || keyCode(KbName('4$'))
                response = 4;
            elseif keyCode(KbName('ESCAPE'))|| keyCode(KbName('e'))
                ListenChar(0);
                sca;
                return;
            end
            if response > 0
                trialEndTime = toc(tStart);
                responseTime = trialEndTime - trialStartTime;
                break;
            end
        end

        if response == 0
            % No response within the time limit
            chosenDeck = 0;
            winAmount = 0;
            loseAmount = 0;
            netOutcome = 0;
            responseTime = maxResponseTime;
        else
            % Determine outcome for the chosen deck
            chosenDeck = response;
            winAmount = winAmounts(chosenDeck);
            if rand() < deckProbabilities(chosenDeck) / 10
                loseAmount = 0;
                netOutcome = winAmount; 
            else
                loseAmount = randsample(loseAmounts{chosenDeck}, 1);
                netOutcome = - loseAmount;
            end
            totalMoney = totalMoney + netOutcome;
            lastOutcome = netOutcome;

            % Play the appropriate sound based on the outcome
            if netOutcome < 0
                if ~isempty(errorPahandle)
                    PsychPortAudio('Start', errorPahandle, 1, 0, 1); % Play error sound
                end
            else
                if ~isempty(pahandle)
                    PsychPortAudio('Start', pahandle, 1, 0, 1); % Play positive/neutral sound
                end
            end
        end

        % Record the result, including totalMoney
        results(trial, :) = [trial, chosenDeck, netOutcome, trialStartTime, trialEndTime, responseTime, totalMoney];

        % Choose the color of the deck rectangle based on the outcome
        if netOutcome < 0
            outcomeColor = negativeOutcomeColor; % Red for negative outcome
        else
            outcomeColor = selectedColor; % Green for positive or zero outcome
        end

        % Draw the card decks with the selected deck in the chosen color
        for i = 1:numDecks
            if i == chosenDeck
                Screen('FillRect', window, outcomeColor, deckRects(:, i));
            else
                Screen('FillRect', window, deckColor, deckRects(:, i));
            end
        end

        % Draw the total money bar with a consistent green color
        barRect = [barXPos, barYPos, barXPos + (totalMoney / maxMoney) * barWidth, barYPos + barHeight];
        Screen('FillRect', window, barColor, barRect);
        Screen('FrameRect', window, [1 1 1], [barXPos, barYPos, barXPos + barWidth, barYPos + barHeight]);
        for grade = grades
            gradeX = barXPos + (grade / maxMoney) * barWidth;
            DrawFormattedText(window, num2str(grade), gradeX, barYPos + barHeight + 5, WhiteIndex(window), [], [], [], [], [], [gradeX, barYPos + barHeight + 5, gradeX + 50, barYPos + barHeight + 30]);
        end

        % Display the total money and last outcome slightly lower on the screen
        moneyText = sprintf('Total Money: $%d\nLast Outcome: $%d', totalMoney, lastOutcome);
        DrawFormattedText(window, moneyText, barXPos, 200, WhiteIndex(window)); % Adjusted Y position to 50 pixels from the top

        % Display win or loss amount
        outcomeText = sprintf('Outcome: $%d', netOutcome);
        DrawFormattedText(window, outcomeText, 'center', yCenter + 200, WhiteIndex(window));
        Screen('Flip', window);

        % Wait until 5 seconds is over
        while GetSecs - startTime < maxResponseTime
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('ESCAPE'))|| keyCode(KbName('e'))
                ListenChar(0);
                sca;
                if ~isempty(pahandle)
                    PsychPortAudio('Close', pahandle);
                end
                
                if ~isempty(errorPahandle)
                    PsychPortAudio('Close', errorPahandle);
                end
                return;
            end
        end

        % Pause for the inter-trial interval 
        WaitSecs(interTrialInterval);

        % Reset the card colors to white for the next trial
        for i = 1:numDecks
            Screen('FillRect', window, deckColor, deckRects(:, i));
        end
        Screen('Flip', window);
    end
 
    % Display Ending Window
    imagePath = 'img3.jpg'; % Path to your image file
    theImage = imread(imagePath); % Load the   image
    imageTexture = Screen('MakeTexture', window, theImage); % Make texture from the image
    [s1, s2, ~] = size(theImage);
    dstRect = CenterRectOnPointd([0 0 0.8*s2 0.8*s1], xCenter, yCenter);
    Screen('DrawTexture', window, imageTexture, [], dstRect);
    Screen('Flip', window);
    KbStrokeWait;
    ListenChar(0);
    sca;
    if ~isempty(pahandle)
        PsychPortAudio('Close', pahandle);
    end

    if ~isempty(errorPahandle)
        PsychPortAudio('Close', errorPahandle);
    end
   
    % Post-task calculations
    totalCDSelections = sum(results(:, 2) == 3 | results(:, 2) == 4);
    totalABSelections = sum(results(:, 2) == 1 | results(:, 2) == 2);
    CD_minus_AB = totalCDSelections - totalABSelections;
    
    % Calculations for every 20 trials
    segmentSize = 20;
    
    % Calculate the number of segments based on the total number of trials
    numSegments = ceil(numTrials / segmentSize);
    
    % Initialize arrays for segment-based calculations
    CDSelectionsPerSegment = zeros(numSegments, 1);
    ABSelectionsPerSegment = zeros(numSegments, 1);
    CD_minus_AB_PerSegment = zeros(numSegments, 1);
    
    for segment = 1:numSegments
        startIdx = (segment - 1) * segmentSize + 1;
        endIdx = min(segment * segmentSize, numTrials);  % Handle the case where the segment is smaller than 20 trials
        segmentData = results(startIdx:endIdx, 2);
    
        CDSelectionsPerSegment(segment) = sum(segmentData == 3 | segmentData == 4);
        ABSelectionsPerSegment(segment) = sum(segmentData == 1 | segmentData == 2);
        CD_minus_AB_PerSegment(segment) = CDSelectionsPerSegment(segment) - ABSelectionsPerSegment(segment);
    end
    
    % Adding the new columns to the results table
    resultsTable = array2table(   results, 'VariableNames', {'TrialNumber', 'SelectedDeck', 'Outcome', 'TrialStartTime', 'TrialEndTime', 'ResponseTime', 'TotalMoney'});
    
    % Extend scalar values across all rows
    resultsTable.('CDSelectionsTotal') = repmat(totalCDSelections, numTrials, 1);
    resultsTable.('ABSelectionsTotal') = repmat(totalABSelections, numTrials, 1);
    resultsTable.('CDminusABSelectionsTotal') = repmat(CD_minus_AB, numTrials, 1);
    
    % Adding segment data to the results table
    for segment = 1:numSegments
        segmentRange = (segment - 1) * segmentSize + 1 : min(segment * segmentSize, numTrials);
        resultsTable.(['CDSelectionsSeg' num2str(segment)]) = repmat(CDSelectionsPerSegment(segment), numTrials, 1);
        resultsTable.(['ABSelectionsSeg' num2str(segment)]) = repmat(ABSelectionsPerSegment(segment), numTrials, 1);
        resultsTable.(['CDminusABSelectionsSeg' num2str(segment)]) = repmat(CD_minus_AB_PerSegment(segment), numTrials, 1);
    end
    
    % Save the results file
    saveFileName = sprintf('results_%s.mat', subjectID);
    save(saveFileName, 'resultsTable');
    
catch ME
    % If an error occurs, close the window and display the error message
    ListenChar(0);
    sca;
    if ~isempty(pahandle)
        PsychPortAudio('Close', pahandle);
    end
    
    if ~isempty(errorPahandle)
        PsychPortAudio('Close', errorPahandle);
    end
    rethrow(ME);
end