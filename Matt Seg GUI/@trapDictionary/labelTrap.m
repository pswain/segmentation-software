function labelTrap(cDictionary,trap_num_to_label)
%% 
%Moves through the frames of 
try isempty(cDictionary.cTrap(trap_num_to_label).image)
    if ~isempty(cDictionary.cTrap(trap_num_to_label).image)
        cDictionary.cTrap(trap_num_to_label).class=logical(zeros(size(cDictionary.cTrap(trap_num_to_label).image)));
        for i=1:size(cDictionary.cTrap(trap_num_to_label).image,3)
            figure(1);imshow(cDictionary.cTrap(trap_num_to_label).image(:,:,i),[],'InitialMagnification',300);
            title(['Trap ' int2str(trap_num_to_label) ' Timepoint ' int2str(i)])
            h=imellipse;
            position = wait(h);
            while sum(sum(h.createMask))
                cDictionary.cTrap(trap_num_to_label).class(:,:,i)=h.createMask | cDictionary.cTrap(trap_num_to_label).class(:,:,i);
                temp_im=cDictionary.cTrap(trap_num_to_label).image(:,:,i);
                temp_im(cDictionary.cTrap(trap_num_to_label).class(:,:,i))=temp_im(cDictionary.cTrap(trap_num_to_label).class(:,:,i))*1.5;
                figure(1);imshow(temp_im,[],'InitialMagnification',300);
                title(['Trap ' int2str(trap_num_to_label) ' Timepoint ' int2str(i)])
                h=imellipse;
                position = wait(h);
            end
            
            cDictionary.labelledSoFar(trap_num_to_label,i)=1;
        end
    else
        error('There are no images in that trap label')
    end
    
catch
    error('That exceeds the number of traps in the dictionary')
end