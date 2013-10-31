function showProgress(percent, message)
    % showProgress ---  Displays a progress bar with the input length
    %
    % Synopsis:        showProgress(fraction, message)
    %
    % Input:           percent = number between 0 and 100, required progress value to show
    %                  message = string to display

    % Output:          
    
    % Notes: May be called from within any loop. The current figure must 
    %        have a structure variable in its guidata with a field called
    %        progressBar with a field progressBarJ - representing a java
    %        component of type javax.swing.JProgressBar then this component
    %        is used to display the progress. If no suitable figure is
    %        found then this function does nothing (except slow down the
    %        code, especially if several figures are open).
    
    %Loop through any open figures to find the one with the progressbar
    %control.
%     figHandles = get(0,'Children');
%     found=false;
%     if size(figHandles,1)>0
%     n=1;
%         while ~found
%             figure(figHandles(n));
%             handles=guidata(gcf);
%             if ~isempty(handles)
%                 if isfield(handles,'progressBarJ')
%                     handles.progressBarJ.setValue(percent);
%                     if nargin>1
%                         handles.progressBarJ.setString(message);
%                     end
%                     found=true;
%                 end
%             end
%             n=n+1;
%         end
%     end
end