function  [predicted_im, decision_im, filtered_image]=classifyImage2StageWhole(cCellSVM,image,trapOutline)
% [predicted_im, decision_im, filtered_image]=classifyImage2StageWhole(cCellSVM,image,trapOutline)
%
%
% Elco. Looks to me like this is just the same as classifyImage2Stage
% non of the extra variables seem to be used since imageTrapsOnly is just
% image and tempCurrentTPOutline Doesn't get used.
if nargin<2 || isempty(trapOutline)
    trapOutline=imdilate(cCellSVM.cTrap.trapOutline,cCellSVM.se.se1);
end

decision_im=ones(size(image,1),size(image,2));
predicted_im=zeros(size(image,1),size(image,2));
rowTraps=[1 size(image,1)];
colTraps=[1 size(image,2)];
tempCurrenTpOutline=cCellSVM.cTrap.currentTpOutline;


% % only process the part of the image that is within the trap area. 
% tpLocCol=find(min(trapOutline,[],1)==0);
% tpLocRow=find(min(trapOutline,[],2)==0);
% rowTraps=[];colTraps=[];
% rowTraps(1)=min(tpLocRow);rowTraps(2)=max(tpLocRow);
% colTraps(1)=min(tpLocCol);colTraps(2)=max(tpLocCol);
% 
% %overwrite size of current trap to make sure getFilterImage works properly,
% %re-write at end of function
% cCellSVM.cTrap.currentTpOutline=cCellSVM.cTrap.currentTpOutline(rowTraps(1):rowTraps(2),colTraps(1):colTraps(2),:);
% 
% imageTrapsOnly=image(rowTraps(1):rowTraps(2),colTraps(1):colTraps(2),:);
% trapOutlineTrapsOnly=trapOutline(rowTraps(1):rowTraps(2),colTraps(1):colTraps(2),:);

imageTrapsOnly=image;
trapOutlineTrapsOnly=trapOutline;

labels=ones(size(image,1)*size(image,2),1);
dec_values=ones(size(image,1)*size(image,2),1);
predict_label=zeros(size(image,1)*size(image,2),1);
dec_valuesTrapsOnly=ones(size(imageTrapsOnly,1)*size(imageTrapsOnly,2),1);
predict_labelTrapsOnly=zeros(size(imageTrapsOnly,1)*size(imageTrapsOnly,2),1);


%get the filteredImage of just the part near traps
filtered_image=getFilteredImage(cCellSVM,imageTrapsOnly);

filtered_image=double(filtered_image(~trapOutlineTrapsOnly(:),:));
filtered_image=(filtered_image - repmat(cCellSVM.scaling.min,size(filtered_image,1),1));
filtered_image=filtered_image*spdiags(1./(cCellSVM.scaling.max-cCellSVM.scaling.min)',0,size(filtered_image,2),size(filtered_image,2));

% sparseTOnly=sparse(filtered_image);
[predict_labelLin, ~, dec_valuesLin] = predict(labels(~trapOutlineTrapsOnly(:)),sparse(filtered_image) , cCellSVM.SVMModelLinear); % test the training data]\
% [predict_labelLin, ~, dec_valuesLin] = predict(labels(~trapOutline(:)), sparse(filtered_image(~trapOutline(:),:)), cCellSVM.SVMModelLinear); % test the training data]\

dec_valuesTrapsOnly(~trapOutlineTrapsOnly(:))=dec_valuesLin(:);
dec_valuesTrapsOnly(trapOutlineTrapsOnly(:))=2;

predict_labelTrapsOnly(~trapOutlineTrapsOnly(:))=predict_labelLin(:);
predict_labelTrapsOnly(trapOutlineTrapsOnly(:))=0;


b=dec_valuesLin;
[B,IX]=sort(b(:),'ascend');

% l=sum(~trapOutlineTrapsOnly(:))*.02;
% loc=IX(1:(round(l)));

% [predict_label_kernel, ~, dec_values_kernel] = svmpredict(ones(length(loc),1), (filtered_image(loc,:)), cCellSVM.SVMModel); % test the training data]\
% [dec_values_kernel] = cuSVMPredict(single(filtered_image(loc,:)),cCellSVM.SVMModelGPU.svs, cCellSVM.SVMModelGPU.alphas,cCellSVM.SVMModelGPU.beta,cCellSVM.SVMModelGPU.gamma,1); % test the training data]\

%reset the gpudevice or it causes problems later
% gpudev=gpuDevice;
% reset(gpudev);

% dec_valuesTrapsOnly(loc)=-dec_values_kernel;
% predict_labelTrapsOnly(loc)=dec_values_kernel<0;

predicted_imTrapsOnly=reshape(predict_labelTrapsOnly,[size(imageTrapsOnly,1) size(imageTrapsOnly,2)]);
decision_imTrapsOnly=reshape(dec_valuesTrapsOnly(:,1),[size(imageTrapsOnly,1) size(imageTrapsOnly,2)]);

decision_im(rowTraps(1):rowTraps(2),colTraps(1):colTraps(2))=decision_imTrapsOnly;
predicted_im(rowTraps(1):rowTraps(2),colTraps(1):colTraps(2))=predicted_imTrapsOnly;

cCellSVM.cTrap.currentTpOutline=tempCurrenTpOutline;

