function S = empty_struct_fields(S)

fn = fieldnames(S);
for fieldname = fn'
    f = fieldname{1};
    if ~iscell(S.(f)) && all(isnan(S.(f)),'all')
        S.(f) = [];
    end
end
