function getCsvFromHpd(hPupilData, opts)
% script that grabs and exports the preprocessed pupil data into csv files
% Input arguments:
%     hPupilData
%     opts.csvfolder = "data/csv"
%     opts.exprSubj = "(\w+)"
%     opts.ROI = []
%     opts.verbose = false
arguments
    hPupilData
    opts.csvfolder = "data/csv"
    opts.exprSubj = "(\w+)"
    opts.ROI = []
    opts.verbose logical = false
    opts.roiFrom string {mustBeMember(opts.roiFrom, ["raw" "fix"])} = "fix"
    opts.export_fixations logical = true
    opts.source string {mustBeMember(opts.source, ["eyelink" "pupillo"])} = "eyelink"
    opts.cleanup logical = true
end

csvfolder = opts.csvfolder;
exprSubj = opts.exprSubj;
ROI = opts.ROI;
verbose = opts.verbose;
roiFrom = opts.roiFrom;
export_fixations = opts.export_fixations;
mkdir(csvfolder);         % make a folder if no folder exists
flipROIs = false;
source = opts.source;
% subjN = size(hPupilData,1);

%% get all subject names (control for multiple sessions)
allFilenames = arrayfun(@(x)string(x.filename),hPupilData);
allSubj = cellfun(@(x)x,regexp(allFilenames,exprSubj,"tokens","once"));

[allSubj, ~, IC] = unique(allSubj);

%nFile = length(allFilenames);
nSubj = size(allSubj,1);
H = cell(nSubj,1);
for s = 1:nSubj
    H{s} = hPupilData(IC == s);
end

%% run loop

for s = 1:nSubj
    % determine how many
    try
    h = H{s};
    nRuns = length(h);
    timeZero = datetime;
    % special treatment if multiple runs
    if nRuns > 1
        o_ = cell(nRuns,1);
    end
    for cRun = 1:length(h)
        thisdata = h(cRun);
        
        
        if source == "eyelink"
            % if only one eye is tracked, copy data to other eye/mean eye to run the rest of the code DO THE CHECK BETTER WTF PAST SELF
            if isempty(thisdata.meanPupil_ValidSamples)
                if isscalar(thisdata.eyesWithData) && strcmp(thisdata.eyesWithData, 'right') && ~isempty(thisdata.rightPupil_RawData)
                    time_total = thisdata.rightPupil_RawData.t_ms;
                    thisdata.meanPupil_ValidSamples.signal.pupilDiameter = thisdata.rightPupil_ValidSamples.signal.pupilDiameter;
                    thisdata.meanPupil_ValidSamples.signal.t = thisdata.rightPupil_ValidSamples.signal.t;
                    thisdata.gaze.L = thisdata.gaze.R;
                elseif isscalar(thisdata.eyesWithData) && strcmp(thisdata.eyesWithData, 'left') && ~isempty(thisdata.leftPupil_RawData)
                    time_total = thisdata.leftPupil_RawData.t_ms;
                    thisdata.meanPupil_ValidSamples.signal.pupilDiameter = thisdata.leftPupil_ValidSamples.signal.pupilDiameter;
                    thisdata.meanPupil_ValidSamples.signal.t = thisdata.leftPupil_ValidSamples.signal.t;
                    thisdata.gaze.R = thisdata.gaze.L;
                else
                    time_total = thisdata.timestamps_RawData_ms;
                end
            else
                time_total = thisdata.timestamps_RawData_ms;
            end
        else
            time_total = round(thisdata.meanPupil_ValidSamples.signal.t*1000, -1);
        end
        o = table();
           
        % get session name
        sessionname = allSubj(s);
            % keep old session name
        o.session = repmat({sessionname},size(time_total));
        % get filled pupil data
