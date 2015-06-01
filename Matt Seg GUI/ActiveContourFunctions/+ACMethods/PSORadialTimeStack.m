function [radii_res,angles] = PSORadialTimeStack(forcing_images,ACparameters,Centers_stack,prior,radii_previous_time_point,exclude_logical_stack)
%function [radii_res,angles,ResultsX,ResultsY] = PSORadialTimeStack(forcing_images,ACparameters,Centers_stack,prior,radii_previous_time_point,exclude_logical_stack)

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

%this is done to try and stop average pixels contributing to outline so that no average of pixel
%values need be taken.
forcing_images = forcing_images - median(forcing_images(:));
Timepoints = size(forcing_images,3);%number of time points being considered

%parameters set by user

alpha = ACparameters.alpha;%0.01%weighs non image parts (none at the moment)
betaElco =ACparameters.beta;%0.01 %weighs difference between consecutive time points.
R_min = ACparameters.R_min;%1;
R_max = ACparameters.R_max;%15; %was initial radius of starting contour. Now it is the maximum size of the cell (must be larger than 5)
MaximumRadiusChange = ACparameters.MaximumRadiusChange;
opt_points = ACparameters.opt_points;%8;
visualise = ACparameters.visualise;%3; %degree of visualisation (0,1,2,3)
EVALS = ACparameters.EVALS;%6000; %maximum number of iterations passed to fmincon
spread_factor = ACparameters.spread_factor;% 1; %used in particle swarm optimisation. determines spread of initial particles.
spread_factor_prior = ACparameters.spread_factor_prior;% 0.5; %used in particle swarm optimisation. determines spread of initial particles.
seeds = ACparameters.seeds;%100;

%parameters internal to the program

