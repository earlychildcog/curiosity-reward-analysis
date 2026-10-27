function getMatFromEdfBatch(edfFolder, matFolder, settings)
% 
% getMatFromEdfBatch converts edf files to mat
% edfFilename string
% matFilename string
% settings.project string = "test";
% settings.varinclude string = "condition";
% settings.messageStart string = "Frame to be desplayed 1$";
% settings.messageEnd string = "BLANK_SCREEN";
arguments
    edfFolder string {mustBeFolder}
    matFolder string = fullfile(edfFolder,"..", "eye-mat");
    settings.project string = "test";
    settings.varinclude string = "condition";
    settings.messageStart string = "Frame to be displayed 1$";
    settings.messageEnd string = "BLANK_SCREEN";
    settings.dofixations logical = true
end
    
    %% Process Directory:

% project=settings.project;
% varinclude=settings.varinclude;
% messageStart=settings.messageStart;
% messageEnd=settings.messageEnd;
% Get files:

if ~isfolder(matFolder)
    mkdir(matFolder);
end
rawFiles         = arrayfun(@(x)string(x.name),dir(fullfile(edfFolder,"*.edf")));

% Process subset of files:
nFiles  = length(rawFiles);

% Disp file information:
printToConsole('L1');
printToConsole(1, 'Processing %i files...\n', nFiles);
% Loop through files:
parfor fileIndx = 1:nFiles
    thisEDF = fullfile(edfFolder, rawFiles(fileIndx));
    thisMAT = fullfile(matFolder, strrep(rawFiles(fileIndx),"edf","mat"));
    hpData = getMatFromEdf(thisEDF, ...
        project=settings.project, ...
        varinclude=settings.varinclude, ...
        messageStart=settings.messageStart, ...
        messageEnd=settings.messageEnd, ...
        dofixations=settings.dofixations);
    hpData.saveMatFile(thisMAT);        % save the mat file
    printToConsole(2, 'Done with file %i.\n',fileIndx);
end
printToConsole(2, 'Done with folder.\n');
printToConsole('L2');


%% edfDataConverter Function:

%moved to separate function so we can clear the persistent variable related to conditions

            












