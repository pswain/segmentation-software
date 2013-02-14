function trackTrapsThroughTime(cTimelapse)


%% Identify the same traps throughout time.
%Use the nearestneighbor function and the x and y locations of traps for
%image t and t+1 to track traps throughput time. Because of stage drift,
%there is the possibility that traps could leave the field of view. To
%correct for that check to see if any traps in image t+1 have the same
%label. If so, the trap with the greatest distance measurement must be
%relabeled as numb_traps+1;


starting_frame=1;
while isempty(cTimelapse.cTimepoint(starting_frame).cTrap)
    starting_frame=starting_frame+1; 
    if starting_frame+1>length(cTimelapse.cTimepoint)
        break;
    end
end

cTimelapse.cTimepoint(starting_frame).cTrap.trap_label=1:length(cTimelapse.cTimepoint(starting_frame).cTrap.xcenter);
num_traps=length(cTimelapse.cTimepoint(starting_frame).cTrap.xcenter);

p=starting_frame;
while ~isempty(cTimelapse.cTimepoint(p+1).cTrap)
    p=p+1; 
    if p+1>length(cTimelapse.cTimepoint)
        break;
    end
end
num_processed_frames=p;


for i=starting_frame:num_processed_frames-1

    QX=cTimelapse.cTimepoint(i+1).cTrap.xcenter';
    QY=cTimelapse.cTimepoint(i+1).cTrap.ycenter';
    dt = DelaunayTri(cTimelapse.cTimepoint(i).cTrap.xcenter',cTimelapse.cTimepoint(i).cTrap.ycenter');
    [PI dist]= nearestNeighbor(dt,QX,QY);
    
    cTimelapse.cTimepoint(i+1).cTrap.trap_label=cTimelapse.cTimepoint(i).cTrap.trap_label(PI);
    cTimelapse.cTimepoint(i+1).cTrap;
    [b m n]=unique(PI);
    if length(b)~=length(PI)
        [n, bin] = histc(PI, b);
        multiple = find(n > 1);
        for j=1:length(multiple)
            index=find(ismember(bin, multiple(j)));
            [val min_index]=min(dist(index));
            index(min_index)=[];
            for k=1:length(index)
                cTimelapse.cTimepoint(i+1).cTrap.trap_label(index(k))=num_traps+1;
                num_traps=num_traps+1;
            end
        end
    end   
end
%% Sort and label the traps
% This creates a struct for each of the traps. This way, you can follow a
% single trap throughout the timelapse, knowing the x,y locations of the
% trap based on the previous stage. 

cTimelapse.cTrapsLabelled=struct('timepoint',{},'xcenter',{},'ycenter',{});
for i=1:num_traps
    i
    tp_index=1;
    for j=starting_frame:num_processed_frames
        ind=find(cTimelapse.cTimepoint(j).cTrap.trap_label==i);
        if length(ind)
            cTimelapse.cTrapsLabelled(i).timepoint(tp_index)=j;
            cTimelapse.cTrapsLabelled(i).xcenter(tp_index)=cTimelapse.cTimepoint(j).cTrap.xcenter(ind);
            cTimelapse.cTrapsLabelled(i).ycenter(tp_index)=cTimelapse.cTimepoint(j).cTrap.ycenter(ind);
            tp_index=tp_index+1;
        end
    end

end
     