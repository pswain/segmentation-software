function [inputObj fieldHistory] = initializeFields(obj, inputObj) 
        % initializeFields --- default function to initialize level object fields for method class
        %
        % Synopsis:  [inputObj fieldHistory] = initializeFields(obj, inputObj) 
        %
        % Input:     obj = object of a method class
        %            inputObj = object of a level class
        %
        % Output:    inputObj = object of a level class

        %Notes - This superclass function is used only if the method class
        %        does not define an initializeFields method. No fields will
        %        be initialized. This method is here so that a method not
        %        found error doesn't arise when a method class with no
        %        initializeFields method is initialized.
        
        
        fieldHistory=struct('objects',{},'fieldnames',{});      
 end