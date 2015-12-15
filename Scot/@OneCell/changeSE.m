function obj=changeSE(obj,shape,size)
    % changeSE --- sets a new structuring element and recalculates segmentation
    %
    % Synopsis:  obj = changeSE (obj)
    %                        
    % Input:     obj= an object of a OneCell class
    %
    % Output:    obj= an object of a OneCell class

    % Notes:     For use during editing of segmentation to see the effect
    %            of changing the structuring element used in imopen
    %            commands
            obj.SESize=size;
            obj.SE=strel(shape,size);
            obj=obj.calculateResult;
end