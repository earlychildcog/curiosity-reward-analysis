function S = fET_GetTimings_curR(T)

fprintf("Extracting timing values.... \n");

markers_steps = [...
    "::trial start" ...              % exposure starts
    "curtain start moving" ...       % hiding starts
    "curtain stop moving" ...        % hiding stops/exploration starts
    "::first trigger colour for" ... % first item starts being revealed
    "::trigger colour for" ...       % second item starts being revealed
    "::end" ...                      % trial ends
    ];
phaseNames = [...
    "exposure" ...
    "hiding" ...
    "exploration" ...
    "revealed1st" ...
    "revealed2nd" ...
    "end" ...
    ];
variablesToExtract = ["session" "trial" "trialType" "isBadFirstPhase" "time0" "time" "messages"];

% --- Only keep data during trials test phase (time0)
time_n = 0;
phase = "exploration";
variables = ["session" "trial" "time"];
S = f_getTimingsFromMarkers(T, markers_steps, phaseNames, phase, variables, time_n);
T = innerjoin(T,S,Keys=["session" "trial"]);
T(T.time < T.time0, :) = []; % take out data before test phase starts (time0)
% --- Extract time1 (1st look at AOI1), time2 (first look at AOI2), difftime (time to look at AOI2 after AOI1)
% Extract time 1st look to AOI1 in table S1 -- just for reference variable: no outlier rejection
time_n = 1;
phase = "revealed1st";
S1 = f_getTimingsFromMarkers(T, markers_steps, phaseNames, phase, variablesToExtract, time_n);
% Extract time trigger reward AOI1 in table S1
% (we don't have a trigger, csn't do it this way)
% Extract 1st look to AOI2 in table S2
time_n = 2;
phase = "revealed2nd";
S2 = f_getTimingsFromMarkers(T, markers_steps, phaseNames, phase, variablesToExtract, time_n);
% Save all to the same table S & calculate time to look at AOI2 after AOI1
S = innerjoin(S1, S2, Keys=variablesToExtract(1:end-2));
% Delete double entries (because small delays can happen in sending triggers for 'first trigger' vs 'trigger', the latter of which is sadly sent even though it shouldn't for AOI1 (as well as AOI2), so AOI1 has 2 triggers and can be picked up several times, especially if noisy data -> gaze lost for a short time and triggers further apart...)
S(S.fixroi1 == S.fixroi2,:) = [];
S = outerjoin(S, S1, Keys=[variablesToExtract(1:end-2) "messages1" "fixroi1" "time1"], MergeKeys=true); % re-add the trials in which only 1 box was open
% Extract time to look at AOI2 after AOI1, merge all, get timings relative to start test phase (time0)
S.difftime = S.time2 - S.time1;
S.time1 = S.time1 - S.time0;
S.time2 = S.time2 - S.time0;
S.isBadReward(:) = 0;
% Exclude trials when reward didn't have time to start for box1
S.isBadReward(S.difftime < 1500) = 1;


% HELPER FUNCTION
function S_Out = f_getTimingsFromMarkers(T, markers_steps, phaseName, phase, variablesToExtract, time_n)
    markers = markers_steps(phaseName==phase);
    S_Out = T(contains(T.messages, markers), variablesToExtract); % can't use directly fixroi because there seems to have a delay and sometimes it's recorded as AOI0 -> reading AOI directly from trigger instead
    % Add a number next to the variables we're keeping
    iTime = find(variablesToExtract=="time");
    if ~isempty(iTime)
        S_Out.Properties.VariableNames(iTime) = sprintf("time%d",time_n);
    end
    iMessages = find(variablesToExtract=="messages");
    if ~isempty(iMessages)
        S_Out.Properties.VariableNames(iMessages) = sprintf("messages%d",time_n);
        % Find the matches
        matches = regexp(S_Out.(sprintf("messages%d",time_n)), markers + " \d+", 'match');
        % Delete double entries for 2nd reveal
        if phase == "revealed2"
            S_Out(S_Out.fixroi1 == S_Out.fixroi2,:) = [];
            S_Out = outerjoin(S_Out,S1,Keys=["session" "trial" "condition" "time0" "isBadFirstPhase" "messages1" "fixroi1" "time1"], MergeKeys=true); % re-add the trials in which only 1 box was open
        end
        % Extract the timing
        S_Out.(sprintf("fixroi%d",time_n)) = cell2mat(cellfun(@(x) str2double(x{1}(end)), matches, 'UniformOutput', false));
    end
end

end