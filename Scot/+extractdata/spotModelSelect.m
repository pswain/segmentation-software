function [num_spots] = spotModelSelect(ImData,varargin)
% Function arguments: [ImData,Wmin,'display']
% (required) ImData = Path to the segmented cell image. This must be
% cropped to a tight bounding rectangle.
% (optional) Wmin = The expected spot/cell size ratio. If unsupplied,
% defaults to 0.25. Decrease[increase] for smaller[larger] spots.
% (optional) 'display' = Will display the fitted bivariate Gaussians.
% It is advisable to run the function several times, since there is a
% random element to the gradient descent algorithm (which might be stuck in
% local minima).

%parameters for PSO optimisation. See help of pso_Trelea_vectorised for more info.
PSO_parameters = [8000 6000 30 2 2 0.9 0.4 1500 1e-25 250 NaN 1 0];

nVarargs = length(varargin);

if nVarargs == 0
        Wmin = 0.25;
        display_on = 0;
elseif nVarargs == 1
        Wmin = varargin{1};
        display_on = 0;
elseif nVarargs == 2 && strcmp(varargin{2}, 'display')
        Wmin = varargin{1};
        display_on = 1;
else
    error('At most two optional arguments expected!')
end
    
% Load image
Dk = double(ImData(:,:,1));

% Channels
Kx = 1:1:numel(Dk(1,:)); % square grids only
Ky = 1:1:numel(Dk(:,1)); % square grids only
[KKx,KKy] = meshgrid(Kx,Ky);

% Get some parameter boundaries
Bmax = max(max(Dk));
Bmax = Bmax(1);
Amax = max(max(Dk));
Amax = Amax(1);
Wmax = numel(Dk(1,:))/8;% %

% Not normalized Gaussian "pdf"
nmvnpdf = @(xx,yy,x0,y0,ww) exp(-0.5.*((((xx-x0).^2)./(ww.^2))+(((yy-y0).^2)./(ww.^2))-0));

%% Inference
options = optimset('Display','off');
warning off;

% % M = 0
% R0 = B
R0_best = rand;
fval0_best = +Inf;
grad0_best = [];
hess0_best = [];
fit_count0 = 0;

anM0 = @(R) M0(R,KKx,KKy,Dk);

% Boundaries
lb = [0];
ub = [Bmax];

while fval0_best == +Inf

    for i=1:1:1
%         if fit_count0 < 2
%             R0 = mean(Dk(:));
%         else
%             R0 = Bmax*rand;
%         end
         try
            
            [optOUT] = pso_Trelea_vectorized_mod(anM0,1,7,[lb ub],0,PSO_parameters,'');
            
            R0 = optOUT(1);
            fval0 = optOUT(2);
            
            hess0 = hessiancsd(anM0,R0);
            
            %Chris' original line from fmincon.
            %[R0,fval0,exitflag0,lambda,output0,grad0,hess0] = fmincon(anM0,R0,[],[],[],[],lb,ub,[],options);
        catch
            continue
        end
        if sum(R0<0)==0 && fval0<fval0_best
            R0_best = R0;
            fval0_best = fval0;
            %grad0_best = grad0;
            %hess0_best = hess0;
        end
    end
    fit_count0 = fit_count0 + 1;
end

% % M = 1
% R1 = (B,A,x0,y0,W)
R1_best = rand(1,5);
fval1_best = +Inf;
grad1_best = [];
hess1_best = [];
fit_count1 = 0;

anM1 = @(R) M1(R,KKx,KKy,Dk);

% Boundaries
lb = [0,0,0,0,Wmin]';
ub = [Bmax,Amax,max(Kx),max(Ky),Wmax]';


% Use the following for better initial values
DDk = conv2(ones(4),Dk); % convolve-smooth the image
[igx,igy] = find(max(max(DDk))==DDk); % note that x-y are reversed

while fval1_best == +Inf

    for i=1:1:1
