t = zeros(1,8);
for cc = 1:6

    p = parpool(cc);
    
    t(cc) = timeit(@parbench);
    fprintf("%d cores in %f\n", cc, t(cc))
    try
    !ioreg -rw0 -c AppleSmartBattery | grep BatteryData | grep -o '"AdapterPower"=[0-9]*' | cut -c 16- | xargs -I %  lldb --batch -o "    print/f %" | grep -o '$0 = [0-9.]*' | cut -c 6-
    catch
    end
    p.delete;
end


plot(1:8, t,'-o')
xlabel("#cores")
ylabel("time (s)")



