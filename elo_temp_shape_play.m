%% shape transform play script

%% make a shape
[radii,angle_mat] = ACBackGroundFunctions.radius_and_angle_matrix([61,61]);

PCentreCell = -1*ones(size(radii));
PEdgeCell = PCentreCell;
PBGCell = PCentreCell;

PCentreCell(radii<20) = -10;

PEdgeCell(radii<20.5 & radii>19.5) = -2;

PBGCell(radii>20) = -10;
PTot = (exp(PCentreCell)+exp(PEdgeCell) + exp(PBGCell));

%PCentreCell = log(exp(PCentreCell)./PTot);
%PEdgeCell = log(exp(PEdgeCell)./PTot);
%PBGCell = log(exp(PBGCell)./PTot);

gui = GenericStackViewingGUI(cat(3,PCentreCell,PEdgeCell,PBGCell))
%%
% make a cell edge image from Centre/Edge/BG probabilitiy images. 
% each image is log((1-P)/P) that pixel is of that type (i.e. inverse bayes
% factor.
% Assumed cell centre is at centre.

X_centre = cumsum(PCentreCell,2,'forward');
Y_centre = cumsum(PCentreCell,1,'forward');

X_edge = cumsum(PEdgeCell,2,'forward');
Y_edge = cumsum(PEdgeCell,1,'forward');

X_BG = cumsum(PBGCell,2,'forward');
Y_BG = cumsum(PBGCell,1,'forward');



[~,angle_mat] = ACBackGroundFunctions.radius_and_angle_matrix(size(PCentreCell));

% this formulation should make it:
%   sum of the centre pixels inside the cell 
%   - sum of the BG pixels inside the cell 
%   + the score of the edge pixels on the cell edge.
% TransformedCellImage = ( - X_BG - X_edge).*cos(angle_mat) + ...
%     ( - Y_BG - Y_edge).*sin(angle_mat) + ...
%     PEdgeCell;

%%
TransformedCellImage = PEdgeCell;
RegionImage = zeros(size(PEdgeCell));
im_size = size(TransformedCellImage);
cen = ceil(im_size/2);
%%
ACparameters = timelapseTrapsActiveContour.LoadDefaultParameters;

ACparameters = ACparameters.ActiveContour;
ACparameters.alpha = 0;
ACparameters.seeds = 50;
ACparameters.seeds_for_PSO = 50;


%%
[radii,angle_mat] = ACBackGroundFunctions.radius_and_angle_matrix([61,61]);


PEdgeCell = -1.7*ones(size(radii));

PEdgeCell(radii<24.5 & radii>14.5) = -2;

PEdgeCell(radii<4.5 & radii>2.5 & angle_mat>1.2*pi & angle_mat<16*pi) = -3;

%% add normal noisenoise

PEdgeCell = PEdgeCell + 4*randn(size(PEdgeCell));

%% add circles of radius 10 and normal distributed intensity

map = rand(im_size);

map = map<0.2;

circ = false(im_size);

circ(radii<16.5 & radii>13.5) = true;

map = conv2(1*map,1*circ);
%map = ma

%PEdgeCell(map) = -1.5;

%%
imshow(PEdgeCell,[]);

TransformedCellImage = PEdgeCell;
%% try doing optimisation on it

[RadiiResult,AnglesResult,ACscore] = ...
                            ACMethods.PSORadialTimeStack(TransformedCellImage,ACparameters,ceil(im_size/2),[],[],[],RegionImage);
                        
                        
seg_res = ACBackGroundFunctions.get_outline_from_radii(RadiiResult,AnglesResult,cen,im_size);

imshow(OverlapGreyRed(TransformedCellImage,seg_res,[],[],true),[]);
RadiiResult
ACscore
%%
radii = RadiiResult;
angles = AnglesResult;

%%
radii(2:3) = 2;
%% get score
score = ACBackGroundFunctions.get_score_snake(TransformedCellImage,radii,angles,cen,ACparameters,[],RegionImage);
seg_res2 = ACBackGroundFunctions.get_outline_from_radii(radii,AnglesResult,cen,im_size);

imshow(OverlapGreyRed(TransformedCellImage,seg_res2,[],[],true),[]);
ACscore
score
radii
RadiiResult

