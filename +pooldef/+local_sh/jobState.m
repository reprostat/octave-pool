function status = jobState(ID)
    [s, w] = system(sprintf('ps -q %d -o state --no-header',ID));
    switch numel(w)
        case 0
            status = 'finished';
        otherwise
            status = 'running';
    end
end
