clc; clear; close all; sca;
KbName('UnifyKeyNames');
% Input subject ID
subjectID = input('Enter Subject ID: ', 's');
if isempty(subjectID)
    disp('Task aborted. No Subject ID entered.');
    return;
end
ListenChar(2);
% Setup Psychtoolbox 
try
    % Initialize Psychtoolbox
    Screen('Preference', 'SkipSyncTests', 1);
    [window, windowRect] = PsychImaging('OpenWindow', 0, [0 0 0]);
    [screenXpixels, screenYpixels] = Screen('WindowSize', window); 
    [xCenter, yCenter] = RectCenter(windowRect); 
    
    % Enable alpha blending for  transparency
    Screen('BlendFunction', window,  'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
    % Load images for predators and prey
    [predatorImg1, ~, alpha1] = imread('predator1.png');
    [predatorImg2, ~, alpha2] = imread('predator2.png');  
    [preyImg1, ~, alpha3] = imread('prey1.png');
    [preyImg2, ~, alpha4] = imread('prey2.png');   
    [preyImg3, ~, alpha5] = imread('prey3.png');
    
    % Combine the color and alpha dataee
    predatorImg1(:,:,4) = alpha1;
    predatorImg2(:,:,4) = alpha2;
    preyImg1(:,:,4) = alpha3;
    preyImg2(:,:,4) = alpha4;
    preyImg3(:,:,4) = alpha5;
    
    % Convert images to textures with transparency
     predatorTextures = {
        Screen('MakeTexture', window, predatorImg1); 
        Screen('MakeTexture', window, predatorImg2)
    };
    
    preyTextures = {
        Screen('MakeTexture', window, preyImg1);
        Screen('MakeTexture', window, preyImg2);
        Screen('MakeTexture', window, preyImg3)
    };
    
    % Task parameters
    numPred = 2;
    numPrey = 3;
    preySpeed = 0.07; % pixels/ms for prey
    predSpeed = 0.07; % pixels/ms for predators (slower than prey)
    eatingDistance = 50; % distance threshold for eating
    
    % Square parameters (central white square)
    windowLength = 675;
    windowWidth = 450;
    windowMargin = 20; 
    windowRect = CenterRectOnPointd([0 0 windowLength windowWidth], xCenter, yCenter);
    vertLines = 5; % Number of vertical lines 
    horizLines = 3; % Number of horizontal lines 
    
    
    % Initial positions and directions
    predPositions = [rand(numPred, 1).* 600 - 300 + xCenter, rand(numPred, 1).* 400 - 200 + yCenter];
    preyPositions = [rand(numPrey, 1).* 600 - 300 + xCenter, rand(numPrey, 1).* 400 - 200 + yCenter]; 
    preyDirections = rand(numPrey, 1) * 360; % degrees
    predDirections = rand(numPred, 1) * 360; % degrees
    
    % Prey visibility and respawn control
    preyVisible = true(numPrey, 1);
    preyReplaceTimes = zeros(numPrey, 1);
    
    % Results
    results = [];
    
    % Display instructions
    displayInstruction('img1.png', window)

    % Timing for interruptions
    minWait = 2; % Minimum wait time before interruption (seconds)
    maxWait = 5; % Maximum wait time before interruption (seconds)

    numTrainTrials = 9; % Number of training trials
    numTestTrials = 90; % Number of test trials
    nextInterruptTime = GetSecs + (minWait + (maxWait - minWait) * rand); % Random initial interruption time
    trialCount = 1;
    

    % Random order for 45 test trials
    trialSelection = randperm (numTestTrials/2);

    % Main task loop
    flag_instruction = 0;
    lastUpdateTime = GetSecs;

    tStart = tic;
    while trialCount <= numTrainTrials + numTestTrials
        % Check for keyboard input
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('ESCAPE'))|| keyCode(KbName('e'))
            break;  
        end
        
        %Calculate time step
        timeStep = (GetSecs - lastUpdateTime) * 1000; % ms
        lastUpdateTime = GetSecs;
       
        if (GetSecs >= nextInterruptTime) && (sum(preyVisible) == numPrey)
          
            if trialCount <= numTrainTrials/3
                taskStartTime = toc(tStart);
                [userClicks, rearrangedPositions, clickTime, distances, meanDistance] = locationInterrupt(window, windowRect, windowMargin, horizLines, vertLines, predPositions, preyPositions, predDirections, preyDirections, predatorTextures, preyTextures);
                taskEndTime = toc(tStart);
                responsTime = taskEndTime - taskStartTime;
                if (trialCount == numTrainTrials/3)
                    flag_instruction = 1;
                end
                results = [results; [repmat(trialCount,size(userClicks,1),1), repmat(1,size(userClicks,1),1), repmat(0,size(userClicks,1),1), transpose(1:size(userClicks,1)), repmat(taskStartTime,size(userClicks,1),1), repmat(taskEndTime,size(userClicks,1),1), repmat(responsTime,size(userClicks,1),1),clickTime, userClicks, rearrangedPositions, distances]; [trialCount, 1, 0, zeros(1,9), meanDistance]];
                trialCount = trialCount + 1;

            elseif trialCount <= numTrainTrials/3*2
                if (flag_instruction == 1) 
                    displayInstruction('img4.png', window)
                    flag_instruction = 0;
                else
                    taskStartTime = toc(tStart);
                    [predictedIndex, slctIndex, Error, clickTime] = typeInterrupt(window, windowRect, windowMargin, horizLines, vertLines, predPositions, preyPositions, predDirections, preyDirections, predatorTextures, preyTextures);
                    taskEndTime = toc(tStart);
                    responsTime = taskEndTime - taskStartTime;
                    results = [results; [repmat(trialCount,size(predictedIndex,1),1), repmat(2,size(predictedIndex,1),1), repmat(0,size(predictedIndex,1),1), transpose(1:size(predictedIndex,1)), repmat(taskStartTime,size(predictedIndex,1),1), repmat(taskEndTime,size(predictedIndex,1),1), repmat(responsTime,size(predictedIndex,1),1),clickTime, predictedIndex, predictedIndex, slctIndex, slctIndex, Error]];  
                    if (trialCount == numTrainTrials/3*2)
                        flag_instruction = 1;
                    end
                    trialCount = trialCount + 1;
                end
                
            elseif trialCount <= numTrainTrials
                if (flag_instruction == 1)
                    displayInstruction('img6.png', window)
                    flag_instruction = 0;
                else
                    taskStartTime = toc(tStart);
                    [predictedDirection, slctDirection, directionError] = directionInterrupt(window, windowRect, windowMargin, horizLines, vertLines, predPositions, preyPositions, predDirections, preyDirections, predatorTextures, preyTextures);
                    taskEndTime = toc(tStart);
                    responsTime = taskEndTime - taskStartTime;
                    results = [results; [trialCount, 3, 0, 1, taskStartTime, taskEndTime, responsTime, responsTime, predictedDirection, predictedDirection, slctDirection, slctDirection, directionError]]; 
                    if (trialCount == numTrainTrials)
                        flag_instruction = 1;
                    end
                    trialCount = trialCount + 1;
                end
                
            elseif trialCount <= numTrainTrials + numTestTrials/6
                if (flag_instruction == 1)
                    displayInstruction('img8.png', window)
                    flag_instruction = 0;
                else
                    taskStartTime = toc(tStart);
                    [userClicks, rearrangedPositions, clickTime, distances, meanDistance] = locationInterrupt(window, windowRect, windowMargin, horizLines, vertLines, predPositions, preyPositions, predDirections, preyDirections, predatorTextures, preyTextures);
                    taskEndTime = toc(tStart);
                    responsTime = taskEndTime - taskStartTime;
                    results = [results; [repmat(trialCount,size(userClicks,1),1), repmat(1,size(userClicks,1),1), repmat(1,size(userClicks,1),1), transpose(1:size(userClicks,1)), repmat(taskStartTime,size(userClicks,1),1), repmat(taskEndTime,size(userClicks,1),1), repmat(responsTime,size(userClicks,1),1),clickTime, userClicks, rearrangedPositions, distances]; [trialCount, 1, 1, zeros(1,9), meanDistance]];
                    if (trialCount == numTrainTrials + numTestTrials/6)
                        flag_instruction = 1;
                    end
                    trialCount = trialCount + 1;
                end
                
            elseif trialCount <= numTrainTrials + numTestTrials/3
                if (flag_instruction == 1)
                    displayInstruction('img9.png', window)
                    flag_instruction = 0;
                else
                    taskStartTime = toc(tStart);
                    [predictedIndex, slctIndex, Error, clickTime] = typeInterrupt(window, windowRect, windowMargin, horizLines, vertLines, predPositions, preyPositions, predDirections, preyDirections, predatorTextures, preyTextures);
                    taskEndTime = toc(tStart);
                    responsTime = taskEndTime - taskStartTime;
                    results = [results; [repmat(trialCount,size(predictedIndex,1),1), repmat(2,size(predictedIndex,1),1), repmat(1,size(predictedIndex,1),1), transpose(1:size(predictedIndex,1)), repmat(taskStartTime,size(predictedIndex,1),1), repmat(taskEndTime,size(predictedIndex,1),1), repmat(responsTime,size(predictedIndex,1),1),clickTime, predictedIndex, predictedIndex, slctIndex, slctIndex, Error]];  
                    if (trialCount == numTrainTrials + numTestTrials/3)
                        flag_instruction = 1;
                    end
                    trialCount = trialCount + 1;
                end
        
                
            elseif trialCount <= numTrainTrials + numTestTrials/2
                if (flag_instruction == 1)
                    displayInstruction('img10.png', window)
                    flag_instruction = 0;
                else
                    taskStartTime = toc(tStart);
                    [predictedDirection, slctDirection, directionError] = directionInterrupt(window, windowRect, windowMargin, horizLines, vertLines, predPositions, preyPositions, predDirections, preyDirections, predatorTextures, preyTextures);
                    taskEndTime = toc(tStart);
                    responsTime = taskEndTime - taskStartTime;
                    results = [results; [trialCount, 3, 1, 1, taskStartTime, taskEndTime, responsTime, responsTime, predictedDirection, predictedDirection, slctDirection, slctDirection, directionError]]; 
                    if (trialCount == numTrainTrials + numTestTrials/2)
                        flag_instruction = 1;
                    end
                    trialCount = trialCount + 1;
                end
                
            else
                if (flag_instruction == 1)
                    displayInstruction('img11.png', window)
                    flag_instruction = 0;
                else
                    if trialSelection(trialCount - 54) <= 15
                        taskStartTime = toc(tStart);
                        [userClicks, rearrangedPositions, clickTime, distances, meanDistance] = locationInterrupt(window, windowRect, windowMargin, horizLines, vertLines, predPositions, preyPositions, predDirections, preyDirections, predatorTextures, preyTextures);
                        taskEndTime = toc(tStart);
                        responsTime = taskEndTime - taskStartTime;
                        results = [results; [repmat(trialCount,size(userClicks,1),1), repmat(1,size(userClicks,1),1), repmat(2,size(userClicks,1),1), transpose(1:size(userClicks,1)), repmat(taskStartTime,size(userClicks,1),1), repmat(taskEndTime,size(userClicks,1),1), repmat(responsTime,size(userClicks,1),1),clickTime, userClicks, rearrangedPositions, distances]; [trialCount, 1, 2, zeros(1,9), meanDistance]];
                    elseif trialSelection(trialCount - 54) <= 30
                        taskStartTime = toc(tStart);
                        [predictedIndex, slctIndex, Error, clickTime] = typeInterrupt(window, windowRect, windowMargin, horizLines, vertLines, predPositions, preyPositions, predDirections, preyDirections, predatorTextures, preyTextures);
                        taskEndTime = toc(tStart);
                        responsTime = taskEndTime - taskStartTime;
                        results = [results; [repmat(trialCount,size(predictedIndex,1),1), repmat(2,size(predictedIndex,1),1), repmat(2,size(predictedIndex,1),1), transpose(1:size(predictedIndex,1)), repmat(taskStartTime,size(predictedIndex,1),1), repmat(taskEndTime,size(predictedIndex,1),1), repmat(responsTime,size(predictedIndex,1),1),clickTime, predictedIndex, predictedIndex, slctIndex, slctIndex, Error]];                 
                    elseif trialSelection(trialCount - 54) <= 45
                        taskStartTime = toc(tStart);
                        [predictedDirection, slctDirection, directionError] = directionInterrupt(window, windowRect, windowMargin, horizLines, vertLines, predPositions, preyPositions, predDirections, preyDirections, predatorTextures, preyTextures);
                        taskEndTime = toc(tStart);
                        responsTime = taskEndTime - taskStartTime;
                        results = [results; [trialCount, 3, 2, 1, taskStartTime, taskEndTime, responsTime, responsTime, predictedDirection, predictedDirection, slctDirection, slctDirection, directionError]];            
                    end  
                    trialCount = trialCount + 1;
                end
 
                        
            end 
            % Set next interruption time
            nextInterruptTime = GetSecs + (minWait + (maxWait - minWait) * rand);
            lastUpdateTime = GetSecs;
        end

        %Draw the back ground
        gameBoard(window, windowRect, windowMargin, horizLines, vertLines);

        for i = 1:numPred
            for j = 1:numPrey
                predDirections(i) = updateDirections(predDirections(i), predPositions(i, :), windowRect, windowMargin);
                predPositions(i, :) = updatePositions(predDirections(i), predPositions(i, :), predSpeed, timeStep);
                Screen('DrawTexture', window, predatorTextures{i}, [], CenterRectOnPointd([0 0 150 150], predPositions(i, 1), predPositions(i, 2)), predDirections(i));
                
                if preyVisible(j)
                    preyDirections(j) = updateDirections(preyDirections(j), preyPositions(j, :), windowRect, windowMargin);
                    preyPositions(j, :) = updatePositions(preyDirections(j), preyPositions(j, :), preySpeed, timeStep);     
                    Screen('DrawTexture', window, preyTextures{j}, [], CenterRectOnPointd([0 0 100 100], preyPositions(j, 1), preyPositions(j, 2)), preyDirections(j));
                
                elseif GetSecs >= preyReplaceTimes(j)
                    % Replace prey at a random position within the square
                    preyPositions(j,:) = [rand(1, 1).* 600 - 300 + xCenter, rand(1, 1).* 400 - 200 + yCenter];
                    preyVisible(j) = true;
                end
                if sqrt(sum((predPositions(i,:) - preyPositions(j,:)).^2)) < eatingDistance
                    preyVisible(j) = false;
                    preyReplaceTimes(j) = GetSecs + 0.05; % 50 ms disappearance
                end
            end
        end
        
        % Flip screen
        Screen('Flip', window);
    end

    displayInstruction('img12.png', window);
    Screen('Flip', window);

    buttons = 0;
    while (~any(buttons))
        [~, ~, buttons] = GetMouse(window);
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyCode(KbName('ESCAPE'))|| keyCode(KbName('e'))
            break;  
        end
    end
    
    % Saving the results table
    resultsTable = array2table(results, 'VariableNames', {'TrialNumber', 'Task', 'TrainOrTest', 'ClickNumber', 'StartTime', 'EndTime', ...
        'ResponsTime', 'ClickTime', 'PredictedValue1', 'PredictedValue2', 'AcctualValue1', 'AcctualValue2', 'Error'});
    saveFileName = sprintf('results_%s.mat', subjectID);
    save(saveFileName, 'resultsTable');

    % Saving the Summary File 
    outputFile = sprintf('results_summary_%s.txt', subjectID);
    
    % Automatically get the system type
    systemType = computer('arch');
    
    % Get the current date and time
    currentDateTime = datetime('now');
    formattedDateTime = datestr(currentDateTime, 'ddd mmm dd HH:MM:SS yyyy');
    
    
    task1_number_train = size(find(results(:,2) == 1 & results(:, 3) == 0),1) / 6;
    task1_number_test_single = size(find(results(:,2) == 1 & results(:, 3) == 1),1) / 6;
    task1_number_test_double = size(find(results(:,2) == 1 & results(:, 3) == 2),1) / 6;
    meanDist_train = mean(results(find(results(:,2) == 1 & results(:, 3) == 0 & results(:, 4) == 0), 13));
    meanDist_test_single = mean(results(find(results(:,2) == 1 & results(:, 3) == 1 & results(:, 4) == 0), 13));
    meanDist_test_double = mean(results(find(results(:,2) == 1 & results(:, 3) == 2 & results(:, 4) == 0), 13));
    time_task1_train = mean(results(find(results(:,2) == 1 & results(:, 3) == 0 & results(:, 4) == 1), 7));
    time_task1_test_single = mean(results(find(results(:,2) == 1 & results(:, 3) == 1 & results(:, 4) == 1), 7));
    time_task1_test_double = mean(results(find(results(:,2) == 1 & results(:, 3) == 2 & results(:, 4) == 1), 7));
    
    task2_number_train = size(find(results(:,2) == 2 & results(:, 3) == 0),1) / 2;
    task2_number_test_single = size(find(results(:,2) == 2 & results(:, 3) == 1),1) / 2;
    task2_number_test_double = size(find(results(:,2) == 2 & results(:, 3) == 2),1) / 2;
    acc_train = mean(results(find(results(:,2) == 2 & results(:, 3) == 0), 13));
    acc_test_single = mean(results(find(results(:,2) == 2 & results(:, 3) == 1), 13));
    acc_test_double = mean(results(find(results(:,2) == 2 & results(:, 3) == 2), 13));
    time_task2_train = mean(results(find(results(:,2) == 2 & results(:, 3) == 0), 7));
    time_task2_test_single = mean(results(find(results(:,2) == 2 & results(:, 3) == 1), 7));
    time_task2_test_double = mean(results(find(results(:,2) == 2 & results(:, 3) == 2), 7));
    
    task3_number_train = size(find(results(:,2) == 3 & results(:, 3) == 0),1);
    task3_number_test_single = size(find(results(:,2) == 3 & results(:, 3) == 1),1);
    task3_number_test_double = size(find(results(:,2) == 3 & results(:, 3) == 2),1);
    directionError_train = mean(results(find(results(:,2) == 3 & results(:, 3) == 0), 13));
    directionError_test_single = mean(results(find(results(:,2) == 3 & results(:, 3) == 1), 13));
    directionError_test_double = mean(results(find(results(:,2) == 3 & results(:, 3) == 2), 13));
    time_task3_train = mean(results(find(results(:,2) == 3 & results(:, 3) == 0), 7));
    time_task3_test_single = mean(results(find(results(:,2) == 3 & results(:, 3) == 1), 7));
    time_task3_test_double = mean(results(find(results(:,2) == 3 & results(:, 3) == 2), 7));
    
    % Open a file to write
    fileID = fopen(outputFile, 'w');
    
    % Write header for the summary
    fprintf(fileID, '===============================================\n');
    fprintf(fileID, '      Summary results from PEBL SA Test\n');
    fprintf(fileID, '===============================================\n');
    fprintf(fileID, '%s\n', formattedDateTime);
    fprintf(fileID, 'System type: %s\n', systemType);
    fprintf(fileID, '\n');
    
    % Write Practice section
    fprintf(fileID, '--------------------------------------------------------------------------------------------\n');
    fprintf(fileID, ' Training:\n');
    fprintf(fileID, 'SA         N           Acc         Time\n');
    fprintf(fileID, '--------------------------------------------------------------------------------------------\n');
    fprintf(fileID, '1          %d          %.5f        %.2f\n', task1_number_train, meanDist_train, time_task1_train);
    fprintf(fileID, '2          %d          %.5f        %.2f\n', task2_number_train, acc_train, time_task2_train);
    fprintf(fileID, '3          %d          %.5f        %.2f\n', task3_number_train, directionError_train, time_task3_train);
    fprintf(fileID, '--------------------------------------------------------------------------------------------\n');
    
    % Write Test section
    fprintf(fileID, '--------------------------------------------------------------------------------------------\n');
    fprintf(fileID, ' TEST:\n');
    fprintf(fileID, '               N                   Accuracy                Time\n');
    fprintf(fileID, 'SA     Sing        Dual       Single       Dual        Single      Dual \n');
    fprintf(fileID, '--------------------------------------------------------------------------------------------\n');
    fprintf(fileID, '1      %d          %d          %.2f        %.2f        %.2f        %.2f\n', task1_number_test_single, task1_number_test_double, meanDist_test_single, meanDist_test_double, time_task1_test_single, time_task1_test_double);
    fprintf(fileID, '2      %d          %d          %.2f        %.2f        %.2f        %.2f\n', task2_number_test_single, task2_number_test_double, acc_test_single, acc_test_double, time_task2_test_single, time_task2_test_double);
    fprintf(fileID, '3      %d          %d          %.2f        %.2f        %.2f        %.2f\n', task3_number_test_single, task3_number_test_double, directionError_test_single, directionError_test_double, time_task3_test_single, time_task3_test_double);
    fprintf(fileID, '--------------------------------------------------------------------------------------------\n');
    
    % Close the file
    fclose(fileID);

