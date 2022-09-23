function status = jobState(ID)
    [s, w] = system(sprintf('powershell -Command "$p = Get-Process -Id %d; $p.Responding"',ID));
    switch w(1:4)
        case 'True'
            status = 'running';
        case 'False'
            status = 'error';
        otherwise
            status = 'finished';
    end
end