%         I = get_gap_index(time_total,round(thisdata.meanPupil_ValidSamples.signal.t*1000));
%         NaNs =  nan(size(time_total,1) -size(thisdata.meanPupil_ValidSamples.signal.pupilDiameter(I),1),1);
    %     oldpupil = [thisdata.meanPupil_ValidSamples.signal.pupilDiameter(I); NaNs];
       
        
        o.pupil = nan(size(time_total));    
        I1 = ismember(time_total,round(thisdata.meanPupil_ValidSamples.signal.t*1000));
        I2 = ismember(round(thisdata.meanPupil_ValidSamples.signal.t*1000),time_total);
        o.pupil(I1) = thisdata.meanPupil_ValidSamples.signal.pupilDiameter(I2);
        
        % for now, we put version gaze
        
        % get gaze data
        if export_fixations
            o.fixation  = thisdata.gaze.fixation;
            o.fixgazeX 	= round(thisdata.gaze.fixgazeX,1);
            o.fixgazeY 	= round(thisdata.gaze.fixgazeY,1);
            o.fixation2  = thisdata.gaze.fixation2;
            o.fixgazeX2 	= round(thisdata.gaze.fixgazeX2,1);
            o.fixgazeY2 	= round(thisdata.gaze.fixgazeY2,1);
        end
        if source == "eyelink"
            o.lx 	= thisdata.gaze.L(:,1);
            o.ly 	= thisdata.gaze.L(:,2);
            o.rx 	= thisdata.gaze.R(:,1);
            o.ry 	= thisdata.gaze.R(:,2);
            o.hdist  = thisdata.gaze.hdist;
        elseif source == "pupillo"
            o_gaze = table;
            o_mess = table;
            o.time = time_total;
            o_gaze.time = round(thisdata.gaze.t*1000 + 0.1,-1); % to avoid stupid roundings when we have multiples of 5
            o_gaze.lx 	= thisdata.gaze.L(:,1);
            o_gaze.ly 	= thisdata.gaze.L(:,2);
            o_gaze.rx 	= thisdata.gaze.R(:,1);
            o_gaze.ry 	= thisdata.gaze.R(:,2);
            o_gaze.hdist  = thisdata.gaze.hdist;
            o_mess.messages = thisdata.gaze.message;
            o_mess.time = round(thisdata.gaze.t_ms + 0.1,-1);   % to avoid stupid roundings when we have multiples of 5      
            o_mess.frame = thisdata.gaze.frame;
            o_gaze = outerjoin(o_gaze, o_mess, 'MergeKeys',true);
            otemp = o;
            if isempty(o)
                warning(['empty at ' thisdata.filename] )
            else
                o = join(o, o_gaze);
            end
            % clear o_gaze
        end
        
        %get sticker distance data
        
        if isempty(o)
            continue
        end
        
        % restrict data only within trial segments
        sstart = [double(thisdata.segmentsTable.segmentStart); Inf];            % segment start times
        send   = [-Inf ; double(thisdata.segmentsTable.segmentEnd)];            % segment end times
        
        trialNo1  = arrayfun(@(t)sum(sstart <= t),time_total);                  % count trial number by start time
        trialNo2  = arrayfun(@(t)size(sstart,1)-sum(send >= t),time_total);     % count trial number by end time
        o.trial = trialNo1;
        badrows = trialNo1 ~= trialNo2;                                         % combine
        o(badrows,:) = [];                                                      % delete data that is not within segments
        time_total(badrows) = [];
        % get conditions
        condition_names = thisdata.segmentsTable.Properties.VariableNames(7:end);
        
        for c=1:size(condition_names,2)
            trial_temp = thisdata.segmentsTable.(condition_names{c});       %assign to variable for computational speed
            o.(condition_names{c}) = trial_temp(o.trial);
        end
        % ok to summarise: if fb and left, changes. If TB and right, changes. So, 2 is correct, 1 is wrong
        if ~isempty(ROI)
            if roiFrom == "fix"
                fixroicol = max([ROI.whichROI(o.fixgazeX,o.fixgazeY),ROI.whichROI(o.fixgazeX2,o.fixgazeY2)], [], 2);
            elseif roiFrom == "raw"
                fixroicol = max([ROI.whichROI(o.lx,o.ly),ROI.whichROI(o.rx,o.ry)], [], 2);
            end
            if flipROIs % here we do condition based fixation results
                roichange = (strcmp(o.trialtype,'TWB') & strcmp(o.list,'2')) | (strcmp(o.trialtype,'TWB-N') & strcmp(o.list,'1'));
                change1 = fixroicol == 1;
                change2 = fixroicol == 2;
                fixroicol(roichange & change1) = 2; 
                fixroicol(roichange & change2) = 1; 
            end
            o.fixroi = fixroicol;
        end
           
        if source == "eyelink"
            o.messages = thisdata.gaze.message(~badrows);
        end
        %normalised time
        trials_present = unique(o.trial);
        trial_starts_ = arrayfun(@(x)find(o.trial == x,1),trials_present); %#ok<NBRAK2> 
        alltrials = 1:max(trials_present);
        trial_starts = zeros(max(trials_present),1);
        trial_starts(trials_present) = trial_starts_;
        o.time = time_total - arrayfun(@(x)time_total(trial_starts(x)),o.trial);
        o = [o(:,1) o(:,end) o(:,2:end-1)];
        o.run = cRun*ones(size(o,1),1);
        
        if nRuns > 1
            o_{cRun} = o;
        end
    end
    if nRuns > 1
        o = cat(1,o_{:});
    end
    x = thisdata.filename;
    filename = regexprep(x, "(" + exprSubj + ").*", "$1.csv");
    writetable(o,fullfile(csvfolder, filename));
    timeOne = datetime;
    if verbose
        fprintf('%s done in %.1f seconds\n', sessionname, seconds(timeOne - timeZero))
    end
    catch err
        fprintf("error while processing subj %s\n",allSubj(s));
        rethrow(err);
    end
end

    
% function I = get_gap_index(T0,T)
% [~,I] = intersect(T,T0);