catch ME   
    % Close window if there is an error
    sca;
    ListenChar(1);
    disp('An error occurred:');
    disp(ME.message);
end

% Close screen after task ends
ListenChar(1);
sca;

%% Functions
function gameBoard(window, windowRect, windowMargin, horizLines, vertLines)
    % Draw the central white square
    Screen('FillRect', window, [255 255 255], windowRect);
    
    windowLength = windowRect(3) - windowRect(1);
    windowWidth = windowRect(4) - windowRect(2);
    vertLineSpacing = (windowLength - 2*windowMargin) / (vertLines + 1);
    horizLineSpacing = (windowWidth - 2*windowMargin) / (horizLines + 1);
    for i = 0:horizLines+1
        % Horizontal lines
        y = windowRect(2) + windowMargin + i * horizLineSpacing;
        Screen('DrawLine', window, [0 0 0], windowRect(1) + windowMargin, y, windowRect(3) - windowMargin, y, 1);
    end
    for i = 0:vertLines+1
        % Vertical lines
        x = windowRect(1) + windowMargin + i * vertLineSpacing;
        Screen('DrawLine', window, [0 0 0], x, windowRect(2) + windowMargin, x, windowRect(4) - windowMargin, 1);
    end
end
function Direction = updateDirections(Direction, Position, windowRect, windowMargin)
    % Some random movements to be unpredictable
    if rand(1,1) <= 0.005
        Direction = Direction + rand(1,1)*10 - 20; 
    end
    % Check if the predator is hitting the edges of the square
    if Position(1) <= (windowRect(1)+windowMargin+20) 
        Direction = rand(1, 1) * 180 - 90;
    elseif Position(1) >= (windowRect(3)-windowMargin-20)
        Direction = rand(1, 1) * 180 + 90;
    elseif Position(2) <= (windowRect(2)+windowMargin+20)
        Direction = rand(1, 1) * 180;
    elseif Position(2) >= (windowRect(4)-windowMargin-20)
        Direction = -rand(1, 1) * 180;
    end
