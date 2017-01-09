function [ radii_mat ] = reorder_radii( radii_mat)
% [ reordered_radii_mat ] = reorder_radii( radii_mat)
%
% for reordering for probability estimate. reorder radii (i.e. permute but
% keep order either unchanged or flipped) so that each row is ordered
% longest first and largest neighbouring entry in position 2.
% e.g [1 3 4 2] -> [4 3 1 2]
%     [5 7 4 1] -> [7 5 1 4]


for i=1:size(radii_mat,1)
    
    radii = radii_mat(i,:);
    %make max radii first entry
    [~,mi] = max(radii);
    
    %TODO - remove this bit
    % included for back compatibility with matlab 2013b
    if nargin(@circshift) == 3
        radii = circshift(radii,-(mi-1),2);
    else
        radii = circshift(radii,-(mi-1));
    end
    % flip so 2nd entry is 2nd largest
    if radii(2)<radii(end)
        radii = fliplr(radii);
        
        %TODO - remove this bit
        % included for back compatibility with matlab 2013b
        if nargin(@circshift) == 3
            radii = circshift(radii,1,2);
        else
            radii = circshift(radii,1);
        end
    end
    radii_mat(i,:) = radii;
end
end

