classdef ACRadialPSO<findedges.FindEdges
    methods
        function obj=ACRadialPSO(varargin)
            % ACCellSerpent --- constructor for an object to run the active contour cell serpent method
            %
            % Synopsis:  obj = ACCellSerpent (varargin)
            %
            % Output:    obj = object of class ACCellSerpent
            
            % Notes:
            
            %Create obj.parameters structure and define default parameter value
            obj.parameters = struct();
            obj.parameters.FindCentresMethod='LoadCentres';%Default value - will calculate the threshold level using the Ostu method.
            obj.paramChoices.FindCentresMethod='findcentres';
            %% parameters
            
            obj.parameters.Alpha = 0.1;
            obj.parameters.Rmin = 1;
            obj.parameters.Rmax = 25;
            obj.parameters.OptimisePoints = 8;
            obj.parameters.ResultPoints = 49;
            obj.parameters.evaluation = 12000; 
            obj.parameters.SpreadFactor = 1; 
            obj.parameters.Seeds = 100;

            
            %Define required fields and images
            obj.requiredImages={'FilteredTargetImage'};
            obj.requiredFields={'Centres'};
            
            %Define user information
            obj.description='Uses active contour method Cell Serpent to find outlines of cells from centre coordinates.';
            obj.paramHelp.FindCentresMethod = 'Parameter ''findcentremethod'': Method used to define cell centres.';
            obj.paramHelp.Alpha = 'Weighs second derivative of radii in cost function, so a higher Alpha favours circular cells';
            obj.paramHelp.Rmin = ['Smallest allowable distance between the centre and the cell edge. Should be 1 for 60x images. '...
                'Accurately spcifying this quantity can dramatically speed up and improve segmentation.'];
            obj.paramHelp.Rmax = 'Largest allowable distance between the centre and the cell edge.Accurately spcifying this quantity can dramatically speed up and improve segmentation.';
            obj.paramHelp.OptimisePoints = ['Number of points used to define the cell edge during optimisation. A larger number will '...
                'give a slower optimisation but the possibility of a more detailed contour. Increase if your cells are strange shapes or very large'];
            obj.paramHelp.ResultPoints = ['Number of points used to construct the result contour. Not an important parameter as long as it''s'...
                ' over 20. Increase if you feel the final shape has many straight lines '];
            obj.paramHelp.evaluation = ['Maximum number of evaluations allowed during the optimisation. Increase if failing to find correct centre, '...
            'though this will slow down the segmentation'];
            obj.paramHelp.SpreadFactor = 'Spread of seed points. Increasing may help to find difficult contours'; 
            obj.paramHelp.Seeds = ['Number of starting points, or seeds, used to search the parameter space. Increasing this number can help find difficult contours '...
                'but will slow down the segmentation.'];
            
            %Call changeparams to redefine parameters if there are input arguments to this constructor
           
            obj=obj.changeparams(varargin{:});
           
            %List the method and level classes that this method will use,
            %in the order in which they are called
            obj.Classes(1).classnames=obj.parameters.FindCentresMethod;
            obj.Classes(1).packagenames='findcentres';
            
            
        end
        
        function paramCheck=checkParams(obj, timelapseObj)
            % checkParams --- checks if the parameters of a Threshold object are in range and of the correct type
            %
            % Synopsis: 	paramCheck = checkParams (obj)
            %
            % Input:	obj = an object of class LoopBasins
            %
            % Output: 	paramCheck = string, either 'OK' or an error message detailing which parameters (if any) are incorrect
            
            % Notes:
            paramCheck='';
            findCentreClasses=obj.listMethodClasses('findcentres');
            if ~any(strcmp(findCentreClasses,obj.parameters.FindCentresMethod));
                paramCheck=[paramCheck 'This parameter must be the name of valid findcentres method.'];
            end
            
            paramCheck = check_param_numeric(obj,'Alpha',paramCheck);
            paramCheck = check_param_numeric(obj,'Rmin',paramCheck);
            paramCheck = check_param_numeric(obj,'Rmax',paramCheck);
            paramCheck = check_param_numeric(obj,'OptimisePoints',paramCheck);
            paramCheck = check_param_numeric(obj,'ResultPoints',paramCheck);
            paramCheck = check_param_numeric(obj,'evaluation',paramCheck);
            paramCheck = check_param_numeric(obj,'SpreadFactor',paramCheck);
            paramCheck = check_param_numeric(obj,'Seeds',paramCheck);
            
            paramCheck = check_param_positive(obj,'Alpha',paramCheck);
            paramCheck = check_param_positive(obj,'Rmin',paramCheck);
            paramCheck = check_param_positive(obj,'Rmax',paramCheck);
            paramCheck = check_param_positive(obj,'OptimisePoints',paramCheck);
            paramCheck = check_param_positive(obj,'ResultPoints',paramCheck);
            paramCheck = check_param_positive(obj,'evaluation',paramCheck);
            paramCheck = check_param_positive(obj,'SpreadFactor',paramCheck);
            paramCheck = check_param_positive(obj,'Seeds',paramCheck);
            
            if isnumeric(obj.parameters.Rmin) &&isnumeric(obj.parameters.Rmax)
                if obj.parameters.Rmin>=obj.parameters.Rmax
                    paramCheck = [paramCheck ' Rmin must be smaller than Rmax.'];
                end
            end
            
            
            if isempty(paramCheck)
                paramCheck='OK';
            end
        end
        
        function [inputObj fieldHistory]=initializeFields(obj, inputObj)
            % initializeFields --- Creates the fields and images required for the ACCellSerpent method to run
            %
            % Synopsis:  obj = initializeFields (obj, inputObj)
            %
            % Output:    obj = object of class ACCellSerpent
            %            inputObj = an object of a level class.
            
            % Notes:     Uses a method in the findcentres class to create
            % the inputObj.RequiredFields.Centres field.
            
            fieldHistory=struct('objects', {},'fieldnames',{});
            
            %Create FilteredTargetImage field - target images with mean of a
            %radius 30 disk subtracted from every point.
            if ~isfield(inputObj.RequiredImages,'FilteredTargetImage')
                filt = fspecial('disk',30);
                im = double(inputObj.Target);
                inputObj.RequiredImages.FilteredTargetImage=im-imfilter(im,filt,'replicate');
            end
            
            %Find centres
            [inputObj fieldHistory] = obj.useMethodClass(obj, inputObj,fieldHistory,'anything', 'findcentres', obj.parameters.FindCentresMethod);

        end
        
        function [inputObj fieldHistory]=run(obj, inputObj)
            % run --- run function for ACCellSerpent, finds cell outlines from centres and input image
            %
            % Synopsis:  result = run(obj, inputObj)
            %
            % Input:     obj = an object of class ACCellSerpent
            %            inputObj = an object carrying the data to be thresholded
            %
            % Output:    inputObj = level object with inputObj.Bin field created or modified
            
            % Notes:
            
            fieldHistory=struct('fieldnames',{},'objects',{});
            
                       
            %Do active contour optimisation
