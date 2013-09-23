classdef TransformImages<MethodsSuperClass
   properties
       resultfield;%string, the field name in inputObj.RequiredImages to which the result of running the current method is saved
       resultImage='Resultfield';%The location of the result image is determined by the value of obj.resultfield
   end
   
   methods
       inputObj=run(obj,inputObj);     
       inputObj=initializeFields(obj,inputObj);       

   end
      
    
    
    
end