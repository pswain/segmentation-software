function  [predicted_im, decision_im, filtered_image,raw_SVM_res]=classifyImage2Stage(cCellSVM,image,trapOutline)
% [predicted_im decision_im filtered_imagemraw_SVM_res]=classifyImage2Stage(cCellSVM,image,trapOutline)
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
%                       dialation of cCellSVM.cTrap.trapOutline. If it is
%                       greyscale then the grey scale image is passed to
%                       the feature function but for classification any
%                       non-zero pixel is considered a trap pixel.
%
% predicted_im      :   binary of whether a pixel is considered a cell
%                       centre pixel or not based on two stage threshold of
%                       0.
% decision_im       :   grayscale image of 'liklihood'  of being a cell
%                       centre. Negative is more likely, 0 is the default
%                       threshold.
%                       Matt was at some point returning this not as an
%                       image but as an image stack, with the second image
%                       slice being a probability to be an edge from a multiclass
%                       classifier. This functionality is still present but
%                       I think it is unused. Just be warned, it may be
%                       good to take the first slice of this value only.
% filtered_image    :   array of filter values used. Not reshaped, so each
%                       row is the filter values for the corresponding
%                       pixel.
% raw_raw_SVM_res   :   the raw decision image values for the two
%                       classifiers (cell to background and inner to edge)
%                       as an [n x n x 2] stack. NOTE unlike decision image
%                       they do not have the traps blotted out. Assume you
%                       know what to do.
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
    trapOutline=imdilate(cCellSVM.cTrap.trapOutline,cCellSVM.se.se2);
end
% protection in case cellVision hasn't been trained yet.
if ~isempty(cCellSVM.scaling.min)
    filtered_image=getFilteredImage(cCellSVM,image,trapOutline);
    trapOutline = trapOutline>=1;
    filtered_image=double(filtered_image);
    filtered_image=(filtered_image - repmat(cCellSVM.scaling.min,size(filtered_image,1),1));
    filtered_image=filtered_image*spdiags(1./(cCellSVM.scaling.max-cCellSVM.scaling.min)',0,size(filtered_image,2),size(filtered_image,2));
else
    filtered_image = zeros(size(image,1),size(image,2));
    predicted_im = filtered_image;
    decision_im = filtered_image;
    raw_SVM_res = [];
    return
end

labels=ones(size(image,1)*size(image,2),1);
dec_values=zeros(size(image,1)*size(image,2),1);
dec_values1=zeros(size(image,1)*size(image,2),1);
dec_values2=zeros(size(image,1)*size(image,2),1);

predict_label=zeros(size(image,1)*size(image,2),1);

% simple linear prediction
if ~isempty(cCellSVM.SVMModelLinear)
    % mex file that does the linear prediction.
    [predict_labelLin, ~, dec_valuesLin] = predict(labels(~trapOutline(:)), sparse(filtered_image(~trapOutline(:),:)), cCellSVM.SVMModelLinear); % test the training data]\
    dec_values(~trapOutline(:))=dec_valuesLin(:,1);
    
    % set trap pixels to some high value
    dec_values(trapOutline(:))=max(10,2*abs(cCellSVM.twoStageThresh));
    if size(dec_valuesLin,2)>2
        dec_values(~trapOutline(:))=-dec_valuesLin(:,2);
        dec_values2(~trapOutline(:))=dec_valuesLin(:,3);
        dec_values2(trapOutline(:))=0;
    else
        dec_values2=[];
    end
    
    
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
        IX(ismember(IX,find(trapOutline))) = [];
        
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
    if ~isempty(dec_values2)
        decision_im2=reshape(dec_values2(:,1),[size(image,1) size(image,2)]);
        decision_im(:,:,2)=decision_im2;
    end
end

% only used if doing to edge/centre classifer.
raw_SVM_res = [];
% if using two classifiers (other and centre|edge and centre|edge).
if ~isempty(cCellSVM.SVMModelCellToOuterLinear) && ~isempty(cCellSVM.SVMModelInnerToEdgeLinear)
    [predict_label1lin, ~, dec_values1lin] = predict(labels(~trapOutline(:)), sparse(filtered_image(~trapOutline(:),:)), cCellSVM.SVMModelCellToOuterLinear); % test the training data]\
    dec_values1(~trapOutline(:))=dec_values1lin(:,1);
    
    predict_label1(~trapOutline(:))=predict_label1lin(:);
    
    [predict_label2lin, ~, dec_values2lin] = predict(labels(~trapOutline(:)), sparse(filtered_image(~trapOutline(:),:)), cCellSVM.SVMModelInnerToEdgeLinear); % test the training data]\
    dec_values2(~trapOutline(:))=dec_values2lin(:,1);
    
    predict_label2(~trapOutline(:))=predict_label2lin(:);
    
    % make predict labels. True for centres.
    predict_label = predict_label1 & predict_label2;
    predict_label(trapOutline(:)) = false;
    predicted_im=reshape(predict_label,[size(image,1) size(image,2)]);
    
    % slightly complicated, but gives log bayes factor for centres assuming
    % that the other two quantities are the log bayes factor for edges or
    % centre and for edges.
    dec_values = dec_values1 + dec_values2 ...
        + log((1 + exp(-dec_values1) + exp(-dec_values2))) ;
    
    dec_values(trapOutline(:))=max(10,2*abs(cCellSVM.twoStageThresh));
    
    decision_im=reshape(dec_values(:,1),[size(image,1) size(image,2)]);
    
    raw_SVM_res = cat(3, ...
    reshape(dec_values1(:,1),[size(image,1) size(image,2)]),...
    reshape(dec_values2(:,1),[size(image,1) size(image,2)]));
end

end