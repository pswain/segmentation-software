function editSegmentation (timelapseObj)    
    % editSegmentation ---  Runs a GUI to edit and extract data from an input timelapse segmentation
    %
    % Synopsis:        timelapseObj=editSegmentation (timelapseObj);
    %                  timelapseObj=editSegmentation (timelapseObj, handles);
    %
    % Input:           timelapseObj = an object of a timelapse class, segmented and tracked
    %                  handles = structure, carrying all GUI information

    % Output:          
    
    % Notes:           This function accepts completed timelapse
    %                  segmentations that have been run either from the
    %                  Matlab command line or through the GUI. In the
    %                  latter case the handles structure is input carrying
    %                  GUI information so not all of the GUI controls and
    %                  variables need to be set up from scratch.

    %Create the GUI
    handles=makeGUI(timelapseObj);
    if ~exist('MIJ')==8    
        %Start Fiji (used for some image processing functions)
        %First set up the classpath using the Miji script - need to find the
        %directory in which the fiji application directory is located. It is two
        %levels up from the current one.
        thispath=mfilename('fullpath');
        k=strfind(thispath,'/');
        thispath=thispath(1:k(end-1));
        addpath(thispath);
        %split=strread(thispath,'%s', 'delimiter','/');
        %twofromend=size(char(split(end)),2);
        %thatpath=thispath(1:end-twofromend);
        addpath([thispath 'Fiji.app/scripts']);
        Miji;
    end
    handles.timelapse=timelapseObj;
    handles=beginEdit(handles);
%     %Identify the first segmented cell - the cell with trackingnumber 1 in the
%     %first timepoint at which any cells are segmented.
%     t=1;
%     timelapseObj.CurrentFrame=[];
%     while isempty(timelapseObj.CurrentFrame)
%         if ~isempty(timelapseObj.TrackingData(t).cells)%could catch an error here - will give an index out of bounds if there are no segmented cells
%             timelapseObj.CurrentFrame=t;
%         t=t+1;
%         end
%     end
      