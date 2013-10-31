function result=largestOnly(input)
    props=regionprops(input,'Area','Image','BoundingBox');
    numobj=size(props,1);%number of connected objects in the result image
    result=false(size(input));
    areas=vertcat(props.Area);
    [area largest]=max(areas);
    bb=vertcat(props(largest).BoundingBox);   
    tlx=ceil(bb(1));
    tly=ceil(bb(2));
    lengthx=bb(3);
    lengthy=bb(4);
    result(tly:tly+lengthy-1,tlx:tlx+lengthx-1)=props(largest).Image;
end 