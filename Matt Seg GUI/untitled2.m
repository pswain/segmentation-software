newD=[];
oldD=[];
oldnewD=[];
trap=7;
for i=1:100
    new=[cTimelapsenew.cTimepoint(i).trapLocations(trap).xcenter cTimelapsenew.cTimepoint(i).trapLocations(trap).ycenter];
    old=[cTimelapse.cTimepoint(i).trapLocations(trap).xcenter cTimelapse.cTimepoint(i).trapLocations(trap).ycenter];
    
        new2=[cTimelapsenew.cTimepoint(i+1).trapLocations(trap).xcenter cTimelapsenew.cTimepoint(i+1).trapLocations(trap).ycenter];
    old2=[cTimelapse.cTimepoint(i+1).trapLocations(trap).xcenter cTimelapse.cTimepoint(i+1).trapLocations(trap).ycenter];
    
    newD=[newD pdist([new; new2])];
    oldD=[oldD pdist([old; old2])];
    
    oldnewD=[oldnewD pdist([new; old])];

end

figure(148);plot([newD; oldD]');
legend('new','old')

figure(149);plot([oldnewD]');

%%
figure(148);plot([newD-oldD]');
%%
new=[]
for i=1:100
    temp=[cTimelapse.cTimepoint(i).trapLocations(trap).xcenter cTimelapse.cTimepoint(i).trapLocations(trap).ycenter]';
    new=[new temp];
end

newsmooth=[];
for i=1:2
    newsmooth(i,:)=smooth(new(i,:),4);
end

figure(1232);plot([newsmooth(1,:); new(1,:)]')
figure(1232);plot([newsmooth(2,:); new(2,:)]')

%%
b=[]
xval=[];
for i=1:100
    xval(i,:)=[cTimelapse.cTimepoint(i).trapLocations(:).xcenter];
%     yval=[cTimelapse.cTimepoint(i).trapLocations(trap).ycenter];
%     b=[b mean(xval)];
end

for i=1:size(xval,2)
    xval(i,:)=[cTimelapse.cTimepoint(i).trapLocations(:).xcenter];
%     yval=[cTimelapse.cTimepoint(i).trapLocations(trap).ycenter];
%     b=[b mean(xval)];
end

figure(1232);plot(b)
figure(1233);plot([newsmooth(1,:); new(1,:)]')



%%
cTrapDisplay(cTimelapsenew,disp.cCellVision,[],[],trap,[])
cTrapDisplay(cTimelapse,disp.cCellVision,[],[],trap,[])