function [ radii_mat ] = reorder_radii( radii_mat)
% [ reordered_radii_mat ] = reorder_radii( radii_mat)
%
% for reordering for probability estimate. reorder radii (i.e. permute but
% keep order either unchanged or flipped) so that the first row is ordered
% longest first and largest neighbouring entry in position 2.
% e.g [1 3 4 2] -> [4 3 1 2]
%     [5 7 4 1] -> [7 5 1 4]
% other rows are reorderd according to row 1.


%make max radii first entry
[~,mi] = max(radii_mat(1,:));

radii_mat = circshift(radii_mat,-(mi-1),2);

% flip so 2nd entry is 2nd largest
if radii_mat(1,2)<radii_mat(1,end)
    radii_mat = fliplr(radii_mat);
    radii_mat = circshift(radii_mat,1,2);
    
end
end

