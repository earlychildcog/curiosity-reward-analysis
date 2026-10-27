% Make plots of the curR eyetracking data

%% Preamble
clear all
close all

flag_doConcatenate = 1;      % REMOVES PAST PREPROCESSED DATA; Preprocess (1) or just load already preprocessed data & plot (0)
% Define input/output paths (normally no need to change)
pathData           = filesep + fullfile("Users", getenv('USER'), "Data", "curR");
pathDataSummaryOut = fullfile(pathData, "Visit%d", "eyetracking", "3_whole-group-visit%d%s");
pathDataStatsOut   = fullfile(pathData, "All 3 visits");
pathFigures        = 'Figures';
fileNamePerVisit   = "data_visit%s.csv";
% Add paths and parallel processing or not
addpath("src");
util.fSetUpFieldtripAndLibrariesAndParallelPool(flagParallel=false, flagLibraries=true, flagFT=false);
% For the outputs: make the folders or prompt to empty it if files are detected
util.fMkDirSafe(pathDataStatsOut);
util.fMkDirSafe(pathFigures);
folderFigures = 'Figures';

%% Concatenate tables
if flag_doConcatenate
    visitStr = ["1","2","3","1_2s"];
    % visitStr = ["1","1_2s"];
    visitNum = str2double(extractBefore(visitStr, 2));
    extraStr = regexprep(visitStr, '^\d+', '');
    ageStr   = 6 + 6*visitNum + "m" + extraStr;
    for iVisit = 1:length(visitStr)
        % ("T_" + visitStr(iVisit))
        fileToRead = fullfile(sprintf(pathDataSummaryOut, visitNum(iVisit), visitNum(iVisit), extraStr(iVisit)), sprintf(fileNamePerVisit,visitStr(iVisit)));
        T = readtable(fileToRead);
        iGender = find(T.Properties.VariableNames == "gender");
        T.Properties.VariableNames(2:end) = T.Properties.VariableNames(2:end) + "_" + ageStr(iVisit);
        T.session = regexprep(T.session, '[a-z]$', ''); % take out the visit letter 'a' 'b' 'c' ('p' for pilots) so all visits have the same subj name
        if iVisit == 1
            T_all = T(:, 1:iGender-1);
        else % merge, avoiding the ctrlvars because we'll have them multiple times otherwise
            T_all = outerjoin(T_all, T(:, 1:iGender-1), keys="session", MergeKeys=true);
        end
    end
    T_all.session = categorical(cell2mat(T_all.session) + "a");
    % T_all = f_calculateMissingPairsICC(T_all);
    [ctrl_vars, ~, incl_sessions] = fET_GetExtraVars_curR(visitNum(1), unique(T_all.session));
    T_all = outerjoin(T_all,ctrl_vars,keys="session",MergeKeys=true);
    writetable(T_all,fullfile(pathDataStatsOut,"data_allVisits.csv"));
else
    T_all = readtable(fullfile(pathDataStatsOut,"data_allVisits.csv"));
end

%% Plots
close all
sessions  = unique(T_all.session);
nSessions = length(sessions);
colmap    = parula(nSessions);
colname   = "difftime";
ftsz   = 30;
ftsz2  = 20;
lnwdth = 2;
dstyht = 1;

col        = colmap([round(nSessions/10),2*round(nSessions/5)],:);
graycolmap = bone(7);
grayCol    = graycolmap(end-3:-1:2,:);


%% --- 1) Raincloud plot time to trigger AOI2 (after opening box1) per condition
variable   = "t_Box2_afterB1";
conditions = {"HG", "LG"};
visits     = {"12m", "18m", "24m"};
args.colors=col(1:2,:);
args.font_size=ftsz;
args.line_width=lnwdth;
args.density_height=dstyht;
args.y_lim=[-1.5,13];
fig = fET_PlotAndSave_TiledRaincloudPlots_PerVisit(folderFigures, T_all, variable, conditions, visits, args,...
    transform=1/1000, titleStr={'Latency'}, yLabel={'Time (s)'}, resize_figure=[3, 1.5]);

%% --- 2) Raincloud plot percentage of trials when triggered AOI2 per condition
variable   = "prop_OpenedBothBoxes";
args.y_lim=[-39,139];
fig = fET_PlotAndSave_TiledRaincloudPlots_PerVisit(folderFigures, T_all, variable, conditions, visits, args,...
    transform=100, titleStr={'Propensity'}, yLabel={'% of trials'}, resize_figure=[3, 1.5]);

%% --- 3) Overall proportion of trials in which opened both boxes
variable   = "prop_OpenedBothBoxes";
condition = "all";
visits     = {"12m", "18m", "24m"};
args.colors=grayCol;
args.y_lim=[-5,105];
fET_PlotAndSave_Boxplots(folderFigures, T_all, variable, condition, visits, args, ...
    y_line=[0, 100], transform=100, titleCell={'Propensity'}, yLabel={'% of trials', '(all trials)'}, resize_figure=[.75, 1]);

%% --- 4) Diff score speed
variable   = "t_Box2_afterB1";
condition = "DiffScore";
visits     = {"12m", "18m", "24m"};
args.colors=grayCol;
args.y_lim=[];
fET_PlotAndSave_Boxplots(folderFigures, T_all, variable, condition, visits, args, ...
    y_line=0, transform=1/1000, titleCell={'Latency'}, yLabel={'Time (s)', '(difference score)'}, resize_figure=[.75, 1]);

%% --- 5) Diff score propensity
variable   = "prop_OpenedBothBoxes";
condition = "DiffScore";
visits     = {"12m", "18m", "24m"};
args.colors=grayCol;
args.y_lim=[];
fET_PlotAndSave_Boxplots(folderFigures, T_all, variable, condition, visits, args, ...
    y_line=[0, 100], transform=100, titleCell={'Propensity'}, yLabel={'% of trials', '(difference score)'}, resize_figure=[.75, 1]);

%% --- 6) POSTHOC ANALYSIS: 2s encoding, visit 1 -- Raincloud plot time to trigger AOI2 (after opening box1) per condition 
args.colors=col(1:2,:);
variable   = "t_Box2_afterB1";
conditions = {"HG", "LG"};
visits     = {"12m_2s","12m"};
args.y_lim=[-1.5,13];
fig = fET_PlotAndSave_TiledRaincloudPlots_PerVisit(folderFigures, T_all, variable, conditions, visits, args,...
    transform=1/1000, title={'Latency', 'for encoding of min. 2s (left) or 1s (right)'}, yLabel={'Time (s)'}, resize_Figure=[1.25, 1.5]);
variable   = "prop_OpenedBothBoxes";
args.y_lim=[-39,139];
fig = fET_PlotAndSave_TiledRaincloudPlots_PerVisit(folderFigures, T_all, variable, conditions, visits, args,...
    transform=100, title={'Propensity', 'for encoding of min. 2s (left) or 1s (right)'}, yLabel={'% trials'}, resize_figure=[1.25, 1.5]);

