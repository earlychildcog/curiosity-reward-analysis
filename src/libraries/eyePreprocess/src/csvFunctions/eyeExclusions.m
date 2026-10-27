function [T, V] = eyeExclusions(T, ipExcl, thresGaze, opts)
% do exclusions on eyetracking data based on gaze on screen
% Input arguments:
% T: table
% ipExcl: N x 2 array for the periods to check
% thresGaze: proportion of fixations needed inside each IP (default 0.5)
% optional name-pairs:
% nameVars: names of variables to include (default all)
% varTrial: name of variable that marks trials
% varCond: name of condition(s) variable(s)
% varSession: name of session (subject) variable
% dimensions: the dimensions of screen (or the gaze data)
% screenPadding: padding on the screen edges for fixation
% varTime: the time variable
% exclusionMeasure: which measure is used for exclusions (fixation or pupil or fixation_binocular)

arguments
    T table
    ipExcl (:,2) double
    thresGaze double = 0.5
    opts.dimensions (1,2) double = [1024 1280]
    opts.screenPadding (1,1) double = 50
    opts.nameVars (1,:) cell = {}
    opts.nameConds = {}
    opts.varTrial string = "trial"
    opts.varCondition string = "condition"
    opts.varSession string = "session"
    opts.varTime string = "time"
    opts.exclusionMeasure string {mustBeMember(opts.exclusionMeasure, ["pupil", "fixation", "fixation_binocular"])} = "fixation"
    opts.extractOnlyIncludedTrials logical = true
    opts.sampleFrequency double = 0.5;
end

dimensions = opts.dimensions;
nameVars = opts.nameVars;
varTrial = opts.varTrial;
varCondition = opts.varCondition;
varSession = opts.varSession;
varTime = opts.varTime;
exclusionMeasure = opts.exclusionMeasure;
sampleFrequency = opts.sampleFrequency;

ipExclStarts = ipExcl(:,1);
ipExclEnds = ipExcl(:,2);

if isscalar(thresGaze)
    thresGaze = repmat(thresGaze, 1, size(ipExcl,1));
end

timeZero = datetime;

screenPadding = opts.screenPadding;
% code the onscreen looking
if exclusionMeasure == "fixation"
    T.onscreen = ( (T.fixgazeX > -screenPadding) & ...
        (T.fixgazeX < screenPadding + dimensions(2)) & ...
        (T.fixgazeY > -screenPadding) & ...
        (T.fixgazeY < screenPadding + dimensions(1)) );
elseif exclusionMeasure == "fixation_binocular"
    T.onscreen = ( (T.fixgazeX > -screenPadding) & ...
        (T.fixgazeX < screenPadding + dimensions(2)) & ...
        (T.fixgazeY > -screenPadding) & ...
        (T.fixgazeY < screenPadding + dimensions(1)) ) | ...
        ( (T.fixgazeX2 > -screenPadding) & ...
        (T.fixgazeX2 < screenPadding + dimensions(2)) & ...
        (T.fixgazeY2 > -screenPadding) & ...
        (T.fixgazeY2 < screenPadding + dimensions(1)) );
elseif exclusionMeasure == "pupil"
    T.onscreen = ~isnan(T.pupil);
end


nIP = length(ipExclStarts);

lTrial = unique(T.(varTrial));
for cIP = 1:nIP
    ipStarts_ = ipExclStarts(cIP);
    ipEnds_ = ipExclEnds(cIP);
    thress_ = thresGaze(cIP);
    T.thisIP = false(size(T,1),1);
    T.thisIP(T.(varTime) < ipEnds_ & T.(varTime) > ipStarts_) = true;
    if thress_ == 0
        I = varfun(@(x)any(x), T(T.thisIP, :), "InputVariables", "onscreen", "GroupingVariables",[varSession varTrial varCondition]);     % mark trials as good/bad for this IP
    elseif isinf(ipEnds_)          % check if we want to have a variable trial end as end of IP or not
        I = varfun(@(x)mean(x) > thress_, T(T.thisIP, :), "InputVariables", "onscreen", "GroupingVariables",[varSession varTrial varCondition]);     % mark trials as good/bad for this IP
    else                        % if it is a fixed time; we take into account that some trials may have ended earlier etc: we use the time we assume regardless real time
        ipSampleLength_ = floor((ipEnds_ - ipStarts_)*sampleFrequency);
        I = varfun(@(x)sum(x)/ipSampleLength_ > thress_, T(T.thisIP, :), "InputVariables", "onscreen", "GroupingVariables",[varSession varTrial varCondition]);     % mark trials as good/bad for this IP
    end
    % J controls whether we have any data (valid or not) in that IP
    J = varfun(@any, T, "InputVariables","thisIP", "GroupingVariables",[varSession varTrial varCondition]); 
    T.thisIP = [];
    I.GroupCount = [];
    J.GroupCount = [];
    I.Properties.VariableNames(end) = "incl" + cIP;
    J.Properties.VariableNames(end) = "incl" + 0;
    I = outerjoin(I,J,"MergeKeys",true);
    I{:,end-1} = I{:,end-1} & I{:,end};
    I(:,end) = [];
    lTrialOut = lTrial(~ismember(lTrial, I.(varTrial)));
    % there is a chance not all conditions are used? Have to return to
    % this
    if ~isempty(lTrialOut)
        Xout = table;
        Xout.(varTrial) = lTrialOut;
        Xout.("incl" + cIP) = true(size(Xout.(varTrial)));
        I = [I; Xout];
    end
    % check if trials do no include IP (eg fam etc?)

    %     if cIP == 2
    %         V = varfun(@max,T,"InputVariables","time","GroupingVariables",["trial" "trialtype"]);
    %         V.
    %     end

    %     Tx.(sprintf('incl%d', cIP)) = false(size(Tx,1),1);

    T = join(T, I, "Keys",[varSession varTrial varCondition]);



end

T.incl = true(size(T,1),1);

for cIP = 1:nIP
    T.incl = T.incl & T.("incl" + cIP);
end

varAll = T.Properties.VariableNames;
varIncl = varAll(contains(varAll, 'incl'));
V = varfun(@(x)sum(x), T(T.(varTime) == 0,:), "InputVariables",varIncl,"GroupingVariables",[varSession varCondition]);
V.Properties.VariableNames = strrep(V.Properties.VariableNames, 'Fun_incl', 'incl');

if opts.extractOnlyIncludedTrials
    T(~T.incl,:) = [];
    T(:, startsWith(T.Properties.VariableNames, 'incl')) = [];
end


timeOne = datetime;

fprintf('Done in %.1f seconds\n', seconds(timeOne - timeZero))







