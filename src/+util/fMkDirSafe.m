function result = fMkDirSafe(pathdir, opts)
% make the folder, or prompt to empty the folder if files are detected in
arguments
    pathdir (1,1) string
    opts.filePattern (1,1) string = "*"     % everything, but eg you can use "*.mat" to only delete mat files
    opts.flagCleanDir (1,1) string {mustBeMember(opts.flagCleanDir, ["no_clean" "force_clean" "ask_and_clean"])} = "ask_and_clean"
end
if isfolder(pathdir)
    prompt_ = sprintf("files detected in %s. Press:\n" + ...
        "Y to delete all\n" + ...
        "N to proceed while keeping all (files with same filenames may be replaced later though)\n" + ...
        "Q to abort\n[YNQ]:", pathdir);
    if ~isempty(setdiff(string({dir(fullfile(pathdir, opts.filePattern)).name}), ["." ".."]))
        if opts.flagCleanDir == "force_clean" || opts.flagCleanDir == "ask_and_clean"
            if opts.flagCleanDir == "ask_and_clean"
                warn_delete_old = input(prompt_,'s');
            end
            if opts.flagCleanDir == "force_clean" || strcmpi(warn_delete_old, 'y')
                disp("proceeding - removing everything in destination folder")
                system("rm -rf " + fullfile(pathdir, opts.filePattern));
            elseif strcmpi(warn_delete_old, 'n')
                disp("proceeding - keeping everything in destination folder (for now)")
            elseif strcmpi(warn_delete_old, 'q')
                error('aborting script by Q')
            else
                error('aborting script: you did not press y or n or q')
            end
        end
    end
else
    mkdir(pathdir);
end
result = 1;