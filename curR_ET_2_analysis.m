%% Analyse curR (reward) data
%

clear all
close all

%% Define important variables
visit        = 1;        % 1/2/3
flagParallel = true;     % false/true  -- here we have to parralellise anyway for function "readcsvBatch"

minNtrialsPerCond      = 2;
outlierThresholdMedian = 2.5;     % Default=2.5; for curE, we used 6 (more variables, fewer trials)
minTimeOnTopScreen     = 1000;    % in ms

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

%%
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

if false
    % --- Extract values on a subject level in table V for t2
    V = varfun(@(x)mean(~isnan(x)), S_good, InputVariables="time1", GroupingVariables=["session" "trialType"]);
    V.Properties.VariableNames(end-1:end) = ["Ntrials_B1" "prop_Box1"];
    V = unstack(V, ["Ntrials_B1" "prop_Box1"], "trialType");
    V.Ntrials_B1_LG(isnan(V.Ntrials_B1_LG)) = 0; V.Ntrials_B1_HG(isnan(V.Ntrials_B1_HG)) = 0;

    Vb = outerjoin(Va,V,keys="session", MergeKeys=true);

    V = varfun(@(x)mean(~isnan(x)), S_good, InputVariables="time2", GroupingVariables=["session" "trialType"]);
    V.Properties.VariableNames(end-1:end) = ["Ntrials" "prop_OpenedBothBoxes"];
    V = unstack(V, ["Ntrials" "prop_OpenedBothBoxes"], "trialType");
    V.Ntrials_LG(isnan(V.Ntrials_LG)) = 0; V.Ntrials_HG(isnan(V.Ntrials_HG)) = 0;
    V_final = outerjoin(Vb,V,keys="session", MergeKeys=true);


    % Extract values on a subject level in table V1 for t1
    % V1 = varfun(@(x)mean(~isnan(x)), S, InputVariables="time1", GroupingVariables=["session" "trialType"]);
    % V1.Properties.VariableNames(end-1:end) = ["Ntrials" "prop_Box1"];
    % V1 = unstack(V1, ["Ntrials" "prop_Box1"], "trialType");
    % V1(V1.Ntrials_HG < 3 | V1.Ntrials_LG < 3,:) = [];
    % V1(isnan(V1.Ntrials_HG) | isnan(V1.Ntrials_LG),:) = [];
    % Prop box1 is 100% by definition of how we do our analysis


    % --- Now save data per trialType in table L
    Lb = varfun(@(x)mean(x,"omitnan"), S_good, InputVariables="time2", GroupingVariables=["session" "trialType"]);
    Lb.t_Box2_afterCurtain = Lb.Fun_time2(:,1);
    Lb.Fun_time2  = [];
    Lb = unstack(Lb, ["GroupCount"  "t_Box2_afterCurtain"], "trialType");

    L2 = varfun(@(x)mean(x,"omitnan"), S_good, InputVariables="difftime", GroupingVariables=["session" "trialType"]);
    L2.t_Box2_afterB1 = L2.Fun_difftime(:,1);
    L2.Fun_difftime  = [];
    L2 = unstack(L2, ["GroupCount"  "t_Box2_afterB1"], "trialType");

    L1 = varfun(@(x)mean(x,"omitnan"), S_good, InputVariables="time1", GroupingVariables=["session" "trialType"]);
    L1.t_Box1 = L1.Fun_time1(:,1);
    L1.Fun_time1 = [];
    L1.logt_Box1 = log(L1.t_Box1);
    L1 = unstack(L1, ["GroupCount"  "t_Box1" "logt_Box1"], "trialType");

    L_final = [L2(:,[1,4:end]),L1(:,4:end),Lb(:,4:end)];

    % --- Export
    T_final = outerjoin(V_final,L_final,keys="session", MergeKeys=true);
    T_final.prop_all   = (T_final.prop_OpenedBothBoxes_LG.*T_final.Ntrials_LG + T_final.prop_OpenedBothBoxes_HG.*T_final.Ntrials_HG)./(T_final.Ntrials_LG + T_final.Ntrials_HG);
    T_final.t2B1_all   = (T_final.t_Box2_afterB1_LG.*T_final.Ntrials_LG + T_final.t_Box2_afterB1_HG.*T_final.Ntrials_HG)./(T_final.Ntrials_LG + T_final.Ntrials_HG);
    T_final.t2_all   = (T_final.t_Box2_afterCurtain_LG.*T_final.Ntrials_LG + T_final.t_Box2_afterCurtain_LG.*T_final.Ntrials_HG)./(T_final.Ntrials_LG + T_final.Ntrials_HG);
    T_final.t1_all     = (T_final.t_Box1_LG.*T_final.Ntrials_LG + T_final.t_Box1_HG.*T_final.Ntrials_HG)./(T_final.Ntrials_LG + T_final.Ntrials_HG);
    T_final.logt1_all  = log(T_final.t1_all);
    T_final.prop_diffScore   = T_final.prop_OpenedBothBoxes_LG - T_final.prop_OpenedBothBoxes_HG;
    T_final.t2B1_diffScore   = T_final.t_Box2_afterB1_LG - T_final.t_Box2_afterB1_HG;
    T_final.logt1_diffScore = T_final.logt_Box1_LG - T_final.logt_Box1_HG;
    T_final.prop1_diffScore  = T_final.prop_Box1_LG - T_final.prop_Box1_HG;
    V_Out = T_final;

    T_final = V_Out;
    % --- Exclude if too few good trials (per trialType)
    V_Out.isExcluded_TooFewGoodTrials(:) = 0;
    for iCond = 1:length(trialTypes)
        V_Out.isExcluded_TooFewGoodTrials(V_Out.("Ntrials_" + trialTypes(iCond)) < minNtrialsPerCond) = 1;
    end
    T_final.isExcluded_Outlier(:) = 0;
    T_final.isExcluded_Outlier(isoutlier(T_final.t_Box2_afterB1_LG,'median',ThresholdFactor=outlierThresholdMedian) ...
        & ~T_final.isExcluded_TooFewGoodTrials) = 1;
    T_final.isExcluded_Outlier(isoutlier(T_final.t_Box2_afterB1_HG,'median',ThresholdFactor=outlierThresholdMedian) ...
        & ~T_final.isExcluded_TooFewGoodTrials) = 1;
    T_final.isExcluded_Outlier(isoutlier(log(T_final.t_Box1_LG),'median',ThresholdFactor=outlierThresholdMedian) ...
        & ~T_final.isExcluded_TooFewGoodTrials) = 1;
    T_final.isExcluded_Outlier(isoutlier(log(T_final.t_Box1_HG),'median',ThresholdFactor=outlierThresholdMedian) ...
        & ~T_final.isExcluded_TooFewGoodTrials) = 1;
    V_Out = T_final;
end

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
