function   [history levelObj]=insertFieldHistory(history, fieldHistory, fieldIndex, levelObj)

%Adds the field history to the history structure
if ~isempty (fieldHistory)
    for n=1:size(fieldHistory.methodobj,2)
        levelObj.Timelapse.HistorySize=levelObj.Timelapse.HistorySize+1;
        history.methodobj(levelObj.Timelapse.HistorySize)=fieldHistory(fieldIndex).methodobj(n);
        history.levelobj(levelObj.Timelapse.HistorySize)=fieldHistory(fieldIndex).levelobj(n);
    end    
end

