function visEdges(edges, varargin)
%VISEDGES displays a list of edges
%
%   VISEDGES(PARAM1,VAL1,PARAM2,VAL2,...)
%   displays a list of edges using name-value pairs to control what must be
%   visualized. These parameters include:
%
%   'showEdges' - Specifies if edges are displayed:
%               true:  edges are displayed (default)
%               false:  edges are not displayed 
% 
%   'showNormals' - Specifies if normal vectors ared displayed:
%               true:  normal vectors are displayed (default)
%               false:  normal vectors are not displayed 

hold on;
showEdges = true;
showNormals = true;

%% parse optional input parameters
v = 1;
while v < numel(varargin)
    switch varargin{v}
        case 'showEdges'
            assert(v+1<=numel(varargin));
            showEdges = varargin{v+1};
        case 'showNormals'
            assert(v+1<=numel(varargin));
            showNormals = varargin{v+1};
        otherwise
            error('Unsupported parameter: %s',varargin{v});
    end
    v = v+2;
end

%% display edges
if showEdges
    seg = 0.6;
    quiver(edges.x-seg/2*edges.ny, edges.y+seg/2*edges.nx, ...
        seg*edges.ny, -seg*edges.nx, 0, 'r.');
end

%% display normal vectors
if showNormals
    quiver(edges.x, edges.y, edges.nx, edges.ny, 0, 'b');
end

hold off
