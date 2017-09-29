function [radii_res,angles,opt_score] = PSORadialTimeStack(forcing_image,ACparameters,radii_previous_time_point,exclude_logical,region_image,cCellMorph)
% [radii_res,angles,score] = PSORadialTimeStack(forcing_image,ACparameters,radii_previous_time_point,exclude_logical,region_image,cCellMorph)
%
% function to optimise the cost function:
%       ACBackgroundFunctions.CFRadialTimeStack 
%
% for a cell at a single timepoint, either with or without a radii from the
% prevoous timepoint.
% optimises the cost function using the powell like line optimisation
% routine
%       ACMethods.spline_grad_search
%
% Input: 
% forcing_image         - forcing images of a single cell with the center
%                         of the cell at the center of the image. Should be
%                         low where edges are likely to be.
%ACparameters           - Structure of parameters set of parameters that can be set by the user:
%                         (see documentation for details)
%
% optional
%
% radii_previous_time_point    - fixed contour (in terms of radii) for the
%                                time point before the current one.
% exclude_logical          - A logical image corresponding to the pixels
%                            which should not be inside the cell (eg
%                            pillars and other cells). Currently crudely
%                            used to set Rmin and Rmax for each radii.
% region_image - like forcing image, an image but one which should be
%                low for interior pixel. It contributes an integral term to
%                the cost function. If all zeros, is ignored.
%
% Output:
% radii_res      - Results as radial coordinates determining the contour.
%                  
% angles         - angles at which the results in radii_res are given. 
%                  



if nargin<3 || isempty(radii_previous_time_point)
    use_previous_timepoint = false;
else
    use_previous_timepoint = true;
end

if nargin<4 || isempty(exclude_logical)
    use_exclude_stack = false;
else
    use_exclude_stack = true;
end

forcing_image = double(forcing_image);
if nargin<5 || isempty(region_image)
    region_image = zeros(size(forcing_image)); 
else
    region_image = double(region_image);
end

if nargin<6 || isempty(cCellMorph)
    error('cell morphology model must be provided');
end

%parameters set by user
radial_punishing_factor = ACparameters.alpha;%0.01%weighs non image parts (none at the moment)
time_change_punishing_factor =ACparameters.beta;%0.01 %weighs difference between consecutive time points.
inflation_weight = ACparameters.inflation_weight;
R_min = ACparameters.R_min;%1; Minimum size of the cell.
R_max = ACparameters.R_max;%15; Maximum size of the cell 
MaximumRadiusChange = ACparameters.MaximumRadiusChange;
opt_points = ACparameters.opt_points;% number of knots used in the spline
visualise = ACparameters.visualise;% false. Wheher to show intermediary results etc.
%parameters internal to the program

sub_image_size = (size(forcing_image,1)-1)/2; %subimage is a size 2*sub_image_size +1 square.

% some functions require the centre of the centre of the cell to be
% specified. In this function, it is always the centre of the image.
Centers_stack = round([1,1]*(sub_image_size)+1);

if visualise
    fig_handle = figure;

end



siy = size(forcing_image,2);
six = size(forcing_image,1);


% if MaximumRadiusChange is <Inf, set lower/pper bounds so that radius can
% only change by the amout allowed.
if use_previous_timepoint
    
    LB =radii_previous_time_point' - MaximumRadiusChange*ones(opt_points,1);
    LB(LB<R_min) = R_min;
    
    UB = radii_previous_time_point' + MaximumRadiusChange*ones(opt_points,1);
    UB(UB>R_max) = R_max;
    
else
    LB = R_min*ones(opt_points,1);
    UB = R_max*ones(size(LB));
end

RminTP = LB;
RmaxTP = UB;

angles = linspace(0,2*pi,opt_points+1)';
angles = angles(1:opt_points,1);

