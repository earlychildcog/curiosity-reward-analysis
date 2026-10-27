function varlist = varlistFromEdf(edfFilename)
arguments
    edfFilename string {mustBeFile}
end

rawEDF = edfImportRaw(char(edfFilename));

evtRows         = arrayfun(@(f) ~isempty(f.message),rawEDF.FEVENT);
eventNames  = {rawEDF.FEVENT(evtRows).message}';

eventNames = regexp(eventNames,'!V TRIAL_VAR (\w*)\s(.*)$','tokens','once');
eventNames = eventNames(~cellfun(@isempty,eventNames));
varlist = unique(cellfun(@(x)string(x{1}),eventNames),'stable');
