function rawEDF = edfImportRaw(edfFileName, edfapi_year)
arguments
    edfFileName string {mustBeFile}
    edfapi_year double {mustBeMember(edfapi_year, [2014 2021])} = 2021
end
persistent edfapi_year_working
% 
% if ismac
%     APIName='edfapi';
% elseif ispc
%     APIName='edfapi64';
% elseif isunix
%     APIName='edfapi';
% end
% 
% % check version of edfmex to run
% try
%     edfapi_version = calllib(APIName,'edf_get_version');
% catch
%     if ismac
%         Headers='/Library/Frameworks/edfapi.framework/Headers';
%         APIDir='/Library/Frameworks/edfapi.framework';
%     elseif ispc
%         Headers='C:\Program Files (x86)\SR Research\EyeLink\EDF_Access_API\Example';
%         APIDir='C:\Program Files (x86)\SR Research\EyeLink\EDF_Access_API\lib\win64';
%     elseif isunix
%         error('Please add the default paths for unix...')
%     end
%     loadlibrary([APIDir filesep APIName],[Headers filesep 'edf.h']);
%     edfapi_version = calllib(APIName,'edf_get_version');
% end
% edfapi_year = edfapi_version(end-3:end);
if isempty(edfapi_year_working)
    edfapi_year_working = edfapi_year;
end

try
    rawEDF = eval("edfmex" + edfapi_year_working + "('" + edfFileName + "')");
catch er
    if edfapi_year == 2021
        edfapi_year_working = edfapi_year;
        warning('default mex file failed, trying with older versions...')
        rawEDF = edfImportRaw(edfFileName, edfapi_year_working);
    else
        throw(er)
    end
end

end