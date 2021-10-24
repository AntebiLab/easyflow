function db=init_efdb()
    % Initialize data structures
    % General DB Info
    % it creates a data structure, mArgs with the following fields
    %    version - double - the version
    %    TubeDB - array of structures Tubes information.
    %       fcsfile - structure containing the parsed fcsfile
    %       Tubename - 1x1 cell containing a string with the tube name
    %       CompensationMtx
    %       CompensationIndex
    %       CompensationPrm
    %       parname
    %       parsymbol
    %       tubepath
    %       tubefile
    %       compdata - (num of cell X num of colors) Array of compensated data
    %    Handles - all the gui handles.
    %       GateList - handle to the uibuttongroup of the gates
    %    GraphDB
    %       Name
    %       Data - String - name of the data tube
    %       Ctrl - String - name of the control tube
    %       Color - String - name of color for x axis
    %       Color2 - String - name of color for y axis
    %       RemoveCtrl - integer
    %       DataDeconv
    %       Gates
    %       Stat - structure to hold statistics
    %           quad - double array of length 2 with the position of the quadrants
    %           quadp - double array of length 4 with the percentage of cells in each quad
    %       plotdata - array of plotted data, [y(:), x(:)]
    %       PlotColor - [r g b] - the color for the graph
    %       Display
    %           Changed - 0 or 1 - should i save the display in the graphdb
    %       gatedindex - logical for the events that pass the combined gates
    %       gatedindexctrl - logical for the events that pass the gates in the control tube
    %       fit - 4x1 cell - cell array with 4 values. results of a fit operation (cfit), goodness of fit (structure), axis scaling, axis scaling param.
    %    GatesDB
    %       getvarname(tube)
    %          gatename - cell array of {[gate_definition] [logical] [color1/defining element] [color2/type] }
    %    Display - parameters for the display
    %       GraphColor: [7x3 double]
    %       graph_type: 'Dot Plot'
    %       graph_type_Radio: 4
    %       graph_Xaxis: 'logicle'
    %       graph_Xaxis_param: [-1000 1000000 0.0251188643150958]
    %       graph_Xaxis_Radio: 1
    %       graph_Yaxis: 'ylin'
    %       graph_Yaxis_param: [0 1000000 1]
    %       graph_Yaxis_Radio: 4
    %       Changed - 0 or 1 - should i save the display in the graphdb
    %       histnormalize: 'Total'
    %    TubeNames - cell array of strings containing the name of all tubes.
    %                with 'None' as the first.
    %    Statistics - parameters to do with statistics
    %       ShowInStatView=logicals indicating which tests to do
    %    copy
    %    curGraph
    %    DBInfo - data for saving things
    %       Name
    %       Path - String - path where to open file dialogs
    %       RootFolder - String - path to a base folder for relative paths
    %       isChanged - 0,1 - should the file be saved
    %       geom - the geometry of the figure
    %           Graphsize - the size of the Graph pane
    %           Gatesize - the size of the Gates pane
    %       enabled_gui - enabled gui components
    %
    %
    
    curversion = easierFlowInfo('version');
    
    db=struct(...
        'version',curversion,...
        'TubeDB',[],...
        'Handles',[],...
        'GraphDB',[],...
        'GatesDB',[],...
        'GatesDBnew',struct(),...
        'Display',[],...
        'TubeNames',{'None'},...
        'Statistics',[],...
        'copy',[],...
        'curGraph',[],...
        'DBInfo',[]...
        );

    db.TubeDB=struct(...
        'fcsfile',{},...
        'Tubename',{},...
        'tubepath',{},...
        'tubefile',{},...
        'parname',{},...
        'parsymbol',{},...
        'CompensationPrm',{},...
        'CompensationMtx',{},...
        'CompensationIndex',{},...
        'compdata',{});

    db.Display.GraphColor=[0,   0,   1;
        0,   0.5, 0;
        1,   0,   0;
        0,   0.75,0.75;
        0.75,0,   0.75;
        0.75,0.75,0;
        0.25,0.25,0.25];
    db.Display.graph_type='Histogram';
    db.Display.graph_type_Radio=5;
    db.Display.graph_Xaxis='log';
    db.Display.graph_Xaxis_param=[0 Inf 1];
    db.Display.graph_Xaxis_Radio=3;
    db.Display.graph_Yaxis='ylin';
    db.Display.graph_Yaxis_param=1;
    db.Display.graph_Yaxis_Radio=4;
    db.Display.smoothprm=100;

    db.DBInfo.Path=pwd;
    db.DBInfo.geom.Graphsize=150;
    db.DBInfo.geom.Gatesize=120;

    db.Statistics.ShowInStatView=[true(1,5),false(1,4)];
end

