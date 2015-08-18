function  [predicted_im decision_im filtered_image]=classifyImage2Stage(cCellSVM,image,trapOutline)

if nargin<2 || isempty(trapOutline)
    trapOutline=imdilate(cCellSVM.cTrap.trapOutline,cCellSVM.se.se1);
end

filtered_image=getFilteredImage(cCellSVM,image);
filtered_image=double(filtered_image);
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


b=dec_values;
b=abs(b-cCellSVM.twoStageThresh);
[B,IX]=sort(b(:),'ascend');

l=sum(~trapOutline(:))*.015; %.035
loc=IX(1:(round(l)));

[predict_label_kernel, ~, dec_values_kernel] = svmpredict(ones(length(loc),1), (filtered_image(loc,:)), cCellSVM.SVMModel); % test the training data]\

dec_values(loc)=dec_values_kernel;
predict_label(loc)=predict_label_kernel;

    predicted_im=reshape(predict_label,[size(image,1) size(image,2)]);
decision_im=reshape(dec_values(:,1),[size(image,1) size(image,2)]);