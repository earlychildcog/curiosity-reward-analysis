function fSetUpFieldtripAndLibrariesAndParallelPool(opts)
arguments
    opts.flagFT        (1,1) logical = false;
    opts.flagParallel  (1,1) logical = false;
    opts.flagLibraries (1,1) logical = false;
end


% Add libraries (excluding fieldtrip because it creates issues when added
% with genpath)
if opts.flagLibraries
    path_genpath_exclude = fullfile("src","libraries","genpath_exclude-1.4.0");
    assert(isfolder(path_genpath_exclude), ...
        "path_genpath_exclude function required -- please check it is included in the libraries")
    addpath(genpath(path_genpath_exclude));
    addpath(genpath_exclude(fullfile('src','libraries'),{'fieldtrip'}));
end

% Add fieldtrip using its ft_default function for proper start up
% (you can also add an elseif condition for your own FT folder)
if opts.flagFT
    path_ft = fullfile(pwd,"src","libraries","fieldtrip");
    assert(isfolder(path_ft), ...
        "FieldTrip toolbox required -- please download it and save your path above -- https://www.fieldtriptoolbox.org/download/")
    addpath(path_ft)
    ft_defaults;
end

% Set up whether we're using parallel processing
if opts.flagParallel
    if ~isempty(gcp('nocreate')) && isa(gcp('nocreate'), 'ThreadPool')       % only process pool works here
        gcp('nocreate').delete;
    elseif isempty(gcp('nocreate'))
        parpool('Processes');
    end
end

end
