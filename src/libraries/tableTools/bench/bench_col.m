
%% bench 1
xmax = 50;
x = randi(xmax,10^8,1);

ymax = 6;
yall = randperm(xmax);
t1 = zeros(1,ymax);
t2 = zeros(1,ymax);
yset = 1:ymax;
for ly = yset
    y = yall(1:ly);
    t1(ly) = timeit(@()any(x == y,2));
    t2(ly) = timeit(@()isInColumn(x, y));
    fprintf("length %d: standard %f sec, custom %f sec\n", ly, t1(ly), t2(ly))
end

figure
plot(1:ymax, t1, '--bo')
hold on
plot(1:ymax, t2, '--ro')
xticks(yset);
xlabel("y length")
ylabel("time (s)")

%% bench 2
xmax = 50;
ymax = 3;
yall = randperm(xmax);
y = yall(1:ymax);


xset = 3:9;
lxset = length(xset);

t1 = zeros(1,lxset);
t2 = zeros(1,lxset);


for cx = 1:lxset
    lx = xset(cx);
    x = randi(xmax,10^lx,1);
    t1(cx) = timeit(@()any(x == y,2));
    t2(cx) = timeit(@()isInColumn(x, y));
    fprintf("length %d: standard %f sec, custom %f sec\n", lx, t1(cx), t2(cx))
end

figure
plot(xset, log10(t1), '--bo')
hold on
plot(xset, log10(t2), '--ro')
xticks(xset);
xlabel("log x length")
ylabel("log time (s)")
