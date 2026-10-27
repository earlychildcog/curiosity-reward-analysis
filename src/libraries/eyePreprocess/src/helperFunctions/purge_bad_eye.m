function hPupilData = purge_bad_eye(hPupilData,threshold)


for s=1:size(hPupilData,1)
    hPupilData(s);
    if size(hPupilData(s).eyesWithData,2) == 2
        leftstd = std(hPupilData(s).leftPupil_RawData.rawSample, 'omitnan');
        rightstd = std(hPupilData(s).rightPupil_RawData.rawSample, 'omitnan');
        if leftstd/rightstd > threshold
            hPupilData(s).leftPupil_RawData.rawSample = [];
            hPupilData(s).eyesWithData = {'right'};
            printToConsole(1, 'left bad eye purged in %s, left std %.2f, right std %.2f \n', hPupilData(s).segmentsTable.SegmentSource{1},leftstd,rightstd );
        elseif rightstd/leftstd > threshold
            hPupilData(s).rightPupil_RawData.rawSample = [];
            hPupilData(s).eyesWithData = {'left'};
            printToConsole(1, 'right bad eye purged in %s, left std %.2f, right std %.2f \n', hPupilData(s).segmentsTable.SegmentSource{1},leftstd,rightstd );
        else
            printToConsole(1, 'no bad eye purged in %s, left std %.2f, right std %.2f \n', hPupilData(s).segmentsTable.SegmentSource{1},leftstd,rightstd );
        end
    elseif isempty(hPupilData(s).eyesWithData)

    else
        eyestd = std(hPupilData(s).(strcat(hPupilData(s).eyesWithData{1},'Pupil_RawData')).rawSample, 'omitnan');
        printToConsole(1, 'only one eye in %s, %s std %.2f \n', hPupilData(s).segmentsTable.SegmentSource{1},hPupilData(s).eyesWithData{1},eyestd );
        
        
    end
end