function x = saccAOIs(x)

% given array x, find how many times non-zero values change

if size(x,2) < size(x,1)            % put as row
    x = x';
end

x(x == 0) = [];
if isempty(x)
    x = NaN;
else
    y = diff([0 x]);
    x(y == 0) = [];
    
end