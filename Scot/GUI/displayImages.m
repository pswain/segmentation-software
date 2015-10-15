function handles=displayImages(handles)
    
    
    

    %First deal with the intermediate images
    %Clear the intermediate image axes
    for n=1:size(handles.reqdImageAxes,2)
        cla(handles.reqdImageAxes(n));
        t=get(handles.reqdImageAxes(n),'Title');
        delete(t);
    end
    %Display the intermediate, required images - only possible if the
    %method object is not in the runmethods package.
    handles.currentMethod.Info=metaclass(handles.currentMethod);
    
    if ~strcmp(handles.currentMethod.Info.ContainingPackage.Name,'runmethods')
        reqdImageNames=handles.currentMethod.requiredImages;
        if isempty(reqdImageNames)
            showMessage(handles,'There are no required images for the current method');
        end
        %Add an image to display centres if this is a required field
        if any(strcmp(handles.currentMethod.requiredFields,'Centres')) && isfield(handles.currentObj.RequiredFields,'Centres');
            reqdImageNames{end+1}='Centres';
        end
        if ~isempty(handles.currentObj.RequiredImages)
            n=1;
            while n<=size(handles.reqdImageAxes,2) && n<=size(reqdImageNames,2)
                set(handles.gui,'CurrentAxes',handles.reqdImageAxes(n));
                if isfield(handles.currentObj.RequiredImages,reqdImageNames{n})
                    if ndims(handles.currentObj.RequiredImages.(reqdImageNames{n}))==2
                        imshow(handles.currentObj.RequiredImages.(reqdImageNames{n}),[]);
                    else
                        img=handles.currentObj.RequiredImages.(reqdImageNames{n})(:,:,end);
                        imshow(img,[]);
                    end
                elseif strcmp('Centres',reqdImageNames{n})
                    imshow(handles.currentObj.Target,[]);
                    hold on;
                    plot(handles.currentObj.RequiredFields.Centres(:,1),handles.currentObj.RequiredFields.Centres(:,2),'Marker','x','Line','none');
                end
                title(reqdImageNames{n},'Units','Normalized','Position', [.5 .92],'Color','r');
                n=n+1;
            end
            if size(reqdImageNames,1)>size(handles.reqdImageAxes,2)
                 set(chooseReqdImage,'Visible','On');
                 %also set its string property
            end
        end 
    else
        showMessage('Intermediate images are not displayed when a runmethod is selected');
    end

    %Now show the result of running a method from a package that does not
    %alter currentObj.Result.
    
    if ~strcmp(handles.currentMethod.resultImage, 'Result')
        handles.currentMethod.showDisplayResult(handles.currentObj,handles.intResult);
        k=strfind(handles.currentMethod.resultImage,'.');
        fieldname=handles.currentMethod.resultImage(k+1:end);
