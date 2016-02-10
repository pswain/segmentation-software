function StackViewer_slider_cb(StackViewer)
%slider call back for PSFViewingGUI. Basically the function
%called everytime the slider of that GUI is moved.
StackDepth = get(StackViewer.slider,'Value');
StackViewer.StackDepth=round(StackDepth);
StackViewer.UpdateImages;

end
