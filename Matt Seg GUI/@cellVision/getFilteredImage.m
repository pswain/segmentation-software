function  filtered_image=getFilteredImage(cCellSVM,image)
%function  filtered_image=getFilteredImage(cCellSVM,image)  image is a
%stack of images and cCellSVM is a cellVision model.


if strcmp(class(cCellSVM.filterFunction),'function_handle')
    
    filtered_image=cCellSVM.filterFunction(cCellSVM,image);
    
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