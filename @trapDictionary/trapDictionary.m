classdef trapDictionary<handle
    
    properties
        cTrap
        labelledSoFar
    end
    
    methods
        
        function cDictionary=trapDictionary()
            %% Read filenames from folder
%             cDictionary.cTrap=struct('image',[],'class',[]);
            labelledSoFar=[];
        end
            
        %functions for adding data to the dictionary. Must already be
        %processed using the 
        addTrap(cDictionary,cTimelapse,trap_num_to_add);
        addAllTraps(cDictionary,cTimelapse);
        
        %add the traps and use the secondary image to auto segment it
        addAllTrapsLabelSecondary(cDictionary,cTimelapse,channels,param,radius);
        addTrapLabelSecondary(cDictionary,cTimelapse,trap_num_to_add)
        
        %display images and make the user label them
        labelTrap(cDictionary,trap_num_to_label);
        labelAllTraps(cDictionary);
        labelAllTrapsContinue(cDictionary);
        
        %saving/loading functions
        loadDictionary(cDictionary)
        saveDictionary(cDictionary)
        saveDictionaryVision(cDictionary,cCellVision)

    end
    
end

