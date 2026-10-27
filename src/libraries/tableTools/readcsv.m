function T = readcsv(file, opts)
% optimised version of readtable
% file: a csv (or similar) file
% varNames (optional): names of variables (columns) to be exported
arguments
    file string {mustBeFile}
    opts.varNames string = string([])
    opts.stringType string {mustBeMember(opts.stringType, ["string" "categorical"])} = "string"
end


optsImport = detectImportOptions(file);
optsImport.VariableTypes = strrep(optsImport.VariableTypes, 'char', opts.stringType);      % read character columns as strings, faster than char

if ~isempty(opts.varNames)
    optsImport.SelectedVariableNames = opts.varNames;
end

T = readtable(file, optsImport);