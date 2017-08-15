classdef cellMorphologyModel <handle
    % CELLMOTIONMODEL a class to train and organise cell motion models and
    % shape models. Basically a collection of the scripts used to train the
    % shape models used in the paper.
    
    properties
        radii_arrays = {} % {tp1_array, tp2_array}
                          % arrays of timepoint radii at successive timepoints.
                          % Each row is single cell, with corresponding
                          % radii in each of the other timepoints. Id the
                          % cell is absent, all radii are zero.
        location_arrays = {} % as radii array but each row is the [x,y] 
                             % location of the cell at consecutive time
                             % points.
        
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
    
end

