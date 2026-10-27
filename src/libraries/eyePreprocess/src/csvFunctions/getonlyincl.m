function getonlyincl(csv_folder, csv_new, dobaseline, mintrials)
% script that goes through the csv files with
% exclusion columns and copies the included subjects/trials
% in a new directory
% some manual adjustments may be needed :V
if ~exist('csv_folder','var')
    csv_folder = 'csv_excl';
end
if ~exist('mintrials','var')
    mintrials = 2;
end
if ~exist('dobaseline','var')
    dobaseline = true;
end
directory = dir([csv_folder '/*.csv']);
files = arrayfun(@(x)x.name,dir([csv_folder '/*.csv']),'UniformOutput',false)';  %{dir([csv_folder '/*.csv']).name};
if ~exist('csv_new','var')
    csv_new = 'csv_onlyinclpupil';
end
mkdir(csv_new);
for f=1:size(files,2)
    T = readtable([csv_folder '/' files{f}]);
    if true %~any(T.famexcl)
        if dobaseline
            T = T(~T.excl1 & ~T.excl2 & ~T.excl3 & ~T.exclbase,:);
        else
            T = T(~T.excl1 & ~T.excl2 & ~T.excl3,:);
        end
        T0 = T(T.time == 0,:);
        if sum(strcmp(T0.condition,'high')) >= mintrials && sum(strcmp(T0.condition,'low')) >= mintrials  && sum(strcmp(T0.condition,'true')) >= mintrials 
            badind = contains(T.Properties.VariableNames,{'trialtype','trialsubtype','ball','outcome','result'});
            T(:,badind) = [];
            writetable(T, [csv_new  '/' files{f}]);
            fprintf('%s exported\n',[csv_new  '/' files{f}]);
        end
    end
end