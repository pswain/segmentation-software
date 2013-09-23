function obj=addToPostHistory(obj, methodObj)
    % addToPostHistory --- inserts a tracking, extractdata or edit method into the record of methods used on a timelapse
    %
    % Synopsis:  obj=addToPostHistory(obj, methodObj)
    %                        
    % Input:     obj = an object of a Timelapse class
    %            methodObj = an object of a method class
    %
    % Output:    obj = an object of a Timelapse class
    %            
    % Notes:     The posthistory records methods that have been run on a
    %            timelapse data set after it has been segmented. These
    %            include tracking, data extraction and manual editing
    %            methods. This function is called when one of these methods
    %            is run and ensures that the new method is added to make a
    %            meaningful post history. Both the methods inserted and the
    %            order in which they appear are managed. For example edit
    %            methods that delete cells manually are only added once -
    %            the record of deleted cells remains in the trackingdata
    %            and result fields so it is not necessary to duplicate it.
    %            A meaningful order must be maintained - with tracking,
    %            editing and then data extraction.

    methodObj.Info=metaclass(methodObj);
    package=methodObj.Info.ContainingPackage.Name;
    sizePostHistory=size(obj.PostHistory.objnumbers,2);
    switch package
        case 'edittimelapse'
            %Do not add if there are any objects of the same type already
            %present
            editMethods=strcmp(obj.PostHistory.packages,'edittimelapse');
            editMethods=find(editMethods);
            if isempty(editMethods)
                %This is the first edit method used. Insert into post
                %history after the trackmethod           
                trackMethod=strcmp(obj.PostHistory.packages,'trackmethods');
                trackMethod=find(trackMethod);
                if ~isempty(trackMethod)
                    obj.PostHistory.objnumbers=[obj.PostHistory.objnumbers methodObj.ObjectNumber];
                    obj.PostHistory.packages{sizePostHistory+1}='edittimelapse';   
                else%There is no recorded track method - editing is occuring before tracking
                    %In this case add the method to the end of the Post
                    %History
                    obj.PostHistory.objnumbers(sizePostHistory+1)=methodObj.ObjectNumber;
                    obj.PostHistory.packages{sizePostHistory+1}='edittimelapse';
                end               
            else%There is at least one edit method already present
                %Insert at the end of the last edit method already there
                lastEdit=editMethods(end);
                if lastEdit<sizePostHistory
                    obj.PostHistory.objnumbers=[obj.PostHistory.objnumbers(1:lastEdit) methodObj.ObjectNumber obj.PostHistory.objnumbers(lastEdit+1:end)];
                    obj.PostHistory.packages=[obj.PostHistory.packages{1:lastEdit}, {'edittimelapse'} obj.PostHistory.packages{lastEdit+1:end}];
                else
                    obj.PostHistory.objnumbers(sizePostHistory+1)=methodObj.ObjectNumber;
                    obj.PostHistory.packages{sizePostHistory+1}='edittimelapse';
                end
            end
        case 'extractdata'
            %Replace any object that has the same dataname - otherwise add
            if any(strcmp(methodObj.datafield, fields(obj.Data)))
                %A method generating the same data field name has been run
                %already - replace this method in the post history
                extractMethods=strcmp(obj.PostHistory.packages,'extractdata');
                extractMethods=find(extractMethods);
                for n=1:size(extractMethods,2)
                    thisMethod=obj.methodFromNumber(obj.PostHistory.objnumbers(extractMethods(n)));
                    if strcmp(methodObj.datafield,thisMethod.datafield)
                        obj.PostHistory(extractMethods(n)).objnumbers=methodObj.ObjectNumber;
                    end
                end                
            else
                %No method exists with the same data field name as the
                %input method. Add the input method to the end of the post
                %history
                obj.PostHistory.objnumbers(size(obj.PostHistory.objnumbers,2)+1)=methodObj.ObjectNumber;
                obj.PostHistory.packages{size(obj.PostHistory.objnumbers,2)}='extractdata';                
            end
        case 'trackmethods'
            %Replace the existing trackmethods entry - always the first
            %item in the posthistory
            if ~isempty(obj.PostHistory)
                trackMethod=strcmp(obj.PostHistory.packages,'trackmethods');
                if any(trackMethod)
                    obj.PostHistory.objnumbers(trackMethod)=methodObj.ObjectNumber;
                else
                    obj.PostHistory(1).objnumbers=methodObj.ObjectNumber;
                    obj.PostHistory(1).packages={'trackmethods'};
                end
            else
                    obj.PostHistory(1).objnumbers=methodObj.ObjectNumber;
                    obj.PostHistory(1).packages={'trackmethods'};
            end
    end
end