%% Analyse curR (reward) data
%

clear all
close all

%% Define important variables
visit        = 1;        % 1/2/3
flagParallel = true;     % false/true  -- here we have to parralellise anyway for function "readcsvBatch"

minNtrialsPerCond      = 2;
outlierThresholdMedian = 2.5;     % Default=2.5; for curE, we used 6 (more variables, fewer trials)
minTimeOnTopScreen     = 2000;    % in ms

%% Define more things
% Define input/output paths (normally no need to change)
pathData           = [filesep, fullfile('Users',getenv('USER'),'Data','curR',sprintf('Visit%d',visit),'eyetracking')];
pathDataCsvIn      = fullfile(pathData, sprintf('2_csv-visit%d',visit));
if minTimeOnTopScreen == 2000; strTimetopScreen = "_2s"; else; strTimetopScreen = ""; end % add a string if we did the posthoc analysis with 2s on top screen
pathDataSummaryOut = fullfile(pathData, sprintf('3_whole-group-visit%d%s',visit,strTimetopScreen));
% Add paths and parallel processing or not
addpath("src");
util.fSetUpFieldtripAndLibrariesAndParallelPool(flagParallel=flagParallel, flagLibraries=true, flagFT=false);
% For the outputs: make the folders or prompt to empty it if files are detected
util.fMkDirSafe(pathDataSummaryOut);
trialTypes = ["LG", "HG"];

%% Load data and get results
% --- Load data (individual CSVs are read into one big table -- this takes
% some time, although done with parallel processing to speed up)
T = readcsvBatch(pathDataCsvIn);
T.session = categorical(T.session);
[ctrl_vars, ~, incl_sessions] = fET_GetExtraVars_curR(visit, unique(T.session));
% --- First do some cleaning (some trial rejection e.g., fam trials, not
% looking long enough at top of screen during exposure)
T = fET_CleanUp_curR(T, trialTypes, minTimeOnTopScreen=minTimeOnTopScreen);
% --- Process test phase of trials (get timings and some trial rejection
% e.g., reward1 not shown before box2 opened)
S = fET_GetTimings_curR(T);
% --- Find the outliers based on difftime and time1 (per session and trialType)
S = fET_GetOutliers_curR(S, trialTypes, outlierThresholdMedian);
% --- Extract N excluded trials (and why) on a subject level in table Va
Va = fET_GetNtrials(S);
% --- Get rid of trials already excluded based of first phase/too short reward/outliers
S_good = S(~S.isBadFirstPhase & ~S.isBadReward & ~S.isOutlier,:);
% --- Get results, grouping by session and trialType
fprintf("Getting results per participant and trialType.... \n");
var_in = "time1"; var_out = ["t_Box1", "logt_Box1"];
V_Out1 = fET_GetResults(S_good, var_in, var_out);
var_in = "time2"; var_out = "t_Box2_afterCurtain";
V_Out2 = fET_GetResults(S_good, var_in, var_out);
var_in = "difftime"; var_out = ["Ntrials", "prop_OpenedBothBoxes", "t_Box2_afterB1"];
V_Out3 = fET_GetResults(S_good, var_in, var_out);
% Merge the outputs into one table
V_Out = outerjoin(V_Out3,V_Out2,keys="session", MergeKeys=true);
V_Out = outerjoin(V_Out,V_Out1,keys="session", MergeKeys=true);
% --- Now exclude participants if too few good trials or outlier
V_Out = fET_GetOutliers_GroupLevel_curR(V_Out, trialTypes, minNtrialsPerCond, outlierThresholdMedian);

%% Export
fprintf("Exporting to csv files.... \n");
% --- With participant outliers (just for reference)
ctrl_vars(~ismember(ctrl_vars.session,V_Out.session),:) = [];
writetable([V_Out,ctrl_vars(:,2:end)],fullfile(pathDataSummaryOut,sprintf("data_visit%d%s_withExcludedParticipants_JUSTFORREFERENCE.csv",visit,strTimetopScreen)));
% --- Without participant outliers
V_final    = V_Out(~V_Out.isExcluded_TooFewGoodTrials & ~V_Out.isExcluded_Outlier,:);
ctrl_vars(~ismember(ctrl_vars.session,V_final.session),:) = [];
writetable([V_final,ctrl_vars(:,2:end)],fullfile(pathDataSummaryOut,sprintf("data_visit%d%s.csv",visit,strTimetopScreen)));
fprintf("All done! \n");
