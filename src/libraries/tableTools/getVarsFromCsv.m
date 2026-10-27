function varNames = getVarsFromCsv(csvfile)
% get the list of variables (column names) from a csv file
arguments
    csvfile string {mustBeFile}
end


opts = detectImportOptions(csvfile);

varNames = opts.VariableNames;
