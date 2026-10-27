% Exclude participants if too few good trials or outlier difftime or time1

function V_Out = fET_GetOutliers_GroupLevel_curR(V_Out, conditions, minNtrialsPerCond, outlierThresholdMedian)

% --- Exclude if too few good trials (per trialType)
V_Out.isExcluded_TooFewGoodTrials(:) = 0;
for iCond = 1:length(conditions)
    V_Out.isExcluded_TooFewGoodTrials(V_Out.("Ntrials_" + conditions(iCond)) < minNtrialsPerCond) = 1;
end
% --- Exclude if outlier (compute it per variable & trialType, then exclude if any is an outlier)
V_Out.isExcluded_Outlier(:) = 0;
V_Out = f_isOutlier(V_Out, "t_Box2_afterB1", conditions, outlierThresholdMedian);
V_Out = f_isOutlier(V_Out, "t_Box1", conditions, outlierThresholdMedian);

% HELPER FUNCTION
    function V_Out = f_isOutlier(V_Out, Var_Name, conditions, outlierThresholdMedian)
        for curr_cond = conditions
            var = V_Out.(Var_Name + '_' + curr_cond);
            if Var_Name == "t_Box1"
                var = log(var);
            end
            V_Out.isExcluded_Outlier(isoutlier(var, 'median', ThresholdFactor=outlierThresholdMedian) & ~V_Out.isExcluded_TooFewGoodTrials) = 1;
        end
    end

end