end
function Position = updatePositions(Direction, Position, speed, timeStep)
        % Update predator position
        Position(1) = Position(1) + cosd(Direction) * speed * timeStep;
        Position(2) = Position(2) + sind(Direction) * speed * timeStep;
end
function [userClicks, rearrangedPositions, clickTime, distances, meanDistance] = locationInterrupt(window, windowRect, windowMargin, horizLines, vertLines, predPositions, preyPositions, predDirections, preyDirections, predatorTextures, preyTextures)
    % Hide all objects
    tic
    gameBoard(window, windowRect, windowMargin, horizLines, vertLines);
    displayTitle('img2.png', window);
    Screen('Flip', window);
    % Collect user guesses
    userClicks = [];
    clickTime = [];
    actualPositions = [preyPositions; predPositions];
    numPred = size(predPositions, 1);
    numPrey = size(preyPositions, 1);
    
    for click = 1:(numPrey + numPred)
        % Wait for user to click
        while true
            [~, ~, keyCode] = KbCheck;
            if keyCode(KbName('ESCAPE'))|| keyCode(KbName('e'))
                break;
            end
            [x, y, buttons] = GetMouse(window);
            if any(buttons)
                userClicks = [userClicks; x, y];
                clickTime = [clickTime; toc];
                % Draw a red circle at the clicked position
                gameBoard(window, windowRect, windowMargin, horizLines, vertLines);
                displayTitle('img2.png', window);           
                for i = 1:size(userClicks, 1)
                    Screen('FrameOval', window, [255 0 0], [userClicks(i,1)-10 userClicks(i,2)-10 userClicks(i,1)+10 userClicks(i,2)+10]);
                end           
                Screen('Flip', window);
                WaitSecs(0.2); % Wait to avoid multiple registrations of a single click
                break;
            end
        end
    end
    
    
    % Initialize arrays to store the results
    rearrangedPositions = zeros(5, 2); % Store rearranged actual positions
    selectedIndices = zeros(5, 1); % Store indices of selected objects
    
    for i = 1:5
        minDistance = inf; % Initialize minimum distance
        minIndex = -1; % Initialize index of the nearest object
        
        for j = 1:5
            if ~ismember(j, selectedIndices)
                % Calculate Euclidean distance
                distance = sqrt((userClicks(i, 1) - actualPositions(j, 1))^2 + ...
                                (userClicks(i, 2) - actualPositions(j, 2))^2);
                            
                % Update minimum distance and index if this is the closest so far
                if distance < minDistance
                    minDistance = distance;
                    minIndex = j;
                end
            end
        end
        
        % Store the nearest object position in the rearranged array
        rearrangedPositions(i, :) = actualPositions(minIndex, :);
        selectedIndices(i) = minIndex;
    end
    
    % Display the rearranged positions
    disp('Rearranged actual positions corresponding to user clicks:');
    disp(rearrangedPositions);

    % Calculate mean distance between guessed and actual locations
    distances = sqrt(sum((userClicks - rearrangedPositions).^2, 2));
    meanDistance = mean(distances);
    
    % Show objects again
    gameBoard(window, windowRect, windowMargin, horizLines, vertLines);
    displayTitle('img3.png', window);
    for i = 1:numPred
        Screen('DrawTexture', window, predatorTextures{i}, [], CenterRectOnPointd([0 0 150 150], predPositions(i, 1), predPositions(i, 2)), predDirections(i));
    end
    for j = 1:numPrey
        Screen('DrawTexture', window, preyTextures{j}, [], CenterRectOnPointd([0 0 100 100], preyPositions(j, 1), preyPositions(j, 2)), preyDirections(j));
    end
    for i = 1:size(userClicks, 1)
        Screen('FrameOval', window, [255 0 0], [userClicks(i,1)-10 userClicks(i,2)-10 userClicks(i,1)+10 userClicks(i,2)+10]);
    end
    Screen('Flip', window); 
    
    % Wait for user to press mouse button to continue
    while true
    [x, y, buttons] = GetMouse(window);
            if any(buttons)
                break;
            end
    end
