function rawdata = getMatFromEdf(edfFilename,settings)
% edfDataConverter Converts a single edf file to a matlab file.
% edfFilename string {mustBeFile}
% settings.project string = "test";
% settings.varinclude string = "condition";
% settings.messageStart string = "Frame to be desplayed 1$";
% settings.messageEnd string = "BLANK_SCREEN";
arguments
    edfFilename string {mustBeFile}
    settings.project string = "test";
    settings.varinclude string = "condition";
    settings.messageStart string = "Frame to be displayed 1$";
    settings.messageEnd string = "BLANK_SCREEN";
    settings.dofixations logical = true
end


project = settings.project;
varinclude = settings.varinclude;
messageStart = settings.messageStart;
messageEnd = settings.messageEnd;
dofixations = settings.dofixations;
    
% Read raw edf file:
rawEDF = edfImportRaw(edfFilename);

t_ms        = rawEDF.FSAMPLE.time';
zeroTime_ms = t_ms(1);
t_ms        = (t_ms - zeroTime_ms);
L_raw       = double(rawEDF.FSAMPLE.pa(1,:)');
R_raw       = double(rawEDF.FSAMPLE.pa(2,:)');
Lx          = double(rawEDF.FSAMPLE.gx(1,:)');
Ly          = double(rawEDF.FSAMPLE.gy(1,:)');
Rx          = double(rawEDF.FSAMPLE.gx(2,:)');
Ry          = double(rawEDF.FSAMPLE.gy(2,:)');
hdist       = double(rawEDF.FSAMPLE.hdata(3,:)');

gazeL       = [Lx Ly];
gazeR       = [Rx Ry];

[~, subjName] = fileparts(edfFilename);
% Find with which eye we work with
if length(unique([rawEDF.RECORDINGS.eye])) > 1
    warning('eye change in %s', subjName)
    % now we decide what to do
    allEyes = [rawEDF.RECORDINGS.eye];
    if all(allEyes ~= 3)
        L_raw = L_raw + R_raw;
        R_raw = R_raw + R_raw;
        if mean([rawEDF.RECORDINGS.eye]) < 1.5
            rawEDF.RECORDINGS(1).eye = 1;
        else
            rawEDF.RECORDINGS(1).eye = 2;
        end
    else
        if mean(allEyes == 2) > 0.6
            rawEDF.RECORDINGS(1).eye = 2;
        elseif mean(allEyes == 1) > 0.6
            rawEDF.RECORDINGS(1).eye = 1;
        else
            warning('deal with eye change in %s', subjName)
        end
    end
end
if rawEDF.RECORDINGS(1).eye == 3
    curEye = 'both';
    L = L_raw;
    R = R_raw;
    if abs(mean((L_raw <= 0)) - mean((R_raw <= 0))) > 0.099
        fprintf(2,'%s, %f left missing, %f right missing\n',subjName, mean((L_raw <= 0)), mean((R_raw <= 0)))
    else
        fprintf('%s, %f left missing, %f right missing\n',subjName,mean((L_raw <= 0)), mean((R_raw <= 0)))
    end
elseif rawEDF.RECORDINGS(1).eye == 2
    curEye = 'right';
    L = nan(size(R_raw));
    R = R_raw;
    gazeL = nan(size(gazeR));
elseif rawEDF.RECORDINGS(1).eye == 1
    curEye = 'left';
    L = L_raw;
    R = nan(size(L_raw));
    gazeR = nan(size(gazeL));
%     R = [];
%     gazeR = [];
end
% Remove the 0 samples:
L(L==0) = NaN;
R(R==0) = NaN;


% Process events (only extract relevant events):
eventDataNames  = {rawEDF.FEVENT.message}';
evtRows         = ~cellfun(@isempty,eventDataNames);
eventData.t     = vertcat(rawEDF.FEVENT(evtRows).sttime);
eventData.name  = string(eventDataNames(evtRows));
rows2delete = eventData.t < zeroTime_ms-1;

eventData.t(rows2delete)    = [];
eventData.name(rows2delete) = [];

eventData.t = eventData.t - zeroTime_ms;

% Find trials start and end times:
%trailStartRows = find(strcmp(eventData.name,'!MODE RECORD CR'));
trialStartRows = ~cellfun(@isempty,regexp(eventData.name, messageStart));
% trialStartRows = [false; trialStartRows(1:end-1)];      %shift trial beginning to capture stim onset message
%trialStartRows = cellfun(@(x)~isempty(x),strfind(eventData.name,'STIM_ONSET'));
%trialEndRows = cellfun(@(x)~isempty(x),strfind(eventData.name,'TRIAL_RESULT 0'));
trialEndRows = ~cellfun(@isempty,strfind(eventData.name,messageEnd));
%assert(sum(trialStartRows)==1);
segmentStart   = eventData.t(trialStartRows);
segmentEnd     = ceil(eventData.t(trialEndRows)/2)*2;

[segmentStart, segmentEnd] = fixSegments(segmentStart, segmentEnd);


if size(segmentStart,1) ~= size(segmentEnd,1)
    error('segmentation error: number of starts and ends do not match in file %s, conversion aborted', edfFilename)
    %         return
end
messages = grab_messages(eventData,t_ms);



segmentN = length(segmentStart);
% get trial variables
vartable = varFromEdfdata(eventData,varinclude);

[~, ~, ~, badInd] = fixSegments(segmentEnd, vartable.timeSent);
vartable.timeSent = [];
vartable(badInd, :) = [];

if size(vartable,1) > size(segmentStart,1)
    error('segmentation error')
end

% Make table:
segmentName  = strcat(project...
    ,strrep(cellstr(num2str((1:segmentN)')),' ','0'));
SegmentSource      = segmentName;
[~,justFileName,~] = fileparts(edfFilename);
SegmentSource(:)   = {justFileName};

[~, fileName]       = fileparts(edfFilename);
fileName = repmat(fileName, [segmentN 1]);
eyeUsed           = segmentName;
eyeUsed(:)        = {curEye};
segmentData = [table(...
    segmentStart,segmentEnd,segmentName,SegmentSource...
    ,fileName,eyeUsed), vartable];
% segmentData = table(...
%     segmentStart,segmentEnd,segmentName,SegmentSource...
%     ,fileType,trial,CA,Condition,picture,eyeUsed);
fs = median(diff(t_ms));
if dofixations
% add parsed fixation
    FIX = rawEDF.FEVENT(contains({rawEDF.FEVENT.codestring},'ENDFIX'));
    
    if strcmp(curEye,'left')
        fixation{1} = FIX([FIX.eye] == 0);
        fixation{2} = [];
    elseif strcmp(curEye,'right')
        fixation{1} = FIX([FIX.eye] == 1);
        fixation{2} = [];
    else
        fixation{1} = FIX([FIX.eye] == 0);
        fixation{2} = FIX([FIX.eye] == 1);
    end
    for i = 1:2
    %fixcol = repmat({''},size(t_ms));
        FIX = fixation{i};
        fixcol{i} = false(size(t_ms));
        fixgazeX{i} = NaN(size(t_ms,1),1);
        fixgazeY{i} = NaN(size(t_ms,1),1);
        
        if ~isempty(FIX)
            ind0 = 1;
            %find fixation times
            fixstart = [FIX(:).sttime];
            fixend = [FIX(:).entime];
            for f=1:size(FIX,2)
                ind0 = find(t_ms >= fixstart(f)-zeroTime_ms,1);
                %fixcol(ind0:(ind0+double(fixend(f)-fixstart(f))/2-1)) = {'FIX'};
                fixcol{i}(ind0:(ind0+double(fixend(f)-fixstart(f))/fs)) = true;
                fixgazeX{i}(ind0:(ind0+double(fixend(f)-fixstart(f))/fs)) = FIX(f).gavx;
                fixgazeY{i}(ind0:(ind0+double(fixend(f)-fixstart(f))/fs)) = FIX(f).gavy;
                % use out of bounds condition on fixations
            %     out_of_bounds = fixgazeX<0 | fixgazeX>1280 | fixgazeY<0 | fixgazeY>1024;
            %     fixcol(out_of_bounds) = false;
            %     fixgazeX(out_of_bounds) = NaN;
            %     fixgazeY(out_of_bounds) = NaN;
            %     if FIX(f).eye == 0
            %         fixgazeL(ind0:(ind0+double(fixend(f)-fixstart(f))/2-1),1) = FIX(f).gavx;
            %         fixgazeL(ind0:(ind0+double(fixend(f)-fixstart(f))/2-1),2) = FIX(f).gavy;
            %     elseif FIX(f).eye == 1
            %         fixgazeR(ind0:(ind0+double(fixend(f)-fixstart(f))/2-1),1) = FIX(f).gavx;
            %         fixgazeR(ind0:(ind0+double(fixend(f)-fixstart(f))/2-1),2) = FIX(f).gavy;
            %     end
            end
        end
    end
else
    fixcol   = {[], []};
    fixgazeX = {[], []};
    fixgazeY = {[], []} ;
end
% count = 0; f0 = false; for f=fixcol', if ~f0 && f, f0=f; count= count+1; elseif f0 && ~f, f0 = f; end, end, count

% Build RawFileModel instance, which saves the data to a mat file that is
% compatible with the other data models:
t_ms = double(t_ms);

L = convert2mm(L);
R = convert2mm(R);

diameterUnit = 'mm';
diameter     = struct('t_ms',t_ms,'L',L,'R',R);
gaze = struct('t_ms',t_ms,'L',gazeL,'R',gazeR,'hdist',hdist,'message',{messages},'fixation',fixcol{1},'fixgazeX',fixgazeX{1},'fixgazeY', fixgazeY{1},'fixation2',fixcol{2},'fixgazeX2',fixgazeX{2},'fixgazeY2', fixgazeY{2});


% delete odd rows

badrows = mod(t_ms,2) == 1;         % does this work for fs = 4? Let's assert!!:
assert(fs == 2 || all(diff(t_ms(~badrows)) > 2.1), "for less than 500Hz sampling rates, presence of skip samples are a problem. One was just discovered in %s", edfFilename)



if any(badrows)
    A = structfun(@(x)x(badrows),gaze,'UniformOutput',false);
    if all(cellfun(@isempty,A.message))
        gaze = structfun(@(x)x(~badrows,:),gaze,'UniformOutput',false);
        diameter = structfun(@(x)x(~badrows,:),diameter,'UniformOutput',false);
    else
        error('lost message, requires further check')
    end
end

% we equal NaN fields (i.e. when there is only one eye) to empty
% gaze = empty_struct_fields(gaze);
diameter = empty_struct_fields(diameter);



rawdata = RawFileModel(diameterUnit,diameter,segmentData, zeroTime_ms,gaze);