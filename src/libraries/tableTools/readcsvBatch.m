function T = readcsvBatch(folder, opts)
arguments
    folder string {mustBeFolder}
    opts.varNames (1,:) {string} = string([])
    opts.verbose logical         = true
    opts.extension string        = "csv"
    opts.includeFilename logical = false % whether to make an extra column with the filename
    opts.stringType string {mustBeMember(opts.stringType, ["string" "categorical" "char"])} = "string"
end
% T = readcsvBatch(folder, varNames)
% read csv files
listFilenames   = arrayfun(@(x)string(x.name), dir(fullfile(folder, "*." + opts.extension)));
verbose         = opts.verbose;
includeFilename = opts.includeFilename;
nFiles          = length(listFilenames);
optsImport      = detectImportOptions(fullfile(folder,listFilenames(1)));
optsImport.VariableTypes = strrep(optsImport.VariableTypes, 'char', opts.stringType);      % read character columns as strings, faster than char
if ~isempty(opts.varNames)
    optsImport.SelectedVariableNames = varNames;                                  % select which variables to export
end
cellT = cell(nFiles,1);         % preassign cell array

% loop and get data
if verbose
    fprintf("Processing %d files in %s\n", nFiles, folder)
end
parfor f = 1:nFiles
    tic
    filepath = fullfile(folder,listFilenames(f));
    if verbose
        fprintf("reading " + filepath)
    end
    T_ = readtable(filepath, optsImport);
    if includeFilename
        T_.filename(:) = listFilenames(f);
    end
    cellT{f} = T_;
    pause(2); % to avoid running out of memory, give it some time after each file otherwise the computer restarts....
    if verbose
        fprintf('... completed in %.2f seconds\n', toc);
    end
end
if verbose
    fprintf('Reading complete - concatenating.\n');
end

T = cat(1,cellT{:});