end
function [predictedDirection, slctDirection, directionError] = directionInterrupt(window, windowRect, windowMargin, horizLines, vertLines, predPositions, preyPositions, predDirections, preyDirections, predatorTextures, preyTextures)
    
    numPred = size(predPositions, 1);
    numPrey = size(preyPositions, 1);
    % select a random predator or prey
    
    if randi(2) == 1
        slctIndex = randi(numPred);
        slctPosition = predPositions(slctIndex, :);
        slctDirection = predDirections(slctIndex);
        slctTexture = predatorTextures{slctIndex};
        slctDimension = [150 150];
    else
        slctIndex = randi(numPrey);
        slctPosition = preyPositions(slctIndex, :);
        slctDirection = preyDirections(slctIndex);
        slctTexture = preyTextures{slctIndex};
        slctDimension = [100 100];
    end
    gameBoard(window, windowRect, windowMargin, horizLines, vertLines);
    displayTitle('img7.png', window);
    Screen('FillOval', window, [255 0 0], [slctPosition(1)-10 slctPosition(2)-10 slctPosition(1)+10 slctPosition(2)+10]);
    Screen('Flip', window);
    

    while true
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('ESCAPE'))|| keyCode(KbName('e'))
            break;
        end
        [x, y, buttons] = GetMouse(window);
        if any(buttons)
            userClick = [x, y];
            predictedDirection = atan2d(userClick(2) - slctPosition(2), userClick(1) - slctPosition(1));
            gameBoard(window, windowRect, windowMargin, horizLines, vertLines);
            displayTitle('img7.png', window);
            Screen('DrawTexture', window, slctTexture, [], CenterRectOnPointd([0 0 slctDimension(1) slctDimension(2)], slctPosition(1), slctPosition(2)), predictedDirection);
            buttonRect = drawDoneButton(window, 720, 750);
            if (checkButtonClick(window, buttonRect))
                break;
            end
            Screen('Flip', window);
            WaitSecs(0.2); % Wait to avoid multiple registrations of a single click
        end
    end
   
    % Normalize predicted direction
    if predictedDirection < 0
        predictedDirection = predictedDirection + 360;
    end
    
    % Calculate the direction error
    directionError = abs(predictedDirection - slctDirection);
    if directionError > 180
        directionError = 360 - directionError;
    end
    
    % Show objects again
    gameBoard(window, windowRect, windowMargin, horizLines, vertLines);
    for i = 1:numPred
        Screen('DrawTexture', window, predatorTextures{i}, [], CenterRectOnPointd([0 0 150 150], predPositions(i, 1), predPositions(i, 2)), predDirections(i));
    end
    for j = 1:numPrey
        Screen('DrawTexture', window, preyTextures{j}, [], CenterRectOnPointd([0 0 100 100], preyPositions(j, 1), preyPositions(j, 2)), preyDirections(j));
    end
    Screen('Flip', window); 
    
