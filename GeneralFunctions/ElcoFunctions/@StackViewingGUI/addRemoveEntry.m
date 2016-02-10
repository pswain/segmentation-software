function addRemoveEntry(StackViewer)
%add or remove entry from the field StackViewer.PSFcomp.Centres{entry} - a
%column vector of all the points in this image stack which correspond the
%the centres of desirable PSF's. 
%Uses the PossiblePSFs field which is found by a threshold and an
%imregionalmax in the instantiation of the GUI.

cp=get(StackViewer.MainAxisHandle,'CurrentPoint');


cp=round(cp);
Cx=cp(1,1);
Cy=cp(1,2);

if strcmp(get(gcbf,'SelectionType'),'alt')
    fprintf('\n   right click at (%d,%d). To do something with this info write a new addRemoveEntry method for your GUI\n',Cx,Cy)
else
    fprintf('\n   left click at (%d,%d). To do something with this info write a new addRemoveEntry method for your GUI\n',Cx,Cy)

   
end

StackViewer.UpdateImages;

end

