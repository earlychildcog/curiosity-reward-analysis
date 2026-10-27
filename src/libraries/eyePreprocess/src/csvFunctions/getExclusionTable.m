function V = getExclusionTable(folderIn)

lFileIn = arrayfun(@(x)x.name,dir([folderIn '/*.csv']),'UniformOutput',false)';  %{dir([csv_folder '/*.csv']).name};
nFile = length(lFileIn);

for cFile = 1:nFile
    nameFile = lFileIn{cFile};
    Tx = readtable(sprintf('%s/%s',folderIn, nameFile));
    
    varAll = Tx.Properties.VariableNames;
    varIncl = varAll(contains(varAll, 'incl'));
    Vx = varfun(@(x)sum(x), Tx(Tx.time == 0,:), "InputVariables",varIncl,"GroupingVariables",["session" "list" "trialtype"]);
%     Vx.Properties.VariableNames(end-1:end) = {'total_trials' 'included_trials'};
    if cFile == 1
        V = Vx;
    else
        V = [V; Vx];
    end

end