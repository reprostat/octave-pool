function cmd = jobDeleteString(ID)
    cmd = sprintf('kill -9 %d',ID);
end