end
function [predictedIndex, slctIndex, Error, clickTime] = typeInterrupt(window, windowRect, windowMargin, horizLines, vertLines, predPositions, preyPositions, predDirections, preyDirections, predatorTextures, preyTextures)
    
    numPred = size(predPositions, 1);
    numPrey = size(preyPositions, 1);
    % select two random predator or prey
    numChoice = 2;
    clickTime = zeros(numChoice,1);
    predictedIndex = zeros(numChoice,1);
    slctIndex = zeros(numChoice,1);
    slctPosition = zeros(numChoice,2);
    slctDirection = zeros(numChoice,1);
    slctTexture = zeros(numChoice,1);
    slctDimension = zeros(numChoice,2);
    
    randomNumber = randperm(numPred + numPrey,numChoice);
    for i = 1:numChoice
        if randomNumber(i) <= numPred
            slctIndex(i) = randomNumber(i);
            slctPosition(i, :) = predPositions(slctIndex(i), :);
            slctDirection(i) = predDirections(slctIndex(i));
            slctTexture(i) = predatorTextures{slctIndex(i)};
            slctDimension(i, :) = [150 150];
        else
            slctIndex(i) = randomNumber(i) - numPred;
            slctPosition(i, :) = preyPositions(slctIndex(i), :);
            slctDirection(i) = preyDirections(slctIndex(i));
            slctTexture(i) = preyTextures{slctIndex(i)};
            slctDimension(i, :) = [100 100];
        end
    end
    gameBoard(window, windowRect, windowMargin, horizLines, vertLines);
    for i = 1:numPred
        Screen('FrameOval', window, [0 0 255], [predPositions(i,1)-10 predPositions(i,2)-10 predPositions(i,1)+10 predPositions(i,2)+10]);
    end
    for j = 1:numPrey
        Screen('FrameOval', window, [0 0 255], [preyPositions(j,1)-10 preyPositions(j,2)-10 preyPositions(j,1)+10 preyPositions(j,2)+10]);
    end
    Screen('FrameOval', window, [0 0 255], [slctPosition(1, 1)-50 slctPosition(1, 2)-50 slctPosition(1, 1)+50 slctPosition(1, 2)+50]);
    displayTitle('img5.png', window);
    button1 = drawButton(window, 380, 750, predatorTextures{1});
    button2 = drawButton(window, 550, 750, predatorTextures{2});
    button3 = drawButton(window, 720, 750, preyTextures{1});
    button4 = drawButton(window, 890, 750, preyTextures{2});
    button5 = drawButton(window, 1060, 750, preyTextures{3});
    Screen('Flip', window);
    tic
    while true
        [~, ~, keyCode] = KbCheck;
        if keyCode(KbName('ESCAPE'))|| keyCode(KbName('e'))
            break;
        end
        click = 0;
        counter = 0;
        for ch = 1:numChoice
            flag = 0;
            while flag == 0
                [~, ~, keyCode] = KbCheck;
                if keyCode(KbName('ESCAPE'))|| keyCode(KbName('e'))
                    break;
                end   
                if (checkButtonClick(window, button1))
                    click = 1;
                    clickTime(ch) = toc;
                    WaitSecs(0.2);
                    flag = 1;
                    counter = counter + 1;
                elseif (checkButtonClick(window, button2))
                    click = 2;
                    clickTime(ch) = toc;
                    WaitSecs(0.2);
                    flag = 1;
                    counter = counter + 1;
                elseif (checkButtonClick(window, button3))
                    click = 3;
                    clickTime(ch) = toc;
                    WaitSecs(0.2);
                    flag = 1;
                    counter = counter + 1;
                elseif (checkButtonClick(window, button4))
                    click = 4;
                    clickTime(ch) = toc;
                    WaitSecs(0.2);
                    flag = 1;
                    counter = counter + 1;
                elseif (checkButtonClick(window, button5))
                    click = 5;
                    clickTime(ch) = toc;
                    WaitSecs(0.2);
                    flag = 1;
                    counter = counter + 1;
                end
                predictedIndex(ch) = click;
                gameBoard(window, windowRect, windowMargin, horizLines, vertLines);
                displayTitle('img5.png', window);
                for i = 1:numPred
                    Screen('FrameOval', window, [0 0 255], [predPositions(i,1)-10 predPositions(i,2)-10 predPositions(i,1)+10 predPositions(i,2)+10]);
                end
                for j = 1:numPrey
                    Screen('FrameOval', window, [0 0 255], [preyPositions(j,1)-10 preyPositions(j,2)-10 preyPositions(j,1)+10 preyPositions(j,2)+10]);
                end
                Screen('FrameOval', window, [0 0 255], [slctPosition(ch, 1)-50 slctPosition(ch, 2)-50 slctPosition(ch, 1)+50 slctPosition(ch, 2)+50]);
            
                button1 = drawButton(window, 380, 750, predatorTextures{1});
                button2 = drawButton(window, 550, 750, predatorTextures{2});
                button3 = drawButton(window, 720, 750, preyTextures{1});
                button4 = drawButton(window, 890, 750, preyTextures{2});
                button5 = drawButton(window, 1060, 750, preyTextures{3});
                switch click
                    case 1
                        Screen('DrawTexture', window, predatorTextures{1}, [], CenterRectOnPointd([0 0 150 150], slctPosition(counter, 1), slctPosition(counter, 2)), slctDirection(counter));
                    case 2
                        Screen('DrawTexture', window, predatorTextures{2}, [], CenterRectOnPointd([0 0 150 150], slctPosition(counter, 1), slctPosition(counter, 2)), slctDirection(counter));
                    case 3
                        Screen('DrawTexture', window, preyTextures{1}, [], CenterRectOnPointd([0 0 100 100], slctPosition(counter, 1), slctPosition(counter, 2)), slctDirection(counter));
                    case 4
                        Screen('DrawTexture', window, preyTextures{2}, [], CenterRectOnPointd([0 0 100 100], slctPosition(counter, 1), slctPosition(counter, 2)), slctDirection(counter));
                    case 5
                        Screen('DrawTexture', window, preyTextures{3}, [], CenterRectOnPointd([0 0 100 100], slctPosition(counter, 1), slctPosition(counter, 2)), slctDirection(counter)); 
                end
                
                Screen('Flip', window);
            end
         
        end
        Error = (slctIndex == predictedIndex);
        break;
    end
    
    % Show objects again
    gameBoard(window, windowRect, windowMargin, horizLines, vertLines);
    for i = 1:numPred
        Screen('DrawTexture', window, predatorTextures{i}, [], CenterRectOnPointd([0 0 150 150], predPositions(i, 1), predPositions(i, 2)), predDirections(i));
    end
    for j = 1:numPrey
        Screen('DrawTexture', window, preyTextures{j}, [], CenterRectOnPointd([0 0 100 100], preyPositions(j, 1), preyPositions(j, 2)), preyDirections(j));
    end
    Screen('Flip', window); 
    typeError = 0;
    
