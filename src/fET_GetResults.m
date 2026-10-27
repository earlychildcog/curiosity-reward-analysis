% Get results, grouping per participant and trialType (or overall), and
% calculating difference scores between trialTypes (TestSame - TestDiff)

function V_Out = fET_GetResults(S_good, var_in, var_out)

% Get values per trialType
V_Out1 = f_GetVariables(S_good, var_in, var_out, ["session", "trialType"]);
% Get values per over all trials
V_Out2 = f_GetVariables(S_good, var_in, var_out, "session");
V_Out2.Properties.VariableNames(~contains(V_Out2.Properties.VariableNames,"session")) = ...
    V_Out2.Properties.VariableNames(~contains(V_Out2.Properties.VariableNames,"session")) + "_all";
% Merge into one output
V_Out = outerjoin(V_Out1,V_Out2,keys="session", MergeKeys=true);
% Add difference scores between trialTypes (renaming them to TestDiff)
for curr_var = var_out
    if contains(curr_var, "Ntrials")
        NtrialsVars = V_Out.Properties.VariableNames(contains(V_Out.Properties.VariableNames,curr_var));
        for iVar = 1:length(NtrialsVars)
            V_Out.(NtrialsVars{iVar})(isnan(V_Out.(NtrialsVars{iVar}))) = 0; % NaNs should be zeros (no count)
        end
    else
        curr_var_trialTypes = V_Out.Properties.VariableNames(contains(V_Out.Properties.VariableNames, curr_var));
        V_Out.(curr_var + "_DiffScore") = V_Out.(curr_var_trialTypes{2}) - V_Out.(curr_var_trialTypes{1});
    end
end

% HELPER FUNCTION
    function V_Out = f_GetVariables(S_good, var_in, var_out, groupingVars)
        % -- First get timings
        T1 = varfun(@(x)mean(x,"omitnan"), S_good, InputVariables=var_in, GroupingVariables=groupingVars);
        var_temp = "Fun_" + var_in;
        var_outT = var_out(find(contains(var_out, "t_"),1,"first"));
        T1.(var_outT)   = T1.(var_temp)(:,1);
        T1.(var_temp)  = [];
        %  -- Optional: add logged values, for time1 only (bound to 0 with a lot of
        % values close to bound: need to log to make sense of variability)
        curr_var2 = var_out(contains(var_out, "log"));
        if ~isempty(curr_var2)
            T1.(curr_var2) = log(T1.(var_outT));
            var_outT = [var_outT, curr_var2];
        end
        % -- Then get counts and proportions (only for difference score to avoid repeated variables)
        if sum(contains(var_out, "Ntrials")) > 0
            P1 = varfun(@(x)mean(~isnan(x)), S_good, InputVariables=var_in, GroupingVariables=groupingVars);
            var_outV = var_out(1:2);
            P1.Properties.VariableNames(end-1:end) = var_outV;
            P1.(var_outV(1))(isnan(P1.(var_outV(1))(:))) = 0; % NaNs should be zeros (no count)
            % -- And group proportion and timing values into one table
            V1 = outerjoin(P1,T1,keys=groupingVars, MergeKeys=true); V1.GroupCount = [];
        else
            V1 = T1;
        end
        if numel(groupingVars) > 1
            if ~contains(var_out, "Ntrials")
                var_out = ["GroupCount", var_out];
            end
            V_Out = unstack(V1, var_out, "trialType");
        else
            V_Out = V1;
        end
        V_Out(:,contains(V_Out.Properties.VariableNames, "GroupCount")) = [];
    end

end