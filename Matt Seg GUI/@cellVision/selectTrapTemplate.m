function selectTrapTemplate(cCellVision,image)
% function selectTrapTemplate(cCellVision,image)
% sets the cTrap field of the cCellVion based on a rectangle selected from
% an image. This is the first stage in starting to train a new cellVision
% model. 
% it is primarily used through the 
cTrap = struct;
fprintf('\n\nplease use the mouse to select a rectangle around a trap\n\n')
h=figure;
set(gcf,'name','select a rectangle around a trap','NumberTitle','off');imshow(image,[]);
rect = getrect(gca);
close(h);
% ensure the trap size is odd
rect(3:4) = rect(3:4) - mod(rect(3:4),2)+1;
% make an integer
rect = round(rect);
cTrap.bb_width = (rect(3)-1)/2;
cTrap.bb_height = (rect(4)-1)/2;
% obtain the trap image
cTrap.trap1= image(rect(2):(rect(2)+rect(4)-1),rect(1):(rect(1)+rect(3)-1));
figure;imshow(cTrap.trap1,[]);
fprintf('\n\n please close the trap image when finished inspecting \n\n');
uiwait();
cCellVision.cTrap = cTrap;

end


