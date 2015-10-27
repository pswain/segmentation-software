function  filtered_image = getFilteredImage(cCellSVM,image,trapOutine)
%  filtered_image = getFilteredImage(cCellSVM,image,trapOutine)
%
% cCellSVM      :   an object of the cellVision class.
% image         :   a stack of images and cCellSVM is a cellVision model.
% trapOutline   :   a grey scale image of the 'trapiness' of pixels. 1 or 
%                   greater is considered to be definitely a trap pixel.
%                   Defauts to an all zeros image.



if nargin<3 || isempty(trapOutine)
    trapOutline = zeros(size(image));
end

if isa(cCellSVM.filterFunction,'function_handle')
    if nargin(cCellSVM.filterFunction)>2
        filtered_image=cCellSVM.filterFunction(cCellSVM,image,trapOutline);
    else
        filtered_image=cCellSVM.filterFunction(cCellSVM,image);
    end
    
elseif ischar(cCellSVM.filterFunction)
    
    if isempty(cCellSVM.cTrap)
        
        filtered_image=cCellSVM.createImFilterSetCellAsic(image);
        
    else
        
        if strcmp(cCellSVM.filterFunction,'full')
            filtered_image=cCellSVM.createImFilterSetCellTrap(image);
        else
            filtered_image=cCellSVM.createImFilterSetCellTrap_Reduced(image);
        end
        
    end
    
end

end