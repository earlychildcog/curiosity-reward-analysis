function gaze_remove_fixations(preprocData)
for iSubj = 1:numel(preprocData)
    fixnames = string(fieldnames(preprocData(iSubj).gaze));
    fixnames = fixnames(startsWith(fixnames, "fix"));
    preprocData(iSubj).gaze = rmfield(preprocData(iSubj).gaze, fixnames);
end