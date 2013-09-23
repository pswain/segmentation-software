function obj=loadTimelapse(fileName)
    % loadTimelapse --- loads a timelapse dataset saved by the saveTimelapse method
    %
    % Synopsis:  obj = loadTimelapse (fileName)
    %            obj = loadTimelapse ()
    %                        
    % Input:     fileName = string, full path and filename of a .sct file created by the saveTimelapse method
    % 
    % Output:   obj = an object of class Timelapse1

    % Notes:  This is a static method - doesn't need a timelapse
    %         object. To run this refer to a Timelapse class
    %         - eg tl=Timelapse1.loadTimelapse()
    
    if nargin==0
        [name,path] = uigetfile('*.sct','Load timelapse dataset');
        if name~=0
            fileName=[path name];
        else
            obj=[];
            showMessage('No file loaded');
            return
        end
    end
    
    if exist(fileName,'file')==2
        showMessage('Loading timelapse data set...');
        load (fileName,'-mat');
        %Create an empty timelapse object
        obj=[];
        obj=Timelapse1('Blank');
        
        %Populate timelapse fields
        obj.Interval=interval;
        obj.TimePoints=TimePoints;
        obj.Moviedir=Moviedir;
        obj.ImageFileList=ImageFileList;
        obj.Data=Data;
        obj.ImageSize=ImageSize;
        obj.SpecifiedParameters=SpecifiedParameters;
        obj.ObjectStruct=ObjectStruct;
        obj.TrackingData=TrackingData;
        obj.CurrentFrame=CurrentFrame;
        obj.CurrentFrame=CurrentFrame;
        obj.StartFrame=StartFrame;
        obj.EndFrame=EndFrame;
        obj.CurrentCell=CurrentCell;
        obj.Name=Name;
        obj.NumObjects=NumObjects;
        obj.RunTrackMethod=RunTrackMethod;
        a=obj.RunExtractMethod;
        obj.RunExtractMethod=a;
        obj.Main=Main;
        obj.HistorySize=HistorySize;
        obj.LevelObjects=LevelObjects;
        obj.NumLevelObjects=NumLevelObjects;
        obj.PostHistory=PostHistory;
        obj.RunMethod=RunMethod;
        obj.ObjectNumber=ObjectNumber;
        obj.Info=Info;
        obj.RequiredImages=RequiredImages;
        obj.RequiredFields=RequiredFields;
        obj.Timelapse=Timelapse;
        obj.Result=Result;
        obj.DisplayResult=DisplayResult;
        obj.Target=Target;
        obj.SegMethod=SegMethod;
    else
        showMessage('Invalid file name entered - no file loaded.');
    end
