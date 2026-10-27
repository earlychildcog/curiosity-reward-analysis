function V = eyeExclusionsBatch(folderIn, folderOut, ipExcl, thresGaze, opts)
% do exclusions on eyetracking data based on gaze on screen
% Input arguments:
% folderIn : folder to read csv files from (must exist)
% folderOut: folder to write new csv files (is created automatically if doesn't exist
% ipExcl: N x 2 array for the periods to check
% thresGaze: proportion of fixations needed inside each IP (default 0.5)
% optional name-pairs:
% nameVars: names of variables to include (default all)
% nameTrialVar: name of variable that marks trials
% nameCondVar: name of condition(s) variable(s)
% nameSessionVar: name of session (subject) variable

arguments
    folderIn string {mustBeFolder}
    folderOut string
    ipExcl (:,2) double
    thresGaze double = 0.5
    opts.dimensions (1,2) double = [1024 1280]
    opts.nameVars (1,:) cell = {}
    opts.nameConds = {}
    opts.nameTrialVar string = "trial"
    opts.nameCondVar string = "condition"
    opts.nameSessionVar string = "session"
    opts.nameTimeVar string = "time";
end

dimensions = opts.dimensions;
nameVars = opts.nameVars;
nameTrialVar = opts.nameTrialVar;
nameCondVar = opts.nameCondVar;
nameSessionVar = opts.nameSessionVar;
nameTimeVar = opts.nameTimeVar;

ipExclStarts = ipExcl(:,1);
ipExclEnds = ipExcl(:,2);
if ~exist("folderOut", "dir")
    mkdir(folderOut);
end

lFileIn = arrayfun(@(x)string(x.name),dir(fullfile(folderIn, "/*.csv")));
nFile = length(lFileIn);
Vcell = cell(nFile,1);
% loop through files
parfor cFile = 1:nFile
    timeZero = datetime;
    nameFile = lFileIn(cFile);
    T = readcsv(fullfile(folderIn, nameFile), nameVars);

    screenPadding = 50;
    % code the onscreen looking
    T.onscreen = ( (T.fixgazeX > -screenPadding) & ... 
        (T.fixgazeX < screenPadding + dimensions(2)) & ...
        (T.fixgazeY > -screenPadding) & ... 
        (T.fixgazeY < screenPadding + dimensions(1)) ) | ...
        ( (T.fixgazeX2 > -screenPadding) & ... 
        (T.fixgazeX2 < screenPadding + dimensions(2)) & ...
        (T.fixgazeY2 > -screenPadding) & ... 
        (T.fixgazeY2 < screenPadding + dimensions(1)) );
    
    
    nIP = length(ipExclStarts);
    Tx = T;
    lTrial = unique(T.(nameTrialVar));
    for cIP = 1:nIP
        ipStarts_ = ipExclStarts(cIP);
        ipEnds_ = ipExclEnds(cIP);
        T_ = T(T.(nameTimeVar) < ipEnds_ & T.(nameTimeVar) > ipStarts_, :);
        X = varfun(@(x)mean(x) > thresGaze, T_, "InputVariables", "onscreen", "GroupingVariables",nameTrialVar);     % mark trials as good/bad for this IP
        X.GroupCount = [];
        X.Properties.VariableNames{end} = sprintf('incl%d', cIP);
        lTrialOut = lTrial(~ismember(lTrial, X.(nameTrialVar)));
        % there is a chance not all conditions are used? Have to return to
        % this
        if ~isempty(lTrialOut)
            Xout = table;
            Xout.(nameTrialVar) = lTrialOut;
            Xout.(sprintf('incl%d', cIP)) = true(size(Xout.(nameTrialVar)));
            X = [X; Xout];
        end
        % check if trials do no include IP (eg fam etc?)
    
    %     if cIP == 2
    %         V = varfun(@max,T,"InputVariables","time","GroupingVariables",["trial" "trialtype"]);
    %         V.
    %     end
        
    %     Tx.(sprintf('incl%d', cIP)) = false(size(Tx,1),1);
        
        Tx = join(Tx, X, "Keys",nameTrialVar);
    
    
    
    end
    
    Tx.incl = Tx.incl1 & Tx.incl2;
    
    writetable(Tx, fullfile(folderOut, sprintf('%s_incl.csv', extractBefore(nameFile, '.csv'))));
    
    varAll = Tx.Properties.VariableNames;
    varIncl = varAll(contains(varAll, 'incl'));
    Vx = varfun(@(x)sum(x), Tx(Tx.(nameTimeVar) == 0,:), "InputVariables",varIncl,"GroupingVariables",[nameSessionVar nameCondVar]);
%     Vx.Properties.VariableNames(end-1:end) = {'total_trials' 'included_trials'};
    Vcell{cFile} = Vx;
    timeOne = datetime;

    fprintf('subj %d done in %.1f seconds\n', T.session(1), seconds(timeOne - timeZero))
end

V = cat(1, Vcell{:});







