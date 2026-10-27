function z = parbench()
    xmax = 50;
    n = 7;
    x = randi(xmax,10^n,1);
    ly = 10;
    kmax = 100;
    A = zeros(1, kmax);
    parfor k = 1:kmax
        yall = randperm(xmax);
        y = yall(1:ly);
        A(k) = mean(isInColumn(x, y));
    end
    z = mean(A, [1 2]);
end