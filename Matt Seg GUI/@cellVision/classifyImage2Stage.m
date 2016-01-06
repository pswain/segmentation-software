function  [predicted_im, decision_im, filtered_image]=classifyImage2Stage(cCellSVM,image,trapOutline)
% [predicted_im decision_im filtered_image]=classifyImage2Stage(cCellSVM,image,trapOutline)
%
% runs the two stage classification, if the model is linear it will just run
% the linear segmentation.
% 
% cCellSVM          :   object of the cellVision class.
% image             :   cell array of image stacks used in generating
%                       decision image. Returned from
%                       timelapseTraps.returnSegmentationTrapStack
% trapOutline       :   optional. grayscale or binary image of trap pixels
%                       which are removed from analysis. Defaults to a
%                       dialation of cCellSVM.cTrap.trapOutline. Any
%                       non-zero pixel is considered a trap pixel.
%
% predicted_im      :   binary of whether a pixel is considered a cell
%                       centre pixel or not based on two stage threshold of
%                       0.
% decision_im       :   grayscale image of 'liklihood'  of being a cell
%                       centre. Negative is more likely, 0 is the default
%                       threshold.
% filtered_image    :   array of filter values used. Not reshaped, so each
%                       row is the filter values for the corresponding
%                       pixel.
%                       
% calculates the transformation image using the getFilteredImage function
% of the cellVision class. Applies the necessary transformations and then
% the linear classification to all non trap pixels (trap pixels being set
% to 2 in the decision image and 0 in the prediction image).
% If the model is a two stage model, pixels within an absolute distance of
% cCellSVM.linearToTwoStageParams.threshold of the twoStageThreshold are
% subjected to the 2nd stage (SVM?). An upper bound 
%   cCellSVM.linearToTwoStageParams.upperBound
% pixels, either defined as a fraction of non cell pixels or as an absolute
% number is also applied to ensure a reasonable computational time. 
%       cCellSVM.linearToTwoStageParams.upperBoundType
% is used to determine if the bound is 'fraction' or 'absolute'.
%


if nargin<3 || isempty(trapOutline)
    trapOutline=imdilate(cCellSVM.cTrap.trapOutline,cCellSVM.se.se1);
end

filtered_image=getFilteredImage(cCellSVM,image,trapOutline);
filtered_image=double(filtered_image);
filtered_image=(filtered_image - repmat(cCellSVM.scaling.min,size(filtered_image,1),1));
filtered_image=filtered_image*spdiags(1./(cCellSVM.scaling.max-cCellSVM.scaling.min)',0,size(filtered_image,2),size(filtered_image,2));

labels=ones(size(image,1)*size(image,2),1);
dec_values=zeros(size(image,1)*size(image,2),1);
dec_values2=zeros(size(image,1)*size(image,2),1);

predict_label=zeros(size(image,1)*size(image,2),1);

% mex file that does the linear prediction.
[predict_labelLin, ~, dec_valuesLin] = predict(labels(~trapOutline(:)), sparse(filtered_image(~trapOutline(:),:)), cCellSVM.SVMModelLinear); % test the training data]\

dec_values(~trapOutline(:))=dec_valuesLin(:,3);
dec_values(trapOutline(:))=0;
dec_values2(~trapOutline(:))=dec_valuesLin(:,2);
dec_values2(trapOutline(:))=2;


predict_label(~trapOutline(:))=predict_labelLin(:);
predict_label(trapOutline(:))=0;

if ~isempty(cCellSVM.SVMModel) && ~strcmp(cCellSVM.method,'linear')
    %if the model has a two stage component apply it to those elements
    %closest to the twoStageThreshold.
    b=dec_values;
    b=abs(b-cCellSVM.twoStageThresh);
    [B,IX]=sort(b(:),'ascend');
    
    % look at only pixels within a certain distance of the two stage
    % threshold.
    IX(B>cCellSVM.linearToTwoStageParams.threshold) = [];
    
    % apply an upper boundary of the number of pixels to apply the two
    % stage model to
    switch cCellSVM.linearToTwoStageParams.upperBoundType
        case 'fraction'
            l=round(sum(~trapOutline(:))*cCellSVM.linearToTwoStageParams.upperBound);
        case 'absolute'
            l=round(cCellSVM.linearToTwoStageParams.upperBound);
        otherwise
            error('linearToTwoStageParams.upperBoundType should be fraction or absolute')
    end
    loc=IX(1:min(l,length(IX)));
    
    % libsvm method for two stage model.
    [predict_label_kernel, ~, dec_values_kernel] = svmpredict(ones(length(loc),1), (filtered_image(loc,:)), cCellSVM.SVMModel); % test the training data]\
    
    dec_values(loc)=dec_values_kernel;
    predict_label(loc)=predict_label_kernel;
end
predicted_im=reshape(predict_label,[size(image,1) size(image,2)]);
decision_im=reshape(dec_values(:,1),[size(image,1) size(image,2)]);