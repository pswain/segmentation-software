for i =1:86
figure(1);imshow(CellInfo(i).TransformedImage1,[]);
figure(2);imshow(CellInfo(i).TransformedImage2,[]);
%figure(2);imshow(trap_px_stack(:,:,i),[])
pause
end

test = rand(61,61,100);
test2 = struct('name',zeros(61,61));
test2(1:100) = test2;

tic;
for i=1:100
test2(i).name = test(:,:,i);
end
toc

tic
test = num2cell(test,[1 2]);
[test2(:).name] = deal(test{:});
toc
test = rand(61,61,100);


for i=1:25
    
    figure(1);imshow(ImageStack(:,:,i),[]);

    figure(2);imshow(ImageStack3(:,:,i),[]);
    
    pause
    
end

for t=1:10
    fprintf('%d\n',t);
    imshow(full(ttacObject.TimelapseTraps.cTimepoint(t).trapInfo(1).cell(1).segmented),[])
    pause
end


 