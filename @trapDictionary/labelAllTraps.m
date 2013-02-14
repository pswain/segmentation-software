function labelAllTraps(cDictionary)

trap_num_to_label=1;
try isempty(cDictionary.cTrap(trap_num_to_label).image)
    if ~isempty(cDictionary.cTrap(trap_num_to_label).image)
        for trap_num_to_label=1:length(cDictionary.cTrap)
            cDictionary.cTrap(trap_num_to_label).class=zeros(size(cDictionary.cTrap(trap_num_to_label).image))>0;
            helpdlg('Select a cell. Double click on ellipse when finished with first cell. When finished with all cells, double click a single point');
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
            
        end
    else
        errordlg('There are no trap images in the dictionary');
    end
    
catch
    errordlg('There are no trap images in the dictionary');
end