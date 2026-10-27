function [ctrl_vars, eegData, incl_sessions] = fET_GetExtraVars_curR(visit, sessions, opts)

arguments
    visit (1,1) int8 {mustBeMember(visit, [1 2 3])}
    sessions categorical
    opts.experiment        = 'curR';
    opts.visitStr          = {'a', 'b', 'c'};
    opts.ctrlVars_filename = 'curio_ctrlVars_EXPERIMENT.csv';
    opts.output_filename   = 'curio_extraVars_EXPERIMENT.csv';
    opts.pathDataRoot      = [filesep, fullfile('Users',getenv('USER'),'Data','EXPERIMENT')];
    % Keeping the following lines for compatibility with EEG expeirments (e.g., curE)
    opts.pathDataEEG       = strcat("FRN", filesep, "4_OutputsForStats");
    opts.eegFileName       = "bothERNandFRN_ValuesinROI_PerSubj_minTwoPeaks_BL-298_-150.csv";
end


% Replace experiment string where needed
opts.pathDataRoot      = strrep(opts.pathDataRoot, 'EXPERIMENT', opts.experiment);
opts.ctrlVars_filename = strrep(opts.ctrlVars_filename, 'EXPERIMENT', opts.experiment);
opts.output_filename   = strrep(opts.output_filename, 'EXPERIMENT', opts.experiment);
% Load ctrl variables data, add a variable for whether subjects were included in EEG nalysis at 12m, and save
ctrl_vars = readtable(fullfile(opts.pathDataRoot, opts.ctrlVars_filename));
ctrl_vars.session = categorical(strcat(ctrl_vars.session, opts.visitStr{visit})); % add the visit letter back
% FOR curE ONLY: load eeg data, keep relevant stuff, find incl. subjects
if strcmp(opts.experiment, 'curE')
    path_DataEEG = fullfile(opts.pathDataRoot, sprintf("Visit%d",visit), opts.pathDataEEG, opts.eegFileName);
    eegData     = readtable(path_DataEEG);
    eegSessions = categorical(eegData{:,1});
    eegData     = eegData(:,contains(eegData.Properties.VariableNames,'RN')); % only export relevant ERN/FRN variables, not ctrlvars or subjnames again...
    incl_sessions = sessions(ismember(sessions, eegSessions));
    ctrl_vars.isInEEGAnalysis12m = ismember(ctrl_vars.session, eegSessions);
    ctrl_vars = renamevars(ctrl_vars, "slope_accuracy", "performance_slopeAccu");
else
    incl_sessions = sessions(ismember(sessions,ctrl_vars.session));
    eegData = [];
end
% Export
writetable(ctrl_vars, fullfile(opts.pathDataRoot, opts.output_filename));
ctrl_vars = ctrl_vars(ismember(ctrl_vars.session, incl_sessions),:);

end