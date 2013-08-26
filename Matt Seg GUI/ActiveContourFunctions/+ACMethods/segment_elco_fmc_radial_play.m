function [Image_Seg,ResultsX,ResultsY,ResultsF] = segment_elco_fmc_radial_play(Image,Centers,show_image,varargin)

% %% temporary placeholder function
% 
% Image_Seg = false([size(Image),size(Centers,1)]);
% 
% disk = strel('disk',5,4);
% 
% for i=1:size(Centers,1)
%     
%     TempImageSeg = zeros(size(Image));
%     TempImageSeg(Centers(i,2),Centers(i,1)) = 1;
%     TempImageSeg = imdilate(TempImageSeg,disk,'same');
%     Image_Seg(:,:,i) = TempImageSeg~=0;
%     
% end
% 
% angles = linspace(0,2*pi,9);
% angles = angles(1:(end-1));
% 
% ResultsX = repmat(Centers(:,1),1,8)+repmat(5*cos(angles),size(Centers,1),1);
% 
% ResultsY = repmat(Centers(:,2),1,8)+repmat(5*sin(angles),size(Centers,1),1);
% 
% ResultsF = 100;
% %%
% 
% end

% Segment_elco_fmc_radial ---
%
% Synopsis:        [Image_Seg,ResultsX,ResultsY,ResultsF] = segment_elco_fmc_radial(Image,Centers,show_image)

% Input:

% Output:

% Notes:

%varargin{1} - logical of probable trap pixels
%varargin{2} - logical of probable trap pixels with even higher confidence
%              (though obviously therefore less pixels)

if size(varargin,2)>=1
    trap_px = varargin{1};
end


Image_Seg = false([size(Image) size(Centers,1)]); %array to hold the segmented image.
Image_Seg_FS = zeros(size(Image)); % for displaying the segmented image.
Image = double(Image);

debug = false;%if set to one the final radii found will be stored in the debug folder of the cell_serpent folder.

