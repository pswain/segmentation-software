function handles=plotSegmented(handles)
    % plotSegmented --- plots timelapse data on the axis handles.plot
    %
    % Synopsis:  handles=plotSegmented (handles)
    %
    % Input:     handles = structure carrying all the information used by the GUI
    %
    % Output:    handles = structure carrying all the information used by the GUI

    % Notes:     Plots timelapse segmentation data. The data comes from the
    %            handles.timelapse.Data structure, which can have several
    %            data sets within it. Before calling this function the 
    %            data set to be plotted should be calculated and also
    %            defined in the field handles.currentDataField as a string
    %            representing the field name.
    

    if ~isempty(handles.timelapse.Data)
        showMessage(handles, ['Plotting ' handles.currentDataField]);
        axes(handles.plot);
        cla;
        data=handles.timelapse.Data.(handles.currentDataField);
        data(data==0)=nan;
        set(handles.plot,'Visible','on');
        %Identify the plot type
        if ~isfield(handles,'plottype')
            handles.plottype='Scatter';
        end
        switch handles.plottype
            case 'Scatter'
                %Add axis labels to the parameters structure of each extractdata
                %method (or as properties of the extractdata object) - then display
                %them here.
                hold on;  
                interval=handles.timelapse.Interval;%Make this more sophisticated - to allow plotting of data with skipped timepoints
                x=0:interval:interval*(size(data,2)-1);
                cc=hsv(size(data,1));

                for c=1:size(data,1)
                   handles.cellhandles(c)=plot(x,data(c,:),'color',cc(c,:),'tag',num2str(c),'Marker','.','ButtonDownFcn',{@plotclick_callback});
                   if c==handles.cellnumber
                      %highlight the currently-selected cell and point
                      set(handles.cellhandles(c),'Marker','x', 'MarkerSize',10, 'LineWidth', 3);
                      thisx=x(handles.timelapse.CurrentFrame);
                      thisy=data(c,handles.timelapse.CurrentFrame);
                      handles.currentPoint=plot(thisx,thisy, 'Marker','o', 'MarkerSize', 15,'LineWidth',4,'color',[0 0 0]);
                   end
                end
                titleString=[handles.timelapse.Name '  ' handles.currentDataField];
                title(titleString,'Units','Normalized','Position', [.5 .9 .5]);
                dataFields=fields(handles.timelapse.Data);
                if size(dataFields,1)>1
                    set(handles.selectGraph, 'Visible','On','String',dataFields);
                end
                showMessage('');
            case 'Histogram'
                %The handles.timelapse.Data entry for the current plot is
                %1d. Similar to the code above - use line to plot vertical
                %lines of a bar graph.
                hold on;                 
                [data cellnumbers]=sort(data);
                %data(isnan(data))=[];
                cc=hsv(length(data));
                handles.cellhandles=zeros(length(data));
                for c=1:length(data)%Loop through the data points
                   if ~isnan(data(c))
                       x=[c c];
                       y=[0 data(c)];
                       handles.cellhandles(cellnumbers(c))=plot(x,y,'color',cc(cellnumbers(c),:),'tag',num2str(cellnumbers(c)),'Marker','none','LineWidth',10,'ButtonDownFcn',{@plotclick_callback});
                       if cellnumbers(c)==handles.cellnumber
                          %highlight the currently-selected cell and point
                          thisx=x;
                          thisy=data(c);
                          handles.currentPoint=plot(thisx,thisy, 'Marker','o', 'MarkerSize', 15,'LineWidth',4,'color',[0 0 0]);
                       end
                   end
                end
                titleString=[handles.timelapse.Name '  ' handles.currentDataField];
                title(titleString,'Units','Normalized','Position', [.5 .9 .5]);
                dataFields=fields(handles.timelapse.Data);
                if size(dataFields,1)>1
                    set(handles.selectGraph, 'Visible','On','String',dataFields);
                end
                showMessage('');
                
        end
        
        
    end
end