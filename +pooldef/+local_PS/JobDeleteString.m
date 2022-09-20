function cmd = jobDeleteString(ID)
    cmd = sprintf('powershell -Command "$p = Stop-Process -Id %d"',ID);
endfunction