% use the exclude logical to change the upper and lower bound to not
% include the excluded pixels.
if use_exclude_stack
    [RminTP,RmaxTP] = ACBackGroundFunctions.set_bounds_from_exclude_image(exclude_logical,Centers_stack(1),Centers_stack(2),angles,LB,UB);   
end
LB(RminTP>LB) = RminTP(RminTP>LB);
UB(RmaxTP<UB) = RmaxTP(RmaxTP<UB);



if visualise
    res_points = 49;% snake points used for visualisation plots.
    % show forcing image, previous time point and exclude logical.
    figure(fig_handle);
    if use_exclude_stack
        imshow(OverlapGreyRed(forcing_image,exclude_logical,[],[],true),[])
    else
        imshow(forcing_image,[])
    end
    
    if use_previous_timepoint
        hold on
        [px,py] = ACBackGroundFunctions.get_points_from_radii(radii_previous_time_point',angles,Centers_stack(1,:),res_points,(sub_image_size*[2 2]+1));
        plot(px,py,'g');
        title('previous timepoint outline and exclude logical');
    end
    drawnow
end

%group of functions taken out of splinefit to speed up optimisation.
[A,n,breaks,dim,jj,C] = ACBackGroundFunctions.splinefit_prep([angles; 2*pi],ones([1 (opt_points+1)]),[angles; 2*pi],'p');

% additional terms that must be precalculated for cost function calculation.
[radii_mat,angles_mat] = ACBackGroundFunctions.radius_and_angle_matrix([six,siy]);

% terms from the cellMorphology model.
cell_morph_terms = {inv(cCellMorph.cov_new_cell_model),cCellMorph.mean_new_cell_model,...
    cCellMorph.thresh_tracked_cell_model,inv(cCellMorph.cov_tracked_cell_model_small),...
    cCellMorph.mean_tracked_cell_model_small,inv(cCellMorph.cov_tracked_cell_model_large),cCellMorph.mean_tracked_cell_model_large};

if use_previous_timepoint
    % if the previous timepoint is used, the prrevious_timepoint_radii is
    % appended to the radii array being costed to allow calcualtion of the
    % time change punishing factor.
    function_to_optimise = @(radii_stack)ACMethods.CFRadialTimeStack(...
        forcing_image,angles,cat(2,repmat(radii_previous_time_point,size(radii_stack,1),1),radii_stack),...
        radial_punishing_factor,time_change_punishing_factor,inflation_weight,use_previous_timepoint,A,...
        n,breaks,jj,C,region_image,radii_mat,angles_mat,cell_morph_terms{:});
else
    function_to_optimise = @(radii_stack)ACMethods.CFRadialTimeStack(...
        forcing_image,angles,radii_stack,...
        radial_punishing_factor,time_change_punishing_factor,inflation_weight,use_previous_timepoint,A...
        ,n,breaks,jj,C,region_image,radii_mat,angles_mat,cell_morph_terms{:});
end


% POWELL LIKE LINE OPTIMISATION
if use_previous_timepoint
    % optimise once from old outline and once from smallest cell
    grad_seeds = [LB';radii_previous_time_point];
else
    % for new cells, just optimise from lower bound.
    grad_seeds = LB';
end

num_seeds = size(grad_seeds,1);
bests = zeros(size(grad_seeds));
scores = zeros(num_seeds,1);

for i = 1:num_seeds
    [bests(i,:),scores(i)] = ACMethods.spline_grad_search(function_to_optimise,[LB UB],grad_seeds(i,:),ACparameters.optimisation_parameters);
end
[opt_score,i] = min(scores);
radii_res = bests(i,:);
angles = angles';


if visualise
    % draw final outline.
    [px,py] = ACBackGroundFunctions.get_points_from_radii(radii_res',angles,Centers_stack,res_points,([2 2]*sub_image_size)+1);
    px2 = [px(end);px];
    py2 = [py(end);py];
    figure(fig_handle);
    hold on
    hold on
    
    plot(px2,py2,'r');
    drawnow
    hold off
    close(fig_handle);
end

end





