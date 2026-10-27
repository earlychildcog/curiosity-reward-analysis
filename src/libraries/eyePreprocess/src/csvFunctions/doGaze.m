function [G] = doGaze(csv_folder, IPstarts, IPends)
% get gaze data function
% all units are in milliseconds


%% settings
% 1 table for all trials, one for first
table_pertrial = table();
table_persubject = table();

exclude_non_ant = false;
baseline = false;
%% set IP
if ~exist('csv_folder','var')
    csv_folder = 'data/csv';
end


%% getting data
% folder with gaze data and exclusion columns
files = arrayfun(@(x)x.name,dir([csv_folder '/*.csv']),'UniformOutput',false)';  %{dir([csv_folder '/*.csv']).name};
old_subj = '';

dls{1} = [];
dls{2} = [];
firstfix{1} = [];
firstfix{2} = [];


% read the mirror results file

S = {};
G = table;
count = 0;

varGroup = {'session','trial','trialtype','list'};

for f=1:size(files,2)           % run through all subjects
    T0 = readtable([csv_folder '/' files{f}]);
    baseROI = max(T0.fixroi) + 1;
    if true %~any(T.famexcl)        % we will not put exclusions based on familiarisation trials because there were none
        T = T0((T0.time >= IPstarts(1)) & (T0.time <= IPends(1)),:);        % restrict to IP and valid trials
        if ~isempty(T)    
            for i = 1:size(IPstarts,2)
                T = T0((T0.time >= IPstarts(i)) & (T0.time <= IPends(i)),:);        % restrict to IP and valid trials
                B = varfun(@(x)[sum(x == 1), sum(x == 2), findleastpos(x, [1 2]), baseFromArray(saccAOIs(x), baseROI)],T,'GroupingVariables',varGroup,'InputVariables',{'fixroi'});
                B.Properties.VariableNames{end} = 'd';
                B.dls = (B.d(:,2)-B.d(:,1))./(B.d(:,2)+B.d(:,1));
                B.durAOI = 2*(B.d(:,2)+B.d(:,1));
                B.firstfix = B.d(:,4)-1;
                B.firstfix(B.firstfix < 0) = NaN;
                B.latency = B.d(:,3)*2-2;
                B.latency(B.latency == Inf) = NaN;
                B.saccAOIS = arrayfun(@(x)arrayFromBase(x, baseROI), B.d(:,5), 'UniformOutput', false);

                B.saccadesNum = floor(log(B.d(:,5))/log(baseROI))+1;
                B.GroupCount = [];
                B.d = [];


                if i == 1
                    L = B;
                else
                    L = join(L,B,'keys',varGroup);
                end
            end
            if exclude_non_ant
                if length(IPstarts) > 1
                    L(isnan(L.dls_B) & isnan(L.dls_L),:) = [];           % delete non-data rows
                else
                    L(isnan(L.dls),:) = [];
                end
            end
            if isempty(L)
                disp(2)
            end
            if baseline         % include pupil data if we asked for it
                
                P = varfun(@(x)[nanmean(x) , mean(x)],T0(T0.time > pupIP(1) & T0.time < pupIP(2),:),'InputVariables','pupil','GroupingVariables',{'session','trial'});
                P.Properties.VariableNames{end} = 'p';
                P.meanpup = P.p(:,2);
                P.nanmeanpup = P.p(:,1);
                P.p = [];
                P.GroupCount = [];
                L = join(L,P,'keys',{'session','trial'});
            end
            if isempty(G)
                G = L;
            else
                G = [G; L];
            end
        end
    end
end

exportVars = varGroup([1, 3, 4]);

%% export data

H = varfun(@(x)mean(~isnan(x)), G, 'InputVariables', 'saccadesNum', 'GroupingVariables', exportVars);
H.Properties.VariableNames(end) = {'anticipated_trials'};
exportcsv = true;
if exportcsv
    writetable(H, 'gazereport_trialanticipation.csv')

    Hw = unstack(H, {'anticipated_trials', 'GroupCount'}, exportVars{2});
    writetable(Hw, 'gazereport_trialanticipation_wide.csv')
end

