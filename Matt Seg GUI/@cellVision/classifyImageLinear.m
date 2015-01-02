function  [predicted_im, decision_im, filtered_image]=classifyImageLinear(cCellSVM,image,trapOutline)
%cCellSVM is a cellVision model
%image is a cell array of image stacks of the right depth (number of
%channels/depths) for the cCellVision model


if nargin<2
    trapOutline=imdilate(cCellSVM.cTrap.trapOutline,cCellSVM.se.se1);
end

filtered_image=double(getFilteredImage(cCellSVM,image));

filtered_image=(filtered_image - repmat(cCellSVM.scaling.min,size(filtered_image,1),1));
filtered_image=filtered_image*spdiags(1./(cCellSVM.scaling.max-cCellSVM.scaling.min)',0,size(filtered_image,2),size(filtered_image,2));

labels=ones(size(image,1)*size(image,2),1);

dec_values=zeros(size(image,1)*size(image,2),1);
predict_label=zeros(size(image,1)*size(image,2),1);

[predict_labelLin, ~, dec_valuesLin] = predict(labels(~trapOutline(:)), sparse(filtered_image(~trapOutline(:),:)), cCellSVM.SVMModelLinear); % test the training data]\
% [predict_label, accuracy, dec_values] = predict(ones(size(image,1)*size(image,2),1), (filtered_image), cCellSVM.SVMModel); % test the training data]\

dec_values(~trapOutline(:))=dec_valuesLin(:);
dec_values(trapOutline(:))=2;

predict_label(~trapOutline(:))=predict_labelLin(:);
predict_label(trapOutline(:))=0;

% dec_values=1./(1+exp(-dec_values))-.5;
predicted_im=reshape(predict_label,[size(image,1) size(image,2)]);
decision_im=reshape(dec_values(:,1),[size(image,1) size(image,2)]);
