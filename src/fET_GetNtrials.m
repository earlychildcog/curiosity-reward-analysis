function V_out = fET_GetNtrials(S)

variables = ["isBadFirstPhase","isBadReward","isOutlier"];
newVarNames = strcat("Ntrials_", ["tot", variables]);

% JUST TO CHECK: DO IT PER trialType AND CHECK NO DIFFERENCE IN N OUTLIERS
% Va = varfun(@(x)sum(x), S, InputVariables=["isBadFirstPhase","isBadReward","isOutlier"], GroupingVariables=["session" "trialType"]);
% Va.Properties.VariableNames(3:end) = ["Ntrials_tot" "Ntrials_isBadFirstPhase" "Ntrials_isBadReward" "Ntrials_isOutlier"];
% Va.Ntrials_badTot     = sum(Va{:,4:end},2);
% Va.Ntrials_PropBadTot = Va.Ntrials_badTot./Va.Ntrials_tot;
% Va = unstack(Va, ["Ntrials_tot" "Ntrials_isBadFirstPhase" "Ntrials_isBadReward" "Ntrials_isOutlier" "Ntrials_badTot" "Ntrials_PropBadTot"], "trialType");
% [h, p, ci, stats] = ttest(Va.Ntrials_PropBadTot_TestDiff, Va.Ntrials_PropBadTot_TestSame); disp(p); % JUST TO CHECK

% Count the outliers
V_out = varfun(@(x)sum(x), S, InputVariables=variables, GroupingVariables="session");
% Rename counting variables
V_out.Properties.VariableNames(2:end) = newVarNames;
% Get an overall outlier count as well
V_out.Ntrials_badTot = sum(V_out{:, end-length(variables)+1:end}, 2);
% And the proportion it represents
V_out.Ntrials_PropBadTot = V_out.Ntrials_badTot ./ V_out.Ntrials_tot;

end