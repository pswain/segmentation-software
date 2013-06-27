function  [predicted_im decision_im filtered_image]=classifyImageLinear(cCellSVM,image)


if isempty(cCellSVM.cTrap)
    filtered_image=cCellSVM.createImFilterSetCellAsic(image);
else
    filtered_image=cCellSVM.createImFilterSetCellTrap(image);
end

filtered_image=(filtered_image - repmat(cCellSVM.scaling.min,size(filtered_image,1),1));
filtered_image=filtered_image*spdiags(1./(cCellSVM.scaling.max-cCellSVM.scaling.min)',0,size(filtered_image,2),size(filtered_image,2));

labels=ones(size(image,1)*size(image,2),1);

[predict_label, ~, dec_values] = predict(labels, sparse(filtered_image), cCellSVM.SVMModelLinear); % test the training data]\
% [predict_label, accuracy, dec_values] = predict(ones(size(image,1)*size(image,2),1), (filtered_image), cCellSVM.SVMModel); % test the training data]\


predicted_im=reshape(predict_label,[size(image,1) size(image,2)]);
decision_im=reshape(dec_values(:,1),[size(image,1) size(image,2)]);