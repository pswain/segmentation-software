%Script to save a dataset created on the Swain lab microscope in OME-Tiff
%format
%Adapted from:
%http://www.openmicroscopy.org/site/support/bio-formats4/developers/matlab-dev.html



%fprintf('Select directory containing your images\n')
%[input_dir] = uigetdir;

%Load basic information from the log file - to go in the metadata
%NOT YET IMPLEMENTED



javaaddpath(fullfile(fileparts(mfilename('fullpath')), 'loci_tools.jar'));
writer = loci.formats.ImageWriter();
metadata = loci.formats.MetadataTools.createOMEXMLMetadata();
metadata.createRoot();
metadata.setImageID('Image:0', 0);
metadata.setPixelsID('Pixels:0', 0);
metadata.setPixelsBinDataBigEndian(java.lang.Boolean.TRUE, 0, 0);
metadata.setPixelsDimensionOrder(ome.xml.model.enums.DimensionOrder.XYZCT, 0);
metadata.setPixelsType(ome.xml.model.enums.PixelType.UINT8, 0);

imageWidth = ome.xml.model.primitives.PositiveInteger(java.lang.Integer(512));
imageHeight = ome.xml.model.primitives.PositiveInteger(java.lang.Integer(512));
numZSections = ome.xml.model.primitives.PositiveInteger(java.lang.Integer(1));
numChannels = ome.xml.model.primitives.PositiveInteger(java.lang.Integer(2));
numTimepoints = ome.xml.model.primitives.PositiveInteger(java.lang.Integer(2));
samplesPerPixel = ome.xml.model.primitives.PositiveInteger(java.lang.Integer(1));

metadata.setPixelsSizeX(imageWidth, 0);
metadata.setPixelsSizeY(imageHeight, 0);
metadata.setPixelsSizeZ(numZSections, 0);
metadata.setPixelsSizeC(numChannels, 0);
metadata.setPixelsSizeT(numTimepoints, 0);
metadata.setChannelID('DIC', 0, 0);
metadata.setChannelSamplesPerPixel(samplesPerPixel, 0, 0);
metadata.setChannelID('GFP', 0, 1);
metadata.setChannelSamplesPerPixel(samplesPerPixel, 0, 1);
%metadata.setChannelID('mCherry', 0, 2);
%metadata.setChannelSamplesPerPixel(samplesPerPixel, 0, 2);

%Create or load images (this will be in a loop)
plane = zeros(1, 512 * 512, 'uint8');
plane2 = 512.*ones(1, 512 * 512, 'uint8');

writer.setMetadataRetrieve(metadata);
writer.setId('number6.ome.tiff');
writer.saveBytes(0, plane); % channel 0, timepoint 0
writer.saveBytes(1, plane2); % channel 1, timepoint 0
writer.saveBytes(2, plane); % channel 0, timepoint 1
writer.saveBytes(3, plane2); % channel 1, timepoint 1
writer.close();