end
function buttonRect = drawDoneButton(window, xCenter, yCenter)
    % Define button size and position
    buttonWidth = 200;
    buttonHeight = 80;
    buttonRect = [0 0 buttonWidth buttonHeight];
    buttonRect = CenterRectOnPointd(buttonRect, xCenter, yCenter); % Adjust position as needed
    % Draw the button on the screen
    Screen('FillRect', window, [255 255 255], buttonRect); % Blue button
    Screen('TextSize', window, 24);
    DrawFormattedText(window, 'DONE', 'center', 'center', [0 0 0], [], [], [], [], [], buttonRect);
end
function buttonRect = drawButton(window, xCenter, yCenter, texture)
    % Define button size and position
    buttonWidth = 150;
    buttonHeight = 75;
    buttonRect = [0 0 buttonWidth buttonHeight];
    buttonRect = CenterRectOnPointd(buttonRect, xCenter, yCenter); % Adjust position as needed
    % Draw the button on the screen
    Screen('FillRect', window, [150 150 150], buttonRect); % Blue button
    Screen('DrawTexture', window, texture, [], CenterRectOnPointd([0 0 100 100], xCenter, yCenter));
end
function clicked = checkButtonClick(window, buttonRect)
    % Check if the user clicks within the button boundaries
    [x, y, buttons] = GetMouse(window);
    clicked = false;
    if any(buttons)
        % Check if the click is within the button rectangle
        if x >= buttonRect(1) && x <= buttonRect(3) && y >= buttonRect(2) && y <= buttonRect(4)
            clicked = true;
        end
    end
end
function displayInstruction(imagePath, window)
    theImage = imread(imagePath);
    imageTexture = Screen('MakeTexture', window, theImage);
    [s1, s2, ~] = size(theImage);
    [xCenter, yCenter] = RectCenter(Screen('Rect', window));
    dstRect = CenterRectOnPointd([0 0 0.8*s2 0.8*s1], xCenter, yCenter);
    Screen('DrawTexture', window, imageTexture, [], dstRect);
    Screen('Flip', window);
    buttons = 0;
    while (~any(buttons))
        [~, ~, buttons] = GetMouse(window);
    end
end
function displayTitle(imagePath, window)
    theImage = imread(imagePath);
    imageTexture = Screen('MakeTexture', window, theImage);
    [s1, s2, ~] = size(theImage);
    [xCenter, yCenter] = RectCenter(Screen('Rect', window));
    dstRect = CenterRectOnPointd([0 0 0.5*s2 0.5*s1], xCenter, 100);
    Screen('DrawTexture', window, imageTexture, [], dstRect);
end