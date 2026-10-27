function hpupildata_cleanup(thisdata)
    if isscalar(thisdata.eyesWithData) && strcmp(thisdata.eyesWithData, 'right') && ~isempty(thisdata.rightPupil_RawData)
        thisdata.meanPupil_ValidSamples.signal.pupilDiameter = thisdata.rightPupil_ValidSamples.signal.pupilDiameter;
        thisdata.meanPupil_ValidSamples.signal.t             = thisdata.rightPupil_ValidSamples.signal.t;
        thisdata.gaze.L = thisdata.gaze.R;
    elseif isscalar(thisdata.eyesWithData) && strcmp(thisdata.eyesWithData, 'left') && ~isempty(thisdata.leftPupil_RawData)
        thisdata.meanPupil_ValidSamples.signal.pupilDiameter = thisdata.leftPupil_ValidSamples.signal.pupilDiameter;
        thisdata.meanPupil_ValidSamples.signal.t             = thisdata.leftPupil_ValidSamples.signal.t;
        thisdata.gaze.R = thisdata.gaze.L;
    end
    thisdata.rightPupil_RawData      = [];
    thisdata.leftPupil_RawData       = [];
    thisdata.leftPupil_ValidSamples  = [];
    thisdata.rightPupil_ValidSamples = [];
    thisdata.gaze.message(thisdata.gaze.message == "") = missing;
end