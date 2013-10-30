function saveTimelapse (obj, path, name)
    % saveTimelapse ---  saves the information contained in the timelapse
    %                    object
    %
    % Synopsis:        saveTimelapse (obj, path, name)
    %
    % Input:           obj = an object of a Timelapse class
    %                  path = string, path of folder to save timelapse
    %                  path = string, name of file to save
    % 
    % Output:          
    
    % Notes:    Saves the information necessary to recreate the timelapse
    %           object. Simply saving the object as a variable is fairly
    %           slow and loading such a file again is extremely slow. This
    %           appears to be something to do with the use of handle
    %           objects.
    
    %Save each field in turn
    filename=[path name];
    interval=obj.Interval;
    save(filename,'interval');
    TimePoints=obj.TimePoints;
    save(filename,'TimePoints', '-append');
    Moviedir=obj.Moviedir;
    save(filename,'Moviedir', '-append');
    ImageFileList=obj.ImageFileList;
    save(filename,'ImageFileList', '-append');
    Data=obj.Data;
    save(filename,'Data', '-append');
    ImageSize=obj.ImageSize;
    save(filename,'ImageSize', '-append');
    SpecifiedParameters=obj.SpecifiedParameters;
    save(filename,'SpecifiedParameters', '-append');
    %May need to revise the way the object struct is saved if this is too
    %slow
    ObjectStruct=obj.ObjectStruct;
    save(filename,'ObjectStruct', '-append');
    TrackingData=obj.TrackingData;
    save(filename,'TrackingData', '-append');
    CurrentFrame=obj.CurrentFrame;
    save(filename,'CurrentFrame', '-append');
    StartFrame=obj.StartFrame;
    save(filename,'StartFrame', '-append');
    EndFrame=obj.EndFrame;
    save(filename,'EndFrame', '-append')
    CurrentCell=obj.CurrentCell;
    save(filename,'CurrentCell', '-append');
    Name=obj.Name;
    save(filename,'Name', '-append');
    NumObjects=obj.NumObjects;
    save(filename,'NumObjects', '-append');
    RunTrackMethod=obj.RunTrackMethod;
    save(filename,'RunTrackMethod', '-append');
    RunExtractMethod=obj.RunExtractMethod;
    save(filename,'RunExtractMethod', '-append');
    Main=obj.Main;
    save(filename,'Main', '-append');
    HistorySize=obj.HistorySize;
    save(filename,'HistorySize', '-append');
    tic
    LevelObjects=obj.LevelObjects;
    save(filename,'LevelObjects','-append');     
    NumLevelObjects=obj.NumLevelObjects;
    save(filename,'NumLevelObjects', '-append');
    PostHistory=obj.PostHistory;
    save(filename,'PostHistory', '-append');
    RunMethod=obj.RunMethod;
    save(filename,'RunMethod', '-append');
    ObjectNumber=obj.ObjectNumber;
    save(filename,'ObjectNumber', '-append');
    Info=obj.Info;
    save(filename,'Info', '-append');
    RequiredImages=obj.RequiredImages;
    save(filename,'RequiredImages', '-append');
    RequiredFields=obj.RequiredFields;
    save(filename,'RequiredFields', '-append');
    Timelapse=obj.Timelapse;
    save(filename,'Timelapse', '-append');  
    Result=obj.Result;
    %This is the slowest part - find a way to speed this up   
    save(filename, 'Result','-append');    
    DisplayResult=obj.DisplayResult;
    save(filename,'DisplayResult', '-append');   
    Target=obj.Target;
    save(filename,'Target', '-append'); 
    SegMethod=obj.SegMethod;
    save(filename,'SegMethod', '-append');  

    
    
    
    



end