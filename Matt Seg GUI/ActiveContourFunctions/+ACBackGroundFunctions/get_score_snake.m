function ACscore = get_score_snake(forcing_image,radii,angles,centre,ACparameters,radii_previous_timepoint,region_image)
% poorly maintained.
siy = size(forcing_image,2);
six = size(forcing_image,1);

alpha = ACparameters.alpha;%0.01%weighs non image parts (none at the moment)
betaElco =ACparameters.beta;%0.01 %weighs difference between consecutive time points.
opt_points = ACparameters.opt_points;%8;
seeds_for_PSO = ACparameters.seeds_for_PSO;%best set actually used for PSO.

angles = reshape(angles, [length(angles),1]);

[A,n,breaks,dim,jj,C] = ACBackGroundFunctions.splinefit_prep([angles; 2*pi],ones([seeds_for_PSO (opt_points+1)]),[angles; 2*pi],'p');
[radii_mat,angles_mat] = ACBackGroundFunctions.radius_and_angle_matrix([six,siy]);


use_previous_timepoint = nargin>6 && ~isempty(radii_previous_timepoint);

if use_previous_timepoint
            ACscore = ACMethods.CFRadialTimeStack(forcing_image,centre,angles,cat(2,radii_previous_time_point,radii),alpha,betaElco,[siy six],use_previous_timepoint,A,n,breaks,jj,C,region_image,radii_mat,angles_mat);    
        else
            ACscore = ACMethods.CFRadialTimeStack(forcing_image,centre,angles,radii,alpha,betaElco,[siy six],use_previous_timepoint,A,n,breaks,jj,C,region_image,radii_mat,angles_mat);   
        end

end