function fieldHistory=addToFieldHistory(fieldHistory, fieldHistory2, fieldIndex)
if ~isempty(fieldHistory2)
    for n=1:size(fieldHistory2,2)
        %any entries must be added under the correct field
        numObjects=size(fieldHistory(fieldIndex).methodobj,2);%the number of objects that have so far been added to this field.
        fieldHistory(fieldIndex).methodobj(numObjects+1)=fieldHistory2(n).methodobj;
        fieldHistory(fieldIndex).levelobj(numObjects+1)=fieldHistory2(n).levelobj;
    end
end