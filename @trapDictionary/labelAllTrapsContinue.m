function labelAllTrapsContinue(cDictionary)
%% 
% This function continues through the dictionary looking for frames of
% traps that haven't yet been ground truth labelled. It starts off at the
% first image of the first trap that hasn't been labelled, and then
% progresses through the timelapse sequentially.
close
trap_num_to_label=1;
try isempty(cDictionary.cTrap(trap_num_to_label).image)
    if ~isempty(cDictionary.cTrap(trap_num_to_label).image)
        for trap_num_to_label=1:length(cDictionary.cTrap)
            try min(cDictionary.labelledSoFar(trap_num_to_label,:))
                if ~min(cDictionary.labelledSoFar(trap_num_to_label,:)) | size(cDictionary.labelledSoFar,1)<size(cDictionary.cTrap(trap_num_to_label).image,3)
                    if ~isfield(cDictionary.cTrap(trap_num_to_label),'class')
                        cDictionary.cTrap(trap_num_to_label).class=zeros(size(cDictionary.cTrap(trap_num_to_label).image))>0;
                    end
                    helpdlg('Select a cell. Double click on ellipse when finished with first cell. When finished with all cells, double click a single point');
                    for i=1:size(cDictionary.cTrap(trap_num_to_label).image,3)
                        try cDictionary.labelledSoFar(trap_num_to_label,i)
                            if ~cDictionary.labelledSoFar(trap_num_to_label,i)
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
                        catch
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
                end
            catch
                if ~isfield(cDictionary.cTrap(trap_num_to_label),'class')
                    cDictionary.cTrap(trap_num_to_label).class=zeros(size(cDictionary.cTrap(trap_num_to_label).image))>0;
                end
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
        end
    else
        errordlg('Err 1:There are no trap images in the dictionary');
    end
catch
    errordlg('Err 2: There are no trap images in the dictionary');
end