%             inputObj.RequiredFields.TempResult = segment_radial_PSO(inputObj.RequiredImages.FilteredTargetImage,inputObj.RequiredFields.Centres,obj.parameters.Alpha,obj.parameters.Rmin,obj.parameters.Rmax,obj.parameters.OptimisePoints,...
%                                                                         obj.parameters.ResultPoints,obj.parameters.SpreadFactor,obj.parameters.evaluation,obj.parameters.Seeds,obj.parameters.SubImageSize);
%             
%                                                                     
            [inputObj.RequiredFields.TempResult] = segment_elco_PSO_radial(inputObj.RequiredImages.FilteredTargetImage,inputObj.RequiredFields.Centres,obj.parameters.Alpha,obj.parameters.Rmin,obj.parameters.Rmax,obj.parameters.OptimisePoints,...
                                                                         obj.parameters.ResultPoints,obj.parameters.SpreadFactor,obj.parameters.evaluation,obj.parameters.Seeds,(obj.parameters.Rmax+2));
                                                                    
             %cells = false(size(inputObj.RequiredImages.FilteredTargetImage,1),size(inputObj.RequiredImages.FilteredTargetImage,1),size(inputObj.RequiredFields.Centres,1));
             %cells(20:40,20:40,:) = true;
            %inputObj.RequiredFields.TempResult = cells;
        end
    end
