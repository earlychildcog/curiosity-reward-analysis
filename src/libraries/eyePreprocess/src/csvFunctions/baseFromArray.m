function x = baseFromArray(a, b)
% 
if any(isnan(a)) || isempty(a)
    x = NaN;
else
    baseVec = arrayfun(@(n)b^n, 0:length(a)-1);
    x = sum(a.*baseVec);
end