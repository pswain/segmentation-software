function ImageStack = ReturnSingleEntry(StackComp,Entry)
%Function to get a single imagestack of a StackComp.


ImageStack = GetStack( StackComp.Directories{Entry},StackComp.Identifiers{Entry} );

end