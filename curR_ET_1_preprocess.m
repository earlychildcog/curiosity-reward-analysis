%% Import eyelink data into Matlab for Curiosity E (error) study
%
% Saves data into mat and csv files, and also defines the AOIs and whether
% gaze is in them; no preprocessing done on location data, a bit on pupil.
%
% At the end, save all participants' data into one big csv files
% /!\ can easily make your matlab crash or even your computer shut down --
% this is the most memory/energy consuming step.
% Pretty long if not using parellel processing
%

clear all
close all

%% Define important variables
visit        = 1;        % 1/2/3
flagParallel = true;     % false/true


%% Define more things
% Define input/output paths (normally no need to change)
pathData           = [filesep, fullfile('Users',getenv('USER'),'Data','curR',sprintf('Visit%d',visit),'eyetracking')];
pathDataEdfIn      = fullfile(pathData, sprintf('0_edf-visit%d',visit));
pathDataMatOut     = fullfile(pathData, sprintf('1_mat-visit%d',visit));
pathDataCsvOut     = fullfile(pathData, sprintf('2_csv-visit%d',visit));
% Add paths and parallel processing or not
addpath("src");
util.fSetUpFieldtripAndLibrariesAndParallelPool(flagParallel=flagParallel, flagLibraries=true, flagFT=false);
% For the outputs: make the folders or prompt to empty it if files are detected
util.fMkDirSafe(pathDataMatOut);
util.fMkDirSafe(pathDataCsvOut);

%% Load data & preprocess the pupil data, save into mat files
% THIS IS AN IMPORTANT STEP USED FOR DETERMINING DATA QUALITY LATER ON
% (even if the analysis focused on non-pupil data)
% identify good pupil samples based on set min/max, interpolate between
% bad samples for gap smaller than max length & smooth
% --- To see what vars are in the edf files (just for checking)
% varlistFromEdf(fullfile(pathDataEdfIn,"curR002a.edf"))
% --- To read the edf data
getMatFromEdfBatch(pathDataEdfIn, pathDataMatOut, messageStart="!MODE RECORD CR", varinclude=["trialno" "trialtype" "positions1" "positions2" "result"])
preprocData = preprocessMatBatch(pathDataMatOut, export=false);

%% Create (padded) ROIs and say if the gaze is in them, then save to csv
ROI = fET_GetROIs;
% ROI.show % To check if the ROIs are good
% Save indiv csv files
fprintf("Now saving individual csv files (this takes a long while).... \n");
getCsvFromHpd(preprocData, csvfolder=pathDataCsvOut, ROI=ROI)
preprocData.delete;
clear postMatFolder preprocData
