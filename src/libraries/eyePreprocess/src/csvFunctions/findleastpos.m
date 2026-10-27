function w = findleastpos(x, values)
% Find first positive number in x, return the position of the number if exists, Inf else

arguments
    x double
    values double = []
end
if ~isempty(values)
    x(~ismember(x,values)) = 0;
end

z = find(x > 0,1);
w = [z x(z)];
if isempty(z)
    w = [Inf 0];
end