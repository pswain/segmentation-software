function out= onOff2bin(in)
out=[];
for i= 1: length(in)
    if (strcmpi(in{i}, 'on'))
    out(i)=1;
    else
        out(i)=0;
    end
end
out=out';
end
