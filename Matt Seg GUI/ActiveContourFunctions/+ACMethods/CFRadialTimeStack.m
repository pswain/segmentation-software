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
inverted_cov_1cell =...
    [0.9568   -0.9824    0.2210   -0.3336    0.2061   -0.1774
   -0.9824    2.3140   -0.7398    0.3936   -0.2683   -0.6752
    0.2210   -0.7398    1.4997   -0.9595    0.4939   -0.3992
   -0.3336    0.3936   -0.9595    1.5773   -1.0942    0.4536
    0.2061   -0.2683    0.4939   -1.0942    1.6916   -0.9590
   -0.1774   -0.6752   -0.3992    0.4536   -0.9590    1.9724];

mu_1cell = [9.1462    8.0528    6.7623    6.1910    6.0670    6.8330];

% for trained time change punishment
% gaussian parameters from paurs of curated cells.
inverted_cov_2cell_small =...
  [126.0658  -42.5615    2.8870   11.8948    5.8586  -16.0099
  -42.5615   81.2443  -12.5124   -0.5058    1.2085   -7.6606
    2.8870  -12.5124   46.5114   -9.3621   10.0087    9.6831
   11.8948   -0.5058   -9.3621   34.9953  -10.3854   -1.6459
    5.8586    1.2085   10.0087  -10.3854   37.9683   -5.5230
  -16.0099   -7.6606    9.6831   -1.6459   -5.5230   45.9440 ];
 
mu_2cell_small = ...
    [1.0446    1.0500    1.0109    0.9922    1.0147    1.0453];
 
inverted_cov_2cell_large =...
    [ 209.5097  -52.0429   10.8542   24.3002   21.5859    2.0933
  -52.0429  177.6484    3.8016   18.1454   18.9507   -4.9919
   10.8542    3.8016   82.4028  -16.4745   20.1983   28.1005
   24.3002   18.1454  -16.4745   83.1338  -16.6482   19.2025
   21.5859   18.9507   20.1983  -16.6482   71.4026  -12.9627
    2.0933   -4.9919   28.1005   19.2025  -12.9627  103.9030 ];

mu_2cell_large = ...
    [1.0277    1.0300    0.9943    0.9610    0.9749    1.0138];

threshold_radius = 6;

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

% make previous_radii_mat the matrix for timepoint 1, whether optimising it
% or not.
previous_radii_mat = radii_stack_mat(:,1:radii_length);

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
        if radii_length ==6 
            
            if t==1
                % apply single timepoint size distribution
                radii_reordered = radii_mat(p,:);
                %make max radii first entry
                [~,mi] = max(radii_reordered);
                radii_reordered = circshift(radii_reordered,-(mi-1),2);
                
                % flip so 2nd entry is 2nd largest
                if radii_reordered(2)<radii_reordered(end)
                    radii_reordered = fliplr(radii_reordered);
                    radii_reordered = circshift(radii_reordered,1,2);
                    
                end
                
                F(p) = F(p) + radial_punishing_factor*(radii_reordered-mu_1cell)*inverted_cov_1cell*((radii_reordered - mu_1cell)');
            else
            % apply time change factor
                radii_reordered_stack = cat(1,previous_radii_mat(p,:),radii_mat(p,:));
                
                for i=1:2
                    radii_reordered = radii_reordered_stack(i,:);
                    %make max radii first entry
                    [~,mi] = max(radii_reordered);
                    radii_reordered = circshift(radii_reordered,-(mi-1),2);
                    
                    % flip so 2nd entry is 2nd largest
                    if radii_reordered(1,2)<radii_reordered(1,end)
                        radii_reordered = fliplr(radii_reordered);
                        radii_reordered = circshift(radii_reordered,1,2);
                        
                    end
                    
                    radii_reordered_stack(i,:) = radii_reordered;
                    
                end
                radii_reordered_norm =  radii_reordered_stack(2,:)./radii_reordered_stack(1,:);
                if mean(radii_reordered_stack(1,:),2)<threshold_radius;
                    F(p) = F(p) + time_change_punishing_factor*(radii_reordered_norm-mu_2cell_small)*inverted_cov_2cell_small*((radii_reordered_norm - mu_2cell_small)');
                else
                    F(p) = F(p) + time_change_punishing_factor*(radii_reordered_norm-mu_2cell_large)*inverted_cov_2cell_large*((radii_reordered_norm - mu_2cell_large)');
                end
            end
        end
        
    end
    
    previous_radii_mat = radii_mat;

    
    
    
    Ftot = Ftot+F;
    
end



end






