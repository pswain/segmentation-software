function highest = gethighest(obj)
% gethighest --- %function to retrieve the largest cell number occuring in the data set.
%
% Synopsis:  [obj highest] = gethighest(obj)
%
% Input:     obj = an object of a timelapse class
%                       
% Output:    highest == scalar, the highest cellnumber in the timelapse

% Notes:     

CellNumbers = zeros(1,5*obj.TimePoints*size(obj.TrackingData(1).cells,2));%1 by n array of cell numbers. 
                                                                      %Intialised in this way to try and avoid growth in loop
x = 1; %track number of elements of CellNumbers already filled
for i = 1:size(obj.TrackingData,2)%loop through the timepoints
    if ~isempty(obj.TrackingData(i).cells)
        x = x+size(obj.TrackingData(i).cells,2);    
        if x>=length(CellNumbers)%avoids CellNumber growing in loop if initial size estimate was too small
            CellNumbers = [CellNumbers zeros(size(CellNumbers))];
        end
        CellNumbers(x+1-size(obj.TrackingData(i).cells,2):x)=[obj.TrackingData(i).cells.cellnumber];
     end
end

highest = max(CellNumbers,[],2);


end