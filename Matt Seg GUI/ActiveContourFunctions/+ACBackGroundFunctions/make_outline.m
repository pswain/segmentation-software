function OutputImage = make_outline(InputImage,LogicalPoints)
%make_outline(InputImage.LogicalImage) makes the true points in the
%LogicalPoints in InputImage red.
% Input image and LogicalPoints are of the same size. Both are nxm matrices
InputImage = double(InputImage);
InputImage = 0.7*InputImage/max(InputImage(:));
InputImage2 = InputImage;
InputImage2(LogicalPoints) = 0.95;
OutputImage = cat(3,InputImage2,InputImage,InputImage);


end

