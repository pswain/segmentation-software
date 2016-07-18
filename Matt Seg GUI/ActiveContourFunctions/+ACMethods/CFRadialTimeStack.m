function [Ftot] = CFRadialTimeStack(im_stack,center_stack,angles,radii_stack_mat,radial_punishing_factor,time_change_punishing_factor,image_size,first_timepoint_fixed,A,n,breaks,jj,C,varargin)
%cost function for snakes algorithm written to be used used with the
%particle optimisation toolbox from the file exchange:

%http://www.mathworks.co.uk/matlabcentral/fileexchange/7506-particle-swarm-optimization-toolbox

%via the call:

%[optOUT] = pso_Trelea_vectorized(@(radii_mat)snake_cost_fun_radial_PSO_play(image,center,angles,radii_mat,R_min,R_max,alpha),opt_points,7,[LowerBound UpperBound],0,P,'',seed);


%and options can be set as appropriate

%should take the center, and draw length(radii) lines at angles 'angles'
%Then draws a spline between them and calculate a cost function.

%im_stack                           - stack of forcing images (edges should be low)
%center_stack                       - stack of proposed center of cell [x y]
%angles                             - vector of angles in radians from the horizontal (horizontal to
%                                     the right is 0, horizontal to the left is pi).
%radii_stack_mat                    - vector of distances along radii (evenly spaced and starting at vertical
%                                     relative to the image) of the contour
%radial_punishing_factor            - column vector:weight of second derivative (or whatever term keeps the thing
%                                     roughly circular). each element of the column is for a single radii
%                                     (so should be same length as angles) so that shape can be
%                                     weighted differently at different angles.
%time_change_punishing_factor       - weight of timepoints sum term (squares of differences in
%                                     radii between timepoints). normally a
%                                     constant (Beta) multiplied by median
%                                     of image stack to try to get robust
%                                     parameter selection
%steps                              - row vector of radial angles that should be used to give total
%                                     coverage of the boundary (normally 0:(1/Rmax):(2*pi) )
%first_timepoint_fixed              - boolean. Set to true if the first
%                                     timepoint is a fixed one to not
%                                     optimise.


%SOME RULES
%radii_mat must be at least 2 wide
%width of radii_mat should be the same as the length of angles
%angles should be given in ascending order (i.e.
%[angles,indices] = sort(angles,1);
%radii_mat = radii_mat(:,indices))

all_outputs = false;

Ftot = 0;
radii_length = size(angles,1);
timepoints = (size(radii_stack_mat,2)/radii_length);
points = size(radii_stack_mat,1);

radial_punishing_factor = mean(radial_punishing_factor);

% for trained radius punishment
% gaussian parameters trained from cellVision training set
inverted_cov =...
    [0.9568   -0.9824    0.2210   -0.3336    0.2061   -0.1774
   -0.9824    2.3140   -0.7398    0.3936   -0.2683   -0.6752
    0.2210   -0.7398    1.4997   -0.9595    0.4939   -0.3992
   -0.3336    0.3936   -0.9595    1.5773   -1.0942    0.4536
    0.2061   -0.2683    0.4939   -1.0942    1.6916   -0.9590
   -0.1774   -0.6752   -0.3992    0.4536   -0.9590    1.9724];

mu = [9.1462    8.0528    6.7623    6.1910    6.0670    6.8330];


if all_outputs
    
    F_image = zeros(points,timepoints);
    F_circular = zeros(points,timepoints);
    F_time = zeros(points,timepoints);
    F_size = zeros(points,timepoints);

    
end

if first_timepoint_fixed

    timepoints_to_optimise = 2:timepoints;

else
    timepoints_to_optimise = 1:timepoints;

end

for ti = 1:length(timepoints_to_optimise)
    t= timepoints_to_optimise(ti);
    radii_mat = radii_stack_mat(:,(1+(t-1)*radii_length):(t*radii_length));
    im = im_stack(:,:,ti);
    center = center_stack(ti,:);
    
    %number of points, length of radii vector
    steps = 0:(1/max(radii_mat(:))):(2*pi);
    
    %resuts vector
    F = zeros(points,1);
    
    imx = size(im,2);%size of image
    imy = size(im,1);
    
    
    %construct spline using file exchange function 'splinefit'
    r_spline = ACBackGroundFunctions.splinefit_thin(A,n,breaks,points,jj,C,[radii_mat radii_mat(:,1)]);
    
    radii_full = ppval(r_spline,steps);
    
    %convert radial coords to x y coords
    cordx_full = round(center(1)+(radii_full.*repmat(cos(steps),points,1)));
    cordy_full = round(center(2)+(radii_full.*repmat(sin(steps),points,1)));
    
    %check coords are within boundary of image
    cordx_full(cordx_full<1) = 1;
    cordx_full(cordx_full>imx) = imx;
    cordy_full(cordy_full<1) = 1;
    cordy_full(cordy_full>imy) = imy;
    
    for p=1:points
        
        %F(p) = ACBackGroundFunctions.cost_from_image(im,[cordx_full(p,:);cordy_full(p,:)]',image_size(1,1));
        
        %testing for inline speed up
        I = (diff(cordx_full(p,:))|diff(cordy_full(p,:)));

        %sums pixel values
        
        if all_outputs
            
            %F_image(p,timepoints_to_optimise(ti)) = (sum(im(cordy_full(p,I)+(image_size(1,1)*(cordx_full(p,I)-1))),2))/sum(I,2);
            
            %try not taking an average score but subtracting median from forcing image first
            F_image(p,timepoints_to_optimise(ti)) = (sum(im(cordy_full(p,I)+(image_size(1,1)*(cordx_full(p,I)-1))),2));
            F(p) = F_image(p,timepoints_to_optimise(ti));
            
        else
            F(p) = (sum(im(cordy_full(p,I)+(image_size(1,1)*(cordx_full(p,I)-1))),2));
            %F(p) = (sum(im(cordy_full(p,I)+(image_size(1,1)*(cordx_full(p,I)-1))),2))/sum(I,2);
        
        end

        %add radial punishing term

    
        
        % trained logliklihood based term.
        if radii_length ==6;
            
            radii_reordered = radii_mat(p,:);
            %make max radii first entry
            [~,mi] = max(radii_reordered);
            radii_reordered = circshift(radii_reordered,-(mi-1),2);
            
            % flip so 2nd entry is 2nd largest
            if radii_reordered(2)<radii_reordered(end)
                radii_reordered = fliplr(radii_reordered);
                radii_reordered = circshift(radii_reordered,1,2);
                
            end
            
            F(p) = F(p) + radial_punishing_factor*(radii_reordered-mu)*inverted_cov*((radii_reordered - mu)');
        end
        
    end
    
    

    
    
    
    Ftot = Ftot+F;
    
end


timepoint_diff_mat = ((radii_stack_mat(:,(radii_length+1):end) -  radii_stack_mat(:,1:(end-radii_length)))./...
                        (radii_stack_mat(:,1:(end-radii_length)))).^2;
                    

if all_outputs
    
    F_time = time_change_punishing_factor*timepoint_diff_mat;
    Ftot = Ftot+ time_change_punishing_factor*sum(timepoint_diff_mat,2);
    F_summary = [Ftot sum(F_image,2) sum(F_circular,2) sum(F_time,2) sum(F_size,2)];
    
else
                    
    Ftot = Ftot+ time_change_punishing_factor*sum(timepoint_diff_mat,2);%sum(timepoint_diff_mat.*timepoint_diff_mat>0.01,2);

end


end






