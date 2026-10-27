function S = fET_GetOutliers_curR(S,  conditions, outlierThresholdMedian)

fprintf("Finding outlier trials.... \n");

% TIME BOX2 FIRST
% First get rid of trials already excluded based of first phase/too short
% reward, grouping by session and trialType
S_good = S((~S.isBadFirstPhase & ~S.isBadReward),:);
S_temp = varfun(@(x)isoutlier(x,'median',ThresholdFactor=outlierThresholdMedian), S_good, InputVariables="time2", GroupingVariables=["session", "trialType"]);
S_temp.Properties.VariableNames(end)   = sprintf("isOutlier_t2");
S_temp.Properties.VariableNames(end-1) = "nTrials";
S_temp.trial(:) = NaN; % re-adding trial # so the two tables can be merged again (have to do it per trialType because trials have been re-ordered in Sout)
for iCond = 1:length(conditions)
    S_temp.trial(S_temp.trialType == conditions(iCond)) = S_good.trial(S_good.trialType == conditions(iCond));
end
S = outerjoin(S,S_temp,keys=["session" "trial" "trialType"], MergeKeys=true);

% TIME BOX1 NEXT
S_good = S((~S.isBadFirstPhase & ~S.isBadReward),:);
S_temp = varfun(@(x) x > prctile(x,95), S_good, InputVariables="time1", GroupingVariables=["session", "trialType"]); % using frequencies here, median not appropriate
S_temp.Properties.VariableNames(end)   = "isOutlier_t1";
S_temp.Properties.VariableNames(end-1) = "nTrials";
S_temp.trial(:) = NaN; % re-adding trial # so the two tables can be merged again (have to do it per trialType because trials have been re-ordered in Sout)
S_temp.trial(S_temp.trialType == "LG") = S_good.trial(S_good.trialType == "LG");
S_temp.trial(S_temp.trialType == "HG") = S_good.trial(S_good.trialType == "HG");
% Merge again
S = outerjoin(S,S_temp,keys=["session" "trial" "trialType"], MergeKeys=true);
S.isOutlier(:) = 0;
S.isOutlier(S.isOutlier_t1 | S.isOutlier_t2) = 1;
% Print to screen how many %trials were outliers
sum(S.isOutlier_t1)/size(S.isOutlier_t1,1)
sum(S.isOutlier_t2)/size(S.isOutlier_t2,1)

end