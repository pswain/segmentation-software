classdef cellMorphologyModel <handle
    % CELLMOTIONMODEL a class to train and organise cell motion models and
    % shape models. Basically a collection of the scripts used to train the
    % shape models used in the paper.
    
    properties
        angles = [] % angles at which the radii are set (should be the same for all cells)
        radii_arrays = {} % {tp1_array, tp2_array}
                          % arrays of timepoint radii at successive timepoints.
                          % Each row is single cell, with corresponding
                          % radii in each of the other timepoints. Id the
                          % cell is absent, all radii are zero.
        location_arrays = {} % as radii array but each row is the [x,y] 
                             % location of the cell at consecutive time
                             % points.
        pos_trap_cell_array =[] % When data is extracted from an 
                                % experimentTracking object, this is the
                                % [position trap cellLabel] of each cell
                                % extracted
        trap_array = [] % when data is extracted from an experimentTracking 
                        % object this is an image stack of the trap pixels
                        % (doubles - 1 certain, 0 certainly not) for each
                        % of the traps from which cells were extracted.
        trap_index_array = [] % array indicating from which trap in trap_array
                              % each cell was extracted.
        mean_new_cell_model = []; % mean of the gaussian used to mode cell 
                                  % model. Fitted to training data.
        cov_new_cell_model = []; % covariance of the gaussian used to model
                                 % new cell shapes. Fitted to training data.
        thresh_tracked_cell_model = []; % threshold mean radius that distinguishes large 
                                        % and small cells in the tracked
                                        % cell model.
        mean_tracked_cell_model_small = []; % mean of the log gaussian used 
                                            % to model small tracked cell shapes. 
                                            % Fitted to training data.
        cov_tracked_cell_model_small = []; % covariance of the log gaussian used to model
                                           % small tracked cell shapes.
                                           % Fitted to training data.
        mean_tracked_cell_model_large = []; % mean of the log gaussian used 
                                            % to model large tracked cell shapes. 
                                            % Fitted to training data.
        cov_tracked_cell_model_large = []; % covariance of the log gaussian used to model
                                           % large tracked cell shapes.
                                           % Fitted to training data.
        motion_model = [] % motion model fitted to training data. astruct to be 
                          % passed to ACMotionPriorObject.FlowInTrapTrained.
                          % had the fields:
                          % flowLookUpTable
                          % sizeLookUpTable
                          % radius_bins
         
        

    end
    
    methods
        
        function cCellMorph = cellMorphologyModel(do_nothing)
            % cCellMorph = cellMorphologyModel(do_nothing)
            % if do_nothing is true, will create a bare cCellMorph (used in
            % loading).
            if nargin<1
                do_nothing = false;
            end
            if ~do_nothing
            end
            
        end
        
        function clearTrainingData(cCellMorph)
            % clearTrainingData(cCellMorph)
            % clears all training data.
            cCellMorph.radii_arrays = {};
            cCellMorph.location_arrays = {};
            cCellMorph.pos_trap_cell_array = [];
            cCellMorph.trap_array = [];
            cCellMorph.trap_index_array = [];
        end
        
        function saveCellMorphologyModel(cCellMorph,location)
            % saveCellMorphologyModel(cCellMorph,location)
            % to save a cellMorphologyModel, by GUI if necessary.
            % save as a variable called cCellMorph (the norm in our code).
            
            if nargin<2 || isempty(location)
                [file,path] = uiputfile('','Please select a location to save the cellMorphologyModel','cCellMorph.mat');
                location = fullfile(path,file);
            end
            save(location,'cCellMorph');
        end
        
        function cCellMorph = loadobj(LoadStructure)
            % load method
            % allows checks for back compatibility and what not when you
            % add new features or want to change their default value.
            %% default loading method: DO NOT CHANGE
            cCellMorph = cellMorphologyModel(true);
            
            FieldNames = fieldnames(LoadStructure);
            %only populate mutable fields occcuring in both the load object
            %and the cCellMorph object.
            FieldNames = intersect(FieldNames,fieldnames(cCellMorph));
            
            for i = 1:numel(FieldNames)
                
                m = findprop(cCellMorph,FieldNames{i});
                if ~strcmp(m.SetAccess,'immutable')
                    cCellMorph.(FieldNames{i}) = LoadStructure.(FieldNames{i});
                end
                
            end
            
            %% back compatibility checks and what not
            %when a new field is added this load operation should be
            %updated to populate the field appropriately and maintain back
            %compatibility.
            

        end 
    end
    
    methods(Static)
        
    function blank_cell_morph = makeInocuousCellMorphModel(opt_points,average_radius)
    % function blank_cell_morph = makeInocuousCellMorphModel(opt_points,average_radius)
    % makes a cellMorphology model that imposes almost nothing about shape.
    % For use in training a new cellMorphologyModel with a different number
    % of opt_points.
    blank_cell_morph = cellMorphologyModel;
    blank_cell_morph.mean_new_cell_model = ones(1,opt_points)*average_radius;
    blank_cell_morph.cov_new_cell_model = diag(blank_cell_morph.mean_new_cell_model.^2);
    blank_cell_morph.thresh_tracked_cell_model = average_radius;
    blank_cell_morph.mean_tracked_cell_model_small = ones(1,opt_points);
    blank_cell_morph.cov_tracked_cell_model_small = diag(blank_cell_morph.mean_tracked_cell_model_small);
    blank_cell_morph.mean_tracked_cell_model_large = blank_cell_morph.mean_tracked_cell_model_small;
    blank_cell_morph.cov_tracked_cell_model_large = blank_cell_morph.cov_tracked_cell_model_small;
    end
        
    end
    
end