%         if fit_count1 < 2
%             % R1 with a better guess at the mean (with added noise) & amplitude & background
%             R1 = [mean(Dk(:)),max(Dk(:))-mean(Dk(:)),igy + (max(Kx)/100)*randn,igx + (max(Ky)/100)*randn,Wmax*rand];
%         else
%             % Random initial values
%             R1 = [Bmax*rand,Amax*rand,max(Kx)*rand,max(Ky)*rand,Wmax*rand];
%         end

        try
            
            [optOUT] = pso_Trelea_vectorized_mod(anM1,5,7,[lb ub],0,PSO_parameters,'');
            
            R1 = optOUT(1:(end-1))';
            fval1 = optOUT(end);
            
            hess1 = hessiancsd(anM1,R1);
            
            %chris' original line
            %[R1,fval1,exitflag1,lambda,output1,grad1,hess1] = fmincon(anM1,R1,[],[],[],[],lb,ub,[],options);
        catch
            continue
        end
        if sum(R1<0)==0 && fval1<fval1_best
            fval1_best = fval1;
            R1_best = R1;
            %grad1_best = grad1;
            hess1_best = hess1;
        end
    end
    fit_count1 = fit_count1 + 1;
end

% % M = 2
% R2 = (B,A1,x01,y01,W1,A2,x02,y02,W2)

% Optimize parameter subset for a single spot (most bright)
R2_1_best = rand(1,5);
fval2_1_best = +Inf;
anM2_1 = @(R) M1(R,KKx,KKy,Dk);
fit_count2_1 = 0;

% Boundaries
lb = [0,0,0,0,Wmin]';
ub = [Bmax,Amax,max(Kx),max(Ky),Wmax]';

% Use the following for better initial values
DDk = conv2(ones(4),Dk); % convolve-smooth the image
[igx1,igy1] = find(max(max(DDk))==DDk); % note that x-y are reversed

% Should improve this!
igx1 = igx1(1);
igy1 = igy1(1);

while fval2_1_best == +Inf

    for i=1:1:1
%         if fit_count2_1 < 2
%             R2_1 = [mean(Dk(:)),max(Dk(:))-mean(Dk(:)),igy1 + (max(Kx)/100)*randn,igx1 + (max(Ky)/100)*randn,Wmax*rand];
%         else
%             R2_1 = [Bmax*rand,Amax*rand,max(Kx)*rand,max(Ky)*rand,Wmax*rand];
%         end
         try
             
            [optOUT] = pso_Trelea_vectorized_mod(anM2_1,5,7,[lb ub],0,PSO_parameters,'');
            
            R2_1 = optOUT(1:(end-1))';
            fval2_1 = optOUT(end);
            
            %chris' original line
            %[R2_1,fval2_1] = fmincon(anM2_1,R2_1,[],[],[],[],lb,ub,[],options);
        catch
            continue
        end
        if sum(R2_1<0)==0 && fval2_1<fval2_1_best
            fval2_1_best = fval2_1;
            R2_1_best = R2_1;
        end
    end
    fit_count2_1 = fit_count2_1 + 1;
end

% Optimize parameter subset for the second spot (least bright)
R2_2_best = rand(1,5);
fval2_2_best = +Inf;
anM2_1 = @(R) M1(R,KKx,KKy,Dk);
fit_count2_1 = 0;

% Boundaries
lb = [0,0,0,0,Wmin]';
ub = [Bmax,Amax,max(Kx),max(Ky),Wmax]';

% To get a good mode position candidate for the second spot, exclude a region ~2W around the center of the 1st spot
DkEx = Dk;
DkEx([max(1,round(R2_1_best(4)-(2*R2_1_best(5)))):min(max(Kx),round(R2_1_best(4)+(2*R2_1_best(5))))],[max(1,round(R2_1_best(3)-(2*R2_1_best(5)))):min(max(Ky),round(R2_1_best(3)+(2*R2_1_best(5))))]) = 0;
% DkEx([max(1,round(R2_1_best(4)-(R2_1_best(5)))):min(max(Kx),round(R2_1_best(4)+(R2_1_best(5))))],[max(1,round(R2_1_best(3)-(R2_1_best(5)))):min(max(Ky),round(R2_1_best(3)+(R2_1_best(5))))]) = 0;
DDkEx = conv2(ones(4),DkEx); % convolve-smooth
[igx2,igy2] = find(max(max(DDkEx))==DDkEx);

