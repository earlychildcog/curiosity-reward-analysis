function t = isInColumn(col, val)
arguments
    col     (:,1)
    val     (1,:)
end
nVal = length(val);
nCol = length(col);
t = false(nCol,1);
for v = 1:nVal
    t = t | col == val(v);    
end