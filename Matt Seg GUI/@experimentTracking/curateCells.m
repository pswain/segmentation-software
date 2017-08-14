function curateCells(cExperiment,poses,figure_position,do_pairs)
% cExperiment.curateCells(poses,figure_position,do_pairs);
% 
% curate all the traps in the selected positions trap by trap and timepoint
% by timepoint using the curateCellTrackingGUI. Close each one in turn to
% move on to the next.
% 
% poses             -   position to curate.
% figure_position   -   position to which to set the figure for the
%                       curation GUI. Can be useful if you want to make the
%                       GUI bigger and don't want to keep setting it by
%                       hand. Just used to set figure.Position.
% do_pairs          -   default false. If true, it will show them in
%                       consecutive pairs. Useful for shape model training.
%
% result will only be saved between positions. If that's a problem it may
% be better to use EXPERIMENTCOMPAREOBJECT, which allows curation with a
% record of which timepoints/traps have been curated.

if nargin<2 || isempty(poses)
    poses = 1:length(cExperiment.dirs);
end

if nargin<3 || isempty(figure_position);
    set_figure_pos = false;
else
    set_figure_pos = true;
end

if nargin<3 || isempty(do_pairs)
    do_pairs = false;
end

curate_channel = 1;

for posi = poses
    fprintf('Starting position %d : %s\n',posi,cExperiment.dirs{posi});
    cTimelapse = cExperiment.loadCurrentTimelapse(posi);
    cTimelapse.ACParams = cExperiment.ActiveContourParameters;
    if do_pairs
        TPs = 1:2:length(cTimelapse.cTimepoint);
    else
        TPs = 1:length(cTimelapse.cTimepoint);
    end
    Traps = cTimelapse.defaultTrapIndices;
    for i = 1:numel(TPs)
        
        TP = TPs(i);
        for TI = Traps
            if do_pairs
                gui = curateCellTrackingGUI(cTimelapse,cCellVision,TP,TI,2,curate_channel);
                gui.slider.Value = TP;
                gui.slider.Min = TP;
                gui.slider.Max = TP+1;
            else
                gui = curateCellTrackingGUI(cTimelapse,cCellVision,TP,TI,1,curate_channel);
                gui.slider.Value = TP;
                gui.slider.Min = TP;
                gui.slider.Max = TP;
            end
            if set_figure_pos
                gui.figure.Position = figure_position;
            end
            uiwait();
            curate_channel = gui.Channels(1);
        end
    end
    cExperiment.saveTimelapseExperiment;
end



end

