function T = fET_CleanUp_curR(T, conditions, opts)

arguments
    T
    conditions
    opts.screenDimensions = [1280 1024];
    opts.minTimeOnTopScreen = 1000;            % in ms (for curR)
end

fprintf("Cleaning up unwanted data (familiarisation, fixation cross, etc.).... \n");
% ---- Find events & remove unwanted trials (familiarisation...)
% VAR FIX -- First fix var names that were switched at recording
T.trialType = T.trialno; T.trialno = []; T.trialNo = T.trialtype; T.trialtype = [];
% NOT TEST -- Only keep data during test trials (remove Fam trials)
T(~contains(T.trialType, "Test"),:) = [];
% INCOMPLETE -- remove trials that were terminated early for various reasons
% FYI, these are the codes saved as flagResult during data acquision:
%   -21 to -25: video break
%   -9: quit
%   -3: skipped trial
%   -1: recalibrate
%    0: default
%    2: ended by looking away
% Only keeping results == 0, large majority and make sense (3990 trials)
% Could also have kept == 2 i.e., ended by looking away (144 trials)
T(T.result ~= 0, :) = [];
% --- Rename conditions (they were not the same in visit 1 than in 2-3)
T.trialType(T.trialType=="TestInvis")     = conditions(2);
T.trialType(T.trialType=="TestInvisSame") = conditions(1);
T.trialType(T.trialType=="TestDiff")      = conditions(2);
T.trialType(T.trialType=="TestSame")      = conditions(1);

% --- Find relevant timings
S0 = T(contains(T.messages, "::trial start"), ["session" "trial" "time"]);         %find time when trial starts and save as timeTrStrt
S0.Properties.VariableNames(end) = "timeTrStrt";
Sb  = T(contains(T.messages, "curtain start moving"), ["session" "trial" "time"]); %find time when curtains stops moving and save as time0
Sb.Properties.VariableNames(end) = "timeTestStrt";
% -------- Flag bad trials based on 1st phase looking time at AOI3 (top half of the screen)
% Create a separate dataset for only the 1st phase of the trial before test
S0 = innerjoin(S0,Sb,Keys=["session" "trial"]);
T0 = innerjoin(T,S0,Keys=["session" "trial"]);
T0(T0.time < T0.timeTrStrt | T0.time > T0.timeTestStrt, :) = [];
% If the child looked at AOI3 for <Xms (opts.minTimeOnTopScreen), reject trial
% NB: sometimes the sampling rate was lowered by mistake -> calculate Xms
% for each dataset separately based on given SR
T_fixroi = groupsummary(T0, {'session', 'trial'}, @(x) sum(x == 3), 'fixroi'); T_fixroi.Properties.VariableNames(end) = "samplesInAOI3";
T_sr     = groupsummary(T0, {'session', 'trial'}, @(x) round(((x(end) - x(1))) / (numel(x) -1)), 'time'); T_sr.Properties.VariableNames(end) = "SR";
T_out    = innerjoin(T_fixroi, T_sr, Keys=["session" "trial"]);
T_out.timeinAOI3    = T_out.samplesInAOI3 .* T_out.SR;
% figure; hist(T_out.timeinAOI3,300); xline(opts.minTimeOnTopScreen); sum(T_out.timeinAOI3<opts.minTimeOnTopScreen)/numel(T_out.timeinAOI3) % JUST TO CHECK
T_out.isBadFirstPhase(:) = 0;
T_out.isBadFirstPhase(T_out.timeinAOI3 < opts.minTimeOnTopScreen,:) = 1; % mark as bad if didn't look long enough (in ms) at AOI3
T = innerjoin(T,T_out,Keys=["session" "trial"]);                    % add that flag to the bigger table

end