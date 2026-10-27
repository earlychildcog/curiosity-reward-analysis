function T = readcsvBatchSerial(folder, varNames, optionals)
arguments
    folder string {mustBeFolder}
    varNames (1,:) {string} = string([])
    optionals.verbose logical = false
end
% T = readcsvBatch(folder, varNames)
% read csv files
listFilenames = arrayfun(@(x)string(x.name), dir(fullfile(folder, "*.csv")));
verbose = optionals.verbose;
nFiles = length(listFilenames);
opts = detectImportOptions(fullfile(folder,listFilenames(1)));
opts.VariableTypes = strrep(opts.VariableTypes, 'char', 'string');      % read character columns as strings, faster than char
if ~isempty(varNames)
    opts.SelectedVariableNames = varNames;                                  % select which variables to export
end
cellT = cell(nFiles,1);         % preassign cell array

% loop and get data
for f = 1:nFiles
    tic
    filename = fullfile(folder,listFilenames(f));
    if verbose
        fprintf("reading " + filename)
    end
    T_ = readtable(filename, opts);
    cellT{f} = T_;
    if verbose
        fprintf('... completed in %.2f seconds\n', toc);
    end
end

T = cat(1,cellT{:});