function fieldHistory=redefineFieldHistory(obj, fieldHistories)
        fieldHistory=struct('objects', {}, 'fields',{});
        numObjs=0;
        %Loop through the required fields.
        for n=1:size(obj.requiredFields,1)
            reqField=obj.requiredFields(n);%the name of the field required by the successful method
            if size(fieldHistories.methods,1)>0
            for h=1:size(fieldHistories.methods,1)
                for f=1:size(fieldHistories(h).methods.requiredFields)
                    if strcmp(reqField, fieldHistories(h).methods.requiredFields(f))==1
                        numObjs=numObjs+1;
                        fieldHistory(n).objects(numObjs)=fieldHistories(h).methods;
                        fieldHistory(n).fields(numObjs)=fieldHistories(h).methods.requiredFields(f);
                    end
                end
            end
            end
        end
    
end