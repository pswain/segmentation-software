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
opt_points = cExperiment.ActiveContourParameters.ActiveContour.opt_points;

for pos = 1:length(cExperiment.dirs)
   
    cTimelapse = cExperiment.loadCurrentTimelapse(pos);
    
    for tp = 1:2:length(cTimelapse.cTimepoint)
        
        for TI = cTimelapse.defaultTrapIndices
               
                cellLabels = union(cTimelapse.cTimepoint(tp).trapInfo(TI).cellLabel,cTimelapse.cTimepoint(tp+1).trapInfo(TI).cellLabel) ;
                
                temp_radii_array_tp1 = zeros(length(cellLabels),opt_points);
                temp_radii_array_tp2 = temp_radii_array_tp1;
                
                temp_centre_array_tp1 = zeros(length(cellLabels),2);
                temp_centre_array_tp2 = temp_centre_array_tp1;
                
                for CI = 1:length(cellLabels)
                    CL = cellLabels(CI);
                    if ismember(CL,cTimelapse.cTimepoint(tp).trapInfo(TI).cellLabel) || ismember(CL,cTimelapse.cTimepoint(tp+1).trapInfo(TI).cellLabel)
                        
                        if ismember(CL,cTimelapse.cTimepoint(tp).trapInfo(TI).cellLabel)
                            CI_of_cell = cTimelapse.cTimepoint(tp).trapInfo(TI).cellLabel == CL;
                            
                            temp_radii_array_tp1(CI,:) = reshape(cTimelapse.cTimepoint(tp).trapInfo(TI).cell(CI_of_cell).cellRadii,[1,opt_points]);
                            temp_centre_array_tp1(CI,:) = double(cTimelapse.cTimepoint(tp).trapInfo(TI).cell(CI_of_cell).cellCenter);
                        end
                        
                        if ismember(CL,cTimelapse.cTimepoint(tp+1).trapInfo(TI).cellLabel)
                            CI_of_cell = cTimelapse.cTimepoint(tp+1).trapInfo(TI).cellLabel == CL;
                            
                            temp_radii_array_tp2(CI,:) = reshape(cTimelapse.cTimepoint(tp+1).trapInfo(TI).cell(CI_of_cell).cellRadii,[1,opt_points]);
                            temp_centre_array_tp2(CI,:) = double(cTimelapse.cTimepoint(tp+1).trapInfo(TI).cell(CI_of_cell).cellCenter);
                        end
                    end
                end
                
                radii_array_tp1 = cat(1,radii_array_tp1,temp_radii_array_tp1);
                radii_array_tp2 = cat(1,radii_array_tp2,temp_radii_array_tp2);
                centre_array_tp1 = cat(1,centre_array_tp1,temp_centre_array_tp1);
                centre_array_tp2 = cat(1,centre_array_tp2,temp_centre_array_tp2);
                
            
        end
    end
    PrintReportString(pos,10)
    
    
end
fprintf('\n done \n')

cCellMorph.radii_arrays = {radii_array_tp1,radii_array_tp2};
cCellMorph.location_arrays = {centre_array_tp1,centre_array_tp2};

end

