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
  [ 3.6850   -1.8042    0.6610    0.1756    0.5107   -0.0625   -1.2654   -0.4407   -0.5562   -0.8113   -0.4586   -0.0849
   -1.8042    7.0565   -2.3833    0.4243    0.6222   -2.1497    0.0148   -1.9660    0.9446   -0.1127   -0.5825    0.3210
    0.6610   -2.3833    5.4670   -1.1714    0.0939    0.8149   -0.3297    0.5652   -2.6783    0.0447    0.1496   -0.8001
    0.1756    0.4243   -1.1714    3.4690   -1.5093   -0.2491   -0.3079   -0.0859    0.5353   -1.3459    0.2008    0.0392
    0.5107    0.6222    0.0939   -1.5093    5.2771   -1.5584   -0.3473   -0.8205   -0.4417    0.3719   -2.5134    0.3101
   -0.0625   -2.1497    0.8149   -0.2491   -1.5584    4.8677   -0.1218    0.1100   -0.7309    0.0958    0.7098   -1.6012
   -1.2654    0.0148   -0.3297   -0.3079   -0.3473   -0.1218    1.7690   -0.3154    0.3806    0.6215    0.2986   -0.4786
   -0.4407   -1.9660    0.5652   -0.0859   -0.8205    0.1100   -0.3154    2.9549   -0.9365    0.3240    0.8932    0.1766
   -0.5562    0.9446   -2.6783    0.5353   -0.4417   -0.7309    0.3806   -0.9365    3.5456   -0.9408    0.3411    0.7558
   -0.8113   -0.1127    0.0447   -1.3459    0.3719    0.0958    0.6215    0.3240   -0.9408    2.8966   -1.2654    0.2338
   -0.4586   -0.5825    0.1496    0.2008   -2.5134    0.7098    0.2986    0.8932    0.3411   -1.2654    3.6476   -1.0149
   -0.0849    0.3210   -0.8001    0.0392    0.3101   -1.6012   -0.4786    0.1766    0.7558    0.2338   -1.0149    2.5496 ];
 
mu_2cell_small = ...
    [6.3255    5.5594    4.9345    4.7670    4.6263    4.7629    6.1710    5.5720    4.9830    4.9389    4.8321    5.0378];
 
inverted_cov_2cell_large =...
    [  2.3252   -1.0645    0.4999    0.4400    0.1024   -0.0282   -1.6182    0.2609   -0.3319   -0.8341   -0.0588    0.2063
       -1.0645    4.2161   -0.7572    0.2109    0.8579   -0.5746    0.2607   -2.1498    0.4998   -0.0011   -1.1088   -0.4927
        0.4999   -0.7572    4.1199   -1.1441   -0.0358    0.9840   -0.3555    0.1993   -2.8321    0.6279   -0.0271   -1.1231
        0.4400    0.2109   -1.1441    3.5522   -1.2739    0.4049   -0.4757   -0.1871    0.4126   -2.1332    0.4667   -0.2236
        0.1024    0.8579   -0.0358   -1.2739    3.6650   -0.9906   -0.1527   -0.8121   -0.0167    0.4856   -2.2233    0.3479
       -0.0282   -0.5746    0.9840    0.4049   -0.9906    4.1526    0.0211   -0.4100   -1.1563   -0.2920    0.5674   -2.3946
       -1.6182    0.2607   -0.3555   -0.4757   -0.1527    0.0211    1.9014   -0.4786    0.5093    0.7099    0.2932   -0.5466
        0.2609   -2.1498    0.1993   -0.1871   -0.8121   -0.4100   -0.4786    2.4660   -0.7676    0.2704    0.8639    0.8028
       -0.3319    0.4998   -2.8321    0.4126   -0.0167   -1.1563    0.5093   -0.7676    3.7467   -1.1574    0.3433    0.8806
       -0.8341   -0.0011    0.6279   -2.1332    0.4856   -0.2920    0.7099    0.2704   -1.1574    3.1400   -1.1870    0.4560
       -0.0588   -1.1088   -0.0271    0.4667   -2.2233    0.5674    0.2932    0.8639    0.3433   -1.1870    3.1958   -0.9830
        0.2063   -0.4927   -1.1231   -0.2236    0.3479   -2.3946   -0.5466    0.8028    0.8806    0.4560   -0.9830    3.1388 ];

mu_2cell_large = ...
    [9.3514    8.0165    6.8417    6.5490    6.4683    6.9211    9.3151    8.0440    6.8029    6.4617    6.4043    7.0368];

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
                radii1_reordered = previous_radii_mat(p,:);
                radii2_reordered = radii_mat(p,:);
                
                %make max radii first entry
                [~,mi] = max(radii1_reordered);
                radii_reordered = cat(1, radii1_reordered,radii2_reordered);
                
                radii_reordered = circshift(radii_reordered,-(mi-1),2);
                
                % flip so 2nd entry is 2nd largest
                if radii_reordered(1,2)<radii_reordered(1,end)
                    radii_reordered = fliplr(radii_reordered);
                    radii_reordered = circshift(radii_reordered,1,2);
                    
                end
                radii_reordered_list = [radii_reordered(1,:) radii_reordered(2,:)];
                if mean(radii1_reordered,2)<threshold_radius;
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






