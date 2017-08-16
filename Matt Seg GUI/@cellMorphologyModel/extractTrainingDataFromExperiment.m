function extractTrainingDataFromExperiment( cCellMorph,cExperiment )
% extractTrainingDataFromExperiment( cCellMorph,cExperiment )
%
% Extract pairs of radii and centres from cExperiment. Assume timepoints
% are organised into pairs (i.e. timpoint 1 and 2 are a consecutive pair,
% timepoint 3 and 4 are a consecutive pair etc.). If a cell is absent at
% one or other timepoint, that row of the array will be all zeros.
%
% To be useful the shape and tracking should have been curated at both
% timepoints of the experiment. currently only extracts for TP 1 and 2.
%
% populates:
% cCellMorph.radii_arrays and cCellMorph.location_arrays

radii_array_tp1 = [];
radii_array_tp2 = [];
centre_array_tp1 = [];
centre_array_tp2 = [];
pos_trap_cell_array = [];
trap_index_array = [];
trap_array = [];
opt_points = cExperiment.ActiveContourParameters.ActiveContour.opt_points;
trap_index = 0;
angles = [];
angles_set = false;

for pos = 1:length(cExperiment.dirs)
   
    cTimelapse = cExperiment.loadCurrentTimelapse(pos);
    
    for tp = 1:2:length(cTimelapse.cTimepoint)
        
        %if the trap pixels have been refined, this function returns them
        temp_trap_array = cTimelapse.returnTrapsPixelsTimepoint(cTimelapse.defaultTrapIndices,tp,...
            cExperiment.cCellVision.cTrap.trapOutline);
        
        for TI = cTimelapse.defaultTrapIndices
                trap_index = trap_index+1;
                cellLabels = union(cTimelapse.cTimepoint(tp).trapInfo(TI).cellLabel,cTimelapse.cTimepoint(tp+1).trapInfo(TI).cellLabel) ;
                
                temp_radii_array_tp1 = zeros(length(cellLabels),opt_points);
                temp_radii_array_tp2 = temp_radii_array_tp1;
                
                temp_centre_array_tp1 = zeros(length(cellLabels),2);
                temp_centre_array_tp2 = temp_centre_array_tp1;
                
                temp_pos_trap_cell_array = zeros(length(cellLabels),3);
                
                temp_trap_index_array = trap_index*ones(length(cellLabels),1);
                
                for CI = 1:length(cellLabels)
                    CL = cellLabels(CI);
                    temp_pos_trap_cell_array(CI,:) = [pos, TI,CL];
                    if ismember(CL,cTimelapse.cTimepoint(tp).trapInfo(TI).cellLabel) || ismember(CL,cTimelapse.cTimepoint(tp+1).trapInfo(TI).cellLabel)
                        
                        if ismember(CL,cTimelapse.cTimepoint(tp).trapInfo(TI).cellLabel)
                            CI_of_cell = cTimelapse.cTimepoint(tp).trapInfo(TI).cellLabel == CL;
                            
                            temp_radii_array_tp1(CI,:) = reshape(cTimelapse.cTimepoint(tp).trapInfo(TI).cell(CI_of_cell).cellRadii,[1,opt_points]);
                            temp_centre_array_tp1(CI,:) = double(cTimelapse.cTimepoint(tp).trapInfo(TI).cell(CI_of_cell).cellCenter);
                            if angles_set
                                % check angles are the same
                                assert(all(angles==cTimelapse.cTimepoint(tp).trapInfo(TI).cell(CI_of_cell).cellAngle));
                            else
                                angles = cTimelapse.cTimepoint(tp).trapInfo(TI).cell(CI_of_cell).cellAngle;
                                angles_set = true;
                            end
                        end
                        
                        if ismember(CL,cTimelapse.cTimepoint(tp+1).trapInfo(TI).cellLabel)
                            CI_of_cell = cTimelapse.cTimepoint(tp+1).trapInfo(TI).cellLabel == CL;
                            
                            temp_radii_array_tp2(CI,:) = reshape(cTimelapse.cTimepoint(tp+1).trapInfo(TI).cell(CI_of_cell).cellRadii,[1,opt_points]);
                            temp_centre_array_tp2(CI,:) = double(cTimelapse.cTimepoint(tp+1).trapInfo(TI).cell(CI_of_cell).cellCenter);
                            if angles_set
                                % check angles are the same
                                assert(all(angles==cTimelapse.cTimepoint(tp+1).trapInfo(TI).cell(CI_of_cell).cellAngle));
                            else
                                angles = cTimelapse.cTimepoint(tp+1).trapInfo(TI).cell(CI_of_cell).cellAngle;
                                angles_set = true;
                            end
                        end
                    end
                end
                
                radii_array_tp1 = cat(1,radii_array_tp1,temp_radii_array_tp1);
                radii_array_tp2 = cat(1,radii_array_tp2,temp_radii_array_tp2);
                
                centre_array_tp1 = cat(1,centre_array_tp1,temp_centre_array_tp1);
                centre_array_tp2 = cat(1,centre_array_tp2,temp_centre_array_tp2);
                
                pos_trap_cell_array = cat(1,pos_trap_cell_array,temp_pos_trap_cell_array);
                trap_index_array = cat(1,trap_index_array,temp_trap_index_array);
                
            
        end
        trap_array = cat(3,trap_array,temp_trap_array);
                
    end
    PrintReportString(pos,10)
    
    
end
fprintf('\n done \n')

cCellMorph.radii_arrays = {radii_array_tp1,radii_array_tp2};
cCellMorph.location_arrays = {centre_array_tp1,centre_array_tp2};
cCellMorph.pos_trap_cell_array = pos_trap_cell_array;
cCellMorph.trap_index_array = trap_index_array;
cCellMorph.trap_array = trap_array;
cCellMorph.angles = angles;

end

