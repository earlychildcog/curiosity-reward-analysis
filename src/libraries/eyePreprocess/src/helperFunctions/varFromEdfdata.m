function vartable = varFromEdfdata(eventData,varinclude)
% Construct table of values of selected trial variables from EDF file
% This function is an attempt of a universal way to import trial variables
% that appear in the message log after the message !V TRIAL_VAR
%
% Use: 
%   vartable = edfTrialVarImporter(eventDataName,varinclude)
%
%   vartable: the resulting table of values of trial variable
%
%   varinclude: optional parameter, which variables to be included. Set '-1' to choose 
%   by graphical user interface prompt. Set it empty ([] or {}) to output an empty table. Give a cell 
%   array of trial variable names to output a table with the values of exactly these variables
%
%--------------------------------------------------------------------------
%
%   This code is built by Dimitris Askitis to supplement 
%   the supplement material to the article:
%
%    Preprocessing Pupil Size Data. Guideline and Code.
%     Mariska Kret & Elio Sjak-Shie. 2018.
%
%--------------------------------------------------------------------------
%
%     This program is free software: you can redistribute it and/or
%     modify it under the terms of the GNU General Public License as
%     published by the Free Software Foundation, either version 3 of
%     the License, or (at your option) any later version.
%
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%     General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see
%     <http://www.gnu.org/licenses/>.
%
%--------------------------------------------------------------------------

%If list of conditions is not specified, then it is just the trial_index condition 

arguments
    eventData
    varinclude string = string([])
end


if isempty(varinclude)              %in case we do not want to import trial variables
    vartable = table();
    warning("no trial variables imported")
    return
end

%Get list of conditions in experiment
messagesVarInd = contains(eventData.name,"!V TRIAL_VAR");
messagesVar_ = regexp(eventData.name(messagesVarInd),"!V TRIAL_VAR (\w*)\s(.*)$","tokens","once");
messagesVar = cat(1,messagesVar_{:});
times = eventData.t(messagesVarInd);
dtimes = [11; diff(times)];
timeList = times(dtimes > 10);


varlist = unique(messagesVar(:,1),"stable");
assert(all(ismember(varinclude,varlist)),'Trial variable name does not appear in the event log');
%no variables were found in message data, so we exit
if isempty(varlist)             
    vartable = table();
    return
end

%get list of variable values
%!!!warning: assumes that all are sent to all trials (unsure if some may
%not be sent, that would prob be bad design)
valuelist = reshape(messagesVar(:,2),length(varlist),[])';



valueincluded = valuelist(:,ismember(varlist,varinclude));

% Find values that can be expressed numerically
% numeric_ind = cellfun(@(x)~isempty(str2num(x)),valueinclude);
% valueinclude(numeric_ind) = cellfun(@(x){str2num(x)},valueinclude(numeric_ind));

vartable = array2table(valueincluded,'VariableNames',varinclude);
vartable.timeSent = timeList;
end
