function [radii_res,angles,opt_score] = PSORadialTimeStack(forcing_images,ACparameters,Centers_stack,prior,radii_previous_time_point,exclude_logical_stack,region_image)
%function [radii_res,angles,score] = PSORadialTimeStack(forcing_images,ACparameters,Centers_stack,prior,radii_previous_time_point,exclude_logical_stack,region_image)

% Segment_elco_fmc_radial ---
%
% Synopsis:        [radii_res,ResultsX,ResultsY] = PSORadialTimeStack(forcing_images,ACparameters,Centers_stack,prior,radii_previous_time_point,exclude_logical_stack)

% Input:           
% forcing_images - stack of forcing images of a single cell at consecutive
%                  timepoints, with the center of the cell at the center of the image.
%ACparameters    - Structure of parameters set of parameters that can be set by the user:
%     alpha                 default =0.01  weighs non image parts (none at the moment)
%     beta                  default = 0.01 weighs difference between consecutive time points.
%     R_min                 default = 1 smallest allowed radius of cell
%     R_max                 default =  15 largest allowed radius of cell
%     opt_points            default = 8  number of radii used to create cell contour
%     visualise             default = 0 degree of visualisation (0,1,2,3)
%     EVALS                 default = 6000; %maximum number of iterations passed to fmincon
%     spread_factor         default = 1 used in particle swarm optimisation. determines spread of initial particles.
%     spread_factor_prior   default =  0.5 used in particle swarm optimisation. determines spread of initial particles.
%     seeds                 default = 100 number of seeds used for Particle Swarm Optimisation
%     TerminationEpoch      default = 500 number of epochs to run for sure before terminating
%     MaximumRadiusChange   default = 2  maximum change in radius allowed
%                           between each consecutive timepoint
% Centers_stack  - [x y] matix of centers of cell at each image in stack

%
% optional
%
% prior                        - priors of radii for the timepoints to be segmented
% radii_previous_time_point    - fixed contour (in terms of radii) for the time point prior
%                                to the stack given
% exclude_logical_stack        - A stack of logical images corresponding to the image stack of
%                                pixels which should not be inside the cell (eg pillars and other
%                                cells). Currently crudely used to set Rmin and Rmax for each radii.


% Output:
% radii_res      - Results as radial coordinates determining the contour.
%                  given as a Timepoints by opt_opints matrix.
% angles         - angles at which the results in radii_res are given. 
%                  given as a Timepoints by opt_opints matrix.


% Notes:


forcing_images = double(forcing_images);
if nargin<7 || isempty(region_image)
    region_image = zeros(size(forcing_images)); 
else
    region_image = double(region_image);
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
EVALS = ACparameters.EVALS;%6000; %maximum number of iterations passed to fmincon
spread_factor = ACparameters.spread_factor;% 1; %used in particle swarm optimisation. determines spread of initial particles.
spread_factor_prior = ACparameters.spread_factor_prior;% 0.5; %used in particle swarm optimisation. determines spread of initial particles.
seeds = ACparameters.seeds;%100; number used to initialise
seeds_for_PSO = ACparameters.seeds_for_PSO;%best set actually used for PSO.
%parameters internal to the program

res_points = 49;%number of the snake points passed to the results matrix (needs to match 'snake_size'field of OOFdataobtainer object
%for storing results


sub_image_size = (size(forcing_images,1)-1)/2; %subimage is a size 2*sub_image_size +1 square.



if nargin<5 || isempty(radii_previous_time_point)
    use_previous_timepoint = false;
else
    use_previous_timepoint = true;
end

if nargin<6 || isempty(exclude_logical_stack)
    use_exclude_stack = false;
else
    use_exclude_stack = true;
end


if visualise
    fig_handle = figure;

end



siy = size(forcing_images,2);
six = size(forcing_images,1);


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
    [RminTP,RmaxTP] = ACBackGroundFunctions.set_bounds_from_exclude_image(exclude_logical_stack,Centers_stack(1),Centers_stack(2),angles,LB,UB);   
end
LB(RminTP>LB) = RminTP(RminTP>LB);
UB(RmaxTP<UB) = RmaxTP(RmaxTP<UB);



if visualise
    % show forcing image, previous time point and exclude logical.
    figure(fig_handle);
    if use_exclude_stack
        imshow(OverlapGreyRed(forcing_images,exclude_logical_stack,[],[],true),[])
    else
        imshow(forcing_images,[])
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

if use_previous_timepoint
    % if the previous timepoint is used, the prrevious_timepoint_radii is
    % appended to the radii array being costed to allow calcualtion of the
    % time change punishing factor.
    function_to_optimise = @(radii_stack)ACMethods.CFRadialTimeStack(forcing_images,angles,cat(2,repmat(radii_previous_time_point,size(radii_stack,1),1),radii_stack),radial_punishing_factor,time_change_punishing_factor,inflation_weight,use_previous_timepoint,A,n,breaks,jj,C,region_image,radii_mat,angles_mat);
else
    function_to_optimise = @(radii_stack)ACMethods.CFRadialTimeStack(forcing_images,angles,radii_stack,radial_punishing_factor,time_change_punishing_factor,inflation_weight,use_previous_timepoint,A,n,breaks,jj,C,region_image,radii_mat,angles_mat);
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
    [bests(i,:),scores(i)] = ACMethods.spline_grad_search(function_to_optimise,[LB UB],grad_seeds(i,:));
end
[opt_score,i] = min(scores);
radii_res = bests(i,:);


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
end
      

if visualise
    
    close(fig_handle);
   
end


angles = angles';

end





