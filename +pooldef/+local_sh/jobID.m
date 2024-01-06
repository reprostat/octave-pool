function ID = jobID(parentID)
[s, w] = system(sprintf("pgrep -P %d",parentID));

if s, ID = NaN;
else, ID = str2double(w);
end
end
