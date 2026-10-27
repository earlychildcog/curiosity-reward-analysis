function S = tableFinaleFix(S, opts)
arguments
    S               table
    opts.varX       (1,1) string        = "time"
    opts.groupVars  string              = ["session" "condition"]
    opts.typeOfFix  string {mustBeMember(opts.typeOfFix, ["cut" "pad"])}   = "cut"
    opts.cutAtPoint double = Inf            % if we fill, maybe we do not want to fill until the end but up to some point
    opts.fs         = 0.1
end
% description: Sometimes trial/condition/subject data misses a final part of data
% (eg a trial ending earlier than others). This can cause some issues in certain functions. 
% This function tool normalises the total times (or any other indexing)
% by either filling the missing times, or cutting the extra times. Default: cut.
% at the moment only cutting is supported

S(S.(opts.varX) > opts.cutAtPoint,:) = [];

maxtT = varfun(@max, S, "InputVariables",opts.varX,"GroupingVariables",opts.groupVars);
mintT = varfun(@min, S, "InputVariables",opts.varX,"GroupingVariables",opts.groupVars);

% cut the table in case we have variable end times ----maybe remove?
minmaxt = min(maxtT.max_time);
maxmaxt = max(maxtT.max_time);

maxmint = max(mintT.min_time);
% step = median(diff(S.time));
% xxx = arrayfun(@(x,y)[x:step:y]', mintT.min_time, maxtT.max_time, "UniformOutput",false);
switch opts.typeOfFix

    case "cut"
        S(S.(opts.varX) > minmaxt,:) = [];

    case "pad"
        maxtT.add = (maxmaxt - maxtT.max_time)/opts.fs;
        maxtT.GroupCount = [];
        miss = varfun(@(x)round((x+opts.fs):opts.fs:maxmaxt, -floor(log10(0.1)))', maxtT, "GroupingVariables", opts.groupVars,"InputVariables","max_" + opts.varX);
        miss.GroupCount = [];
        miss.Properties.VariableNames(end) = opts.varX;
        S = outerjoin(S, miss, 'MergeKeys', true);
end