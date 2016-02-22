classdef experimentLogging<handle
    %experimentLogging Class to track progress of segmentation
    %   Use this class to update a log file and progress bars when
    %   iterating through time-consuming procedures
    
    properties
        progress_bar
        cExperiment

        file_handle = []
        file_name = 'cExperiment_log.txt'
        file_dir
        
        start_time = [] % Also used to identify if a protocol is running
        protocol_name = 'creating experiment'; % default first protocol name
        protocol_args = ''
        position = [] % Index of current position, empty if not initialised
        npos = [] % Total number of positions to iterate over
        timepoint = [] % Index of current timepoint, empty if not initialised
        ntimes = [] % Total number of time points to iterate over
        
        window_closed = false
        cancel = false
    end
    
    properties (Transient)
        % Handles to all of the listeners are stored here
        listenPositionChanged
        listenTimepointChanged
        listenExptLogMsg
        listenPosLogMsg
    end
    
    methods
        function this = experimentLogging(cExperiment)
            %Constructor Construct an experimentLogging object
            %   Pass in an experimentTracking object to intialise
            
            % Save a handle to the cExperiment, since it will be used to
            % update the log file name and find the loaded timeLapse:
            this.cExperiment = cExperiment;
            
            % Also start listening for events on the cExperiment:
            this.listenPositionChanged = ...
                addlistener(cExperiment,'PositionChanged',@this.update_pos);
            this.listenExptLogMsg = ...
                addlistener(cExperiment,'LogMsg',@this.log_message);
            
            % Initialise the progress bar class
            this.progress_bar = Progress('0;'); % Dummy callback to create 'finalise' button
            this.progress_bar.finalise_button.setLabel('Cancel...');
            button_handle = handle(this.progress_bar.finalise_button,'callbackproperties');
            set(button_handle, 'MouseClickedCallback', {@this.cancel_protocol});
        
            % Centre the dialog box
            this.progress_bar.frame.setLocationRelativeTo([]);

            % Initialise the log file properties
            this.file_dir = cExperiment.saveFolder;
        end
        
        function add_arg(this,name,value)
            value = this.flatten_struct('',value);
            this.protocol_args = [this.protocol_args,name,': ',value,'\n'];
        end
        
        function start_protocol(this,name,npos)
            % Call this function before a protocol starts that requires
            % logging. Optionally supply the number of positions that will
            % be iterated over.
            if ~isempty(this.start_time)
                % Another protocol may have terminated prematurely, so
                % force a reset:
                this.reset;
            end
            if nargin<3
                this.npos = length(this.cExperiment.dirs);
            else
                this.npos = npos;
            end
            this.start_time = datetime('now');
            this.protocol_name = name;
            this.progress_bar.frame.setTitle(name);
            % The following should automatically open the log file if it
            % isn't already open:
            if isempty(this.protocol_args)
                this.append(['\n\n=====================\n',...
                    datestr(now),'\tStart ',name,'...\n']);            
            else
                this.append(['\n\n=====================\n',...
                    datestr(now),'\tStart ',name,' using parameters:\n',...
                    this.protocol_args]);
            end
        end
        
        function timestring = time_taken(this)
            % Return a string reporting the time since the protocol was
            % started
            if ~isempty(this.start_time)
                runtime = diff([this.start_time;datetime('now')]);
                if runtime<minutes(1)
                    timestring = sprintf('%0.0f secs',seconds(runtime));
                elseif runtime<hours(1)
                    timestring = sprintf('%0.1f mins',minutes(runtime));
                else
                    timestring = sprintf('%0.1f hours',hours(runtime));
                end
            else
                timestring = '0 secs';
            end
        end
        
        function complete_protocol(this)
            % Call this function after a protocol that has been logging has
            % now finished. Can be safely called even if protocol was never
            % started.
            if ~isempty(this.start_time)
                this.append([datestr(now),'\tSuccessfully completed ',...
                    this.protocol_name,' in ',this.time_taken,...
                    '.\n---------------------\n']);
            end
            this.reset;
        end
        
        function protocol_error(this)
            % Call this function whenever an error has been thrown
            % mid-protocol. Logging terminates with an error message and 
            % the state is reset.
            if this.cancel
                if ~isempty(this.start_time)
                    this.append([datestr(now),'\t',...
                        this.protocol_name,' was cancelled by user after ',...
                        this.time_taken,'.\n---------------------\n']);
                end
            else
                if ~isempty(this.start_time)
                    this.append([datestr(now),'\t',...
                        this.protocol_name,' terminated with an error after ',...
                        this.time_taken,'.\n---------------------\n']);
                end
                
                e = errordlg(['Oh no! There was an error when ',this.protocol_name,'.']);
                uiwait(e);
            end
            
            this.reset;
        end            
        
        function reset(this)
            % Reset the state of the logger
            
            % Pop bars off the progress bar until it is closed
            while this.progress_bar.bar_count > 0
                this.progress_bar.pop_bar;
            end
            % Note that the above automatically removes the ticker when the
            % bar count reaches 0.
             
            % Just in case the user closed the window manually in
            % the previous run:
            assignin('base', ['prog_terminate',...
                num2str(this.progress_bar.window_number)], false);
            this.window_closed = false;
            
            % Reset the cancel flag in case it got set
            this.cancel = false;

            % Close the log file for now
            this.close_logfile;
            
            this.position = [];
            this.npos = [];
            this.timepoint = [];
            this.ntimes = [];
            this.protocol_args = '';
            
            % Reset start_time last in case there are any errors with the above
            this.start_time = [];
        end            
        
        function cancel_protocol(this,~,~)
            this.cancel = true;
        end
        
        function update_progress(this,val)
            % Write a wrapper function to update the progress bar and
            % handle the case when the progress window has been closed.
            % Unlike the default behaviour of the Progress class, here we
            % just want window closure to be silent. 

            % Only call the following if the window has not been closed
            % already:
            if ~this.window_closed
                %Let the swing thread assign the terminate flag if necessary
                drawnow;
                %Check for terminate flag
                if (evalin('base', ['prog_terminate' num2str(this.progress_bar.window_number)]))
                    % The listener and ticker are guaranteed to be cleaned 
                    % up by this.reset before the next protocol is run.
                    this.window_closed = true;
                else
                    this.progress_bar.set_val(val);
                end
            end
        end
        
        function update_pos(this,~,posUpdateEvent)
            % Callback function for the PositionChanged event

            % Add this experimentLogging instance to the cTimelapse:
            posUpdateEvent.cTimelapse.logger = this;
            
            % Start listening for events on the timelapseTraps object:
            this.listenPosLogMsg = ...
                addlistener(posUpdateEvent.cTimelapse,'LogMsg',@this.log_message);
            this.listenTimepointChanged = ...
                addlistener(posUpdateEvent.cTimelapse,'TimepointChanged',@this.update_timepoint);
            
            % Only do anything else if a protocol is running
            if ~isempty(this.start_time)
                
                % Update the number of timepoints that we might expect to
                % process:
                this.ntimes = length(posUpdateEvent.cTimelapse.timepointsToProcess);
                
                % Update progress bar:
                if isempty(this.position)
                    this.position = 1;
                    this.progress_bar.push_bar('Position',1,this.npos);
                else
                    if this.position > 0 && this.position < this.npos
                        % If a timepoint was set, then we should now pop 
                        % that bar off the stack:
                        if ~isempty(this.timepoint) && ...
                                this.progress_bar.bar_count > 1
                            this.progress_bar.pop_bar;
                            fprintf('\n'); % New line for command window dot tracking
                            this.timepoint = []; % Reset the timepoint tracker
                        end
                        this.position = this.position+1;
                        
                        this.update_progress(this.position);

                    else
                        % If the number of positions supplied to
                        % start_protocol was correct, then this should
                        % never be called, but to future proof:
                        
                        % Looping of the positions should have finished, so
                        % pop the necessary progress bars:
                        if ~isempty(this.timepoint) && ...
                                this.progress_bar.bar_count > 1
                            this.progress_bar.pop_bar;
                            fprintf('\n'); % New line for command window dot tracking
                            this.timepoint = []; % Reset the timepoint tracker
                        end

                        this.progress_bar.pop_bar;
                    end
                end
                
                % Append a message to the log file
                this.append(sprintf('%s\tProcessing position %i (%s)\n',...
                    datestr(now),posUpdateEvent.index,posUpdateEvent.label));
            end
        end
        
        function update_timepoint(this,~,~)
            % Callback function for the TimepointChanged event

            % Only do anything if a protocol is running
            if ~isempty(this.start_time)
                
                % Update progress bar:
                if isempty(this.timepoint)
                    this.timepoint = 1;
                    this.progress_bar.push_bar('Time point',1,this.ntimes);
                    fprintf('.');
                else
                    if this.timepoint > 0 && this.timepoint < this.ntimes
                        this.timepoint = this.timepoint+1;
                        this.update_progress(this.timepoint);
                        fprintf('.');
                        % Break line every 60 timepoints
                        if mod(this.timepoint,60)==0
                            fprintf('\n');
                        end
                    else
                        % If this.ntimes was correct, then this should never
                        % be called, but just in case...
                        this.progress_bar.pop_bar;
                        this.timepoint = [];
                    end
                end
                
                % Do not log time points to the log file.
            end
        end
        
        function log_message(this,~,msgEvent)
            % Callback function for the LogMsg event. Just add the message
            % to the log file/command window.
            this.append([datestr(now),'\t',msgEvent.message,'\n']);
        end
        
        function append(this,msg)
            % Ensure that the file is open for appending
            this.open_logfile;
            fprintf(this.file_handle,msg);
            fprintf(msg); % Also output to command window for backward compatibility
        end
        
        function open_logfile(this)
            if isempty(this.file_handle)
                % Update file_dir in case it has changed:
                this.file_dir = this.cExperiment.saveFolder;
                % Open the file
                this.file_handle = ...
                    fopen([this.file_dir,filesep,this.file_name],'at');
            elseif ~strcmp(this.file_dir,this.cExperiment.saveFolder)
                % Close the old file handle
                this.close_logfile;
                % Update file_dir since it has changed (and also ensure
                % that we never enter an infinite loop...)
                this.file_dir = this.cExperiment.saveFolder;
                % Try opening the log file again
                this.open_logfile;
            else
                % Otherwise do nothing, file should already be open
                return
            end
        end
        
        function close_logfile(this)
            if ~isempty(this.file_handle)
                fclose(this.file_handle);
            end
            this.file_handle = [];
        end
        
        function delete(this)
            if ~isempty(this.progress_bar)
                this.progress_bar.frame.dispose;
            end
            if ~isempty(this.file_handle)
                fclose(this.file_handle);
            end
        end
        
        function obj = saveobj(~)
            % The contents of this class should not be saved
            warning('The experimentLogging class should not be saved since it cannot be reloaded properly. Please only instantiate using the constructor.');
            obj = {};
        end
    end
    
    methods (Static)
        function changePos(cExperiment,posIndex,cTimelapse)
            % First check (if we can) whether we should cancel this protocol
            if isa(cExperiment.logger,'experimentLogging')
                if cExperiment.logger.cancel
                    error('protocol cancelled by user');
                end
            end
            notify(cExperiment,'PositionChanged',...
                loggingEvents.PosUpdate(posIndex,cExperiment.dirs{posIndex},cTimelapse));
        end
        
        function changeTimepoint(cTimelapse,timepoint)
            % First check (if we can) whether we should cancel this protocol
            if isa(cTimelapse.logger,'experimentLogging')
                if cTimelapse.logger.cancel
                    error('protocol cancelled by user');
                end
            end
            notify(cTimelapse,'TimepointChanged',loggingEvents.TimepointUpdate(timepoint));
        end
        
        function textout = flatten_struct(textin,value,depth)
            % Recursive function that converts almost any basic type to a
            % formatted string:
            
            if nargin<3
                depth = 0;
            end
            
            if ischar(value)
                textout = [textin,value];
                return
            end
            
            if isnumeric(value)
                textout = [textin,num2str(value)];
                return
            end
            
            if iscell(value)
                textout = textin; % just in case the cell has zero length
                if length(value)>0
                    textout = experimentLogging.flatten_struct(textout,value{1},depth);
                end
                
                if length(value)>1
                    for i=2:length(value)
                        textout = experimentLogging.flatten_struct(...
                            [textout,', '],value{i},depth);
                    end
                end
                return
            end

            if isstruct(value)
                 % Initialise textout in case there are no fields:
                textout = [textin,'{\n'];
                vnames = fieldnames(value);
                for i=1:length(vnames)
                    textout = [experimentLogging.flatten_struct(...
                        [textout,repmat(' ',1,2*(depth+1)),vnames{i},': '],...
                        value.(vnames{i}),depth+1),'\n'];
                end
                textout = [textout,repmat(' ',1,2*depth),'}'];
                return
            end
            
            if isa(value,'function_handle')
                textout = [textin,func2str(value)];
                return
            end
            
            if islogical(value)
                if length(value)==1
                    if value
                        textout = [textin,'yes'];
                    else
                        textout = [textin,'no'];
                    end
                else
                    textout = [textin,num2str(value)];
                end
                return
            end
            
            % Default operation:
            textout = [textin,'<object of class "',class(value),'">'];
        end
        
        function this = loadobj(obj)
            % This object cannot be loaded. Throw a warning.
            warning('The experimentLogging class cannot be loaded. Please instantiate using the constructor instead.');
            this = obj;
        end
    end
    
end