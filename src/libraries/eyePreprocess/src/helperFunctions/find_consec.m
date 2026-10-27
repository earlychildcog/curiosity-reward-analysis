function [consec, index] = find_consec(A,x)
% function that finds consecutive values in an array
% A: array of numbers
% x: number to find. Default 1
arguments
    A
    x = 1
end

if size(A,2) == 1 && size(A,1) > 1      %requires row vector
    A = A';                             %flips if column vector
end

start1 = strfind([0,A == x],[0 1]);
end1 = strfind([A == x,0],[1 0]);
consec = end1 - start1 + 1;
index = start1;
if isempty(consec)
    consec = 0;
    index = [];
end
end