function  [predicted_im decision_im filtered_image]=classifyImage2Stage(cCellSVM,image)

filtered_image=getFilteredImage(cCellSVM,image);

filtered_image=(filtered_image - repmat(cCellSVM.scaling.min,size(filtered_image,1),1));
filtered_image=filtered_image*spdiags(1./(cCellSVM.scaling.max-cCellSVM.scaling.min)',0,size(filtered_image,2),size(filtered_image,2));


[predict_label, ~, dec_values] = predict(ones(size(image,1)*size(image,2),1), sparse(filtered_image), cCellSVM.SVMModelLinear); % test the training data]\
% [predict_label, accuracy, dec_values] = predict(ones(size(image,1)*size(image,2),1), (filtered_image), cCellSVM.SVMModel); % test the training data]\

trapOutline=imdilate(cCellSVM.cTrap.trapOutline,cCellSVM.se.se1);
dec_values(trapOutline(:))=2;
b=dec_values;
[B,IX]=sort(b(:),'ascend');
% [B,IX]=sort(dec_values(:),'ascend');
l=length(IX)*.035;
loc=IX(1:(round(l)));

% 
% bw=dec_values<thresh;
% bw=imdilate(bw,se1);
% loc=bw>0;
% [predict_label_kernel, ~, dec_values_kernel] = svmpredict(ones(sum(loc),1), (filtered_image(loc,:)), cCellSVM.SVMModel); % test the training data]\


[predict_label_kernel, ~, dec_values_kernel] = svmpredict(ones(length(loc),1), (filtered_image(loc,:)), cCellSVM.SVMModel); % test the training data]\

dec_values(loc)=dec_values_kernel;
predict_label(loc)=predict_label_kernel;

predicted_im=reshape(predict_label,[size(image,1) size(image,2)]);
decision_im=reshape(dec_values(:,1),[size(image,1) size(image,2)]);