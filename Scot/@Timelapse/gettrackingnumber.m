function trackingnumber=gettrackingnumber(obj,cellnumber, frame)
    % gettrackingnumber --- returns the trackingnumber corresponding to an input cellnumber at an input frame
    %
    % Synopsis:  trackingnumbers=gettrackingnumber(obj,cellnumber, frame)
    %
    % Input:     obj = an object of a timelapse class
    %            cellnumber = integer, the cellnumber to find trackingnumbers for
    %            frame = integer, the frame at which to find the trackingnumber
    %
    % Output:    trackingnumber = integer, for the input cellnumber at the input frame

    % Notes:    
            
    cellnos=[obj.TrackingData(frame).cells.cellnumber];
    match=cellnos==cellnumber;
    if any (match)
        trackingnumber=find(match);
    else
        trackingnumber=0;
    end
end
