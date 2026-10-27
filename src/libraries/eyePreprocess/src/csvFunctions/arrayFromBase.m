function a = arrayFromBase(d, b)

assert(size(d,1) == 1);

n = max(1,round(log2(max(d)+1)/log2(b)));
while any(b.^n <= d)
    n = n + 1;
end
if nargin == 3
    n = max(n,nin);
end
a(n) = rem(d,b);
% any(d) must come first as it short circuits for empties
while any(d) && n >1
    n = n - 1;
    d = floor(d/b);
    a(n) = rem(d,b);
end

a = flip(a);