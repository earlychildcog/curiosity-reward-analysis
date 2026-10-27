function ROI = fET_GetROIs(opts)

arguments
    opts.screenDimensions = [1024 1280];
    opts.back_imag        = fullfile("stim","_HiddenInBoxes.png");          % Background image to use
    opts.paddingScale     = 1/12;                                           % Set padding, if we want some (else set padding=0) -- curR: 1/12; curE: 1/30
    opts.YB               = 3/4;
    opts.BoxRadius        = 1/7;
end

% Define ROI size like Psychtoolbox wants it
W  = opts.screenDimensions(2);
H  = opts.screenDimensions(1);
rectObj = round(repmat([3/16, opts.YB; 13/16 ,opts.YB]', 2, 1).*[W H W H]' + [-1 -1 1 1]'*H*(opts.BoxRadius));
rectTopHalf = round(repmat([1 1/2]', 2, 1).*[1 1 W H]');
% Calculating W and H because Matlab calls rectangles in a different way than psychtoolbox
rectObj(3,:) = rectObj(3,:) - rectObj(1,:);  % height
rectObj(4,:) = rectObj(4,:) - rectObj(2,:);  % width
% Pad the rects
paddingPix    = ceil(opts.paddingScale * opts.screenDimensions(1));
padding_array = [-paddingPix, -paddingPix, 2*paddingPix, 2*paddingPix]; %extend ROIs
rectObj = rectObj + padding_array';
% Define ROI size like Matlab wants it
ROI = ROIclass([rectObj, rectTopHalf]', opts.back_imag, ["L"; "R"; "topHalf"]);

end