end

function [Image_Seg] = segment_elco_PSO_radial(Image,Centers,alpha,R_min,R_max,opt_points,res_points,spread_factor,EVALS,seeds,sub_image_size,varargin)

% Segment_elco_PSO_radial ---
% Segment_elco_radial_PSO ---
%
% Synopsis:        [Image_Seg] = segment_radial_PSO(Image,Centers,alpha,R_min,R_max,opt_points,res_points,spread_factor,Evals,seeds,sub_image_size,varargin)

% Input:           Image          -    DIC image of the cells
%                  Centers        -    column vector of centers of cells
%                  alpha          -    weight of second derivative of radius that
%                                      keeps cell fairly cicular
%                  R_min          -    minimum radius of cells
%                  R_max          -    maximum radius of cells
%                  opt_points     -    number of radii used to construct
%                                      contour
%                  res_points     -    number of points used to construct
%                                      outputed contour
%                  spread_factor  -    degree of randomness used in seed
%                                      to generate seeds
%                  EVALS          -    maximum number of function
%                                      evaluation
%                  seeds          -    number of seeds used for particle
%                                      swarm optimisation
%                  sub_image_size -    size of subimage calculated for each
%                                      cell
% Output:

% Notes:

%These are not used at this stage but I have left them in so that we can
%use the same function later.
%varargin{1} - logical of probable trap pixels
%varargin{2} - logical of probable trap pixels with even higher confidence
%              (though obviously therefore less pixels)

if size(varargin,2)>=1
    trap_px = varargin{1};
end


if size(varargin,2)>=2
    trap_px_cert = varargin{2};
end

Image_Seg = false([size(Image) size(Centers,1)]); %array to hold the segmented image.
Image = double(Image);


[X,Y] = meshgrid(1:size(Image,2), 1:size(Image,1)); %mesh for processing of results



Image = (Image-min(Image(:)))/(max(Image(:)) - min(Image(:)));%normalise image as snake_elco expects