% Should improve this!
igx2 = igx2(1);
igy2 = igy2(1);

while fval2_2_best == +Inf

    for i=1:1:1
%         if fit_count2_1 < 2
%             R2_2 = [mean(Dk(:)),max(DkEx(:))-mean(Dk(:)),igy2 + (max(Kx)/100)*randn,igx2 + (max(Ky)/100)*randn,Wmax*rand];
%         else
%             R2_2 = [Bmax*rand,Amax*rand,max(Kx)*rand,max(Ky)*rand,Wmax*rand];
%         end
        try
            
            [optOUT] = pso_Trelea_vectorized_mod(anM2_1,5,7,[lb ub],0,PSO_parameters,'');
            
            R2_2 = optOUT(1:(end-1))';
            fval2_2 = optOUT(end);
            
            %Chris' original line
            %[R2_2,fval2_2] = fmincon(anM2_1,R2_2,[],[],[],[],lb,ub,[],options);
        catch
            continue
        end
        if sum(R2_2<0)==0 && fval2_2<fval2_2_best
            fval2_2_best = fval2_2;
            R2_2_best = R2_2;
        end
    end
    fit_count2_1 = fit_count2_1 + 1;
end

% Final optimization of entire parameter set
R2_best = rand(1,9);
fval2_best = +Inf;
%grad2_best = [];
hess2_best = [];
anM2 = @(R) M2(R,KKx,KKy,Dk);
fit_count2 = 0;

% Boundaries
lb = [0,0,0,0,Wmin,0,0,0,Wmin]';
ub = [Bmax,Amax,max(Kx),max(Ky),Wmax,Amax,max(Kx),max(Ky),Wmax]';

while fval2_best == +Inf;
    for i=1:1:1    
%         if fit_count2 < 2
%             R2 = [R2_1_best,R2_2_best(2:5)];
%         else
%             R2 = [R2_1_best,Amax*rand,max(Kx)*rand,max(Ky)*rand,Wmax*rand];
%         end
        try
            
            [optOUT] = pso_Trelea_vectorized_mod(anM2,9,7,[lb ub],0,PSO_parameters,'');
            
            R2 = optOUT(1:(end-1))';
            fval2 = optOUT(end);
            
            hess2 = hessiancsd(anM2,R2);
            
            %Chris' original line
            %[R2,fval2,exitflag2,lambda,output2,grad2,hess2] = fmincon(anM2,R2,[],[],[],[],lb,ub,[],options);
        catch
            continue
        end
        if sum(R2<0)==0 && fval2<fval2_best
            fval2_best = fval2;
            R2_best = R2;
            %grad2_best = grad2;
            hess2_best = hess2;
        end
    end
    fit_count2 = fit_count2 + 1;
end

% Display model fitting
if display_on == 1
    figure(1)
    subplot(2,3,1)
    surf(KKx,KKy,Dk); shading flat; view([0,90]); colormap('bone');
    set(gca,'XLim',[min(Kx),max(Kx)]); set(gca,'YLim',[min(Kx),max(Kx)]);
    title('Image');

    subplot(2,3,2)
    contour(Dk); colormap('bone');
    set(gca,'XLim',[min(Kx),max(Kx)]); set(gca,'YLim',[min(Kx),max(Kx)]);
    title('Image-Contour');

    subplot(2,3,4)
    contour(R1_best(1) + R1_best(2)*nmvnpdf(KKx,KKy,R1_best(3),R1_best(4),R1_best(5)));
    set(gca,'XLim',[min(Kx),max(Kx)]); set(gca,'YLim',[min(Kx),max(Kx)]);
    title('Inference: M=1');

    subplot(2,3,5)
    contour(R2_best(1) + R2_best(2)*nmvnpdf(KKx,KKy,R2_best(3),R2_best(4),R2_best(5)) + + R2_best(6)*nmvnpdf(KKx,KKy,R2_best(7),R2_best(8),R2_best(9)));
    set(gca,'XLim',[min(Kx),max(Kx)]); set(gca,'YLim',[min(Kx),max(Kx)]);
    title('Inference: M=2');
    colormap('bone');