method = 'PSO'; %'PSO','fmincon'
debug = false;%if set to one the final radii found will be stored in the debug folder of the cell_serpent folder.
res_points = 49;%number of the snake points passed to the results matrix (needs to match 'snake_size'field of OOFdataobtainer object
%for storing results
epochs_to_terminate = ACparameters.TerminationEpoch;%500;


sub_image_size = (size(forcing_images,1)-1)/2; %subimage is a size 2*sub_image_size +1 square.

if nargin<4 || isempty(prior)
    prior_provided = false;
else
    prior_provided = true;
    prior = reshape(prior',1,[]);
    D2radii_prior = [];
    for TP = 1:Timepoints
        [D2radii_prior_part] = ACBackGroundFunctions.second_derivative_snake((prior(((TP-1)*opt_points)+(1:opt_points)))');
        D2radii_prior = [D2radii_prior D2radii_prior_part'];
    end
    
end

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


if visualise>=1
    fig_handle = figure;
    %imshow(show_image,[])
    %fig_handle2 = figure;
    
end


radii_init_score_all = [];
D2radii_all = [];

siy = size(forcing_images,2);
six = size(forcing_images,1);

if use_previous_timepoint
    
    LB = kron(ones(Timepoints,1),radii_previous_time_point') - kron((1:Timepoints)',MaximumRadiusChange*ones(opt_points,1));
    LB(LB<R_min) = R_min;
    
    UB = kron(ones(Timepoints,1),radii_previous_time_point') + kron((1:Timepoints)',MaximumRadiusChange*ones(opt_points,1));
    UB(UB>R_max) = R_max;
    
else
    %set lower bounds to be centre -  starting contour radius s_R
    LB = R_min*ones(opt_points*Timepoints,1);
    %set lower bounds to be centre +  starting contour radius s_R
    UB = R_max*ones(size(LB));

end


for iP=1:Timepoints
    %fprintf('cell %d \n',iP)
    if use_exclude_stack
        [radii_init_score,angles,RminTP,RmaxTP] = ACBackGroundFunctions.initialise_snake_radial(forcing_images(:,:,iP),opt_points,Centers_stack(iP,1),Centers_stack(iP,2),R_min,R_max,exclude_logical_stack(:,:,iP));
        LB((iP-1)*opt_points + (1:opt_points)) = RminTP(:);
        UB((iP-1)*opt_points + (1:opt_points)) = RmaxTP(:);
    else
        [radii_init_score,angles] = ACBackGroundFunctions.initialise_snake_radial(forcing_images(:,:,iP),opt_points,Centers_stack(iP,1),Centers_stack(iP,2),R_min,R_max);
        
    end
    radii_init_score_all = [radii_init_score_all radii_init_score'];
    [D2radii] = ACBackGroundFunctions.second_derivative_snake(radii_init_score);
    D2radii_all = [D2radii_all D2radii'];

   

 if visualise>=1
    figure(fig_handle);
    subplot(1,Timepoints,iP);
    if use_exclude_stack
        imshow(OverlapGreyRed(forcing_images(:,:,iP),exclude_logical_stack(:,:,iP),[],[],true),[])
    else
        imshow(forcing_images(:,:,iP),[])
    end
    [px,py] = ACBackGroundFunctions.get_points_from_radii(radii_init_score,angles,Centers_stack(iP,:),res_points,(sub_image_size*[2 2]+1));
    hold on
    plot(px,py,'b');
    title(['timepoint ' num2str(iP)])
    
    if use_previous_timepoint && iP==1
        
        [px,py] = ACBackGroundFunctions.get_points_from_radii(radii_previous_time_point',angles,Centers_stack(iP,:),res_points,(sub_image_size*[2 2]+1));
        plot(px,py,'g');
    
    
        
    end
    drawnow
end


    
end


%     %initialise the snake




%% using particle optimisation tool box

%parameters for particle swarm optimisation

%get second derivative of radii

% %parameter values used (see help pso_Trelea_vectorized for more details
%on these

%defaults parameter values
%Pdef = [100 2000 24 2 2 0.9 0.4 1500 1e-25 250 NaN 0 0];

if prior_provided %prior given
    
    
    %seeds are evenly distributed cicles between Rmin and Rmax.
    radii_init_all = linspace(0,1,floor(seeds/3));
    PSOseed1 = (repmat(radii_init_all',1,opt_points*Timepoints).*repmat((UB-LB)',floor(seeds/3),1)) + repmat(LB',floor(seeds/3),1);
    
    %seed values are a distribution around the usual starting function
    %given by 'initialise_snake_radial'
    PSOseed2 = repmat(radii_init_score_all,floor(seeds/3),1);
    PSOseed2 = PSOseed2-spread_factor*randn(size(PSOseed2)).*repmat(D2radii_all,size(PSOseed2,1),1);
    if size(PSOseed2,1)>0
        PSOseed2(1,:) = radii_init_score_all;
    end
    %seed values are a distribution around the prior given (if given)
    PSOseed3 = repmat(prior,seeds-2*floor(seeds/3),1);
    PSOseed3 = PSOseed3-spread_factor_prior*randn(size(PSOseed3)).*repmat(D2radii_prior,size(PSOseed3,1),1);
    
    if size(PSOseed3,1)>0
        PSOseed3(1,:) = prior;
    end
    
    PSOseed = [PSOseed1;PSOseed2;PSOseed3];
    
else
    
    %seeds are evenly distributed cicles between Rmin and Rmax.
    radii_init_all = linspace(0,1,floor(seeds/2));
    PSOseed1 = (repmat(radii_init_all',1,opt_points*Timepoints).*repmat((UB-LB)',floor(seeds/2),1)) + repmat(LB',floor(seeds/2),1);
    
    %seed values are a distribution around the usual starting function
    %given by 'initialise_snake_radial'
    PSOseed2 = repmat(radii_init_score_all,ceil(seeds/2)-1,1);
    PSOseed2 = PSOseed2+spread_factor*randn(size(PSOseed2)).*repmat(D2radii_all,ceil(seeds/2)-1,1);
    PSOseed2 = [radii_init_score_all;PSOseed2];
    
    
    PSOseed = [PSOseed1;PSOseed2];
    
    
end

SuperLB = repmat(LB',seeds,1);
I =PSOseed<SuperLB;
PSOseed(I) = SuperLB(I);

SuperUB = repmat(UB',seeds,1);
I =PSOseed>SuperUB;
PSOseed(I) = SuperUB(I);

%%particle swarm optimisation

%group of functions taken out of splinefit to speed up optimisation.
[A,n,breaks,dim,jj,C] = ACBackGroundFunctions.splinefit_prep([angles; 2*pi],ones([seeds (opt_points+1)]),[angles; 2*pi],'p');

switch method
    %%Using particle swarm
    case 'PSO'
        
        P = [0 EVALS seeds 4 0.5 0.4 0.4 1500 1e-25 epochs_to_terminate NaN 3 1];
        
        %not sure multiplying by the interquartile range is sensible. 
        radial_punishing_factor = alpha*iqr(forcing_images(:))*ones(opt_points,1);
        time_change_punishing_factor = betaElco*iqr(forcing_images(:));

        %PSO(functname,D(dimension of problem),mv(defaut 4),VarRange(defaut [-100 100]),minmax,PSOparams,plotfcn,PSOseedValue(a particle number x D (dimension) matrix))
        %(im_stack,center_stack,angles,radii_stack_mat,Rmin,Rmax,alpha,image_size,A,n,breaks,jj,C)
        if use_previous_timepoint
            
            [optOUT] = ACBackGroundFunctions.pso_Trelea_vectorized_mod(@(radii_stack)ACMethods.CFRadialTimeStack(forcing_images,Centers_stack,angles,cat(2,repmat(radii_previous_time_point,size(radii_stack,1),1),radii_stack),radial_punishing_factor,time_change_punishing_factor,[siy six],use_previous_timepoint,A,n,breaks,jj,C),opt_points*Timepoints,4,[LB UB],0,P,'',PSOseed);
        
        else
            
            [optOUT] = ACBackGroundFunctions.pso_Trelea_vectorized_mod(@(radii_stack)ACMethods.CFRadialTimeStack(forcing_images,Centers_stack,angles,radii_stack,radial_punishing_factor,time_change_punishing_factor,[siy six],use_previous_timepoint,A,n,breaks,jj,C),opt_points*Timepoints,4,[LB UB],0,P,'',PSOseed);
        
        end
        radii_stack = optOUT(1:(end-1));
        ResultsF = optOUT(end);

%%%%%%%%%%%%%%%%%%%% NOT WELL MAINTAINED  -   CHECK DIFFERENCE WITH PSO CASE BEFORE UNCOMMENTING AND USING   %%%%%%%%%%%%%%%%%        
%     case 'fmincon' 
%      %% using fmincon
%         
%         options = optimset('Algorithm','interior-point','MaxFunEvals',10*EVALS,'MaxIter',10*EVALS,'Display','off','TolFun',10e-7);
%         
%         %fmincon part
%         ResultsF = Inf;
%         for trials =1:seeds
%         [radii_stack_temp,F] = fmincon(@(radii_stack)ACMethods.CFRadialTimeStack(forcing_images,Centers_stack,angles,radii_stack,alpha,betaElco,[siy six],A,n,breaks,jj,C),PSOseed(trials,:),[],[],[],[],LB(1,:),UB(1,:),[],options);
%         
%         if F<ResultsF
%             radii_stack = radii_stack_temp';
%             ResultsF = F;
%         end
%         
%         end
%    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end


%% non optimisation specific
radii_res = [];

for iP = 1:Timepoints
    radii = radii_stack((((iP-1)*opt_points)+1):iP*opt_points);
    radii_res = cat(1,radii_res,radii');
    
    if visualise>=1
        [px,py] = ACBackGroundFunctions.get_points_from_radii(radii,angles,Centers_stack(iP,:),res_points,([2 2]*sub_image_size)+1);
        %make px py a looped list of the form expected by the rest of the
        %program
        px2 = [px(end);px];
        py2 = [py(end);py];
        figure(fig_handle);
        hold on
        if Timepoints>1 %for some reason subplot seems to crap out with hold if there is only one timepoint
        subplot(1,Timepoints,iP);
        end
        hold on
        
        plot(px2,py2,'r');
        drawnow
        hold off
            %      figure(fig_handle2);
    end
      
end

if visualise>=3
    if false
        pause
    else
        pause(0.3)
        [pxFULL,pyFULL] = ACBackGroundFunctions.get_full_points_from_radii(radii_res(1,:)',angles,Centers_stack(1,:),([2 2]*sub_image_size)+1);
        LogicalPoints = false(([2 2]*sub_image_size)+1);
        LogicalPoints(pyFULL + (pxFULL-1)*(2*sub_image_size + 1)) = true;
        %OutlineImage = ACBackGroundFunctions.make_outline(forcing_images(:,:,1),LogicalPoints);
        OutlineImage = OverlapGreyRed(forcing_images(:,:,1),LogicalPoints,false,[],true);
        figure_handle_2 = figure;
        imshow(OutlineImage,[]);
        pause
        close(figure_handle_2)
    end
elseif visualise>=1
    pause(0.1)
end


if visualise>=1
    
    close(fig_handle);
   
end


angles = repmat(angles',Timepoints,1);

end