for iP=1:size(Centers,1)
    findedges.ACRadialPSO.showProgress(iP/size(Centers,1)*100, 'findedges method ACRadialPSO. Finding contours...')
    
    %set lower bounds to be centre -  starting contour radius s_R
    LB = R_min*ones(opt_points,1);
    %set lower bounds to be centre +  starting contour radius s_R
    UB = R_max*ones(size(LB));
    
    
    
    %
    
     %get a transformed sub image of the original image in which the center
    %is at the centre of the image
    
    if size(varargin,2)==1
        sub_image = image_transform_radial_gradient(Image,Centers(iP,:),sub_image_size,trap_px);
    elseif size(varargin,2)==2
        sub_image = image_transform_radial_gradient(Image,Centers(iP,:),sub_image_size,trap_px,trap_px_cert);
    else
        sub_image = image_transform_radial_gradient(Image,Centers(iP,:),sub_image_size);
    end
   
    
    [siy,six] = size(sub_image);
    
    %     %initialise the snake
     [radii_init_score,angles] = initialise_snake_radial(sub_image,opt_points,round(six/2), round(siy/2),R_min,R_max,'min');
    
    
    
    
    
   
    
    
            %% using particle optimisation tool box
            
            %parameters for particle swarm optimisation
            
            %get second derivative of radii
            [D2radii] = second_derivative_snake(radii_init_score);
            
            % %parameter values used (see help pso_Trelea_vectorized for more details
            %on these
            P = [0 EVALS seeds 2 2 0.9 0.4 1500 1e-25 250 NaN 1 1];
            %defaults parameter values
    %Pdef = [100 2000 24 2 2 0.9 0.4 1500 1e-25 250 NaN 0 0];
    
    %seed values are a distribution around the usual starting function
    %given by 'initialise_snake_radial'
    
    %PSOseed1 are evenly distributed circles between R_min and R_max.
            radii_init = linspace(R_min,R_max,floor(seeds/2));
            PSOseed1 = repmat(radii_init',1,opt_points);

            
            %PSOseed2 are distributed around the radii found by taking the minimal
    %score for each radius from the starting image.
    
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
            [optOUT] = pso_Trelea_vectorized_mod(@(radii)snake_cost_fun_radial_PSO_efficient(sub_image,fliplr(round(size(sub_image)/2)),radii,alpha,size(sub_image),A,n,breaks,jj,C),opt_points,7,[LB UB],0,P,'',PSOseed);
            
            radii = optOUT(1:(end-1));
            F = optOUT(end);
            

    %% non optimisation specific
     %get the xy coordinates of 'res_points' points around the contour
   
    [px,py] = get_points_from_radii(radii,angles,Centers(iP,:),res_points,size(Image));
    
    
    
    %make px py a looped list of the form expected by the rest of the
    %program
    px2 = [px(end);px];
    py2 = [py(end);py];
    
   %Use these coordinates to build an image of the cell.
    Image_Seg(:,:,iP) = inpolygon(X,Y,px2,py2);
   
   
    
  
    
    
end
findedges.ACRadialPSO.showProgress(0, '')



end

function [radii,angles] = initialise_snake_radial(im,N,x,y,Rmin,Rmax,method)
% Initialises the snakes with a centre at x,y in the image im.

%INPUTS

% N      - number of snake points
% (x,y)  - seeding coordinate
% Rmin   - smallest allowed radius
% Rmax   - largest allowed radius
%method  - either 'min' or 'circle'. In the case of min the function picks
%          the a value for each radius at which the image is minimised. In
%          the case of 'circle' a circle of radius 5 is chosen.


%OUTPUTS

%radii   - a column vector of length N containing the radii of the points
%          which define the contour. radii are given in pixel units.
%angles  - a column vector of length N containing the angle of each of
%          corresponding radii in 'radii' which define the spline. angles
%          are given in radians anticlockwise to the x axis - so that a
%          line to the right of centre is angle 0, and a line to the left
%          of the center is of angle pi


%N = max(N,4);


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
            cordx(cordx>size(im,2)) = size(im,2);
            
            cordy(cordy<1) = 1;
            cordy(cordy>size(im,1)) = size(im,1);
            
            
            score = zeros(size(cordx));
            for j = 1:length(score)
                score(j) = im(cordy(j),cordx(j));
            end
            
            
            [~,minIndex] = min(score);
            
            radii(i) = Rmin+minIndex-1;
            
            
            
            
            
        end
        
       
    case 'circle'
        radii = 5*ones(size(angles));
end

end

function [px,py] = get_points_from_radii(radii,angles,center,point_number,image_size)

%gives x y coordinates for a snakes defined by center, radii and angles:

%INPUTS:
%radii        - a column vector of length N containing the radii of the points
%               which define the contour. radii are given in pixel units.

%angles       - a column vector of length N containing the angle of each of
%               corresponding radii in 'radii' which define the spline. angles
%               are given in radians anticlockwise to the x axis - so that a
%               line to the right of centre is angle 0, and a line to the left
%               of the center is of angle pi.

%center       - the center of the cell in the x y coordinates in which you want
%               the coordinates of your points.

%point_number - the number of points around the contour which should be
%               output.


%OUTPUTS:
%px           - x coordinates of points on the contour.

%py           - y coordinates of points on the contour.



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
px(px>image_size(2)) = image_size(2);

py(py<1) = 1;
py(py>image_size(1)) = image_size(1);



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


function [F] = snake_cost_fun_radial_PSO_efficient(im,center,radii_mat,alpha,image_size,A,n,breaks,jj,C)
%cost function for snakes algorithm written to be used used with the
%particle optimisation toolbox from the file exchange:

%http://www.mathworks.co.uk/matlabcentral/fileexchange/7506-particle-swarm-optimization-toolbox

%via the call:

%[optOUT] = pso_Trelea_vectorized(@(radii)snake_cost_fun_radial_PSO_efficient(sub_image,fliplr(round(size(sub_image)/2)),radii,alpha,sub_image_size,sub_image_size,A,n,breaks,jj,C),opt_points,7,[LB UB],0,P,'',PSOseed);
       

%and options can be set as appropriate

%should take the center, and draw length(radii) lines at angles 'angles'
%Then draws a spline between them and calculate a cost function.

%INPUTS:

%im         - forcing image (edges should be low)
%center     - proposed center of cell [x y]
%radii_mat  - vector of distances along radii (evenly spaced and starting at vertical
%             relative to the image) of the contours. Each row is a
%             contour, so that size(radii_mat,2) = size(angles,1)
%alpha      - weight of second derivative (or whatever term keeps the thing
%             roughly circular)
%imx        - size of image in x direction
%imy        - size of image in y direction
%A,n,break,jj,c - inputs from splinefit that I don't entirely understand.
%                 See splinfit_prep.

%OUTPUTS
%F          - vector of scores for the different contours making up
%             radii_mat


%SOME RULES
%radii_mat must be at least 2 wide
%width of radii_mat should be the same as the length of angles
%angles should be given in ascending order (i.e. 
%[angles,indices] = sort(angles,1);
%radii_mat = radii_mat(:,indices))

%number of points, length of radii vector
[points,radii_length] = size(radii_mat);

steps = 0:(1/max(radii_mat(:))):(2*pi);

%results vector
F = zeros(points,1);

imx = size(im,2);%size of image
imy = size(im,1);


%construct spline using file exchange function 'splinefit'

%TESTING CHANGES FOR SPEED
%r_spline = splinefit([angles; 2*pi],[radii_mat radii_mat(:,1)],[angles; 2*pi],'p');%make the spline

%[A,n,breaks,dim,jj,C] = splinefit_prep([angles; 2*pi],ones(size(radii_mat)+[0 1]),[angles; 2*pi],'p');
    

r_spline = splinefit_thin(A,n,breaks,points,jj,C,[radii_mat radii_mat(:,1)]);


%TESTING CHANGES FOR SPEED
radii_full = ppval(r_spline,steps);

%radii_full = spline([-1*angles(2,1); angles; 2*pi],[radii(end);radii;radii(1)],steps);

%convert radial coords to x y coords
cordx_full = round(center(1)+(radii_full.*repmat(cos(steps),points,1)));
cordy_full = round(center(2)+(radii_full.*repmat(sin(steps),points,1)));

%check coords are within boundary of image
cordx_full(cordx_full<1) = 1;
cordx_full(cordx_full>imx) = imx;
cordy_full(cordy_full<1) = 1;
cordy_full(cordy_full>imy) = imy;


%calculate score due to forcing image for each individiual point
for p=1:points
    
    F(p) = cost_fun(im,[cordx_full(p,:);cordy_full(p,:)]',image_size(1,1));
    
end


D2radii = second_derivative_snake_stack(radii_mat);
                        
F = F+alpha*(abs(F).*(sum((D2radii./radii_mat).^2,2))); %add punishment for very uneven cell outlines
     

end


function F = cost_fun(im,coords_full,y_length)
%computes the cost function due to the image for a single set of coords.

%im          - image
%coords_full - [x y] coords of proposed pixels
%y_length    - height of image
              
%eliminate repeated coords. works because repeated coords are always
%adjacent to each other. (Matt came up with it - he's so clever)
I = (diff(coords_full(:,1))|diff(coords_full(:,2)));

%sums pixel values
F = (sum(im(coords_full(I,2)+(y_length*(coords_full(I,1)-1)))))/sum(I,1);
                   
   
end



function [D2radii] = second_derivative_snake_stack(radii)

%calculate second derivative of points radii (D^2 r / D (theta) ^2)
%radii is expected to be an unlooped list (i.e. a list of unrepeated,
%evenly spaced radii.
radii2 = [radii(:,end) radii radii(:,1)];
mask = [-1 2 -1];

D2radii = conv2(radii2,mask,'valid');


end


function image = image_transform_radial_gradient(image,center,image_length,varargin)
%does a gradient transformation along the radial direction away from the
%center. Gives low values for changes from dark to light when moving out
%from the center. Tends to give low pixel values for edge pixels in DIC
%images.

%INPUTS

%image        -  image to be transformed
%center       -  center of the cell
%image_length -  half the size of the image to be produced

%varargin{1}  -  logical of probable trap pixels
%varargin{2}  -  logical of probable trap pixels with even higher confidence
%                (though obviously therefore less pixels)

%OUTPUTS

%image        -  image of size 2*image_length by 2*image_length which has been
%                transformed

if size(varargin,2)>=1
    trap_px = get_cell_image(varargin{1},center,image_length)~=0;
end


if size(varargin,2)>=2
    trap_px_cert = get_cell_image(varargin{2},center,image_length)~=0;
end

image = get_cell_image(image,center,image_length);

[ximg,yimg] = gradient(image);

%image is now (2*image_length+1) by (2*image_length+1) centered on center (so center is (image_length+1) (image_length+1))

xcoord = repmat(-image_length:image_length,(2*image_length +1),1);

ycoord = repmat((-image_length:image_length)',1,(2*image_length +1));

xcoord((image_length +1),(image_length +1)) = 1;

ycoord((image_length +1),(image_length +1)) = 1;

[R,angle] = xy_to_radial(xcoord(:),ycoord(:));

R = reshape(R,(2*image_length+1),(2*image_length+1));

angle = reshape(angle,(2*image_length+1),(2*image_length+1));

image = -ximg.*cos(angle) -yimg.*sin(angle);



if size(varargin,2)>=1
   image(trap_px) = median(image(:));

end


if size(varargin,2)>=2
    image(trap_px_cert) = max(image(:));
end






end


function [R,angle] = xy_to_radial(x,y)
%converts to a radius and an angle between 0 and 2pi
R = sqrt((x.^2) + (y.^2));
angle = atan(y./x);


angle = angle+(pi*(x<0));

angle = mod(angle,2*pi);

%convert x and y to an angle

end

function show_image = get_cell_image(image,center,image_length)
%get a image_length by image_length chunk of the image centered on center

info = whos('image');
if strcmp(info.class,'logical')
m = false;
else
    m = median(image(:));
end
image = padarray(image,[image_length image_length],m);
center(center<=1)=1;
center(center>512)=512;
%gets 30 by 30 square centered on 'center' in the original image
try
show_image = image(round(center(1,2))+(0:(2*image_length))',round(center(1,1))+(0:(2*image_length))');
catch
    disp('debug point in ACRadialPSO');
end

end


function paramCheck = check_param_numeric(obj,name,paramCheck)
%small function to check if a parameter is numeric


if ~isnumeric(obj.parameters.(name))
    paramCheck=[paramCheck ' ' name ' must be a number.'];
end


end


function paramCheck = check_param_positive(obj,name,paramCheck)
%small function to check if a parameter is numeric


if isnumeric(obj.parameters.(name))
    if any(obj.parameters.(name)<0)
        paramCheck=[paramCheck ' ' name ' must be a positive number.'];
    end
end


end
