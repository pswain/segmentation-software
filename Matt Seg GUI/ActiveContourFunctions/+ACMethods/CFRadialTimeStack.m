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
  [5.0596   -2.7307    0.1211    0.3408    0.3509   -0.6415   -2.9563    0.3584   -0.1877   -0.5309   -0.6394    1.0401
   -2.7307    6.7259   -1.4121    0.0310    0.5175   -1.5071    1.4214   -2.1847    0.2875   -0.0252    0.1510   -0.8673
    0.1211   -1.4121    4.2240   -0.9882    0.6526    0.7322    0.3217   -0.4339   -1.4757    0.2029   -0.8075   -0.8829
    0.3408    0.0310   -0.9882    3.3715   -1.4292   -0.0941   -0.7121    0.5696    0.0064   -1.0910   -0.1321    0.2611
    0.3509    0.5175    0.6526   -1.4292    4.4595   -0.9602    0.0763   -0.9671   -0.6212   -0.0787   -1.5167   -0.5260
   -0.6415   -1.5071    0.7322   -0.0941   -0.9602    4.6500    0.2399    0.4803   -0.6877   -0.1471    0.2808   -2.1064
   -2.9563    1.4214    0.3217   -0.7121    0.0763    0.2399    4.2216   -2.6745    0.2467    0.4752   -0.0109   -0.8285
    0.3584   -2.1847   -0.4339    0.5696   -0.9671    0.4803   -2.6745    6.5590   -1.0608    0.3196    0.8131   -1.1432
   -0.1877    0.2875   -1.4757    0.0064   -0.6212   -0.6877    0.2467   -1.0608    3.3298   -1.2017    0.8583    0.9440
   -0.5309   -0.0252    0.2029   -1.0910   -0.0787   -0.1471    0.4752    0.3196   -1.2017    3.1498   -0.9407   -0.0030
   -0.6394    0.1510   -0.8075   -0.1321   -1.5167    0.2808   -0.0109    0.8131    0.8583   -0.9407    3.2044   -0.6219
    1.0401   -0.8673   -0.8829    0.2611   -0.5260   -2.1064   -0.8285   -1.1432    0.9440   -0.0030   -0.6219    4.7186 ];
 
mu_2cell_small = ...
    [6.3255    5.5594    4.9345    4.7670    4.6263    4.7629    6.5815    5.7947    4.9388    4.6609    4.6340    4.9249];
 
inverted_cov_2cell_large =...
    [  2.6359   -0.8025    0.3421    0.2855    0.2958    0.1125   -2.1504    0.2958   -0.1498   -0.5241   -0.3273   -0.0194
   -0.8025    3.8175   -0.1673    0.3996    0.3219   -0.4894    0.1868   -2.2453   -0.0584   -0.2204   -0.5324   -0.3220
    0.3421   -0.1673    2.7266   -0.7241    0.5034    0.5840   -0.0903   -0.5205   -1.2599    0.0936   -0.4508   -0.8568
    0.2855    0.3996   -0.7241    2.6610   -0.8739    0.5520   -0.3632   -0.3065   -0.1195   -1.1677   -0.0427   -0.2625
    0.2958    0.3219    0.5034   -0.8739    2.6652   -0.4896   -0.2910   -0.3484   -0.5616    0.0106   -1.1263   -0.1628
    0.1125   -0.4894    0.5840    0.5520   -0.4896    3.2996   -0.2897   -0.1268   -0.8835   -0.3416   -0.0107   -1.6397
   -2.1504    0.1868   -0.0903   -0.3632   -0.2910   -0.2897    2.7876   -0.9325    0.2976    0.3793    0.5385   -0.1276
    0.2958   -2.2453   -0.5205   -0.3065   -0.3484   -0.1268   -0.9325    3.6059   -0.1942    0.4718    0.4150   -0.0258
   -0.1498   -0.0584   -1.2599   -0.1195   -0.5616   -0.8835    0.2976   -0.1942    2.5281   -0.8569    0.7907    0.5253
   -0.5241   -0.2204    0.0936   -1.1677    0.0106   -0.3416    0.3793    0.4718   -0.8569    2.7350   -1.0784    0.6240
   -0.3273   -0.5324   -0.4508   -0.0427   -1.1263   -0.0107    0.5385    0.4150    0.7907   -1.0784    2.6417   -0.6495
   -0.0194   -0.3220   -0.8568   -0.2625   -0.1628   -1.6397   -0.1276   -0.0258    0.5253    0.6240   -0.6495    3.0213 ];

mu_2cell_large = ...
    [9.3514    8.0165    6.8417    6.5490    6.4683    6.9211    9.5887    8.2295    6.7597    6.2510    6.2557    6.9803];

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
                radii_reordered_list = [radii_reordered_stack(1,:) radii_reordered_stack(2,:)];
                if mean(radii_reordered_stack(1,:),2)<threshold_radius;
                    F(p) = F(p) + time_change_punishing_factor*(radii_reordered_list-mu_2cell_small)*inverted_cov_2cell_small*((radii_reordered_list - mu_2cell_small)');
                else
                    F(p) = F(p) + time_change_punishing_factor*(radii_reordered_list-mu_2cell_large)*inverted_cov_2cell_large*((radii_reordered_list - mu_2cell_large)');
                end
            end
        end
        
    end
    
    previous_radii_mat = radii_mat;

    
    
    
    Ftot = Ftot+F;
    
end



end






