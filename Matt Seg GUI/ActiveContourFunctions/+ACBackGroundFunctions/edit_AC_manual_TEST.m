%%  TESTS FOR EDIT_AC_MANUAL

% assumes the existence of small_im

%% minimum inputs
[radii,angles,center] = ACBackGroundFunctions.edit_AC_manual(small_im);
radii
angles
center

%% with centre

[radii,angles,center] = ACBackGroundFunctions.edit_AC_manual(small_im,round(fliplr(size(small_im))/3));
radii
angles
center


%% with radi

[radii,angles,center] = ACBackGroundFunctions.edit_AC_manual(small_im,round(fliplr(size(small_im))/3),12*ones(12,1));
radii
angles
center

%% with radii and angles (doesn't quite work)

angles = sort(2*pi*rand(12,1));
angles2 = angles;

[radii,angles,center] = ACBackGroundFunctions.edit_AC_manual(small_im,round(fliplr(size(small_im))/3),12*ones(12,1),angles);
radii
angles
center

angles2==angles


