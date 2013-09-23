function paramCheck=checkParams(obj, timelapseObj) 
        % checkParams --- default function to confirm parameters of method classes are OK
        %
        % Synopsis:  paramCheck=checkParams(obj)
        %
        % Input:     obj = object of a method class
        %
        % Output:    paramCheck = cell array of strings, either {'OK'}, {'Not checked'} or a list of names of incorrect paramters      

        %Notes - This superclass function is used only if the method class
        %        does not define a checkParams method. This will only
        %        return {'OK'} if the class has no parameters. Otherwise it
        %        will return {'Not checked'} because this method does not
        %        know what the parameter types and value ranges are
        %        supposed to be. Subclasses that define parameters should
        %        have their own paramCheck methods that override this one
        %        and check each parameter value, returning a cell array of
        %        parameter names that are not OK. In future can optionally
        %        define a structure in the method class - eg called
        %        obj.parameterRange that would detail the data type
        %        and allowed values for each parameter. Could then make use
        %        of that to check all values in this superclass method.
        if size(fields(obj.parameters),1)==0
            paramCheck={'OK'};
        else
            paramCheck={'Not checked'};
        end       
 end