alpha = 0.01; %weighs non image parts (none at the moment)
R_min = 4;%5;
R_max = 20;%30; %was initial radius of starting contour. Now it is the maximum size of the cell (must be larger than 5)
opt_points = 10;
res_points = 49;%number of the snake points passed to the results matrix (needs to match 'snake_size'field of OOFdataobtainer object
%for storing results
visualise = 1; %degree of visualisation (0,1,2,3)
EVALS = 50000; %maximum number of iterations passed to fmincon
spread_factor = 1; %used in particle swarm optimisation. determines spread of initial particles.
method = 'PSO';

sub_image_size = 30; %subimage is a size 2*sub_image_size +1 square.

ResultsX = zeros([size(Centers,1) res_points+1]);
ResultsY = ResultsX;
ResultsF = zeros(size(Centers,1),1);

[X,Y] = meshgrid(1:size(Image,2), 1:size(Image,1)); %mesh for processing of results



Image = (Image-min(Image(:)))/(max(Image(:)) - min(Image(:)));%normalise image as snake_elco expects


if debug
    
    radii_mat = zeros(opt_points,size(Centers,1)); %matrix in which to store all radii results
    forcing_images = zeros([(sub_image_size*[2 2] + 1) size(Centers,1)]); %matrix in which to store all radii results
    
end

if visualise>=1
    fig_handle = figure;
    imshow(show_image,[])
    %fig_handle2 = figure;
    
end

if visualise>=2
    fig_handle2 = figure;
end


for iP=1:size(Centers,1)
    fprintf('cell %d \n',iP)
    
    %set lower bounds to be centre -  starting contour radius s_R
    LB = R_min*ones(opt_points,1);
    %set lower bounds to be centre +  starting contour radius s_R
    UB = R_max*ones(size(LB));
    
    
    
    %
    
    %get a transformed sub image of the original image in which the center
    %is at coordinate [31 31]
    
    if size(varargin,2)==1
        sub_image = image_transform_radial_gradient_DICangle_and_radialaddition(Image,Centers(iP,:),sub_image_size,-45,trap_px);
       %sub_image = image_transform_traps(Image,Centers(iP,:),sub_image_size,-45,trap_px);
    else
       % sub_image = image_transform_radial_gradient_DICangle_and_radialaddition(Image,Centers(iP,:),sub_image_size,-45);
       sub_image = image_transform_traps(Image,Centers(iP,:),sub_image_size,135);
       
    end
    if debug
    
    
    forcing_images(:,:,iP) = sub_image; %matrix in which to store all radii results
    
    end
    
    
    [siy,six] = size(sub_image);
    
    %     %initialise the snake
    [radii_init,angles] = initialise_snake_radial(sub_image,opt_points,round(six/2), round(siy/2),R_min,R_max,'circles');
    
    [radii_init_score,~] = initialise_snake_radial(sub_image,opt_points,round(six/2), round(siy/2),R_min,R_max,'min');
    
    
    if visualise>=1
        figure(fig_handle);
        [px,py] = get_points_from_radii(radii_init_score,angles,Centers(iP,:),res_points);
        hold on
        plot(px,py,'b');
        drawnow
    end
    
    
    
    
    if visualise>=2
        figure(fig_handle2);
        imshow(sub_image,[]);
        hold on
        plot((px-Centers(iP,1))+sub_image_size+1,(py-Centers(iP,2))+sub_image_size+1,'b');
        plot(sub_image_size+1,sub_image_size+1,'or')
        drawnow
        %fig_handle2 = figure;
        
    end
    
    switch method
        case 'fmincon'
            %% using fmincon
            
            options = optimset('Algorithm','interior-point','MaxFunEvals',EVALS,'MaxIter',EVALS,'Display','iter','TolFun',10e-10);
            
            %fmincon part
            [A,n,breaks,dim,jj,C] = splinefit_prep([angles; 2*pi],ones(size(radii_init')+[0 1]),[angles; 2*pi],'p');
            steps = 0:(1/R_max):(2*pi);
            
            
            [radii,F] = fmincon(@(radii)snake_cost_fun_radial_PSO_efficient(sub_image,fliplr(round(size(sub_image)/2)),angles,radii,R_min,R_max,alpha,steps,size(sub_image),A,n,breaks,dim,jj,C),radii_init_score',[],[],[],[],LB,UB,[],options);
            
            radii = radii';
            
            %% fminsearch - Belder Mead for local minima
        case 'fminsearch'
            
            [radii,F] = fminsearch(@(radii)snake_cost_fun_radial_play(sub_image,[31 31],angles,radii,R_min,R_max,alpha),radii_init);
            
            
            
            
        case 'PSO'
            %% using particle optimisation tool box
            
            %parameters for particle swarm optimisation
            
            %get second derivative of radii
            [D2radii] = second_derivative_snake(radii_init_score);
            
            % %parameter values used (see help pso_Trelea_vectorized for more details
            %on these
            P = [100 6000 30 4 0.5 0.4 0.4 1500 1e-25 450 NaN 3 1];
            %defaults parameter values
            %Pdef = [100 2000 24 2 2 0.9 0.4 1500 1e-25 250 NaN 0 0];
            
            
            rand_num =randn(P(3),opt_points);%normally distributed matrix to make PSOseed
            
            
            %If radii has 2nd derivative
            %rand_num = spread_factor*rand_num.*repmat(D2radii',P(3),1);
            
            
            %PSOseed1 are evenly distributed circles between R_min and R_max.
            radii_init = linspace(R_min,R_max,floor(P(3)/2));
            PSOseed1 = repmat(radii_init',1,opt_points);

            
            PSOseed2 = repmat(radii_init_score',ceil(P(3)/2),1);
            PSOseed2 = PSOseed2+spread_factor*randn(size(PSOseed2)).*repmat(D2radii',ceil(P(3)/2),1);
            
            PSOseed = [PSOseed1;PSOseed2];
            
            PSOseed(PSOseed<R_min) = R_min;
            PSOseed(PSOseed>R_max) = R_max;
            
            %steps in polar angle that will determine how fine grained to image
            %path used to calculate cost function is.
            steps = 0:(1/R_max):(2*pi);
            %%particle swarm optimisation
            
            %group of functions taken out of splinefit to speed up optimisation.
            [A,n,breaks,dim,jj,C] = splinefit_prep([angles; 2*pi],ones(size(PSOseed)+[0 1]),[angles; 2*pi],'p');
            
            
            
            
            
            %PSO(functname,D(dimension of problem),mv(defaut 4),VarRange(defaut [-100 100]),minmax,PSOparams,plotfcn,PSOseedValue(a particle number x D (dimension) matrix))
            [optOUT] = ACBackGroundFunctions.pso_Trelea_vectorized_mod(@(radii)snake_cost_fun_radial_PSO_efficient(sub_image,fliplr(round(size(sub_image)/2)),angles,radii,R_min,R_max,alpha,steps,size(sub_image),A,n,breaks,dim,jj,C),opt_points,7,[LB UB],0,P,'',PSOseed);
            
            %for debugging (allows you to see the 5 best contours
            %[optOUT] = pso_Trelea_vectorized_mod_1cellsegment_debug(@(radii)snake_cost_fun_radial_PSO_efficient(sub_image,fliplr(round(size(sub_image)/2)),angles,radii,R_min,R_max,alpha,steps,size(sub_image),A,n,breaks,dim,jj,C),opt_points,sub_image,fliplr(round(size(sub_image)/2)),angles,7,[LB UB],0,P,'',PSOseed);
            
%            pso_Trelea_vectorized_mod_1cellsegment_debug(functname,D,show_image,center,angles,varargin)
            
            radii = optOUT(1:(end-1));
            F = optOUT(end);
            
    end
    %% non optimisation specific
    
    [px,py] = get_points_from_radii(radii,angles,Centers(iP,:),res_points);
    
    
    
    %make px py a looped list of the form expected by the rest of the
    %program
    px2 = [px(end);px];
    py2 = [py(end);py];
    
    ResultsX(iP,:) = px2(:);
    ResultsY(iP,:) = py2(:);
    ResultsF(iP) = F;
    Image_Seg(:,:,iP) = inpolygon(X,Y,px2,py2);
    Image_Seg_FS(Image_Seg(:,:,iP)) = iP;
    
    if visualise>=1
        
        figure(fig_handle);
        hold on
        plot(px2,py2,'r');
        drawnow
        
        if visualise>=2
            figure(fig_handle2);
            hold on
            plot((px2-Centers(iP,1))+sub_image_size+1,(py2-Centers(iP,2))+sub_image_size+1,'r');
            drawnow
            hold off
            if visualise>=3
                pause
            end
        else
            pause(0.1)
        end
        %      figure(fig_handle2);
    end
    
    
    if debug
        
        radii_mat(:,iP) = radii;
        
        
    end
    
    
    
end


if debug
    
    D = dir('/Network/Servers/sce-bio-c01949.bio.ed.ac.uk/home0/ebakker/Documents/MATLAB/cell_serpent/debug_radial/data_files/');
    file_number = length(D) - 1;
    save(['/Network/Servers/sce-bio-c01949.bio.ed.ac.uk/home0/ebakker/Documents/MATLAB/cell_serpent/debug_radial/data_files/radial_debug_file_' num2str(file_number) '.mat'],'Image','Centers','radii_mat','forcing_images');
    fprintf(['\n \n saved timepoint as radial_debug_file_' num2str(file_number) '.mat\n \n'])
    
end

if visualise>=1
    
    close(fig_handle);
    if visualise>=2
        close(fig_handle2);
    end
    
end
end

function [radii,angles] = initialise_snake_radial(im,N,x,y,Rmin,Rmax,method)
% Initialises the snakes with a centre at x,y in the image im.
% N      - number of snake points
% (x,y)  - seeding coordinate
% R      - was initial radius, changed initial point starting position
% selection algorithm so that it is now the maximum radius of starting
% point (20 is good)
%


N = max(N,4);


% make an N+1 length vector of equally spaced angles.
angles = linspace(0,2*pi,N+1)';
angles = angles(1:N,1);
radii = zeros(size(angles));


switch method
    case 'min'
        for i=1:N
            %loops through all the first N points (leaving out the repeated zero
            %N+1) and get the best point in the image for them.
            cordx = uint16(x+(Rmin:Rmax)'*cos(angles(i)));%radial cords
            cordy = uint16(y+(Rmin:Rmax)'*sin(angles(i)));
            
            cordx(cordx<1) = 1;
            cordx(cordx>512) = 512;
            
            cordy(cordy<1) = 1;
            cordy(cordy>512) = 512;
            
            
            score = zeros(size(cordx));
            for j = 1:length(score)
                score(j) = im(cordy(j),cordx(j));
            end
            
            
            [~,minIndex] = min(score);
            
            radii(i) = Rmin+minIndex-1;
            
            
            
            
            
        end
        
        % OLD WAY OF DETERMINING STARTING COORDINATES
        %     px = x + 5*cos(t);
        %     py = y + 5*sin(t);
        %
    case 'circle'
        radii = 5*ones(size(angles));
end

end

function [px,py] = get_points_from_radii(radii,angles,center,point_number)

if point_number<2
    error('need at least 2 radial points')
end


%order the angles vector (may not be necessary)
[angles,indices_angles] = sort(angles,1);
radii = radii(indices_angles);

%construct spline using file exchange function 'splinefit'
r_spline = splinefit([angles; 2*pi],[radii;radii(1)],[angles; 2*pi],'p');%make the spline

steps = linspace(0,2*pi,point_number+1)';
steps = steps(1:point_number,1);
radii_full = ppval(r_spline,steps);

%convert radial coords to x y coords
px = round(center(1)+radii_full.*cos(steps));%radial cords
py = round(center(2)+radii_full.*sin(steps));

%check they are sensible
px(px<1) = 1;
px(px>512) = 512;

py(py<1) = 1;
py(py>512) = 512;



end

function [D2radii] = second_derivative_snake(radii)

%calculate second derivative of points radii (D^2 r / D (theta) ^2)
%radii is expected to be an unlooped list (i.e. a list of unrepeated,
%evenly spaced radii.
N = length(radii);
radii2 = [radii(N); radii; radii(1)];
mask = [-1; 2; -1];

D2radii = conv2(radii2,mask,'valid');


end