%         %Need to work out which level the method is operating at to
%         %determine which result image (and intermediate images) to show.
%         
%         if isfield(handles.currentObj.RequiredImages,fieldname);
%             imageSlices=size(handles.currentObj.RequiredImages.(fieldname),3);%the number of different versions of this result image recorded
%             if imageSlices==1       
%                 methodResult=handles.currentObj.RequiredImages.(fieldname)(:,:,1);
%             else%need to decide which slice to use.            
%                 resultName=handles.workflowResultImageNames(handles.Level);%Name of the result image
%                 levelName=handles.workflowLevels(handles.Level);%Name of the current image level
%                 level=handles.Level;%run forwards from the current level until it moves to a different current object type
%                 foundEnd=false;%variable to check if we've reached a different object type
%                 sameResultImage=false(handles.historySize,1);%will be true if the result image of the tested level is of the same type as the current method
%                 while ~foundEnd
%                     level=level+1;
%                     if strcmp(resultName,handles.workflowResultImageNames(level))
%                        sameResultImage(level)=true;
%                     end
%                     if ~strcmp(levelName,handles.workflowLevels(level))%the object type has changed
%                         foundEnd=true;
%                     end
%                     %Now can count how many of the methods immediately following the
%                     %current method in the history have the same result image
%                     numSameResults=sum(sameResultImage(handles.Level:level));
%                     %The result image to use is now numSameResults back from
%                     %level.
%                     methodResult=handles.currentObj.(handles.currentMethod.resultImage(:,:,end-numSameResults));
%                 end
%             end
%             %Display the result of running this method in panel 1 of the
%             %intermediate images pane
%             set(handles.gui,'CurrentAxes',handles.intResult);imshow(methodResult,[]);
            title(fieldname,'Units','Normalized','Position', [.5 .92],'Color','g','FontSize',12');
        
    else
        %Clear the intermediate result image as it doesn't exist for the
        %current method
        cla(handles.intResult);
        t=get(handles.intResult,'Title');
        delete(t);
    end
    
    %Finally deal with the result image panels
    %Update the target image - or create it if it doesn't yet exist.
    highlighted=handles.rawImages.(handles.rawDisplay)(:,:,:,round(handles.timelapse.CurrentFrame));
    target=highlighted;
    if handles.region(1)+handles.region(3)-1>size(highlighted,2)
       handles.region(3)=size(highlighted,2)-handles.region(1); 
    end
    if handles.region(2)+handles.region(4)-1>size(highlighted,1)
       handles.region(4)=size(highlighted,1)-handles.region(2); 
    end
    handles.region(handles.region<=0)=1;
    if isfield(handles,'region')%handles.region will not exist if no cell has yet been segmented
        highlighted(handles.region(2):handles.region(2)+handles.region(4)-1,handles.region(1):handles.region(1)+handles.region(3)-1,:)=highlighted(handles.region(2):handles.region(2)+handles.region(4)-1,handles.region(1):handles.region(1)+handles.region(3)-1,:).*2;
    end
    if isfield(handles.tpresultaxes,'targetimage')
        if ishandle(handles.tpresultaxes.targetimage)
            set(handles.tpresultaxes.targetimage,'CData',highlighted);
            set(handles.cellresultaxes.targetimage,'CData',target);

        else
            axes(handles.tpresultaxes.target);handles.tpresultaxes.targetimage=imshow(highlighted);
            axes(handles.cellresultaxes.target);handles.cellresultaxes.targetimage=imshow(target);

        end
    else
       axes(handles.tpresultaxes.target);handles.tpresultaxes.targetimage=imshow(highlighted);
       axes(handles.cellresultaxes.target);handles.cellresultaxes.targetimage=imshow(target);
    end
    
    
    %If a timelapse is segmented then also update the merged and binary result
    %images.
    segmented=false;
    if ~isempty(handles.timelapse.DisplayResult)
        if ~isempty(handles.timelapse.DisplayResult(handles.timelapse.CurrentFrame).timepoints)
        if size(handles.timelapse.TrackingData,2)>=handles.timelapse.CurrentFrame
            segmented=true;
            result=full(handles.timelapse.DisplayResult(handles.timelapse.CurrentFrame).timepoints);
        
        if isfield(handles.tpresultaxes,'binaryimage')
            set(handles.tpresultaxes.binaryimage,'CData',result);
            set(handles.cellresultaxes.binaryimage,'CData',result);

        else
            axes(handles.tpresultaxes.binary);handles.tpresultaxes.binaryimage=imshow(result); 
            axes(handles.cellresultaxes.binary);handles.cellresultaxes.binaryimage=imshow(result);

        end
        
        %Make the segmented cells magenta
        magCells=result;
        %Remove the selected cell
        if handles.trackingnumber>0
            if  size(handles.timelapse.Result(handles.timelapse.CurrentFrame).timepoints,2)>=handles.trackingnumber;
                thisCellResult=handles.timelapse.Result(handles.timelapse.CurrentFrame).timepoints(handles.trackingnumber).slices;
                thisCellResult=thisCellResult(1:handles.timelapse.ImageSize(2),1:handles.timelapse.ImageSize(1));
            else
                thisCellResult=false(size(result));
            end
        else
            thisCellResult=false(size(result));
        end        
        magCells(thisCellResult)=false;
        %Add magenta cells to merged image
        mainImage=double(handles.rawImages.(handles.rawDisplay)(:,:,1,handles.timelapse.CurrentFrame));
        mainImage=mainImage./255;
        merged(:,:,1)=mainImage+magCells./3;%3 is a transparency factor - could make that controllable by the user
        merged(:,:,3)=mainImage+magCells./3;%3 is a transparency factor - could make that controllable by the user
        %Make the selected cell green
        if handles.trackingnumber>0            
            merged(:,:,2)=mainImage+thisCellResult./3;%3 is a transparency factor - could make that controllable by the user       
        end
        merged(merged>1)=1;
        if isfield(handles.tpresultaxes,'mergedimage')
            set(handles.tpresultaxes.mergedimage,'CData',merged);           
        else
            axes(handles.tpresultaxes.merged);handles.tpresultaxes.mergedimage=imshow(merged);
        end
        if isfield(handles.cellresultaxes,'mergedimage')
        	set(handles.cellresultaxes.mergedimage,'CData',merged);
        else
            axes(handles.cellresultaxes.merged);handles.cellresultaxes.mergedimage=imshow(merged);
        end

        %Update the region image displays too - set the correct zoom level
        if isfield(handles,'region');           
            set(handles.cellresultaxes.target,'XLim',[handles.region(1) handles.region(1)+handles.region(3)-1],'YLim',[handles.region(2) handles.region(2)+handles.region(4)-1]);
            %handles.cellresultaxes.targetimage=imshow(handles.rawImages.(handles.rawDisplay)(y:y+yl-1,x:x+xl-1,:,handles.timelapse.CurrentFrame),[]);
            set(handles.cellresultaxes.merged,'XLim',[handles.region(1) handles.region(1)+handles.region(3)-1],'YLim',[handles.region(2) handles.region(2)+handles.region(4)-1]);
            %handles.cellresultaxes.mergedimage=imshow(merged(y:y+yl-1,x:x+xl-1,:),[]);
            set(handles.cellresultaxes.binary,'XLim',[handles.region(1) handles.region(1)+handles.region(3)-1],'YLim',[handles.region(2) handles.region(2)+handles.region(4)-1]);
            %handles.cellresultaxes.binaryimage=imshow(result(y:y+yl-1,x:x+xl-1));
        end
        end
        end
        
   if segmented==false
    	set(handles.tpresultaxes.binaryimage,'CData',[]);
        set(handles.tpresultaxes.mergedimage,'CData',[]);
        set(handles.cellresultaxes.binaryimage,'CData',[]);
        set(handles.cellresultaxes.mergedimage,'CData',[]);  
        set(handles.cellresultaxes.targetimage,'CData',[]);  
   end
    
   end
   %Set the select cell by clicking callback for the images in the
   %timepoint result axes
   if isfield(handles.tpresultaxes,'targetimage')
        set(handles.tpresultaxes.targetimage,'ButtonDownFcn',{@clickSelect_callback,handles});
   end
   if isfield(handles.tpresultaxes,'binaryimage')
        set(handles.tpresultaxes.binaryimage,'ButtonDownFcn',{@clickSelect_callback,handles});
   end
    if isfield(handles.tpresultaxes,'mergedimage')
        set(handles.tpresultaxes.mergedimage,'ButtonDownFcn',{@clickSelect_callback,handles});
   end

   drawnow;
end