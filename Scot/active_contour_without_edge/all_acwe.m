function out = all_acwe(img)

 obj.parameters = struct();
               obj.parameters.splitregion='WshSplit';%Default region splitting method. NOTE: If a parameter defines use of another class then the contents need to be copied to the obj.Classes property (after the call to changeparams).
               obj.parameters.mu=0.1;%mu: the length term of equation(9) in ref[1] (see acew.m)
               obj.parameters.v=0.1;%v: the area term of eq(9)
               obj.parameters.epsilon=1;%epsilon: the parameter to avoid 0 denominator
               obj.parameters.timestep=0.1;%timestep: the descenting step each time(positive real number)
               obj.parameters.lambda1=1;%lambda1, lambda2: the data fitting term
               obj.parameters.lambda2=1;
               obj.parameters.iterations=200;%numIter: the number of iterations
               obj.parameters.pc=1;%pc: the penalty coefficient(used to avoid reinitialization according to [2])

              
img = double(img);

                 target_image = 250*(img-min(img(:)))/(max(img(:))-min(img(:))) +1;
                 
target_image = medfilt2(target_image, [5, 5]);
                  [X,Y] = meshgrid(1:size(target_image,2), 1:size(target_image,1));
            
            %give the binary image as the initial contour (everything
            %inside the initial contour is set to 2)
            contourResult = 2*ones(size(target_image));
            contourResult(5:(end-5),5:(end-5)) = -2;
            
            %Now apply the chan-vese active contour method to the main
            %target image, using the bin image as a mask. This will refine
            %the bin image result.
            %The particular implementation of the chanvese is called
            %acwe.m. It was downloaded from the file exchange:
            %http://www.mathworks.co.uk/matlabcentral/fileexchange/34548-active-contour-without-edge
            %and written by Su Dongcai
            %it applies a gradient descent method to minise the chan vese
            %cost function.
            
            
            figure
            for n=1:obj.parameters.iterations
                
                contourResult=acwe(contourResult, target_image,  obj.parameters.timestep,...
                    obj.parameters.mu, obj.parameters.v, obj.parameters.lambda1, obj.parameters.lambda2, obj.parameters.pc, obj.parameters.epsilon, 1);
                
                if mod(n,10)==0
                    pause(0.1);
                    imshow(target_image, []);hold on;axis off,axis equal
                    [c,h] = contour(contourResult,[0 0],'r');
                    hold off;
                end
                
            end
            contourResult = padarray(contourResult,[2 2],1);   
            c = contour(contourResult,[0,0],'r');
            index = find(c(1,:)==0);
            index = [index length(c)];
            c = c-2;
            
            imres = false(size(target_image));
            
            for i=1:(size(index,2)-1)
                
                imres = imres | inpolygon(X,Y,c(1,(index(i)+1):(index(i+1)-1))',c(2,(index(i)+1):(index(i+1)-1))');
                imshow(imres,[]);


            end
            figure
            imshow(imres,[]);
            out = contourResult;
            
            

end