end

%% Reliabilities and model selection

% Covariance matrices from estimated hessians
S0 = 2*(hess0_best \ eye(size(hess0_best)));
S1 = 2*(hess1_best \ eye(size(hess1_best)));
S2 = 2*(hess2_best \ eye(size(hess2_best))); % fast way to invert matrices accurately

% % Marginal posterior pdfs (model evidence)
E0 = -Inf;
E1 = -Inf;
E2 = -Inf;

m = 0;
if det(hess0_best) ~= 0 % catch singular hessian
    E0 = log((factorial(m)*((4*pi)^(numel(R0_best)/2)))*(1/(Bmax*((max(Kx)-min(Kx))*(max(Kx)-min(Ky))*Amax*Wmax)^(m)))*real(1/sqrt(det(hess0_best)))) + (-0.5*fval0_best);
end
m = 1;
if det(hess1_best) ~= 0 % catch singular hessian
    E1 = log((factorial(m)*((4*pi)^(numel(R1_best)/2)))*(1/(Bmax*((max(Kx)-min(Kx))*(max(Ky)-min(Ky))*Amax*Wmax)^(m)))*real(1/sqrt(det(hess1_best)))) + (-0.5*fval1_best);
end
m = 2;
if det(hess2_best) ~= 0 % catch singular hessian
    E2 = log((factorial(m)*((4*pi)^(numel(R2_best)/2)))*(1/(Bmax*((max(Kx)-min(Kx))*(max(Ky)-min(Ky))*Amax*Wmax)^(m)))*real(1/sqrt(det(hess2_best)))) + (-0.5*fval2_best);
end

% Normalize
Enorm = max([E0,E1,E2]);
E0 = (E0-Enorm);
E1 = (E1-Enorm);
E2 = (E2-Enorm);

E0 = exp(E0);
E1 = exp(E1);
E2 = exp(E2);

Enorm = E0+E1+E2;
E0 = E0/Enorm;
E1 = E1/Enorm;
E2 = E2/Enorm;

if display_on == 1
    figure(1)
    subplot(2,3,[3,6])
    plot([0,1,2],[E0,E1,E2],'ko-');
    xlabel('M');
    ylabel('Marginal posterior prob.');
    title('Model selection');
    set(gcf,'position',[617,336,774,391])
end

num_spots =[E0,E1,E2];

end




function [ chi2 ] = M0( R,KKx,KKy,Dk )

chi2 = zeros(size(R,1),1);

for i = 1:size(R,1)
    Fk = R(i) * ones(size(KKx));
    chi2(i) = sum(sum(((Fk-Dk)./(Fk)).^2));
end

end






function [ chi2 ] = M1( R,KKx,KKy,Dk )
% R1 = (B,A,x0,y0,W)

chi2 = zeros(size(R,1),1);

for i = 1:size(R,1)
% Not normalized Gaussian "pdf"
nmvnpdf = @(xx,yy,x0,y0,ww) exp(-0.5.*((((xx-x0).^2)./(ww.^2))+(((yy-y0).^2)./(ww.^2))-0)); 

Fk = R(i,1) + (R(i,2)*nmvnpdf(KKx,KKy,R(i,3),R(i,4),R(i,5)));
chi2(i) = sum(sum(((Fk-Dk)./(Fk)).^2));
end

end




function [ chi2 ] = M2( R,KKx,KKy,Dk )
% R2 = (B,A1,x01,y01,W1,A2,x02,y02,W2)

chi2 = zeros(size(R,1),1);

for i = 1:size(R,1)
% Not normalized Gaussian "pdf"
nmvnpdf = @(xx,yy,x0,y0,ww) exp(-0.5.*((((xx-x0).^2)./(ww.^2))+(((yy-y0).^2)./(ww.^2))-0)); 

Fk = R(i,1) + (R(i,2)*nmvnpdf(KKx,KKy,R(i,3),R(i,4),R(i,5))) + (R(i,6)*nmvnpdf(KKx,KKy,R(i,7),R(i,8),R(i,9)));
chi2(i) = sum(sum(((Fk-Dk)./(Fk)).^2));

end

end



