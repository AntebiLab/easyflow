function easyflow(varargin)
%EASYFLOW - A GUI for facs data.
%   EASYFLOW()
%   EASYFLOW
%   Opens up a new empty easyflow session.
%
%   EASYFLOW('session_filename')
%   EASYFLOW session_filename
%   Opens up the session saved in session_filename.

%Todos
% gate edit: change gate name
% gate edit: move enitre gate (with ctrl)
% remove the use of fh in functions
% remove the use of mArgs

%written by Yaron Antebi
curversion=3.20;
versiondate='Feb 02, 2020';

% Initialize 
fh = init_gui();

% Check arguments
if nargin>1
    error('Wrong number of arguments');
elseif nargin==1
    % Load session
    SessionLoadCallback(fh,[],varargin{1});
end

%  Render GUI visible
set(fh,'Visible','on');

%%  Initialization functions
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
        db.DBInfo.geom.Graphsize=100;
        db.DBInfo.geom.Gatesize=120;
        
        db.Statistics.ShowInStatView=[true(1,5),false(1,4)];
    end
    function fh=init_gui
        Handles=[];
        %%  Construct the figure
        scrsz=get(0,'ScreenSize');
        guisize=700;
        Handles.fh=figure('Position',[(scrsz(3)-800)/2,(scrsz(4)-700)/2,800,700],...
            'MenuBar','none',...
            'Name','EasyFlow - FACS Analysis Tool',...
            'NumberTitle','off',...
            'Visible','off',...
            'ResizeFcn',{@fhResizeFcn},...
            'KeyPressFcn',{@fhKeyPressFcn},...
            'WindowButtonDownFcn',@ResizeFcn,...
            'WindowButtonMotionFcn',@fhMotionFcn,...
            'CloseRequestFcn',@fhClose);
        %%  Construct the UI regions
        uicontrol(Handles.fh,...
            'Style','listbox',...
            'Position',[0 0 100 guisize-30],...
            'Max',2,...
            'Tag','GraphList',...
            'Value',[],...
            'CreateFcn',@GeneralCreateFcn,...
            'Callback',@GraphListCallback);
        uicontrol(Handles.fh,...
            'Style','pushbutton',...
            'Position',[0 guisize-30 50 30],...
            'String','Add',...
            'Tag','AddBtn',...
            'CreateFcn',@GeneralCreateFcn,...
            'Callback',@AddBtnCallback);
        uicontrol(Handles.fh,...
            'Style','pushbutton',...
            'Position',[50 guisize-30 50 30],...
            'String','Del',...
            'Tag','DelBtn',...
            'CreateFcn',@GeneralCreateFcn,...
            'Callback',@DelBtnCallback);
        uipanel(Handles.fh,...
            'Units','pixels',...
            'Position',[100,guisize-100,guisize-200,100],...
            'Tag','TopPanel',...
            'CreateFcn',@GeneralCreateFcn);
        uibuttongroup(...
            'Units','pixels',...
            'Position',[guisize-120 0 120 guisize],...
            'Tag','GateList',...
            'CreateFcn',@GeneralCreateFcn);
        axes('Parent',Handles.fh,...
            'Units','pixels',...
            'OuterPosition',[100,0,guisize-100,guisize-100],...
            'Tag','ax',...
            'CreateFcn',@GeneralCreateFcn);
        %%  Construct the top panel
        uicontrol(Handles.TopPanel,...
            'Style','edit',...
            'HorizontalAlignment','left',...
            'String','GraphName',...
            'BackgroundColor',[1 1 1],...
            'Position',[5 75 122 20],...
            'Tag','GraphName',...
            'Enable','off',...
            'CreateFcn',@GeneralCreateFcn,...
            'Callback',@GraphNameCallback);
        uicontrol(Handles.TopPanel,...
            'Style','text',...
            'HorizontalAlignment','left',...
            'String','Data:',...
            'Position',[5 50 122 20]);
        uicontrol(Handles.TopPanel,...
            'Style','popupmenu',...
            'Position',[5 35 122 20],...
            'String',' ',...
            'BackgroundColor',[1 1 1],...
            'Tag','TubePUM',...
            'Enable','off',...
            'CreateFcn',@GeneralCreateFcn,...
            'Callback',@TubePUMCallback);
        uicontrol(Handles.TopPanel,...
            'Style','text',...
            'HorizontalAlignment','left',...
            'String','Control:',...
            'Visible','off',...
            'Position',[137 50 122 20]);
        uicontrol(Handles.TopPanel,...
            'Style','text',...
            'HorizontalAlignment','left',...
            'String','X Axis:',...
            'Position',[269-132 50 122 20]);
        uicontrol(Handles.TopPanel,...
            'Style','popupmenu',...
            'Position',[269-132 35 122 20],...
            'String',' ',...
            'BackgroundColor',[1 1 1],...
            'Tag','ColorPUM',...
            'Enable','off',...
            'CreateFcn',@GeneralCreateFcn,...
            'Callback',@ColorPUMCallback);
        uicontrol(Handles.TopPanel,...
            'Style','text',...
            'HorizontalAlignment','left',...
            'String','Y Axis:',...
            'Position',[401-132 50 122 20]);
        uicontrol(Handles.TopPanel,...
            'Style','popupmenu',...
            'Position',[401-132 35 122 20],...
            'String',' ',...
            'BackgroundColor',[1 1 1],...
            'Tag','Color2PUM',...
            'Enable','off',...
            'CreateFcn',@GeneralCreateFcn,...
            'Callback',@Color2PUMCallback);
        cicon(:,:,1)=max(min(filter2(ones(3,3)/6,rand(16,16)),1),0);
        cicon(:,:,2)=max(min(filter2(ones(3,3)/6,rand(16,16)),1),0);
        cicon(:,:,3)=max(min(filter2(ones(3,3)/6,rand(16,16)),1),0);
        uicontrol(Handles.TopPanel,...
            'Style','pushbutton',...
            'Position',[543-132 35 30 30],...
            'Cdata',cicon,...
            'Tag','ColorBtn',...
            'CreateFcn',@GeneralCreateFcn,...
            'Enable','off',...
            'Callback',@ColorBtnCallback);
        %%  Constract the menu
        MenuSession = uimenu(Handles.fh,...
            'Label','Session',...
            'Callback',@mSessionCallback);
        MenuData = uimenu(Handles.fh,...
            'Label','Data',...
            'Callback',@mDataCallback);
        MenuGraphs = uimenu(Handles.fh,...
            'Label','Graphs',...
            'Callback',@mGraphsCallback);
        MenuDisplay = uimenu(Handles.fh,...
            'Label','Display',...
            'Callback',@mDisplayCallback);
        MenuGates = uimenu(Handles.fh,...
            'Label','Gates',...
            'Callback',@mGatesCallback);
        MenuStats = uimenu(Handles.fh,'Label','Stats');
        MenuHelp = uimenu(Handles.fh,'Label','Help');
        %%    Sessions menu
        uimenu(MenuSession,...
            'Label','New Session',...
            'Callback',@SessionNewCallback);
        uimenu(MenuSession,...
            'Label','Open Session...',...
            'Callback',@SessionLoadCallback);
        uimenu(MenuSession,...
            'Label','Save',...
            'Callback',@SessionSaveCallback);
        uimenu(MenuSession,...
            'Label','Save As...',...
            'Callback',@SessionSaveAsCallback);
        uimenu(MenuSession,...
            'Label','Export To Workspace...',...
            'Callback',@SessionExportCallback);
        uimenu(MenuSession,...
            'Label','Use Relative Path',...
            'Callback',@SessionUseRelPath);
        %%    Data menu
        GenerateDataMenu(MenuData)
        %%    Graphs menu
        GenerateGraphsMenu(MenuGraphs)
        %%    Display menu
        GenerateDisplayMenu(MenuDisplay)
        %%    Gates menu
        GenerateGatesMenu(MenuGates)
        %%    STATS menu
        uimenu(MenuStats,...
            'Label','Stat Window...',...
            'Callback',@StatWinCallback);
        uimenu(MenuStats,...
            'Label','SetUp...',...
            'Callback',@ViewSetup);
        %%    HELP menu
        uimenu(MenuHelp,...
            'Label','Show Keyboard Shortcuts',...
            'Callback',{@HelpKeys});
        uimenu(MenuHelp,...
            'Label','About...',...
            'Callback',{@HelpAbout});
        %% Context menus
        %Graphs
        GraphsCM = uicontextmenu('Parent',Handles.fh,...
            'Callback',@mGraphsCallback);
        set(Handles.GraphList,'UIContextMenu',GraphsCM);
        GenerateGraphsMenu(GraphsCM)
        %Gates
        Handles.GatesCM = uicontextmenu('Parent',Handles.fh,...
            'Callback',@mGatesCallback);
        set(Handles.GateList,'UIContextMenu',Handles.GatesCM);
        GenerateGatesMenu(Handles.GatesCM)
        %Display
        DisplayCM = uicontextmenu('Parent',Handles.fh,...
            'Callback',@mDisplayCallback);
        set(Handles.ax,'UIContextMenu',DisplayCM);
        GenerateDisplayMenu(DisplayCM);

        %% construction function
        function GeneralCreateFcn(hObject,~)
            if ~isempty(get(hObject,'Tag'))
                Handles.(get(hObject,'Tag'))=hObject;
            end
        end
        function GenerateDataMenu(hObject)
            % Data menu
            uimenu(hObject,...
                'Label','Load Data Files...',...
                'Callback',@SampleLoadCallback);
            uimenu(hObject,...
                'Label','Load Data Folder...',...
                'Callback',@FolderLoadCallback);
            uimenu(hObject,...
                'Label','Save Samples',...
                'Callback',@TubeSaveCallback);
            uimenu(hObject,...
                'Label','Remove Samples...',...
                'Callback',@TubeRemoveCallback);
            uimenu(hObject,...
                'Label','Rename Samples...',...
                'Callback',@TubeRenameCallback);
            uimenu(hObject,...
                'Label','File Rename Samples...',...
                'Callback',@FileTubeRenameCallback);
            uimenu(hObject,...
                'Label','Samples parameters...',...
                'Callback',@TubeShowPrmCallback);
            MenuTubeComp=uimenu(hObject,...
                'Label','Compensation');
            uimenu(hObject,...
                'Label','View Parameters...',...
                'Callback',@TubePrmCallback);
            uimenu(hObject,...
                'Label','Add parameter',...
                'callback',@TubeAddParam);
            % Compensation submenu
            uimenu(MenuTubeComp,...
                'Label','Set Compensation...',...
                'Callback',@TubeCompCallback);
        end
        function GenerateGraphsMenu(hObject)
            uimenu(hObject,...
                'Label','Batch...',...
                'Callback',{@ToolsBatch});
            uimenu(hObject,...
                'Label','Add all tubes',...
                'Callback',{@ToolsAddall});
            uimenu(hObject,...
                'Label','New Fit',...
                'Callback',{@ToolsNewFit});
            uimenu(hObject,...
                'Label','Apply Fit',...
                'Callback',{@ToolsApplyFit});
            uimenu(hObject,...
                'Label','Remove Fit',...
                'Callback',{@ToolsRemFit});
            uimenu(hObject,...
                'Label','Export Data',...
                'Callback',{@ToolsExport});
        end
        function GenerateGatesMenu(hObject)
            uimenu(hObject,...
                'Label','Add Gate',...
                'Callback',@MenuGatesAddGate);
            uimenu(hObject,...
                'Label','Add Contour Gate',...
                'Callback',@MenuGatesAddContourGate);
            uimenu(hObject,...
                'Label','Add Logical Gate',...
                'Callback',@MenuGatesAddLogicalGate);
            uimenu(hObject,...
                'Label','Add Artifacts Gate',...
                'Callback',@MenuGatesAddArtifactsGate);
            uimenu(hObject,...
                'Label','Remove Gate',...
                'Callback',@MenuGatesRemove);
            uimenu(hObject,...
                'Label','Edit Gates',...
                'Callback',@MenuGatesEditor);
        end
        function GenerateDisplayMenu(hObject)
            acmquadmenu=uimenu(hObject,...
                'Label','Quadrants');
            uimenu(acmquadmenu,...
                'Label','Set Quadrants',...
                'Callback',@ACM_setquad);
            uimenu(acmquadmenu,...
                'Label','Copy Quadrants',...
                'Callback',@ACM_cpquad);
            uimenu(acmquadmenu,...
                'Label','Paste Quadrants',...
                'Callback',@ACM_pastequad);
            uimenu(acmquadmenu,...
                'Label','Remove Quadrants',...
                'Callback',@ACM_rmquad);
            uimenu(hObject,...
                'Label','Fix Axis',...
                'Callback',@ACM_fixaxis);
            uimenu(hObject,...
                'Label','Draw to Figure',...
                'Callback',@ACM_DrawToFigure);
            uimenu(hObject,...
                'Label','Graph Properties...',...
                'Callback',@ACM_graphprop);
        end
        
        %% Handles to functions
        Handles.DrawFcn=@DrawGraphs;
        Handles.UpdateGateListFcn=@UpdateGateList;
        Handles.CalculateGatedData=@CalculateGatedData;
        Handles.RecalcGateLogicalMask=@RecalcGateLogicalMask;
        
        %% Create a database and add to gui
        efdb=init_efdb();
        efdb.Handles=Handles;
        efdb_save(efdb);
        
        %% remove return value
        fh = Handles.fh;

    end

%%  Callbacks for MYGUI.
% loading DB        efdb=efdb_load(hObject);
% saving DB         efdb_save(efdb);
% disable gui       efdb=disable_gui(efdb);
% enable gui        efdb=enable_gui(efdb);
%
    function ResizeFcn(hObject,~)
        WBDF = get(gcf,'WindowButtonDownFcn');
        WBUF = get(gcf,'WindowButtonUpFcn');
        WBMF = get(gcf,'WindowButtonMotionFcn');
        pntr = get(gcf,'Pointer');
        
        efdb=efdb_load(hObject);
        p=get(hObject,'CurrentPoint');
        if p(1)>efdb.DBInfo.geom.Graphsize && p(1)<=efdb.DBInfo.geom.Graphsize+5
            %resize the graph list
            hObject.WindowButtonMotionFcn=@ResizeWBMF;
            hObject.WindowButtonUpFcn=@ResizeWBUP;
        else
            %do nothing
        end

        function ResizeWBUP(hObject,~)
            set(gcf,'WindowButtonDownFcn', WBDF);
            set(gcf,'WindowButtonUpFcn', WBUF);
            set(gcf,'WindowButtonMotionFcn', WBMF);
            set(gcf,'Pointer', pntr);
        end
        function ResizeWBMF(hObject,~)
            efdb=efdb_load(hObject);
            mp=get(hObject,'CurrentPoint');
            efdb.DBInfo.geom.Graphsize=mp(1);
            efdb_save(efdb);
            fhResizeFcn(hObject,[]);
        end
 
    end
    function fhResizeFcn(hObject,~)
        efdb=efdb_load(hObject);
        guipos=get(hObject,'Position');
        Graphsize=efdb.DBInfo.geom.Graphsize;
        Gatesize=efdb.DBInfo.geom.Gatesize;
        %guisize x must include the graphs, gates, and 450 for the top_panel
        %guisize y must include the top_panel+a bit for the axis
        guisizex=max(Graphsize+Gatesize+450,guipos(3));
        guisizey=max(100+10,guipos(4));
        guipos=[guipos(1),guipos(2)+guipos(4)-guisizey,guisizex,guisizey];
        set(hObject,'Position',guipos);
        set(efdb.Handles.GraphList,'Position',[0 0 Graphsize guisizey-30]);
        set(efdb.Handles.AddBtn,'Position',[0 guisizey-30 floor(Graphsize/2) 30]);
        set(efdb.Handles.DelBtn,'Position',[floor(Graphsize/2) guisizey-30 ceil(Graphsize/2) 30]);
        set(efdb.Handles.TopPanel,'Position',[Graphsize,guisizey-100,guisizex-Graphsize-Gatesize,100]);
        set(efdb.Handles.GateList,'Position',[guisizex-Gatesize 0 Gatesize guisizey]);
        set(efdb.Handles.ax,'OuterPosition',[Graphsize 0 guisizex-Graphsize-Gatesize,guisizey-100]);
        efdb_save(efdb);
        %redraw the gates in the gate list
        UpdateGateList(efdb);
    end
    function fhClose(hObject,eventdata)
        efdb=efdb_load(hObject);
        if isfield(efdb,'DBInfo') && isfield(efdb.DBInfo,'isChanged') && efdb.DBInfo.isChanged==1
            button = questdlg('Some unsaved data will be lost.','Exit EasyFlow','Save', 'Quit', 'Cancel', 'Cancel');
            if strcmp(button,'Cancel')
                return
            end
            if strcmp(button,'Save')
                if isfield(efdb.DBInfo,'Name') && exist(efdb.DBInfo.Name,'file')
                    SessionSaveCallback(hObject,eventdata);
                else
                    SessionSaveAsCallback(hObject,eventdata);
                end
            end
        end
        
        if isfield(efdb.Handles,'graphprop')
            delete(efdb.Handles.graphprop)
            efdb.Handles=rmfield(efdb.Handles,'graphprop');
        end
        if isfield(efdb.Handles,'statwin')
            delete(efdb.Handles.statwin)
            efdb.Handles=rmfield(efdb.Handles,'statwin');
        end
        if isfield(efdb.Handles,'gateedit')
            delete(efdb.Handles.gateedit)
            efdb.Handles=rmfield(efdb.Handles,'gateedit');
        end
        if isfield(efdb.Handles,'compensation')
            delete(efdb.Handles.compensation)
            efdb.Handles=rmfield(efdb.Handles,'compensation');
        end
        efdb_save(efdb);
        if isempty(gcbf)
            if length(dbstack) == 1
                warning('MATLAB:closereq', ...
                    'Calling closereq from the command line is now obsolete, use close instead');
            end
            close force
        else
            delete(gcbf);
        end
    end
    function fhKeyPressFcn(hObject,eventdata)
        efdb=efdb_load(hObject);
        if strcmp(eventdata.Modifier,'control')
            if strcmp(eventdata.Key,'a')
                for graph=efdb.curGraph
                    efdb.GraphDB(graph).Name=efdb.GraphDB(graph).Data;
                end
                List=get(efdb.Handles.GraphList,'String');
                List(get(efdb.Handles.GraphList,'Value'))={efdb.GraphDB(efdb.curGraph).Data};
                set(efdb.Handles.GraphList,'String',List);
                set(efdb.Handles.GraphName,'String',efdb.GraphDB(efdb.curGraph(1)).Data);
                efdb.DBInfo.isChanged=1;
                efdb = DrawGraphs(efdb);
            end
            if strcmp(eventdata.Key,'c')
                for graph=efdb.curGraph
                    efdb.GraphDB(graph).PlotColor=[];
                end
                efdb.DBInfo.isChanged=1;
                efdb = DrawGraphs(efdb);
            end
        end
        efdb_save(efdb);
    end
    function fhMotionFcn(hObject,~)
        efdb=efdb_load(hObject);
        fhIn=efdb.Handles.fh;
        p=get(fhIn,'CurrentPoint');
        if strcmp(efdb.Handles.GraphList.Enable,'on')
            if p(1)>efdb.DBInfo.geom.Graphsize && p(1)<=efdb.DBInfo.geom.Graphsize+5
                set(fhIn,'Pointer','right')
            else
                set(fhIn,'Pointer','arrow')
            end
        end
    end

    function TubePUMCallback(hObject,eventdata)
        efdb=efdb_load(hObject);
        for curGraph=efdb.curGraph
            efdb.GraphDB(curGraph).Data=efdb.TubeNames{get(hObject,'Value')};
            efdb.GraphDB(curGraph).DataDeconv=[];
            %set up the new gates for this tube
            curtube=matlab.lang.makeValidName(efdb.GraphDB(curGraph).Data);
            %keep gates that exist in the new tube
            if isfield(efdb,'GatesDB') && isfield(efdb.GatesDB,curtube)
                efdb.GraphDB(curGraph).Gates=efdb.GraphDB(curGraph).Gates(isfield(efdb.GatesDB.(curtube),efdb.GraphDB(curGraph).Gates));
            else
                efdb.GraphDB(curGraph).Gates=[];
            end
        end
        efdb=CalculateGatedData(efdb);
        efdb.DBInfo.isChanged=1;
        efdb=DataChange(efdb);
        efdb_save(efdb);
        GraphListCallback(efdb.Handles.GraphList,eventdata)
        efdb=CalculateMarkers(efdb);
        efdb_save(efdb);
    end
    function ColorPUMCallback(hObject,~)
        efdb=efdb_load(hObject);
        if strcmp(get(hObject,'String'),' ')
            return;
        end
        colorlist=get(hObject,'String');
        colorname=strtrim(strtok(colorlist(get(hObject,'Value')),':'));
        for curGraph=efdb.curGraph
            efdb.GraphDB(curGraph).Color=char(colorname);
            efdb.GraphDB(curGraph).DataDeconv=[];
        end
        %change color to show homogeneity
        set(efdb.Handles.ColorPUM,'ForegroundColor',[0 0 0]);
        efdb.DBInfo.isChanged=1;
        efdb = DrawGraphs(efdb);
        efdb=CalculateMarkers(efdb);
        efdb=DataChange(efdb);
        efdb_save(efdb);
    end
    function Color2PUMCallback(hObject,~)
        efdb=efdb_load(hObject);
        colorlist=get(hObject,'String');
        colorname=strtrim(strtok(colorlist(get(hObject,'Value')),':'));
        for curGraph=efdb.curGraph
            efdb.GraphDB(curGraph).Color2=char(colorname);
            efdb.GraphDB(curGraph).DataDeconv=[];
        end
        %change color to show homogeneity
        set(efdb.Handles.Color2PUM,'ForegroundColor',[0 0 0]);
        efdb.DBInfo.isChanged=1;
        %if the graph properties editor exists tell it to update the
        %buttons.
        %if not, only check that color2 is ok.
        if isfield(efdb.Handles,'graphprop')
            Args=guidata(efdb.Handles.graphprop);
            Args.SetEnabledBtnsFcn(efdb.Handles.fh,efdb.Handles.graphprop);
        else
            if get(efdb.Handles.Color2PUM,'Value')==1 ...color 2 is 'None'
                    && ~strcmp(efdb.Display.graph_type,'Histogram') %we must have histogram
                efdb.Display.graph_type='Histogram';
                efdb.Display.graph_type_Radio=4;
                efdb.Display.Changed=1;
                efdb.DBInfo.isChanged=1;
            end
        end
        efdb = DrawGraphs(efdb);
        efdb = CalculateMarkers(efdb);
        efdb = DataChange(efdb);
        efdb_save(efdb);
    end
    function AddBtnCallback(hObject,eventdata)
        efdb=efdb_load(hObject);
        %reselect selected graphs to save their configuration
        GraphListCallback(efdb.Handles.GraphList,eventdata);
        %add item to the GraphList and GraphDB and select the new graph
        List=get(efdb.Handles.GraphList,'String');
        curGraph=length(List)+1;
        List{curGraph}=['Graph_' num2str(curGraph)];
        %create the new item
        if ~isfield(efdb,'curGraph') || isempty(efdb.curGraph) || efdb.curGraph(1)==0
            efdb.GraphDB(curGraph).Name=['Graph_' num2str(curGraph)];
            efdb.GraphDB(curGraph).Data=char(efdb.TubeNames(1));
            efdb.GraphDB(curGraph).Ctrl='None';
            efdb.GraphDB(curGraph).Color='None';
            efdb.GraphDB(curGraph).Color2='None';
            efdb.GraphDB(curGraph).RemoveCtrl=0;
            efdb.GraphDB(curGraph).DataDeconv=[];
            efdb.GraphDB(curGraph).Gates={};
            efdb.GraphDB(curGraph).GatesOff={};
            %mArgsIn.GraphDB(curGraph).Markers={};
            efdb.GraphDB(curGraph).Stat=struct;
            efdb.GraphDB(curGraph).plotdata=[];
            efdb.GraphDB(curGraph).gatedindex=[];
            efdb.GraphDB(curGraph).gatedindexctrl=[];
            efdb.GraphDB(curGraph).Display=efdb.Display;
            efdb.GraphDB(curGraph).fit=[];
        else
            prevGraph=efdb.curGraph(1);
            efdb.GraphDB(curGraph).Name=['Graph_' num2str(curGraph)];
            efdb.GraphDB(curGraph).Data=efdb.GraphDB(prevGraph).Data;
            efdb.GraphDB(curGraph).Ctrl=efdb.GraphDB(prevGraph).Ctrl;
            efdb.GraphDB(curGraph).Color=efdb.GraphDB(prevGraph).Color;
            efdb.GraphDB(curGraph).Color2=efdb.GraphDB(prevGraph).Color2;
            efdb.GraphDB(curGraph).RemoveCtrl=efdb.GraphDB(prevGraph).RemoveCtrl;
            efdb.GraphDB(curGraph).DataDeconv=efdb.GraphDB(prevGraph).DataDeconv;
            efdb.GraphDB(curGraph).Gates=efdb.GraphDB(prevGraph).Gates;
            efdb.GraphDB(curGraph).GatesOff=efdb.GraphDB(prevGraph).GatesOff;
            %mArgsIn.GraphDB(curGraph).Markers=mArgsIn.GraphDB(prevGraph).Markers;
            efdb.GraphDB(curGraph).Stat=efdb.GraphDB(prevGraph).Stat;
            efdb.GraphDB(curGraph).plotdata=efdb.GraphDB(prevGraph).plotdata;
            efdb.GraphDB(curGraph).gatedindex=efdb.GraphDB(prevGraph).gatedindex;
            efdb.GraphDB(curGraph).gatedindexctrl=efdb.GraphDB(prevGraph).gatedindexctrl;
            efdb.GraphDB(curGraph).Display=efdb.GraphDB(prevGraph).Display;
            efdb.GraphDB(curGraph).fit=efdb.GraphDB(prevGraph).fit;
        end
        set(efdb.Handles.GraphList,'String',List);
        set(efdb.Handles.GraphList,'Value',curGraph);
        efdb.DBInfo.isChanged=1;
        efdb_save(efdb);
        GraphListCallback(efdb.Handles.GraphList,eventdata);
    end
    function DelBtnCallback(hObject,eventdata)
        %delete item from the GraphList and GraphDB and select the previous
        %one
        efdb=efdb_load(hObject);
        selected=get(efdb.Handles.GraphList,'Value');
        if selected==0
            return;
        end
        efdb.GraphDB(selected)=[];
        
        List=get(efdb.Handles.GraphList,'String');
        List(selected)=[];
        efdb.curGraph=min(min(selected),length(List));
        
        set(efdb.Handles.GraphList,'Value',efdb.curGraph);
        set(efdb.Handles.GraphList,'String',List);
        
        efdb.DBInfo.isChanged=1;
        efdb_save(efdb);
        GraphListCallback(efdb.Handles.GraphList,eventdata);
    end
    function ColorBtnCallback(hObject,~)
        efdb=efdb_load(hObject);
        color=uisetcolor;
        if ~isscalar(color)
            [efdb.GraphDB(efdb.curGraph).PlotColor]=deal(color);
        end
        efdb.DBInfo.isChanged=1;
        efdb = DrawGraphs(efdb);
        efdb_save(efdb);
    end
    function GraphNameCallback(hObject,~)
        efdb=efdb_load(hObject);
        List=get(efdb.Handles.GraphList,'String');
        List{get(efdb.Handles.GraphList,'Value')}=get(hObject,'String');
        set(efdb.Handles.GraphList,'String',List);
        efdb.GraphDB(get(efdb.Handles.GraphList,'Value')).Name=get(hObject,'String');
        efdb.DBInfo.isChanged=1;
        efdb_save(efdb);
    end
    function GraphListCallback(hObject,~)
        efdb=efdb_load(hObject);
        fhIn=efdb.Handles.fh;
        %if changed, save the display settings for the old graphs
        graphlist=get(hObject,'Value');
        if isfield(efdb.Display,'Changed') && efdb.Display.Changed==1
            for graph=efdb.curGraph %this is the previously selected graphs
                efdb.GraphDB(graph).Display=efdb.Display;
            end
        end
        if isempty(graphlist)
            return
        elseif graphlist(1)==0 %no graphs
            efdb.curGraph=0;
            set(efdb.Handles.TubePUM,'Enable','off');
            set(efdb.Handles.ColorPUM,'Enable','off');
            set(efdb.Handles.Color2PUM,'Enable','off');
            set(efdb.Handles.GraphName,'Enable','off');
            set(efdb.Handles.ColorBtn,'Enable','off');
            return
        else
            %clear plotdata from old plotted graphs
            if isfield(efdb,'curGraph') && ~isempty(efdb.curGraph) && ~any(efdb.curGraph==0)
                [efdb.GraphDB(efdb.curGraph).plotdata]=deal([]);
            end
            
            efdb.curGraph=graphlist;
            %enable compnents,
            %read the TopPanel parameters for the first one of the graphs and verify them
            %ColorBtn
            set(efdb.Handles.ColorBtn,'Enable','on');
            %Name
            if isscalar(efdb.curGraph)
                set(efdb.Handles.GraphName,'Enable','on');
                if ~isfield(efdb.GraphDB(efdb.curGraph(1)),'Name') || ~ischar(efdb.GraphDB(efdb.curGraph(1)).Name)
                    efdb.GraphDB(efdb.curGraph(1)).Name=['Graph_' num2str(efdb.curGraph(1))];
                end
                set(efdb.Handles.GraphName,'String',efdb.GraphDB(efdb.curGraph(1)).Name);
            else
                set(efdb.Handles.GraphName,'Enable','off');
                set(efdb.Handles.GraphName,'String',efdb.GraphDB(efdb.curGraph(1)).Name);
            end
            %Data
            set(efdb.Handles.TubePUM,'Enable','on');
            if length(unique({efdb.GraphDB(efdb.curGraph).Data}))==1
                set(efdb.Handles.TubePUM,'ForegroundColor',[0 0 0]);
                %23/3/9     DataNumber=find(cellfun(@(x) strcmp(x,mArgsIn.GraphDB(mArgsIn.curGraph(1)).Data),mArgsIn.TubeNames),1);
                DataNumber=find(strcmp(efdb.GraphDB(efdb.curGraph(1)).Data,efdb.TubeNames),1);
                if DataNumber
                    set(efdb.Handles.TubePUM,'Value',DataNumber);
                else
                    set(efdb.Handles.TubePUM,'Value',1);
                end
            else
                set(efdb.Handles.TubePUM,'ForegroundColor',[1 0 0]);
                set(efdb.Handles.TubePUM,'Value',1);
            end
            
            %set up the new gates for this graph
            UpdateGateList(efdb);
            
            %Color and color2
            %create the common colors lists.
            %if the data tube is not found or one of the graph is
            %none, the list is empty
            if isfield(efdb.TubeDB,'Tubename') && length(unique([efdb.TubeDB.Tubename,{efdb.GraphDB(efdb.curGraph).Data}]))==length(unique([efdb.TubeDB.Tubename]))
                tubeidx=arrayfun(@(x) find(strcmp([efdb.TubeDB.Tubename],x),1,'first'), {efdb.GraphDB(efdb.curGraph).Data});
                allparname=[efdb.TubeDB(tubeidx).parname];
                [allparname,m,n]=unique(allparname(:),'first');
                apearencenum=histcounts(n,1:length(allparname));
                %take all param that appear in all tubes and sort them according to
                %their apearence order
                parname=allparname(apearencenum==length(efdb.curGraph));
                m=m(apearencenum==length(efdb.curGraph));
                [msort,indx]=sort(m);
                parname=char(parname(indx));%=allparname(msort)
                allparsym=[efdb.TubeDB(tubeidx).parsymbol];
                parsym=char(allparsym(msort));
                seperator=char(ones(size(parname,1),1)*': ');
                %set new lists with the colors
                set(efdb.Handles.ColorPUM,'String',[{'None'};cellstr([parname,seperator,parsym])]);
                set(efdb.Handles.Color2PUM,'String',[{'None'};cellstr([parname,seperator,parsym])]);
            else
                set(efdb.Handles.ColorPUM,'String',{'None'});
                set(efdb.Handles.Color2PUM,'String',{'None'});
            end
            set(efdb.Handles.ColorPUM,'Enable','on');
            if length(unique({efdb.GraphDB(efdb.curGraph).Color}))==1
                set(efdb.Handles.ColorPUM,'ForegroundColor',[0 0 0]);
                colorlist=strtrim(strtok(get(efdb.Handles.ColorPUM,'String'),':'));
                colorind=find(strcmp(colorlist,efdb.GraphDB(efdb.curGraph(1)).Color),1,'first');
                if colorind
                    set(efdb.Handles.ColorPUM,'Value',colorind);
                else
                    set(efdb.Handles.ColorPUM,'Value',1);
                end
            else
                set(efdb.Handles.ColorPUM,'ForegroundColor',[1 0 0]);
                set(efdb.Handles.ColorPUM,'Value',1);
            end
            set(efdb.Handles.Color2PUM,'Enable','on');
            if length(unique({efdb.GraphDB(efdb.curGraph).Color2}))==1
                set(efdb.Handles.Color2PUM,'ForegroundColor',[0 0 0]);
                color2list=strtrim(strtok(get(efdb.Handles.Color2PUM,'String'),':'));
                color2ind=find(strcmp(color2list,efdb.GraphDB(efdb.curGraph(1)).Color2),1,'first');
                if color2ind
                    set(efdb.Handles.Color2PUM,'Value',color2ind);
                else
                    set(efdb.Handles.Color2PUM,'Value',1);
                end
            else
                set(efdb.Handles.Color2PUM,'ForegroundColor',[1 0 0]);
                set(efdb.Handles.Color2PUM,'Value',1);
            end
            
            %read the display settings from the first graph, and update the
            %figure prop window.
            if isfield(efdb.GraphDB(efdb.curGraph(1)),'Display') && ~isempty(efdb.GraphDB(efdb.curGraph(1)).Display)
                efdb.Display=efdb.GraphDB(efdb.curGraph(1)).Display;
                if isfield(efdb.Display,'Axis')
                    set(findobj(fhIn,'Label','Fix Axis'), 'Checked', 'on');
                else
                    set(findobj(fhIn,'Label','Fix Axis'), 'Checked', 'off');
                end
                if isfield(efdb.Handles,'graphprop')
                    guidata(fhIn,efdb);
                    Args=guidata(efdb.Handles.graphprop);
                    Args.SetEnabledBtnsFcn(fhIn,efdb.Handles.graphprop);
                    efdb=guidata(fhIn);
                end
                efdb.Display.Changed=0;
            end
            %update the compensation window
            if isfield(efdb.Handles,'compensation')
                guidata(fhIn,efdb);
                Args=guidata(efdb.Handles.compensation);
                Args.fUpdateComp(fhIn);
                efdb=guidata(fhIn);
            end
        end
        efdb.DBInfo.isChanged=1;
        %Draw Graphs
        efdb = DrawGraphs(efdb);
        efdb_save(efdb);
    end
    function GateListCallback(hObject,~)
        efdb=efdb_load(hObject);
        gatename=get(hObject,'Tag');
        for graph=get(efdb.Handles.GraphList,'Value')
            efdb.GraphDB(graph).DataDeconv=[];
            efdb.GraphDB(graph).Gates(strcmp(efdb.GraphDB(graph).Gates,gatename))=[];
            efdb.GraphDB(graph).GatesOff(strcmp(efdb.GraphDB(graph).GatesOff,gatename))=[];
            if get(hObject,'Value')==1
                efdb.GraphDB(graph).Gates{end+1}=gatename;
            else
                efdb.GraphDB(graph).GatesOff{end+1}=gatename;
            end
        end
        efdb.DBInfo.isChanged=1;
        guidata(fh,efdb)
        %Update list, and Draw Graphs
        %tbd: maybe change this to the general datachange function
        efdb=CalculateGatedData(efdb);
        UpdateGateList(efdb);
        efdb = DrawGraphs(efdb);
        efdb_save(efdb);
    end

    function mSessionCallback(hObject,varargin)
        fhIn=ancestor(hObject,'figure');
        efdbIn=guidata(fhIn);
        filemenu=get(hObject,'Children');
        set(filemenu,'Enable','on');
        if ~isfield(efdbIn,'DBInfo') || ~isfield(efdbIn.DBInfo,'Name') || ~exist(efdbIn.DBInfo.Name,'file')
            set(filemenu(strcmp(get(filemenu,'Label'),'Save')),'Enable','off');
        end
        if isfield(efdbIn,'DBInfo') && isfield(efdbIn.DBInfo,'isChanged') && efdbIn.DBInfo.isChanged==0
            set(filemenu(strcmp(get(filemenu,'Label'),'Save')),'Enable','off');
            set(filemenu(strcmp(get(filemenu,'Label'),'Save As...')),'Enable','off');
        end
        if isempty(efdbIn.GraphDB)
            set(filemenu,'Enable','off');
            set(findobj(hObject,'Label','Open Session...'),'Enable','on');
        end
        MenuFileRelpath=findobj(hObject,'Label','Use Relative Path');
        if isfield(efdbIn.DBInfo,'RootFolder')
            MenuFileRelpath.Checked='on';
        else
            MenuFileRelpath.Checked='off';
        end        
        if isequal(rmfield(efdbIn,'Handles'),rmfield(init_efdb,'Handles'))
            set(findobj(hObject,'Label', 'New Session'),'Enable','off')
        else
            set(findobj(hObject,'Label', 'New Session'),'Enable','on')
        end
    end
    function mDataCallback(hObject,varargin)
        fhIn=ancestor(hObject,'figure');
        efdbIn=guidata(fhIn);
        menuobj=get(hObject,'Children');
        set(menuobj,'Enable','on');
        if isempty(efdbIn.TubeDB)
            set(menuobj,'Enable','off');
        end
        item = findobj(hObject, 'Label', 'Load Data Files...');
        item.Enable='on';
        item = findobj(hObject, 'Label', 'Load Data Folder...');
        item.Enable='on';
    end
    function mGraphsCallback(hObject,~)
        mArgsIn=guidata(fh);
        set(get(hObject,'Children'),'Enable','on');
        if isempty(mArgsIn.GraphDB)
            set(get(hObject,'Children'),'Enable','off');
            set(findobj(hObject,'Label','Add all tubes'),'Enable','on');
        elseif strcmp(mArgsIn.Display.graph_type,'Histogram')
            set(findobj(hObject,'Label','Load Fit'),'Enable','on');
            if isscalar(mArgsIn.curGraph)
                set(findobj(hObject,'Label','New Fit'),'Enable','on');
            else
                set(findobj(hObject,'Label','New Fit'),'Enable','off');
            end
        else
            set(findobj(hObject,'Label','Load Fit'),'Enable','off');
            set(findobj(hObject,'Label','New Fit'),'Enable','off');
        end
        guidata(fh,mArgsIn);
    end
    function mDisplayCallback(hObject,~)
        mArgsIn=guidata(fh);
        if strcmp(mArgsIn.Display.graph_type,'Histogram')
            set(findobj(hObject,'Label','Quadrants'),'Enable','off');
        else
            set(findobj(hObject,'Label','Quadrants'),'Enable','on');
        end
    end
    function mGatesCallback(hObject,~)
        fhIn=ancestor(hObject,'figure');
        efdbIn=guidata(fhIn);
        if isempty(efdbIn.curGraph) 
            set(hObject.Children,'Enable','off')
        else
            set(hObject.Children,'Enable','on')
        end
        if strcmp(efdbIn.Display.graph_type,'Histogram')
            set(findobj(hObject,'Label','Add Contour Gate'),'Enable','off');
        end
        if isempty(fieldnames(efdbIn.GatesDBnew))
            set(findobj(hObject,'Label','Add Logical Gate'),'Enable','off');
        end
        % it the menu is called not on a gate, disable editing options
        if strcmp(get(gco,'Tag'),'GateList')
            set(findobj(hObject,'Label','Remove Gate'),'Enable','off');
            set(findobj(hObject,'Label','Edit Gates'),'Enable','off');
        end
    end

    function SessionNewCallback(varargin)
        eval(mfilename);
    end
    function SessionLoadCallback(hObject,eventdata,filename)
        fhIn=ancestor(hObject,'figure');
        efdbIn=guidata(fhIn);
        set(fhIn,'pointer','watch');
        if exist('filename','var') %Load input session file
            [dname,fname,fext]=fileparts(filename);
            if isempty(dname)
                %only filename with no directory
                dname=pwd;
            end
            if isempty(fext)
                %defult efl extension
                fext='.efl';
            end
            dirname=[dname filesep];
            filename=[fname,fext];
        else %Browse for file to open
            if isfield(efdbIn,'DBInfo') && isfield(efdbIn.DBInfo,'Path') && ischar(efdbIn.DBInfo.Path) && exist(efdbIn.DBInfo.Path,'dir')
                [filename,dirname]=uigetfile('*.efl','Open Analysis',efdbIn.DBInfo.Path);
            else
                [filename,dirname]=uigetfile('*.efl','Open Analysis',pwd);
            end
        end
        if ~ischar(filename) || ~exist([dirname,filename],'file')
            set(fhIn,'pointer','arrow');
            return
        end
        
        %if this is not a new window with empty database then open a new
        %easyflow instance
        if ~isempty(efdbIn.TubeDB) || ~isempty(efdbIn.GraphDB)
            eval([mfilename '(''' [dirname,filename] ''')'])
            return
        end
        
        readargs=load('-mat',[dirname,filename]);
        %move these into updateversion when having a new version
        %until here        
        if isfield(readargs,'sArgs')
            sArgs=readargs.sArgs;
            %update the file to the new version
            oldmArgsIn=efdbIn;
            if ~isfield(sArgs,'version') || sArgs.version~=curversion
                sArgs=UpdateVersion(sArgs);
                if isempty(sArgs)
                    guidata(fhIn,oldmArgsIn);
                    set(fhIn,'pointer','arrow');
                    return;
                end
            end
            if ischar(dirname) && exist(dirname,'dir')
                sArgs.DBInfo.Path=dirname;
            end
            sArgs.DBInfo.Name=[dirname,filename];
            sArgs.DBInfo.isChanged=0;
            %if needed change paths to absolute
            if isfield(sArgs.DBInfo,'RootFolder')
                sArgs=rel2abspath(sArgs);
            end
            %add the handles
            sArgs.Handles=efdbIn.Handles;
            %set up either the loaded tubeDB or load the saved one
            if ~isfield(sArgs,'TubeDB')
                if isempty(efdbIn.TubeDB)
                    msgbox('File does not contain tubes. Please load the tubes first.','EasyFlow','error','modal');
                    uiwait;
                    return
                else
                    button='Current';
                end
            elseif ~isempty(efdbIn.TubeDB)
                button = questdlg('Load saved tubes or use current?.','Load Session','Saved', 'Current', 'Saved');
                set(fhIn,'pointer','watch');
            else
                button='Saved';
            end
            if strcmp(button,'Saved')
                foundall=1;
                usenewdir=0;
                newdir=pwd;
                tic; ntot=length(sArgs.TubeDB);
                h=waitbar(0,'Loading Tubes...');
                tmpTubeDB=cell(length(sArgs.TubeDB),1);
                for i=1:length(sArgs.TubeDB)
                    if exist([sArgs.TubeDB(i).tubepath filesep sArgs.TubeDB(i).tubefile],'file')
                        fcsfile=fcsload([sArgs.TubeDB(i).tubepath filesep sArgs.TubeDB(i).tubefile]);
                    elseif usenewdir==1 && exist([newdir filesep sArgs.TubeDB(i).tubefile],'file') 
                        fcsfile=fcsload([newdir filesep sArgs.TubeDB(i).tubefile]);
                    else
                        tmpbutton = questdlg(['Cannot find ' sArgs.TubeDB(i).tubefile ...
                            'in directory ' sArgs.TubeDB(i).tubepath ...
                            '.'],'Load Session','Browse', 'Skip', 'Browse');
                        if strcmp(tmpbutton,'Next')
                            foundall=0;
                            continue
                        else
                            tmpnewdir=uigetdir(sArgs.DBInfo.Path,'Select Samples Folder');
                            sArgs.DBInfo.Path=tmpnewdir;
                            fcsfile=fcsload([tmpnewdir filesep sArgs.TubeDB(i).tubefile]);
                            usenewdir=1;
                            newdir=tmpnewdir;
                        end
                    end
                    if isempty(fcsfile)
                        foundall=0;
                        continue
                    end
                    tmpTubeDB{i}=LoadTube(fcsfile);
                    waitbar(i/ntot,h,['Loading Tubes (' num2str(ceil(toc*(ntot/i-1))) ' sec)']);
                end
                tmpTubeDB=cell2mat(tmpTubeDB);
                close(h);
                if foundall==0
                    msgbox('Some tubes were not opend successfully.','EasyFlow','error','modal');
                    uiwait;
                end
                
                if exist('tmpTubeDB','var')
                    [tmpTubeDB.Tubename]=deal(sArgs.TubeDB.Tubename);
                    sArgs.TubeDB=tmpTubeDB;
                else
                    msgbox('Cannot find fcs files.','EasyFlow','error','modal');
                    uiwait;
                    sArgs.TubeDB=[];
                end
            else
                sArgs.TubeDB=efdbIn.TubeDB;
            end
            
        else
            sArgs=efdbIn;
        end
        guidata(fhIn,sArgs)
        efdbIn=guidata(fhIn);
        % reread the tubes
        if ~isempty(efdbIn.TubeDB)
            efdbIn.TubeNames=[{'None'};[efdbIn.TubeDB.Tubename]'];
        else
            efdbIn.TubeNames={'None'};
        end
        set(efdbIn.Handles.TubePUM,'String',efdbIn.TubeNames);
        
        % initialize GraphDB and set all DataDeconv to []
        if isfield(efdbIn.GraphDB,'DataDeconv')
            efdbIn.GraphDB=rmfield(efdbIn.GraphDB,'DataDeconv');
            efdbIn.GraphDB(efdbIn.curGraph(1)).DataDeconv=[];
        end
        %read the graph list
        if isfield(efdbIn.GraphDB,'Name')
            List={efdbIn.GraphDB.Name};
            set(efdbIn.Handles.GraphList,'String',List);
            set(efdbIn.Handles.GraphList,'Value',efdbIn.curGraph);
        end
        %update the gate list
        UpdateGateList(efdbIn);
        guidata(fhIn,efdbIn);
        GraphListCallback(efdbIn.Handles.GraphList,[]);
        set(fhIn,'pointer','arrow')
        [~ ,name]=fileparts(efdbIn.DBInfo.Name);
        set(fhIn,'Name',['EasyFlow - FACS Analysis Tool (' name ')'])
        %resize the gui to the saved configuration
        fhResizeFcn(fhIn,eventdata)
        %finally, if I just opened the file, ischanged=0;
        efdbIn=guidata(fhIn);
        efdbIn.DBInfo.isChanged=0;
        guidata(fhIn,efdbIn);
    end
    function SessionSaveCallback(~,~)
        mArgsIn=guidata(fh);
        sArgs=mArgsIn;
        %remove raw data and handles before saving
        sArgs.TubeDB=rmfield(sArgs.TubeDB,'fcsfile');
        sArgs.TubeDB=rmfield(sArgs.TubeDB,'compdata');
        sArgs=rmfield(sArgs,'Handles');
        %if needed change paths to relative
        if isfield(sArgs.DBInfo,'RootFolder')
            sArgs=abs2relpath(sArgs);
        end
        sArgs.DBInfo.Path='';
        sArgs.DBInfo.Name='';
        sArgs.DBInfo.enabled_gui='';
        if ~isfield(mArgsIn,'DBInfo') || ~isfield(mArgsIn.DBInfo,'Name') || ~exist(mArgsIn.DBInfo.Name,'file')
            msgbox('No file selected. Use Save As.','EasyFlow','error','modal');
            uiwait;
            return
        end
        mArgsIn.DBInfo.isChanged=0;
        save(mArgsIn.DBInfo.Name,'sArgs');
        guidata(fh,mArgsIn);
        [~ ,name]=fileparts(mArgsIn.DBInfo.Name);
        set(fh,'Name',['EasyFlow - FACS Analysis Tool (' name ')'])
    end
    function SessionSaveAsCallback(~,~)
        mArgsIn=guidata(fh);
        sArgs=mArgsIn;
        %remove raw data and handles before saving
        sArgs.TubeDB=rmfield(sArgs.TubeDB,'fcsfile');
        sArgs.TubeDB=rmfield(sArgs.TubeDB,'compdata');
        sArgs=rmfield(sArgs,'Handles');
        %if needed change paths to relative
        if isfield(sArgs.DBInfo,'RootFolder')
            sArgs=abs2relpath(sArgs);
        end
        sArgs.DBInfo.Path='';
        sArgs.DBInfo.Name='';
        sArgs.DBInfo.enabled_gui='';
        if isfield(mArgsIn.DBInfo,'Path') && ischar(mArgsIn.DBInfo.Path) && exist(mArgsIn.DBInfo.Path,'dir')
            [file,path] = uiputfile('*.efl','Save As',mArgsIn.DBInfo.Path);
        else
            [file,path] = uiputfile('*.efl','Save As',pwd);
        end
        if ischar(path) && exist(path,'dir')
            mArgsIn.DBInfo.Path=path;
        end
        mArgsIn.DBInfo.Name=[path,file];
        save(mArgsIn.DBInfo.Name,'sArgs');
        mArgsIn.DBInfo.isChanged=0;
        guidata(fh,mArgsIn);
        [~ ,name]=fileparts(mArgsIn.DBInfo.Name);
        set(fh,'Name',['EasyFlow - FACS Analysis Tool (' name ')'])
    end
    function SessionExportCallback(~,~)
        mArgsIn=guidata(fh);
        export2wsdlg({'Save MetaData as:'},{'mArgsIn'},{mArgsIn});
        guidata(fh,mArgsIn)
    end
    function SessionUseRelPath(~,~)
        mArgsIn=guidata(fh);
        MenuFileRelpath=findobj(fh,'Label','Use Relative Path');
        if strcmp(MenuFileRelpath.Checked,'off')
            MenuFileRelpath.Checked='on';
            mArgsIn.DBInfo.RootFolder='.';
            mArgsIn.DBInfo.isChanged=1;
        else
            MenuFileRelpath.Checked='off';
            mArgsIn.DBInfo=rmfield(mArgsIn.DBInfo,'RootFolder');
            mArgsIn.DBInfo.isChanged=1;
        end
        guidata(fh,mArgsIn)
    end

    function SampleLoadCallback(~,~)
        set(fh,'pointer','watch');
        mArgsIn=guidata(fh);
        if isfield(mArgsIn,'DBInfo') && isfield(mArgsIn.DBInfo,'Path') && ischar(mArgsIn.DBInfo.Path) && exist(mArgsIn.DBInfo.Path,'dir')
            [filename,dirname]=uigetfile('*.fcs','Open Tubes',mArgsIn.DBInfo.Path,'MultiSelect','on');
        else
            [filename,dirname]=uigetfile('*.fcs','Open Tubes',pwd,'MultiSelect','on');
        end
        if ischar(dirname) && exist(dirname,'dir')
            mArgsIn.DBInfo.Path=dirname;
        end
        if ischar(filename)
            filename={filename};
        elseif isnumeric(filename) && filename==0
            set(fh,'pointer','arrow');
            return
        end
        tic; ntot=length(filename); loopnum=0;
        h=waitbar(0,'Loading Tubes...','WindowStyle','modal');
        for curfile=filename
            if ~exist([dirname char(curfile)],'file')
                continue
            end
            fcsfile=fcsload([dirname char(curfile)]);
            if isempty(fcsfile)
                continue
            end
            % the TUBE NAME is the field by which the tube is named, if not
            % use filname and make a tubename field
            ctube=LoadTube(fcsfile);
            if ~isempty(mArgsIn.TubeDB)
                %automatically make tubename unique
                tubename=matlab.lang.makeUniqueStrings(ctube.Tubename{1},[mArgsIn.TubeDB.Tubename]);
                ctube.fcsfile=fcssetparam(ctube.fcsfile,'TUBE NAME',tubename);
                ctube.Tubename{1}=tubename;

                if isempty(ctube.Tubename{1})
                    continue
                elseif any(strcmp(strcat({mArgsIn.TubeDB.tubepath},{mArgsIn.TubeDB.tubefile}),[ctube.tubepath ctube.tubefile]))
                    %there is a different tube with the same file path.
                    msgbox(['Can''t open file ' fcsfile.filename '. The file is already open.'],'EasyFlow','error','modal');
                    uiwait;
                    continue;
                end
            end
            mArgsIn.TubeDB(end+1)=ctube;
            % if this tube already appears in the graphDB then recalc gated
            % data
            if isfield(mArgsIn,'curGraph') && ~isempty(mArgsIn.curGraph)
                tmpcur=mArgsIn.curGraph;
                mArgsIn.curGraph=find(strcmp({mArgsIn.GraphDB.Name},mArgsIn.TubeDB(end).Tubename));
                mArgsIn=CalculateGatedData(mArgsIn);
                mArgsIn.curGraph=tmpcur;
            end
            loopnum=loopnum+1;
            waitbar(loopnum/ntot,h,['Loading Tubes (' num2str(ceil(toc*(ntot/loopnum-1))) ' sec)']);
        end
        close(h);
        mArgsIn.TubeNames=[{'None'};[mArgsIn.TubeDB.Tubename]'];
        set(mArgsIn.Handles.TubePUM,'String',mArgsIn.TubeNames);
        guidata(fh,mArgsIn);
        set(fh,'pointer','arrow');
    end
    function FolderLoadCallback(~,~)
        set(fh,'pointer','watch');
        mArgsIn=guidata(fh);
        if isfield(mArgsIn,'DBInfo') && isfield(mArgsIn.DBInfo,'Path') && ischar(mArgsIn.DBInfo.Path) && exist(mArgsIn.DBInfo.Path,'dir')
            dirname=uigetdir(mArgsIn.DBInfo.Path,'Open Tubes');
        else
            dirname=uigetdir(pwd,'Open Tubes');
        end
        if exist(dirname,'dir')
            mArgsIn.DBInfo.Path=dirname;
        end
        filename = dir([dirname, filesep, '**', filesep, '*.fcs'])';
        tic; ntot=length(filename); loopnum=0;
        h=waitbar(0,'Loading Tubes...','WindowStyle','modal');
        for curfilestruct=filename
            dirname = curfilestruct.folder;
            curfile = curfilestruct.name;
            if ~exist([dirname filesep char(curfile)],'file')
                continue
            end
            fcsfile=fcsload([dirname filesep char(curfile)]);
            if isempty(fcsfile)
                continue
            end
            % the TUBE NAME is the field by which the tube is named, if not
            % use filname and make a tubename field
            ctube=LoadTube(fcsfile);
            if ~isempty(mArgsIn.TubeDB)
                %automatically make tubename unique
                tubename=matlab.lang.makeUniqueStrings(ctube.Tubename{1},[mArgsIn.TubeDB.Tubename]);
                ctube.fcsfile=fcssetparam(ctube.fcsfile,'TUBE NAME',tubename);
                ctube.Tubename{1}=tubename;


                if isempty(ctube.Tubename{1})
                    continue
                elseif any(strcmp(strcat({mArgsIn.TubeDB.tubepath},{mArgsIn.TubeDB.tubefile}),[ctube.tubepath ctube.tubefile]))
                    %there is a different tube with the same file path.
                    msgbox(['Can''t open file ' fcsfile.filename '. The file is already open.'],'EasyFlow','error','modal');
                    uiwait;
                    continue;
                end
            end
            mArgsIn.TubeDB(end+1)=ctube;
            % if this tube already appears in the graphDB then recalc gated
            % data
            if isfield(mArgsIn,'curGraph') && ~isempty(mArgsIn.curGraph)
                tmpcur=mArgsIn.curGraph;
                mArgsIn.curGraph=find(strcmp({mArgsIn.GraphDB.Name},mArgsIn.TubeDB(end).Tubename));
                mArgsIn=CalculateGatedData(mArgsIn);
                mArgsIn.curGraph=tmpcur;
            end
            loopnum=loopnum+1;
            waitbar(loopnum/ntot,h,['Loading Tubes (' num2str(ceil(toc*(ntot/loopnum-1))) ' sec)']);
        end
        close(h);
        mArgsIn.TubeNames=[{'None'};[mArgsIn.TubeDB.Tubename]'];
        set(mArgsIn.Handles.TubePUM,'String',mArgsIn.TubeNames);
        guidata(fh,mArgsIn);
        set(fh,'pointer','arrow');
    end
    function TubeSaveCallback(~,~)
        mArgsIn=guidata(fh);
        button = questdlg('Do you really want to overwrite tube data files? you should save an original version of the files.', 'Save Tubes', 'Save', 'Cancel', 'Cancel');
        if strcmp(button,'Save')
            fcssave([mArgsIn.TubeDB.fcsfile],1);
        end
    end
    function TubeShowPrmCallback(~,~)
        mArgsIn=guidata(fh);
        S=mArgsIn.TubeNames(2:end);
        if isempty(S)
            msgbox('No open tubes were found.','EasyFlow','error','modal');
            uiwait;
            return;
        end
        [Selection,ok] = listdlg('ListString',S,'Name','Select Tube','PromptString','Select tubes to rename','SelectionMode','single');
        if ok==0
            return;
        end        
        if ok==1
            i=Selection;
            fcsedit(mArgsIn.TubeDB(i).fcsfile);
            guidata(fh,mArgsIn);
        end
    end
    function TubeRemoveCallback(~,eventdata)
        mArgsIn=guidata(fh);
        if ~isfield(mArgsIn.TubeDB,'Tubename')
            msgbox('No open tubes were found.','EasyFlow','error','modal');
            uiwait;
            return;
        end
        S=[mArgsIn.TubeDB.Tubename];
        if isempty(S)
            msgbox('No open tubes were found.','EasyFlow','error','modal');
            uiwait;
            return;
        end
        [Selection,ok] = listdlg('ListString',S,'Name','Select Tube','PromptString','Select tubes to be removed','OKString','Remove');
        if ok==1
            % remove it from the TubeDB structures
            mArgsIn.TubeDB=mArgsIn.TubeDB(setdiff(1:length(S),Selection));
            if isfield(mArgsIn,'GatesDB')
                mArgsIn.GatesDB=rmfield(mArgsIn.GatesDB,intersect(matlab.lang.makeValidName(S(Selection)),fieldnames(mArgsIn.GatesDB)));
            end
            mArgsIn.TubeNames=[{'None'};[mArgsIn.TubeDB.Tubename]'];
            set(mArgsIn.Handles.TubePUM,'String',mArgsIn.TubeNames);
        end
        %reread graphs
        guidata(fh,mArgsIn);
        GraphListCallback(mArgsIn.Handles.GraphList,eventdata)
    end
    function TubeRenameCallback(~,~)
        mArgsIn=guidata(fh);
        S=mArgsIn.TubeNames(2:end);
        if isempty(S)
            msgbox('No open tubes were found.','EasyFlow','error','modal');
            uiwait;
            return;
        end
        [Selection,ok] = listdlg('ListString',S,'Name','Select Tube','PromptString','Select tubes to rename');
        if ok==0
            return;
        end
        renamerule=inputdlg('Enter the new name. Use $ as the original tube name');
        if isempty(renamerule)
            return;
        end
        
        if ok==1
            for i=Selection
                %check that the new name does not exists
                if any(strcmp([mArgsIn.TubeDB([1:i-1,i+1:end]).Tubename],strrep(renamerule, '$', S(i))))
                    %tubename already already exists, continue
                    msgbox(['Can''t rename ' mArgsIn.TubeDB(i).Tubename ' to ' strrep(renamerule, '$', S(i)) '. The new tube name already exists.'],'EasyFlow','error','modal');
                    uiwait;
                    continue;
                end
                % rename it in the TubeDB structures
                mArgsIn.TubeDB(i).Tubename=strrep(renamerule, '$', S(i));
                % change in the fcsfiles
                mArgsIn.TubeDB(i).fcsfile=fcssetparam(mArgsIn.TubeDB(i).fcsfile,'TUBE NAME',mArgsIn.TubeDB(i).Tubename{1});
                % replace the names in the GraphDB and GatesDB
                if ~isempty(mArgsIn.GraphDB)
                    [mArgsIn.GraphDB(strcmp({mArgsIn.GraphDB.Data},S(i))).Data]=deal(strrep(char(renamerule), '$', S{i}));
                end
                if isfield(mArgsIn,'GatesDB') && isfield(mArgsIn.GatesDB,matlab.lang.makeValidName(S(i)))
                    mArgsIn.GatesDB.(matlab.lang.makeValidName(strrep(char(renamerule), '$', S{i})))=mArgsIn.GatesDB.(matlab.lang.makeValidName(S{i}));
                    mArgsIn.GatesDB=rmfield(mArgsIn.GatesDB,matlab.lang.makeValidName(S{i}));
                end
            end
            mArgsIn.TubeNames=[{'None'};[mArgsIn.TubeDB.Tubename]'];
            set(mArgsIn.Handles.TubePUM,'String',mArgsIn.TubeNames);
            guidata(fh,mArgsIn);
        end
    end
    function FileTubeRenameCallback(~,~)
        mArgsIn=guidata(fh);
        S=mArgsIn.TubeNames(2:end);
        if isempty(S)
            msgbox('No open tubes were found.','EasyFlow','error','modal');
            uiwait;
            return;
        end
        % open an xls file with the renaming
        if isfield(mArgsIn,'DBInfo') && isfield(mArgsIn.DBInfo,'Path') && ischar(mArgsIn.DBInfo.Path) && exist(mArgsIn.DBInfo.Path,'dir')
            [xlsfilename,targetdir]=uigetfile('.xlsx','Open Template',mArgsIn.DBInfo.Path);
        else
            [xlsfilename,targetdir]=uigetfile('.xlsx','Open Template',pwd);
        end
        if ~ischar(targetdir)
            return
        end
        mArgsIn.DBInfo.Path=targetdir;
        enabled_gui=findobj(fh,'Enable','on');
        set(enabled_gui,'Enable','off');
        set(fh,'pointer','watch');
        drawnow
        [~,~,template]=xlsread([targetdir,xlsfilename]);
        template=cellfun(@num2str,template,'uni',0);
        
        for i=1:size(template,1)
            %use the filename to get the tubename
            tubenum=find(strcmp({mArgsIn.TubeDB.tubefile}',[template{i,1},'.fcs']));
            if isempty(tubenum)
                continue
            end
            NonEmptyFields=~strcmp(template(i,1:end),'NaN');
            NonEmptyFields(1)=0;
            newtubename={strjoin(template(i,NonEmptyFields),'_')};
            %check that the new name does not exists
            if any(strcmp([mArgsIn.TubeDB([1:tubenum-1,tubenum+1:end]).Tubename],newtubename))
                %tubename already already exists, continue
                msgbox(['Can''t rename ' mArgsIn.TubeDB(i).Tubename ' to ' newtubename{1} '. The new tube name already exists.'],'EasyFlow','error','modal');
                uiwait;
                continue;
            end
            % rename it in the TubeDB structures
            mArgsIn.TubeDB(tubenum).Tubename=newtubename;
            % change in the fcsfiles
            mArgsIn.TubeDB(tubenum).fcsfile=fcssetparam(mArgsIn.TubeDB(tubenum).fcsfile,'TUBE NAME',newtubename);
            % replace the names in the GraphDB and GatesDB
            if ~isempty(mArgsIn.GraphDB)
                [mArgsIn.GraphDB(strcmp({mArgsIn.GraphDB.Data},S(tubenum))).Data]=deal(newtubename{1});
            end
            if isfield(mArgsIn,'GatesDB') && isfield(mArgsIn.GatesDB,matlab.lang.makeValidName(S(tubenum)))
                mArgsIn.GatesDB.(matlab.lang.makeValidName(newtubename{1}))=mArgsIn.GatesDB.(matlab.lang.makeValidName(S{tubenum}));
                mArgsIn.GatesDB=rmfield(mArgsIn.GatesDB,matlab.lang.makeValidName(S{tubenum}));
            end
        end
        
        mArgsIn.TubeNames=[{'None'};[mArgsIn.TubeDB.Tubename]'];
        set(mArgsIn.Handles.TubePUM,'String',mArgsIn.TubeNames);
        guidata(fh,mArgsIn);
        set(fh,'pointer','arrow')
        set(enabled_gui,'Enable','on');
    end
    function TubeCompCallback(~,~)
        v=version('-release');
        v=str2double(v(1:end-1));
        if v<2008
            msgbox('You have an old version of MATLAB. Update.','EasyFlow','error','modal');
            uiwait;
            return;
        end
        EasyFlow_compensation(fh);
        mArgsIn=guidata(fh);
        mArgsIn.DBInfo.isChanged=1;
        guidata(fh,mArgsIn)
    end
    function TubePrmCallback(~,~)
        mArgsIn=guidata(fh);
%        newfcs=fcsedit([mArgsIn.TubeDB.fcsfile])
%        mArgsIn.DBInfo.isChanged=1;
        guidata(fh,mArgsIn)
    end
    function TubeAddParam(~,~)
        set(fh,'pointer','watch');
        mArgsIn=guidata(fh);
        %select the tubes for which we want to add the new parameter
        S=mArgsIn.TubeNames(2:end);
        if isempty(S)
            msgbox('No open tubes were found.','EasyFlow','error','modal');
            uiwait;
            return;
        end
        [Selection,ok] = listdlg('ListString',S,'Name','Select Tubes','PromptString','Select tubes to add parameter');
        if ok==0
            return;
        end

        ParamName=char(inputdlg('Parameter Name:','Add Parameter'));

        %define the new parameter
        calcprm_eq=char(inputdlg('Insert equation. Use p1,p2,... as your parameters. Note that they are vectors'...
            ,'Define Equation'));
        %change mArgsIn.TubeDB:
        %cprmnum is the next number of calculated param. find the last
        %calculated param say CP8 so the next one is CP9. 
        cprmnum=max(... find the maximum of all calculated parameter numbers
            cellfun(... for every tube in tubeindex
            @(tubex) max([0 cellfun(@(x) str2double(x(3)), ...get the character after the CP
            ...mArgsIn.TubeDB(1).parname( ~cellfun(@isempty, strfind(tubex,'CP')) ))])+1 ...for every parname with 'CP'
            mArgsIn.TubeDB(1).parname(contains(tubex,'CP')) )])+1 ...for every parname with 'CP'
            ,{mArgsIn.TubeDB(Selection).parname}));
        for i=Selection
            mArgsIn.TubeDB(i).parname{end+1}=['CP' num2str(cprmnum)];
            mArgsIn.TubeDB(i).parsymbol{end+1}=ParamName;
            calcprm_eq_rep=regexprep(calcprm_eq,'p([0-9]*)',['mArgsIn.TubeDB(' num2str(i) ').compdata(:,$1)']);
            mArgsIn.TubeDB(i).compdata(:,end+1)=eval(calcprm_eq_rep);
            
            %change the fcsfile itself
            %the data
            mArgsIn.TubeDB(i).fcsfile.fcsdata(:,end+1)=mArgsIn.TubeDB(i).compdata(:,end);
            %and the header
            ParamProp=cellfun(@(x) x(4), mArgsIn.TubeDB(i).fcsfile.var_name(~cellfun(@isempty, regexp(mArgsIn.TubeDB(i).fcsfile.var_name,'\$P1[A-Z]','once'))));
            pnum=num2str(str2double(mArgsIn.TubeDB(i).fcsfile.var_value(strcmp(mArgsIn.TubeDB(i).fcsfile.var_name,'$PAR')))+1);
            mArgsIn.TubeDB(i).fcsfile=fcssetparam(mArgsIn.TubeDB(i).fcsfile, '$PAR', pnum);
            
            for pprop=ParamProp'
                switch pprop
                    case 'B'
                        pname=['$P' pnum 'B'];
                        pval='32';
                    case 'E'
                        pname=['$P' pnum 'E'];
                        pval='0.000000,0.000000';
                    case 'G'
                        pname=['$P' pnum 'G'];
                        pval='1';
                    case 'N'
                        pname=['$P' pnum 'N'];
                        pval=['CP' num2str(cprmnum)];
                    case 'R'
                        pname=['$P' pnum 'R'];
                        pval='262144';
                    case 'S'
                        pname=['$P' pnum 'S'];
                        pval=ParamName;
                    otherwise
                        pname=['$P' pnum pprop];
                        pval='';
                        msgbox('Everything is fine, but tell Yaron: Add Parap>UnknownParamProp'...
                            ,'EasyFlow','warn','modal');
                end
                mArgsIn.TubeDB(i).fcsfile=fcssetparam(mArgsIn.TubeDB(i).fcsfile, pname, pval);
            end
            
            

        end
        guidata(fh,mArgsIn);
        GraphListCallback(mArgsIn.Handles.GraphList,[])
        set(fh,'pointer','arrow')
    end

    function ToolsBatch(~,~)
        mArgsIn=guidata(fh);
        inpstr=inputdlg({'Replace (regexp allowed)','With'},'Batch conversion',[1,5]');
        if isempty(inpstr)
            return
        end
        str1=inpstr{1};
        str2=cellstr(inpstr{2})';
        initial_tubenum=length(mArgsIn.GraphDB);
        GraphDB=fcsbatch(mArgsIn.GraphDB(mArgsIn.curGraph),str1,str2);
        mArgsIn.GraphDB=[mArgsIn.GraphDB,GraphDB];
        set(mArgsIn.Handles.GraphList,'String',{mArgsIn.GraphDB.Name});
        mArgsIn.DBInfo.isChanged=1;
        
        %recalculate gates for the new graphs
        tic;
        curGraph=mArgsIn.curGraph;
        h=waitbar(0,'Loading...');
        loop_length=length(mArgsIn.GraphDB)-initial_tubenum;
        for i=(initial_tubenum+1):length(mArgsIn.GraphDB)
            mArgsIn.curGraph=i;
            if ~isfield(mArgsIn,'GatesDB') || ~isfield(mArgsIn.GatesDB,char((matlab.lang.makeValidName(mArgsIn.GraphDB(mArgsIn.curGraph).Data))))
                mArgsIn.GraphDB(mArgsIn.curGraph).Gates={};
            else
                mArgsIn.GraphDB(mArgsIn.curGraph).Gates=intersect(...
                    mArgsIn.GraphDB(mArgsIn.curGraph).Gates,...
                    fieldnames(mArgsIn.GatesDB.(matlab.lang.makeValidName(mArgsIn.GraphDB(1).Data))));
            end
            mArgsIn=CalculateGatedData(mArgsIn);
            timeleft=toc*(loop_length/(i-initial_tubenum)-1);
            waitbar((i-initial_tubenum)/loop_length,h,[num2str(5*ceil(timeleft/5)) ' seconds remaining...']);
        end
        delete(h);
        mArgsIn.curGraph=curGraph;
        guidata(fh,mArgsIn)
    end
    function ToolsAddall(~,eventdata)
        mArgsIn=guidata(fh);
        curgraph=length(mArgsIn.GraphDB)+1;
        %reselect selected graphs to save their configuration
        GraphListCallback(mArgsIn.Handles.GraphList,eventdata);
        for tubename=mArgsIn.TubeNames(2:end)'
            mArgsIn=AddGraph(mArgsIn,[],tubename{1});
        end
        mArgsIn.curGraph=curgraph:length(mArgsIn.GraphDB);
        set(mArgsIn.Handles.GraphList,'Value',mArgsIn.curGraph);

        mArgsIn=CalculateGatedData(mArgsIn);
        mArgsIn.DBInfo.isChanged=1;
        mArgsIn=DataChange(mArgsIn);
        guidata(fh,mArgsIn);
        GraphListCallback(mArgsIn.Handles.GraphList,eventdata)
        mArgsIn=guidata(fh);
        mArgsIn=CalculateMarkers(mArgsIn);
        guidata(fh,mArgsIn);
    end
    function ToolsNewFit(~,~)
        mArgsIn=guidata(fh);
        f=mArgsIn.GraphDB(mArgsIn.curGraph(1)).plotdata(:,1);
        h=mArgsIn.GraphDB(mArgsIn.curGraph(1)).plotdata(:,2);
        cftool(f,h);
        guidata(fh,mArgsIn)
    end
    function ToolsApplyFit(~,~)
        mArgsIn=guidata(fh);
        vars=evalin('base','who');
        vars=vars(cellfun(@(x) isa(evalin('base',x),'fittype'),vars));
        fitvarname=popupdlg('choose a fit variable',vars);
        if isempty(fitvarname)
            return;
        end
        fitvar=evalin('base',vars{fitvarname});        
        %precheck if variable is fittype
        if ~isa(fitvar,'fittype')
            msgbox(['The variable ' vars{fitvarname} ' does not contain a fit data.'],'EasyFlow','error','modal');
            uiwait;
            return;
        end
        for cgraph=mArgsIn.curGraph
            f=mArgsIn.GraphDB(cgraph).plotdata(:,1);
            h=mArgsIn.GraphDB(cgraph).plotdata(:,2);
            [cfun,gof]=fit(f(:),h(:),fitvar);
            h=line(f, cfun(f));
            set(h,'linestyle',':');
            set(h,'Color',mArgsIn.GraphDB(cgraph).PlotColor);
            mArgsIn.GraphDB(cgraph).fit={cfun,gof,mArgsIn.Display.graph_Xaxis,mArgsIn.Display.graph_Xaxis_param(3)};
        end
        guidata(fh,mArgsIn)
    end
    function ToolsRemFit(~,~)
        mArgsIn=guidata(fh);
        [mArgsIn.GraphDB(mArgsIn.curGraph).fit]=deal([]);
        mArgsIn = DrawGraphs(mArgsIn);
        guidata(fh,mArgsIn)
    end
    function ToolsExport(~,~)
        mArgsIn=guidata(fh);
        output=cell(length(mArgsIn.curGraph),1);
        for i=1:length(mArgsIn.curGraph)
            graph=mArgsIn.curGraph(i);
            gateddata=[];
            pname=[];
            tubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],mArgsIn.GraphDB(graph).Data),1,'first');
            if tubeidx
                gateddata=mArgsIn.TubeDB(tubeidx).compdata(mArgsIn.GraphDB(graph).gatedindex,:);
                pname=mArgsIn.TubeDB(tubeidx).parsymbol;
            end
            output{i}.Data=gateddata;
            output{i}.Name=mArgsIn.GraphDB(graph).Name;
            output{i}.ParamName=pname;
        end
        export2wsdlg({'Save Data as:'},{'Output'},{cell2mat(output)}); % if problem remove the 'cell2mat'
    end
    function StatWinCallback(~,~)
        EasyFlow_statwin(fh);
    end
    function ViewSetup(~,~)
        mArgsIn=guidata(fh);
        StatNames={'Count','Mean','Median','rSD','Std','% of total','% of gate','Quadrants','Fit'};
        Num_stat=length(StatNames);
        size_y=25+20*ceil(Num_stat/2)+100+25;
        
        h=figure('Position',[0,0,300,size_y],...
            'MenuBar','none',...
            'Name','Statistics SetUp',...
            'NumberTitle','off',...
            'Visible','off');
        movegui(h,'center');
        
        uicontrol(h,'Style','text',...
            'Position',[0,0,300,size_y],...
            'String','');
        btngrp_stat=uibuttongroup(...
            'Title','Choose the Statistics to be Calculated:',...
            'Units','pixels',...
            'Position',[0 size_y-25-20*ceil(Num_stat/2) 300 25+20*ceil(Num_stat/2)]);
        for i=1:2:Num_stat
            uicontrol(btngrp_stat,...
                'Style','checkbox',...
                'String',[StatNames{i}],...
                'Tag',StatNames{i},...
                'Position',[5 25+20*ceil(Num_stat/2)-35-10*i 110 20],...
                'Value',mArgsIn.Statistics.ShowInStatView(i),...
                'Callback',{@SetShowInStatView});
            if i<Num_stat
                uicontrol(btngrp_stat,...
                    'Style','checkbox',...
                    'String',[StatNames{i+1}],...
                    'Tag',StatNames{i+1},...
                    'Position',[115 25+20*ceil(Num_stat/2)-35-10*i 110 20],...
                    'Value',mArgsIn.Statistics.ShowInStatView(i+1),...
                    'Callback',{@SetShowInStatView});
            end
        end
        uibuttongroup(...
            'Units','pixels',...
            'Position',[0,25,300,size_y-25-20*ceil(Num_stat/2)-25],...
            'Title','Choose the Quadrants Statistics:');


        uicontrol(h,'Style','push',...
            'Position',[0,size_y-25-20*ceil(Num_stat/2)-100-25,300,25],...
            'String','Set',...
            'Callback',{@(a,b) close(get(a,'parent'))} );
        
        
        set(h,'visible','on')
        
        function SetShowInStatView(hObject,~)
            mArgsIn=guidata(fh);
            objects=findobj(get(hObject,'Parent'),'Style','checkbox');
            vals=get(objects,'value');
            res=logical(cell2mat(vals))';
            mArgsIn.Statistics.ShowInStatView=res(end:-1:1);
            %close(get(hObject,'Parent'));
            guidata(fh,mArgsIn);
            % Recalc the statistics
            if isfield(mArgsIn.Handles,'statwin')
                Args=guidata(mArgsIn.Handles.statwin);
                Args.fCalcStat(mArgsIn);
            end

        end

    end
    function HelpKeys(~,~)
        h=figure('Position',[0,0,400,140],...
            'MenuBar','none',...
            'Name','EasyFlow Keyboard Shortcuts',...
            'NumberTitle','off',...
            'Visible','off');
        
        shortcut_keys={...
            'Ctrl-A',...
            'Ctrl-C',...
            ''};
        shortcut_desc={...
            'Rename graphs with sample name',...
            'Assign defult colors',...
            ''};
        
        hTitle=uicontrol(h,'Style','text',...
            'Position',[0,100,400,40],...
            'FontSize',20,...
            'FontWeight','bold',...
            'String',' Keyboard Shortcuts ');
        hKeys=uicontrol(h,'Style','text',...
            'Position',[0,0,90,100],...
            'FontSize',10,...
            'HorizontalAlignment','right',...
            'String',shortcut_keys);
        hDesc=uicontrol(h,'Style','text',...
            'Position',[110,0,300,100],...
            'FontSize',10,...
            'HorizontalAlignment','left',...
            'String',shortcut_desc);

        hspace=20;
        hKeys.Position(3)=hKeys.Extent(3);
        hDesc.Position(1)=hKeys.Position(1)+hKeys.Position(3)+hspace;
        hDesc.Position(3)=hDesc.Extent(3);
        hTitle.Position(3)=max(hTitle.Extent(3),hKeys.Extent(3)+hDesc.Extent(3)+hspace);
        h.Position(3)=hTitle.Position(3);
        movegui(h,'center');

        set(h,'Visible','on')
        
        
    end
    function HelpAbout(~,~)
        h=figure('Position',[0,0,300,140],...
            'MenuBar','none',...
            'Name','About EasyFlow',...
            'NumberTitle','off',...
            'Visible','off');
        movegui(h,'center');
        
        uicontrol(h,'Style','text',...
            'Position',[0,130,300,10],...
            'FontSize',10,...
            'FontWeight','normal',...
            'String','');
        uicontrol(h,'Style','text',...
            'Position',[0,90,300,40],...
            'FontSize',20,...
            'FontWeight','bold',...
            'String','EasyFlow');
        uicontrol(h,'Style','text',...
            'Position',[0,70,300,20],...
            'FontSize',10,...
            'FontWeight','bold',...
            'String','FACS Analysis Tool');
        uicontrol(h,'Style','text',...
            'Position',[0,60,300,10],...
            'FontSize',10,...
            'FontWeight','normal',...
            'String','');
        uicontrol(h,'Style','text',...
            'Position',[0,40,300,20],...
            'FontSize',10,...
            'FontWeight','normal',...
            'String',['Version ', sprintf('%.2f',curversion), ' ', versiondate]);
        uicontrol(h,'Style','text',...
            'Position',[0,20,300,20],...
            'FontSize',10,...
            'FontWeight','normal',...
            'String','Authors:');
        uicontrol(h,'Style','text',...
            'Position',[0,00,300,20],...
            'FontSize',10,...
            'FontWeight','normal',...
            'String','Yaron E Antebi');
        
        set(h,'Visible','on')
        
        
    end

    function ACM_graphprop(~,~)
        EasyFlow_figprop(fh);
    end
    function ACM_fixaxis(~,~)
        mArgsIn=guidata(fh);
        if strcmp(get(gcbo, 'Checked'),'on')
            if isfield(mArgsIn.Display,'Axis')
                mArgsIn.Display=rmfield(mArgsIn.Display,'Axis');
            end
            axis('auto');
            set(gcbo, 'Checked', 'off');
        else
            mArgsIn.Display.Axis=axis;
            set(gcbo, 'Checked', 'on');
        end
        mArgsIn.Display.Changed=1;
        mArgsIn.DBInfo.isChanged=1;
        guidata(fh,mArgsIn)
    end
    function ACM_setquad(~,~)
        mArgsIn=guidata(fh);
        [x,y]=ginput(1);
        %rescale the coordinates to its linear scale values
        switch mArgsIn.Display.graph_Xaxis
            case 'log'
                x=10.^x;
            case 'logicle'
                x=2*sinh(log(10)*x)/mArgsIn.Display.graph_Xaxis_param(3);
        end
        switch mArgsIn.Display.graph_Yaxis
            case 'ylog'
                y=10.^y;
            case 'ylogicle'
                y=2*sinh(log(10)*y)/mArgsIn.Display.graph_Yaxis_param(3);
        end
        for cgraph=mArgsIn.curGraph
            mArgsIn.GraphDB(cgraph).Stat.quad=[x,y];
        end
        mArgsIn=CalculateMarkers(mArgsIn);
        DrawQuads(mArgsIn);
        mArgsIn.DBInfo.isChanged=1;
        guidata(fh,mArgsIn)
    end
    function ACM_cpquad(~,~)
        mArgsIn=guidata(fh);
        mArgsIn.copy.quad=mArgsIn.GraphDB(mArgsIn.curGraph(1)).Stat.quad;
        mArgsIn.DBInfo.isChanged=1;
        guidata(fh,mArgsIn)
    end
    function ACM_pastequad(~,~)
        mArgsIn=guidata(fh);
        if isfield(mArgsIn,'copy') && isfield(mArgsIn.copy,'quad')
            for cgraph=mArgsIn.curGraph
                mArgsIn.GraphDB(cgraph).Stat.quad=mArgsIn.copy.quad;
            end
        end
        mArgsIn=CalculateMarkers(mArgsIn);
        DrawQuads(mArgsIn);
        mArgsIn.DBInfo.isChanged=1;
        guidata(fh,mArgsIn)
    end
    function ACM_rmquad(~,~)
        mArgsIn=guidata(fh);
        mArgsIn.GraphDB(mArgsIn.curGraph(1)).Stat=rmfield(mArgsIn.GraphDB(mArgsIn.curGraph(1)).Stat,'quad');
        delete(findobj(gca,'Tag','quad'));
        mArgsIn.DBInfo.isChanged=1;
        mArgsIn=CalculateMarkers(mArgsIn);
        guidata(fh,mArgsIn)
    end
    function ACM_DrawToFigure(hObject,~)
        efdb=efdb_load(hObject);
        DrawToFigure(efdb);
    end

    function MenuGatesAddGate(hObject,~)
        efdbIn=efdb_load(hObject);
        efdbIn=disable_gui(efdbIn);
        
        %
        %check parameters and determine the gate name
        %
        %check that all plots have the same axis
        allplots_color={efdbIn.GraphDB(efdbIn.curGraph).Color};
        if size(unique(cell2mat(allplots_color(:)),'rows'),1)~= 1
            %not all plots have the same x-axis. 
            %cannot create a gate
            msgbox('All plots should have the same X-axis.','EasyFlow','error','modal');
            uiwait;
            enable_gui(efdbIn);
            return;
        end
        if ~strcmp(efdbIn.Display.graph_type,'Histogram')
            %need also to check the y axis
            allplots_color={efdbIn.GraphDB(efdbIn.curGraph).Color2};
            if size(unique(cell2mat(allplots_color(:)),'rows'),1)~= 1
                %not all plots have the same y-axis.
                %cannot create a gate
                msgbox('All plots should have the same Y-axis.','EasyFlow','error','modal');
                uiwait;
                enable_gui(efdbIn);
                return;
            end
        end
        gatename=char(inputdlg('Gate name:','Add Gate',1));
        % check that the name is non empty and valid and doesn't exist already.
        if isempty(gatename)
            enable_gui(efdbIn);
            return;
        end
        if ~isvarname(gatename)
            msgbox('The gate name is invalid. It should containt leters and numbers and start with a letter.','EasyFlow','error','modal');
            uiwait;
            enable_gui(efdbIn);
            return;
        end
        if isfield(efdbIn,'GatesDBnew')
            allgates=fieldnames(efdbIn.GatesDBnew);
            if any(strcmp(allgates,gatename))
                msgbox('A gate with this name already exists.','EasyFlow','error','modal');
                uiwait;
                enable_gui(efdbIn);
                return;
            end
        end
        
        %
        %create the gate
        %
        switch efdbIn.Display.graph_type
            case 'Histogram'
                %define the gate
                lingate=gate1d;
                %do the necessary transformation on the values of the gate to make
                %them linear
                switch efdbIn.Display.graph_Xaxis
                    case 'log'
                        lingate(1:2)=10.^lingate(1:2);
                    case 'logicle'
                        lingate(1:2)=2*sinh(log(10)*lingate(1:2))/efdbIn.Display.graph_Xaxis_param(3);
                end
                %create the gate structure
                new_gate{1}=lingate;
                new_gate{2}=efdbIn.GraphDB(efdbIn.curGraph(1)).Color;
                new_gate{3}='1D';
                %add to the GatesDB 
                efdbIn.GatesDBnew.(gatename)=new_gate;
            otherwise
                %define the gate
                lingate=gate2d;
                %do the necessary transformation on the values of the gate to make
                %them linear
                switch efdbIn.Display.graph_Xaxis
                    case 'log'
                        lingate(1,:)=10.^lingate(1,:);
                    case 'logicle'
                        lingate(1,:)=2*sinh(log(10)*lingate(1,:))/efdbIn.Display.graph_Xaxis_param(3);
                end
                switch efdbIn.Display.graph_Yaxis
                    case 'ylog'
                        lingate(2,:)=10.^lingate(2,:);
                    case 'ylogicle'
                        lingate(2,:)=2*sinh(log(10)*lingate(2,:))/efdbIn.Display.graph_Yaxis_param(3);
                end
                %create the gate structure
                new_gate{1}=lingate;
                new_gate{2}=efdbIn.GraphDB(efdbIn.curGraph(1)).Color;
                new_gate{3}=efdbIn.GraphDB(efdbIn.curGraph(1)).Color2;
                %add to the GatesDB 
                efdbIn.GatesDBnew.(gatename)=new_gate;
        end
%removed on 2020_01_14. should be deleteable.
        % apply the gate to all tubes 
%        for cur_tube_indx=1:length(efdbIn.TubeDB)
%            gatemask=calculate_gate_mask(efdbIn.TubeDB(cur_tube_indx),new_gate);
%            efdbIn.TubeDB(cur_tube_indx).gatemask.(gatename)=gatemask;
%        end
        % Update the GUI component
        UpdateGateList(efdbIn);
        %DrawGraphs(fh);
        efdbIn=enable_gui(efdbIn);
        efdb_save(efdbIn);
    end
    function MenuGatesAddContourGate(hObject,~)
        efdbIn=efdb_load(hObject);
        efdbIn=disable_gui(efdbIn);
        
        %
        %check parameters and determine the gate name
        %
        %contour only works in 2d
        if strcmp(efdbIn.Display.graph_type,'Histogram')
            msgbox('A gate with this name already exists.','EasyFlow','error','modal');
            uiwait;
            return;
        end        
        %check that all plots have the same x and y axis
        allplots_color={efdbIn.GraphDB(efdbIn.curGraph).Color};
        if size(unique(cell2mat(allplots_color(:)),'rows'),1)~= 1
            %not all plots have the same x-axis. 
            %cannot create a gate
            msgbox('All plots should have the same X-axis.','EasyFlow','error','modal');
            uiwait;
            enable_gui(efdbIn);
            return;
        end
        allplots_color={efdbIn.GraphDB(efdbIn.curGraph).Color2};
        if size(unique(cell2mat(allplots_color(:)),'rows'),1)~= 1
            %not all plots have the same y-axis.
            %cannot create a gate
            msgbox('All plots should have the same Y-axis.','EasyFlow','error','modal');
            uiwait;
            enable_gui(efdbIn);
            return;
        end
        gatename=char(inputdlg('Gate name:','Add Gate'));
        % check that the name is non empty and valid and doesn't exist already.
        if isempty(gatename)
            enable_gui(efdbIn);
            return;
        end
        if ~isvarname(gatename)
            msgbox('The gate name is invalid. use only a letter followed by letters and numbers.','EasyFlow','error','modal');
            uiwait;
            enable_gui(efdbIn);
            return;
        end
        if isfield(efdbIn,'GatesDBnew')
            allgates=fieldnames(efdbIn.GatesDBnew);
            if any(strcmp(allgates,gatename))
                msgbox('A gate with this name already exists.','EasyFlow','error','modal');
                uiwait;
                enable_gui(efdbIn);
                return;
            end
        end
        
        %
        %create the gate
        %
        %define the gate
        lingate=gate2d_cntr;
        %do the necessary transformation on the values of the gate to make
        %them linear
        switch efdbIn.Display.graph_Xaxis
            case 'log'
                lingate(1,:)=10.^lingate(1,:);
            case 'logicle'
                lingate(1,:)=2*sinh(log(10)*lingate(1,:))/efdbIn.Display.graph_Xaxis_param(3);
        end
        switch efdbIn.Display.graph_Yaxis
            case 'ylog'
                lingate(2,:)=10.^lingate(2,:);
            case 'ylogicle'
                lingate(2,:)=2*sinh(log(10)*lingate(2,:))/efdbIn.Display.graph_Yaxis_param(3);
        end
        %create the gate structure
        new_gate{1}=lingate;
        new_gate{2}=efdbIn.GraphDB(efdbIn.curGraph(1)).Color;
        new_gate{3}=efdbIn.GraphDB(efdbIn.curGraph(1)).Color2;
        %add to the GatesDB
        efdbIn.GatesDBnew.(gatename)=new_gate;
        
        % apply the gate to all tubes
        for cur_tube_indx=1:length(efdbIn.TubeDB)
            gatemask=calculate_gate_mask(efdbIn.TubeDB(cur_tube_indx),new_gate);
            efdbIn.TubeDB(cur_tube_indx).gatemask.(gatename)=gatemask;
        end
        % Update the GUI component
        UpdateGateList(efdbIn);
        
        efdbIn=enable_gui(efdbIn);
        efdb_save(efdbIn);
    end
    function MenuGatesAddLogicalGate(hObject,~)
        efdbIn=efdb_load(hObject);
        efdbIn=disable_gui(efdbIn);

        %
        %check parameters and determine the gate name
        %
        gatename=char(inputdlg('Gate name:','Add Logical Gate'));
        % check that the name is non empty and valid and doesn't exist already.
        if isempty(gatename)
            return;
        end
        if ~isvarname(gatename)
            msgbox('The gate name is invalid. use only a letter followed by letters and numbers.','EasyFlow','error','modal');
            uiwait;
            enable_gui(efdbIn);
            return;
        end
        if isfield(efdbIn,'GatesDBnew')
            allgates=fieldnames(efdbIn.GatesDBnew);
            if any(strcmp(allgates,gatename))
                msgbox('A gate with this name already exists.','EasyFlow','error','modal');
                uiwait;
                enable_gui(efdbIn);
                return;
            end
        end
        
        
        %select gates and logical operation
        if isempty(allgates)
            msgbox('No gates were found.','EasyFlow','error','modal');
            uiwait;
            enable_gui(efdbIn);
            return;
        end
        [Selection,ok] = listdlg('ListString',allgates,'Name','Select Gates','PromptString','Select gates','OKString','OK');
        if ok~=1
            enable_gui(efdbIn);
            return
        end
        switch length(Selection)
            case 0
                msgbox('No gates were selected.','EasyFlow','error','modal');
                uiwait;
                enable_gui(efdbIn);
                return;
            case 1
                logical_op={'Not'};
            case 2
                logical_op={'And','Or','Xor'};
            otherwise
                logical_op={'And','Or'};
        end
        [OpSelection,ok] = listdlg('ListString',logical_op,'Name','Select Operation','PromptString','Select logical operation','OKString','OK','SelectionMode','single');
        if ok~=1
            enable_gui(efdbIn);
            return
        end
        %create the gate structure
        new_gate{1}=logical_op{OpSelection};
        new_gate{2}=allgates(Selection);
        new_gate{3}='logical';
        %add to the GatesDB
        efdbIn.GatesDBnew.(gatename)=new_gate;

        % apply the gate to all tubes
        for cur_tube_indx=1:length(efdbIn.TubeDB)
            gatemask=calculate_gate_mask(efdbIn.TubeDB(cur_tube_indx),new_gate);
            efdbIn.TubeDB(cur_tube_indx).gatemask.(gatename)=gatemask;
        end
        % Update the GUI component
        UpdateGateList(efdbIn);
        
        efdbIn=enable_gui(efdbIn);
        efdb_save(efdbIn);
    end
    function MenuGatesAddArtifactsGate(hObject,~)
        efdbIn=efdb_load(hObject);
        efdbIn=disable_gui(efdbIn);

        %
        %check parameters and determine the gate name
        %
        gatename=char(inputdlg('Gate name:','Add Artifacts Gate'));
        % check that the name is non empty and valid and doesn't exist already.
        if isempty(gatename)
            return;
        end
        if ~isvarname(gatename)
            msgbox('The gate name is invalid. use only a letter followed by letters and numbers.','EasyFlow','error','modal');
            uiwait;
            return;
        end
        if isfield(efdbIn,'GatesDBnew')
            allgates=fieldnames(efdbIn.GatesDBnew);
            if any(strcmp(allgates,gatename))
                msgbox('A gate with this name already exists.','EasyFlow','error','modal');
                uiwait;
                enable_gui(efdbIn);
                return;
            end
        end
        
        %take the y axis unless it is a 1d histogram
        if strcmp(efdbIn.Display.graph_type,'Histogram')
            colorname=efdbIn.GraphDB(efdbIn.curGraph(1)).Color;
            disp_scale=efdbIn.Display.graph_Xaxis;
            disp_par=efdbIn.Display.graph_Xaxis_param(3);
        else
            colorname=efdbIn.GraphDB(efdbIn.curGraph(1)).Color2;
            disp_scale=efdbIn.Display.graph_Yaxis(2:end);
            disp_par=efdbIn.Display.graph_Yaxis_param(3);
        end
        %create the gate structure
        new_gate{1}={disp_scale,disp_par};
        new_gate{2}=colorname;
        new_gate{3}='artifact';
        %add to the GatesDB
        efdbIn.GatesDBnew.(gatename)=new_gate;

        % apply the gate to all tubes
        for cur_tube_indx=1:length(efdbIn.TubeDB)
            gatemask=calculate_gate_mask(efdbIn.TubeDB(cur_tube_indx),new_gate);
            efdbIn.TubeDB(cur_tube_indx).gatemask.(gatename)=gatemask;
        end
        % Update the GUI component
        UpdateGateList(efdbIn);
        
        efdbIn=enable_gui(efdbIn);
        efdb_save(efdbIn);
    end
    function MenuGatesEditor(hObject,~)
        efdbIn=efdb_load(hObject);
        efdbIn=disable_gui(efdbIn);
        gatename = get(gco,'Tag');
        old_gate = efdbIn.GatesDBnew.(gatename);

        switch efdbIn.Display.graph_type
            case 'Histogram'
                %make sure the color is proper
                if ~strcmp(old_gate{2},efdbIn.GraphDB(efdbIn.curGraph(1)).Color) ...
                        || ~strcmp(old_gate{3},'1D')
                    msgbox(['wrong axis need ', old_gate{2}, ' and ', old_gate{3}],'EasyFlow','error','modal');
                    uiwait;
                    enable_gui(efdbIn);
                    return;
                end
                efdbIn = remove_gates(gatename, efdbIn);
                efdbIn = DrawGraphs(efdbIn);
                %get the old gate values
                lingate=old_gate{1};
                %scale the numbers to the axis scaling
                scalegate=[lin2scale(lingate(1:2), efdbIn.Display.graph_Xaxis, efdbIn.Display.graph_Xaxis_param),... 
                    lin2scale(lingate(3), efdbIn.Display.graph_Yaxis, efdbIn.Display.graph_Yaxis_param)];
                %define the new gate
                scalegate = gate1d(scalegate);
                %transform back to linear values
                lingate=[scale2lin(scalegate(1:2), efdbIn.Display.graph_Xaxis, efdbIn.Display.graph_Xaxis_param),... 
                    scale2lin(scalegate(3), efdbIn.Display.graph_Yaxis, efdbIn.Display.graph_Yaxis_param)];
                %create the gate structure
                new_gate{1}=lingate;
                new_gate{2}=efdbIn.GraphDB(efdbIn.curGraph(1)).Color;
                new_gate{3}='1D';
                %add to the GatesDB 
                efdbIn.GatesDBnew.(gatename)=new_gate;
            otherwise
                %make sure the color is proper
                if ~strcmp(old_gate{2},efdbIn.GraphDB(efdbIn.curGraph(1)).Color) ...
                        || ~strcmp(old_gate{3},efdbIn.GraphDB(efdbIn.curGraph(1)).Color2)
                    msgbox(['wrong axis need ', old_gate{2}, ' and ', old_gate{3}],'EasyFlow','error','modal');
                    uiwait;
                    enable_gui(efdbIn);
                    return;
                end
                efdbIn = remove_gates(gatename, efdbIn);
                efdbIn = DrawGraphs(efdbIn);
                %get the old gate values
                lingate=old_gate{1};
                %scale the numbers to the axis scaling
                scalegate=[lin2scale(lingate(1,:), efdbIn.Display.graph_Xaxis, efdbIn.Display.graph_Xaxis_param);... 
                    lin2scale(lingate(2,:), efdbIn.Display.graph_Yaxis, efdbIn.Display.graph_Yaxis_param)];

                %define the gate
                scalegate=gate2d(scalegate);
                %transform back to linear values
                lingate=[scale2lin(scalegate(1,:), efdbIn.Display.graph_Xaxis, efdbIn.Display.graph_Xaxis_param);... 
                    scale2lin(scalegate(2,:), efdbIn.Display.graph_Yaxis, efdbIn.Display.graph_Yaxis_param)];
                %create the gate structure
                new_gate{1}=lingate;
                new_gate{2}=efdbIn.GraphDB(efdbIn.curGraph(1)).Color;
                new_gate{3}=efdbIn.GraphDB(efdbIn.curGraph(1)).Color2;
                %add to the GatesDB 
                efdbIn.GatesDBnew.(gatename)=new_gate;
        end
        % Update the GUI component
        UpdateGateList(efdbIn);
        efdbIn=enable_gui(efdbIn);
        efdb_save(efdbIn);
    end
    function MenuGatesRemove(hObject,~)
        efdbIn=efdb_load(hObject);
        gatename = get(gco,'Tag');
        efdbIn = remove_gates(gatename, efdbIn);
        efdbIn = DrawGraphs(efdbIn);
        efdb_save(efdbIn);
    end
    function efdb = remove_gates(gatename, efdb)
        efdb.GatesDBnew=rmfield(efdb.GatesDBnew,gatename);
        %remove the gate from all graphs
        for i=1:length(efdb.GraphDB)
            efdb.GraphDB(i).Gates(strcmp(efdb.GraphDB(i).Gates,gatename))=[];
            efdb.GraphDB(i).GatesOff(strcmp(efdb.GraphDB(i).GatesOff,gatename))=[];
        end
        %remove it from tubes
        for i=1:length(efdb.TubeDB)
            if isfield(efdb.TubeDB(i),'gatemask') && isfield(efdb.TubeDB(i).gatemask,gatename)
                efdb.TubeDB(i).gatemask = rmfield(efdb.TubeDB(i).gatemask,gatename);
            end
        end
        % recalculate gates state
        curGraph = efdb.curGraph;
        efdb.curGraph = 1:length(efdb.GraphDB);
        efdb=CalculateGatedData(efdb);
        efdb.curGraph = curGraph;
        UpdateGateList(efdb);
    end
    function l = scale2lin(s,axis_scale, axis_param)
        l=s;
        switch axis_scale
            case {'log', 'ylog'}
                l=10.^s;
            case {'logicle', 'ylogicle'}
                l=2*sinh(log(10)*s)/axis_param(3);
        end
        
    end
    function s = lin2scale(l,axis_scale, axis_param)
        s=l;
        switch axis_scale
            case {'log', 'ylog'}
                s=log10(l);
            case {'logicle', 'ylogicle'}
                s=asinh(0.5*l*axis_param(3))/log(10);
        end
        
    end
%%  Functions for specific events
    function mArgsIn=DataChange(mArgsIn)
        %this function should be executed every time the data is changed,
        %i.e. the graph looks different. it acts only on the mArgsIn.curGraph
        %and redo the analysis
        
        %remove the fit
        [mArgsIn.GraphDB(mArgsIn.curGraph).fit]=deal([]);
        
    end
    function mArgsIn=AddGraph(mArgsIn,template,datatube)
        if ~exist('datatube','var')
            datatube=char(mArgsIn.TubeNames(1));
        end
        if ~exist('template','var')
            template=[];
        end
        %add item to the GraphList and GraphDB and select the new graph
        List=get(mArgsIn.Handles.GraphList,'String');
        curGraph=length(List)+1;
        List{curGraph}=['Graph_' num2str(curGraph)];
        %create the new item
        if isempty(template)
            mArgsIn.GraphDB(curGraph).Name=['Graph_' num2str(curGraph)];
            mArgsIn.GraphDB(curGraph).Data=datatube;
            mArgsIn.GraphDB(curGraph).Ctrl='None';
            mArgsIn.GraphDB(curGraph).Color='None';
            mArgsIn.GraphDB(curGraph).Color2='None';
            mArgsIn.GraphDB(curGraph).RemoveCtrl=0;
            mArgsIn.GraphDB(curGraph).DataDeconv=[];
            mArgsIn.GraphDB(curGraph).Gates={};
            mArgsIn.GraphDB(curGraph).GatesOff={};
            mArgsIn.GraphDB(curGraph).Stat=struct;
            mArgsIn.GraphDB(curGraph).plotdata=[];
            mArgsIn.GraphDB(curGraph).gatedindex=[];
            mArgsIn.GraphDB(curGraph).gatedindexctrl=[];
            mArgsIn.GraphDB(curGraph).Display=mArgsIn.Display;
            mArgsIn.GraphDB(curGraph).fit=[];
        else
            prevGraph=template;
            mArgsIn.GraphDB(curGraph).Name=['Graph_' num2str(curGraph)];
            mArgsIn.GraphDB(curGraph).Data=mArgsIn.GraphDB(prevGraph).Data;
            mArgsIn.GraphDB(curGraph).Ctrl=mArgsIn.GraphDB(prevGraph).Ctrl;
            mArgsIn.GraphDB(curGraph).Color=mArgsIn.GraphDB(prevGraph).Color;
            mArgsIn.GraphDB(curGraph).Color2=mArgsIn.GraphDB(prevGraph).Color2;
            mArgsIn.GraphDB(curGraph).RemoveCtrl=mArgsIn.GraphDB(prevGraph).RemoveCtrl;
            mArgsIn.GraphDB(curGraph).DataDeconv=mArgsIn.GraphDB(prevGraph).DataDeconv;
            mArgsIn.GraphDB(curGraph).Gates=mArgsIn.GraphDB(prevGraph).Gates;
            mArgsIn.GraphDB(curGraph).GatesOff=mArgsIn.GraphDB(prevGraph).GatesOff;
            mArgsIn.GraphDB(curGraph).Stat=mArgsIn.GraphDB(prevGraph).Stat;
            mArgsIn.GraphDB(curGraph).plotdata=mArgsIn.GraphDB(prevGraph).plotdata;
            mArgsIn.GraphDB(curGraph).gatedindex=mArgsIn.GraphDB(prevGraph).gatedindex;
            mArgsIn.GraphDB(curGraph).gatedindexctrl=mArgsIn.GraphDB(prevGraph).gatedindexctrl;
            mArgsIn.GraphDB(curGraph).Display=mArgsIn.GraphDB(prevGraph).Display;
            mArgsIn.GraphDB(curGraph).fit=mArgsIn.GraphDB(prevGraph).fit;
        end
        set(mArgsIn.Handles.GraphList,'String',List);
        set(mArgsIn.Handles.GraphList,'Value',curGraph);
        mArgsIn.DBInfo.isChanged=1;
    end

%%  Utility functions for MYGUI
    function efdb = DrawGraphs(efdb)
        %Draw the graphs. use the mArgsIn.Display.graph_* parameters
        %mArgsIn.Display.graph_Xaxis can be 'lin' 'log' 'asinh' 'logicle'
        %mArgsIn.Display.graph_type can be 'Histogram','Dot Plot','Colored Dot
        %Plot','Contour','Filled Contour'
        %mArgsIn.Display.graph_Yaxis can be 'ylin' or 'ylog'
        %set up the axis for plotting
        set(0,'CurrentFigure',efdb.Handles.fh)
        plot(1,1);
        cla(efdb.Handles.ax);
        hold on;
        switch efdb.Display.graph_type
            case 'Histogram'
                efdb = DrawHist(efdb);
            case {'Contour', 'Filled Contour', 'Dot Plot', 'Colored Dot Plot'}
                efdb = Draw2D(efdb);
            otherwise
                efdb = DrawHist(efdb);
        end
        hold off
        efdb=CalculateMarkers(efdb);
    end
    function mArgsIn = DrawToFigure(mArgsIn)
        %Draw the graphs in a special figure. use the mArgsIn.Display.graph_* parameters
        %mArgsIn.Display.graph_Xaxis can be 'lin' 'log' 'asinh' 'logicle'
        %mArgsIn.Display.graph_type can be 'Histogram','Dot Plot','Colored Dot
        %Plot','Contour','Filled Contour'
        %mArgsIn.Display.graph_Yaxis can be 'ylin' or 'ylog'
        %set up the axis for plotting
        hFig=figure;
        plottools(hFig);
        cla(gca);
        hold on;
        switch mArgsIn.Display.graph_type
            case 'Histogram'
                mArgsIn = DrawHist(mArgsIn);
            case {'Contour', 'Filled Contour', 'Dot Plot', 'Colored Dot Plot'}
                mArgsIn = Draw2D(mArgsIn);
            otherwise
                mArgsIn = DrawHist(mArgsIn);
        end
        hold off
        %set font size to 12 and typeface to Arial
        h = legend('show');
        set(h,'FontSize',12);
        set(h,'FontName','Arial');
        
        %set line widths of profiles
        hs = get(gca,'Children');
        set(hs,'LineWidth',2);
        
        %set font size and typeface for axis labels
        h=gca;
        set(h,'FontSize',12);
        set(h,'FontName','Arial');

    end
    function mArgsIn = DrawHist(mArgsIn)
        %Draw histograms.
        %go over all selected graphs and draws them.
        %if no Ctrl only draws the data.
        %if have Ctrl, cna either draw both or do deconvolution.
        no_data_graphs=[];
        allgraphs=get(mArgsIn.Handles.GraphList,'Value');
        lgnd=cell(1,length(allgraphs));
        lgnd_len = 0;
        for i=1:length(allgraphs)
            graph=allgraphs(i);
            if isfield(mArgsIn.TubeDB,'Tubename')
                tubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],mArgsIn.GraphDB(graph).Data),1,'first');
            else
                tubeidx=[];
            end
            %check that the tube exists
            if isempty(tubeidx)
                mArgsIn.GraphDB(graph).plotdata=[];
                continue
            end
            %check histnormalize display settings.
            if ~isfield(mArgsIn.Display,'histnormalize')
                mArgsIn.Display.histnormalize='Total';
            end
            %find the color index
            colorind=find(strcmp(mArgsIn.TubeDB(tubeidx).parname,mArgsIn.GraphDB(graph).Color),1,'first');
            if isempty(colorind)
                continue
            end
            % add the graphname to the legend
            lgnd_len = lgnd_len +1;
            lgnd{lgnd_len}=mArgsIn.GraphDB(graph).Name;
            %create the plotdata and the control data
            gateddata=mArgsIn.TubeDB(tubeidx).compdata(mArgsIn.GraphDB(graph).gatedindex,:);
            mArgsIn.GraphDB(graph).plotdata=gateddata(:,colorind);
            if ~strcmp(mArgsIn.GraphDB(graph).Ctrl,'None')
                ctrlidx=find(strcmp([mArgsIn.TubeDB.Tubename],mArgsIn.GraphDB(graph).Ctrl),1,'first');
                gatedCtrl=mArgsIn.TubeDB(ctrlidx).compdata(mArgsIn.GraphDB(graph).gatedindexctrl,:);
                if isfield(mArgsIn.GraphDB(graph),'RemoveCtrl') && isequal(mArgsIn.GraphDB(graph).RemoveCtrl,1)
                    if ~isfield(mArgsIn.GraphDB(graph),'DataDeconv') || isequal(mArgsIn.GraphDB(graph).DataDeconv,[])
                        %create deconv
                        mArgsIn.GraphDB(graph).DataDeconv=fcsdeconv(gateddata(:,colorind),gatedCtrl(:,colorind));
                    end
                    mArgsIn.GraphDB(graph).plotdata=mArgsIn.GraphDB(graph).DataDeconv;
                end
            end
            %draw the data
            if isempty(mArgsIn.GraphDB(graph).plotdata)
                no_data_graphs=[no_data_graphs ''', ''' mArgsIn.GraphDB(graph).Name];
                continue;
            end
            switch mArgsIn.Display.histnormalize
                case 'Gated'
                    %integral = gated percent
                    normprm=prod(mArgsIn.GraphDB(graph).Stat.gatepercent);
                    yname='Percent of total';
                case 'Abs'
                    %integral=num of cells
                    normprm=length(gateddata(:,colorind));
                    yname='Number of events';
                otherwise
                    %integral = 1
                    normprm=1;
                    yname='Percent';
            end
            fcshist(mArgsIn.GraphDB(graph).plotdata,mArgsIn.Display.graph_Xaxis,mArgsIn.Display.graph_Xaxis_param,mArgsIn.Display.graph_Yaxis,'norm',normprm,'smooth',mArgsIn.Display.smoothprm);
            [hist,bins]=fcshist(mArgsIn.GraphDB(graph).plotdata,mArgsIn.Display.graph_Xaxis,mArgsIn.Display.graph_Xaxis_param,mArgsIn.Display.graph_Yaxis,'norm',normprm,'smooth',mArgsIn.Display.smoothprm);
            mArgsIn.GraphDB(graph).plotdata=[bins(:),hist(:)];
            graphs=get(gca,'Children');
            if ~isfield(mArgsIn.GraphDB(graph),'PlotColor') || length(mArgsIn.GraphDB(graph).PlotColor)~=3
                mArgsIn.GraphDB(graph).PlotColor=mArgsIn.Display.GraphColor(mod(graph,7)+(mod(graph,7)==0)*7,:);
            end
            set(graphs(1),'Color',mArgsIn.GraphDB(graph).PlotColor);
            %if a fit exists, draw the fit
            if isfield(mArgsIn.GraphDB(graph),'fit') && ~isempty(mArgsIn.GraphDB(graph).fit)
                scaledbins=fcsscaleconvert(bins,mArgsIn.Display.graph_Xaxis,mArgsIn.Display.graph_Xaxis_param(3),mArgsIn.GraphDB(graph).fit{3},mArgsIn.GraphDB(graph).fit{4});
                dy=diff(bins);
                dy=mean([dy(1) dy; dy dy(end)]);
                dx=diff(scaledbins);
                dx=mean([dx(1) dx; dx dx(end)]);
                J=dx./dy;
                h=line(bins, J'.*mArgsIn.GraphDB(graph).fit{1}(scaledbins));
                set(h,'linestyle',':');
                set(h,'Color',mArgsIn.GraphDB(graph).PlotColor);
                lgnd{end+1}=[mArgsIn.GraphDB(graph).Name ' - Fit'];
            end
            %if also control, draw the control
            if ~strcmp(mArgsIn.GraphDB(graph).Ctrl,'None')...
                    && (~isfield(mArgsIn.GraphDB(graph),'RemoveCtrl') || ~isequal(mArgsIn.GraphDB(graph).RemoveCtrl,1))
                lgnd{end+1}=[mArgsIn.GraphDB(graph).Name ' Control'];
                if isempty(gatedCtrl)
                    msgbox(['The control for graph ' mArgsIn.GraphDB(graph).Name ' contains no data.'],'EasyFlow','error','modal');
                    uiwait;
                    continue;
                end
                fcshist(gatedCtrl(:,colorind),mArgsIn.Display.graph_Xaxis,mArgsIn.Display.graph_Xaxis_param,mArgsIn.Display.graph_Yaxis,'norm',normprm,'smooth',mArgsIn.Display.smoothprm);
                graphs=get(gca,'Children');
                if ~isfield(mArgsIn.GraphDB(graph),'PlotColor') || length(mArgsIn.GraphDB(graph).PlotColor)~=3
                    mArgsIn.GraphDB(graph).PlotColor=mArgsIn.Display.GraphColor(mod(graph,7)+(mod(graph,7)==0)*7,:);
                end
                set(graphs(1),'Color',mArgsIn.GraphDB(graph).PlotColor);
                set(graphs(1),'LineStyle',':');
            end
        end
        %set up the periphery of the graph
        fs=min(10,30/length(lgnd));
        if ~isempty(lgnd) && ~isempty(get(gca,'Children')) && fs>1.5
            legend(lgnd,'FontSize',fs,'Interpreter','None');
        end
        if isfield(mArgsIn.Display,'Axis')
            axis(mArgsIn.Display.Axis);
        end
        xlabel(getcolumn(get(mArgsIn.Handles.ColorPUM,'string')',get(mArgsIn.Handles.ColorPUM,'value')));
        if exist('yname','var')
            ylabel(yname);
        end
        if ~isempty(no_data_graphs)
            msgbox(['The graphs ''' no_data_graphs ''' contain no data.'],'EasyFlow','error','modal');
            uiwait;
        end
    end
    function mArgsIn = Draw2D(mArgsIn)
        %Draw 2d contours
        no_data_graphs=[];
        if isscalar(mArgsIn.curGraph) || strcmp(mArgsIn.Display.graph_type,'Dot Plot')
            for graph=mArgsIn.curGraph
                tubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],mArgsIn.GraphDB(graph).Data),1,'first');
                %check that the tube exists
                if isempty(tubeidx)
                    mArgsIn.GraphDB(graph).plotdata=[];
                    continue
                end
                gateddata=mArgsIn.TubeDB(tubeidx).compdata(mArgsIn.GraphDB(graph).gatedindex,:);
                mArgsIn.GraphDB(graph).plotdata=[];
                if isempty(gateddata)
                    no_data_graphs=[no_data_graphs ''', ''' mArgsIn.GraphDB(graph).Name];
                    continue;
                end
                colorind=find(strcmp(mArgsIn.TubeDB(tubeidx).parname,mArgsIn.GraphDB(graph).Color),1,'first');
                if ~colorind, continue, end
                color2ind=find(strcmp(mArgsIn.TubeDB(tubeidx).parname,mArgsIn.GraphDB(graph).Color2),1,'first');
                if ~color2ind, continue, end
                fcscontour(gateddata,...
                    colorind,color2ind,...
                    mArgsIn.Display.graph_type,mArgsIn.Display.graph_Xaxis,mArgsIn.Display.graph_Xaxis_param,mArgsIn.Display.graph_Yaxis,mArgsIn.Display.graph_Yaxis_param);
                mArgsIn.GraphDB(graph).plotdata=gateddata(:,[colorind,color2ind]);
                graphs=get(gca,'Children');
                if strcmp(get(get(gca,'children'),'type'),'line')
                    if ~isfield(mArgsIn.GraphDB(graph),'PlotColor') || length(mArgsIn.GraphDB(graph).PlotColor)~=3
                        mArgsIn.GraphDB(graph).PlotColor=mArgsIn.Display.GraphColor(mod(graph,7)+(mod(graph,7)==0)*7,:);
                    end
                    set(graphs(1),'Color',mArgsIn.GraphDB(graph).PlotColor);
                end
            end
        else
            dilute=length(mArgsIn.curGraph);
            alldata=[];
            for graph=mArgsIn.curGraph
                tubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],mArgsIn.GraphDB(graph).Data),1,'first');
                %check that the tube exists
                if isempty(tubeidx)
                    continue
                end
                gateddata=mArgsIn.TubeDB(tubeidx).compdata(mArgsIn.GraphDB(graph).gatedindex,:);
                mArgsIn.GraphDB(graph).plotdata=[];
                if isempty(gateddata)
                    no_data_graphs=[no_data_graphs ''', ''' mArgsIn.GraphDB(graph).Name];
                    continue;
                end
                colorind=find(strcmp(mArgsIn.TubeDB(tubeidx).parname,mArgsIn.GraphDB(graph).Color),1,'first');
                if ~colorind, continue, end
                color2ind=find(strcmp(mArgsIn.TubeDB(tubeidx).parname,mArgsIn.GraphDB(graph).Color2),1,'first');
                if ~color2ind, continue, end
                %                 fcscontour(gateddata,...
                %                     colorind,color2ind,...
                %                     mArgsIn.Display.graph_type,mArgsIn.Display.graph_Xaxis,mArgsIn.Display.graph_Xaxis_param,mArgsIn.Display.graph_Yaxis,mArgsIn.Display.graph_Yaxis_param);
                mArgsIn.GraphDB(graph).plotdata=gateddata(:,[colorind,color2ind]);
                alldata=[alldata; mArgsIn.GraphDB(graph).plotdata(1:dilute:end,:)];
                %                 graphs=get(gca,'Children');
                %                 if strcmp(get(get(gca,'children'),'type'),'line')
                %                     if ~isfield(mArgsIn.GraphDB(graph),'PlotColor') || length(mArgsIn.GraphDB(graph).PlotColor)~=3
                %                         mArgsIn.GraphDB(graph).PlotColor=mArgsIn.Display.GraphColor(mod(graph,7)+(mod(graph,7)==0)*7,:);
                %                     end
                %                     set(graphs(1),'Color',mArgsIn.GraphDB(graph).PlotColor);
                %                 end
            end
            fcscontour(alldata,...
                1,2,...
                mArgsIn.Display.graph_type,mArgsIn.Display.graph_Xaxis,mArgsIn.Display.graph_Xaxis_param,mArgsIn.Display.graph_Yaxis,mArgsIn.Display.graph_Yaxis_param);
        end
        if isfield(mArgsIn.Display,'Axis')
            axis(mArgsIn.Display.Axis);
        else
            axis tight;
        end
        if ~isempty(no_data_graphs)
            msgbox(['The graphs ''' no_data_graphs ''' contain no data.'],'EasyFlow','error','modal');
            uiwait;
        end
        if isfield(mArgsIn.GraphDB(mArgsIn.curGraph(1)).Stat,'quad')
            DrawQuads(mArgsIn);
        end
        xlabel(getcolumn(get(mArgsIn.Handles.ColorPUM,'string')',get(mArgsIn.Handles.ColorPUM,'value')));
        ylabel(getcolumn(get(mArgsIn.Handles.ColorPUM,'string')',get(mArgsIn.Handles.Color2PUM,'value')));
    end
    function mArgsIn = DrawQuads(mArgsIn)
        quad=mArgsIn.GraphDB(mArgsIn.curGraph(1)).Stat.quad;
        posx=mArgsIn.GraphDB(mArgsIn.curGraph(1)).plotdata(:,1)>quad(1);
        posy=mArgsIn.GraphDB(mArgsIn.curGraph(1)).plotdata(:,2)>quad(2);
        quad1=sum(and(posx,posy))/length(posx)*100;
        quad2=sum(and(~posx,posy))/length(posx)*100;
        quad3=sum(and(~posx,~posy))/length(posx)*100;
        quad4=sum(and(posx,~posy))/length(posx)*100;
        % rescale quad to the axis scale
        switch mArgsIn.Display.graph_Xaxis
            case 'log'
                quadx=log10(quad(1));
            case 'logicle'
                quadx=asinh(quad(1)*mArgsIn.Display.graph_Xaxis_param(3)/2)/log(10);
            otherwise
                quadx=quad(1);
        end
        % rescale quad to the axis scale
        switch mArgsIn.Display.graph_Yaxis
            case 'ylog'
                quady=log10(quad(2));
            case 'ylogicle'
                quady=asinh(quad(2)*mArgsIn.Display.graph_Yaxis_param(3)/2)/log(10);
            otherwise
                quady=quad(2);
        end
        
        frame=axis;
        delete(findobj(gca,'Tag','quad'));
        line([frame(1),frame(2)],[quady,quady],'Color','k','Tag','quad');
        line([quadx,quadx],[frame(3),frame(4)],'Color','k','Tag','quad');
        axis(frame);
        text(frame(1)+(frame(2)-frame(1))*0.99,frame(3)+(frame(4)-frame(3))*0.99,[num2str(quad1),'%'],'BackgroundColor',[.7 .7 .7],'HorizontalAlignment','right','VerticalAlignment','top','Tag','quad');
        text(frame(1)+(frame(2)-frame(1))*0.01,frame(3)+(frame(4)-frame(3))*0.99,[num2str(quad2),'%'],'BackgroundColor',[.7 .7 .7],'HorizontalAlignment','left','VerticalAlignment','top','Tag','quad');
        text(frame(1)+(frame(2)-frame(1))*0.01,frame(3)+(frame(4)-frame(3))*0.01,[num2str(quad3),'%'],'BackgroundColor',[.7 .7 .7],'HorizontalAlignment','left','VerticalAlignment','bottom','Tag','quad');
        text(frame(1)+(frame(2)-frame(1))*0.99,frame(3)+(frame(4)-frame(3))*0.01,[num2str(quad4),'%'],'BackgroundColor',[.7 .7 .7],'HorizontalAlignment','right','VerticalAlignment','bottom','Tag','quad');
    end

    function UpdateGateList(mArgsIn)
        % Populate the gate list component in the gui.
        if ~isfield(mArgsIn,'curGraph') || isempty(mArgsIn.curGraph) || ~isfield(mArgsIn.GraphDB(mArgsIn.curGraph(1)),'Gates')
            return
        end
        
        %get the indices of the selected and unselected gates.
        selected=[]; unselected=[];
        allGates=fieldnames(mArgsIn.GatesDBnew);
        for cgraph=mArgsIn.curGraph
            curtube=matlab.lang.makeValidName(mArgsIn.GraphDB(cgraph).Data);
            if isfield(mArgsIn,'GatesDB') && isfield(mArgsIn.GatesDB,curtube)
                [allGates,~,inew]=unique([allGates; cell(fieldnames(mArgsIn.GatesDB.(curtube)))]);
                selected=inew(selected)'; unselected=inew(unselected)';
            end
            for gate=mArgsIn.GraphDB(cgraph).Gates
                if isempty(gate) || ~any(strcmp(gate,allGates));
                    mArgsIn.GraphDB(cgraph).Gates(strcmp(mArgsIn.GraphDB(cgraph).Gates,gate))=[];
                    continue
                end
                selected(end+1)=find(strcmp(gate,allGates));
            end
            for gate=mArgsIn.GraphDB(cgraph).GatesOff
                if isempty(gate) || ~any(strcmp(gate,allGates));
                    mArgsIn.GraphDB(cgraph).GatesOff(strcmp(mArgsIn.GraphDB(cgraph).GatesOff,gate))=[];
                    continue
                end
                unselected=[find(strcmp(gate,allGates)) unselected];
            end
        end
        %find those that appear as selected in all graphs
        tmp=find(hist(selected,1:length(allGates))==length(mArgsIn.curGraph));
        %the others are both selected and unselected
        both=setdiff(unique(selected),tmp);
        %take those in tmp but in the order they first apear in tmp (the
        %order for the last tube)
        [~,iselected]=intersect(selected,tmp);
        selected=selected(sort(iselected));
        %remove those that are both from the unselected
        tmp=setdiff(unique(unselected),both);
        [~,iunselected]=intersect(unselected,tmp);
        unselected=unselected(sort(iunselected));
        % make row vectors
        selected=selected(:)';
        unselected=unselected(:)';
        both=both(:)';
%        if isempty(unselected), unselected=[]; end
        delete(get(mArgsIn.Handles.GateList,'Children'))
        guipos=get(mArgsIn.Handles.fh,'Position');
        guisizey=guipos(4);
        pos=1;
        %first put the selected gates by the order of their selection
        for item=selected
            h=uicontrol(mArgsIn.Handles.GateList,...
                'Style','checkbox',...
                'String',[allGates{item}],...
                'Tag',allGates{item},...
                'Position',[5 guisizey-5-20*pos 110 20],...
                'Value',1,...
                'Callback',@GateListCallback,...
                'UIContextMenu', mArgsIn.Handles.GatesCM);
            if length(mArgsIn.curGraph)==1
                set(h,'String',[allGates{item} ' (' num2str(round(100*mArgsIn.GraphDB(mArgsIn.curGraph(1)).Stat.gatepercent(pos))) '%)'])
            end
            pos=pos+1;
        end
        %then put the non determined
        for item=both
            uicontrol(mArgsIn.Handles.GateList,...
                'Style','checkbox',...
                'String',allGates{item},...
                'Tag',allGates{item},...
                'Position',[5 guisizey-5-20*pos 110 20],...
                'Value',1,...
                'ForegroundColor',[1 0 0],...
                'FontAngle','italic',...
                'Callback',@GateListCallback,...
                'UIContextMenu', mArgsIn.Handles.GatesCM);
            pos=pos+1;
        end
        %then put the unselected gates by the order of their unselection
        for item=unselected
            uicontrol(mArgsIn.Handles.GateList,...
                'Style','checkbox',...
                'String',allGates{item},...
                'Tag',allGates{item},...
                'Position',[5 guisizey-5-20*pos 110 20],...
                'Value',0,...
                'Callback',@GateListCallback,...
                'UIContextMenu', mArgsIn.Handles.GatesCM);
            pos=pos+1;
        end
        %then put the rest
        for item=1:length(allGates)
            if find([selected both unselected]==item)
            else
                uicontrol(mArgsIn.Handles.GateList,...
                    'Style','checkbox',...
                    'String',allGates{item},...
                    'Tag',allGates{item},...
                    'Position',[5 guisizey-5-20*pos 110 20],...
                    'Value',0,...
                    'Callback',@GateListCallback,...
                    'UIContextMenu', mArgsIn.Handles.GatesCM);
                pos=pos+1;
            end
        end
    end
    function mArgsIn=UpdateVersion(mArgsIn)
        if ~isfield(mArgsIn,'version') || mArgsIn.version<2.5
            %Update to version 0.2.5
            mArgsIn.version=2.5;
            %if color is an integer, change it to a string.
            if isnumeric([mArgsIn.GraphDB.Color])
                DT={mArgsIn.GraphDB.Data};
                CLR={mArgsIn.GraphDB.Color};
                CLR2={mArgsIn.GraphDB.Color2};
                for i=1:length(DT)
                    if isfield(mArgsIn.hdr,DT{i})
                        mArgsIn.GraphDB(i).Color=mArgsIn.hdr.(DT{i}).par(CLR{i}).name;
                        mArgsIn.GraphDB(i).Color2=mArgsIn.hdr.(DT{i}).par(CLR2{i}).name;
                    elseif strcmp('None',DT{i})
                        mArgsIn.GraphDB(i).Color='None';
                        mArgsIn.GraphDB(i).Color2='None';
                    else
                        msgbox(['Your file was saved in an older version and cannot be converted. To convert it you need first to load the tube ' DT{i}]...
                            ,'EasyFlow','error','modal');
                        uiwait;
                        mArgsIn=[];
                        return;
                    end
                end
            end
            %if ther is GraphDB.Isotype, GraphDB.RemoveIso, change to Ctrl and
            %RemoveCtrl
            if isfield(mArgsIn.GraphDB,'Isotype')
                [mArgsIn.GraphDB.Ctrl]=deal(mArgsIn.GraphDB.Isotype);
                mArgsIn.GraphDB=rmfield(mArgsIn.GraphDB,'Isotype');
            end
            if isfield(mArgsIn.GraphDB,'RemoveIso')
                [mArgsIn.GraphDB.RemoveCtrl]=deal(mArgsIn.GraphDB.RemoveIso);
                mArgsIn.GraphDB=rmfield(mArgsIn.GraphDB,'RemoveIso');
            end
            %change the gates to save the color name rather than the number
            if isfield(mArgsIn,'GatesDB')
                for tube=fieldnames(mArgsIn.GatesDB)'
                    for gatename=fieldnames(mArgsIn.GatesDB.(char(tube)))'
                        if isfield(mArgsIn,'hdr') && isfield(mArgsIn.hdr,char(tube))
                            if length(mArgsIn.GatesDB.(char(tube)).(char(gatename)))>1 && isnumeric(mArgsIn.GatesDB.(char(tube)).(char(gatename)){2})
                                if length(mArgsIn.GatesDB.(char(tube)).(char(gatename)))==2
                                    mArgsIn.GatesDB.(char(tube)).(char(gatename)){2}=mArgsIn.hdr.(char(tube)).par(mArgsIn.GatesDB.(char(tube)).(char(gatename)){2}).name;
                                elseif length(mArgsIn.GatesDB.(char(tube)).(char(gatename)))==3
                                    mArgsIn.GatesDB.(char(tube)).(char(gatename)){2}=mArgsIn.hdr.(char(tube)).par(mArgsIn.GatesDB.(char(tube)).(char(gatename)){2}).name;
                                    mArgsIn.GatesDB.(char(tube)).(char(gatename)){3}=mArgsIn.hdr.(char(tube)).par(mArgsIn.GatesDB.(char(tube)).(char(gatename)){3}).name;
                                end
                            end
                        elseif isfield(mArgsIn,'TubeDB') && any(strcmp([mArgsIn.TubeDB.Tubename],tube))
                            tubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],tube));
                            if length(mArgsIn.GatesDB.(char(tube)).(char(gatename)))>1 && isnumeric(mArgsIn.GatesDB.(char(tube)).(char(gatename)){2})
                                if length(mArgsIn.GatesDB.(char(tube)).(char(gatename)))==2
                                    mArgsIn.GatesDB.(char(tube)).(char(gatename)){2}=mArgsIn.TubeDB(tubeidx).parname(mArgsIn.GatesDB.(char(tube)).(char(gatename)){2});
                                elseif length(mArgsIn.GatesDB.(char(tube)).(char(gatename)))==3
                                    mArgsIn.GatesDB.(char(tube)).(char(gatename)){2}=mArgsIn.TubeDB(tubeidx).parname(mArgsIn.GatesDB.(char(tube)).(char(gatename)){2});
                                    mArgsIn.GatesDB.(char(tube)).(char(gatename)){3}=mArgsIn.TubeDB(tubeidx).parname(mArgsIn.GatesDB.(char(tube)).(char(gatename)){3});
                                end
                            end
                        elseif strcmp('None',char(tube))
                            continue
                        else
                            msgbox(['Your file was saved in an older version and cannot be converted. To convert it you need first to load the tube ' char(tube)]...
                                ,'EasyFlow','error','modal');
                            uiwait;
                            mArgsIn=[];
                            return;
                        end
                    end
                end
            end
            %end update to ver 0.2.5
        end
        if mArgsIn.version<2.6
            %update to ver 0.2.6
            %mArgsIn.workdata=mArgsIn.data;
            %mArgsIn.data=mArgsIn.datauncomp;
            %mArgsIn=rmfield(mArgsIn,datauncomp);
        end
        if mArgsIn.version<2.7
            curGraph=mArgsIn.curGraph;
            mArgsIn.curGraph=1:length(mArgsIn.GraphDB);
            mArgsIn=CalculateGatedData(mArgsIn);
            mArgsIn.curGraph=curGraph;
        end
        if mArgsIn.version<2.8
            %add a 'fit' field
            if ~isempty(mArgsIn.GraphDB) && ~isfield(mArgsIn.GraphDB,'fit')
                [mArgsIn.GraphDB.fit]=deal([]);
            end
        end
        if mArgsIn.version<2.9
            %arrange the gates
            %recalculate the gate logical indices
            if isempty(mArgsIn.TubeDB)
                mArgsIncur=guidata(mArgsIn.Handles.fh);
                mArgsIn2=mArgsIncur;
                mArgsIn2.GraphDB=[];
                mArgsIn2.TubeNames={'None'};
                if isfield(mArgsIn2,'curGraph')
                    mArgsIn2=rmfield(mArgsIn2,'curGraph');
                end
                if isfield(mArgsIn2,'GatesDB')
                    mArgsIn2=rmfield(mArgsIn2,'GatesDB');
                end
                if isfield(mArgsIn2,'copy')
                    mArgsIn2=rmfield(mArgsIn2,'copy');
                end
                guidata(mArgsIn.Handles.fh,mArgsIn2)
                TubeLoadCallback(0,[],mArgsIn.Handles.fh);
                mArgsIn2=guidata(mArgsIn.Handles.fh);
                mArgsIncur.TubeDB=mArgsIn2.TubeDB;
                mArgsIncur.TubeNames=mArgsIn2.TubeNames;
                guidata(mArgsIn.Handles.fh,mArgsIncur)
                mArgsIn.TubeDB=mArgsIn2.TubeDB;
                mArgsIn.TubeNames=mArgsIn2.TubeNames;
            end
            if isfield(mArgsIn.TubeDB, 'Tubename')
                for ctubename=[mArgsIn.TubeDB.Tubename];
                    ctubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],ctubename),1,'first');
                    if isfield(mArgsIn,'GatesDB') && isfield(mArgsIn.GatesDB,matlab.lang.makeValidName(char(ctubename)))
                        for gatename=fieldnames(mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))))'
                            gate=mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(gatename));
                            if length(gate)==2
                                gate{3}=gate{2};
                                gate{4}=[];
                                colorind=find(strcmp(mArgsIn.TubeDB(ctubeidx).parname,gate{3}),1,'first');
                                gate{2}=...
                                    mArgsIn.TubeDB(ctubeidx).compdata(:,colorind)>gate{1}(1) ...
                                    & mArgsIn.TubeDB(ctubeidx).compdata(:,colorind)<gate{1}(2);
                            elseif length(gate)==3
                                gate{4}=gate{3};
                                gate{3}=gate{2};
                                colorind(1)=find(strcmp(mArgsIn.TubeDB(ctubeidx).parname,gate{3}),1,'first');
                                colorind(2)=find(strcmp(mArgsIn.TubeDB(ctubeidx).parname,gate{4}),1,'first');
                                gate{2}=...
                                    gate2d(gate{1},mArgsIn.TubeDB(ctubeidx).compdata,colorind(1),colorind(2));
                            end
                            mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(gatename))=gate;
                        end
                    end
                end
            end
            [mArgsIn.GraphDB.GatesOff]=deal({});
        end
        if mArgsIn.version<3.0
            for i=1:length(mArgsIn.GraphDB)
                if ~isfield(mArgsIn.GraphDB(i).Display,'smoothprm')
                    mArgsIn.GraphDB(i).Display.smoothprm=-1;
                end
                if ~isfield(mArgsIn,'Statistics')
                    mArgsIn.Statistics.ShowInStatView=true(1,9);
                end
            end
            if isfield(mArgsIn,'GatesDB')
                for tube=fieldnames(mArgsIn.GatesDB)'
                    for gate=fieldnames(mArgsIn.GatesDB.(char(tube)))'
                        if isempty(mArgsIn.GatesDB.(char(tube)).(char(gate)){4}) && isinf(mArgsIn.GatesDB.(char(tube)).(char(gate)){1}(3))
                            mArgsIn.GatesDB.(char(tube)).(char(gate)){1}(3)=0;
                        end
                    end
                end
            end

            mArgsIn.DBInfo.geom.Graphsize=100;
            mArgsIn.DBInfo.geom.Gatesize=120;
        end
        if mArgsIn.version<3.19
            %
            % Change the field DBFile to DBInfo
            %
            mArgsIn.DBInfo=mArgsIn.DBFile;
            mArgsIn=rmfield(mArgsIn,'DBFile');
            %
            % New gates strucutre. global gates for all tubes.
            %
            %collect all gates from all tubes into a single structure which
            %will be the new GatesDB
            allgates=struct();
            for tube=fieldnames(mArgsIn.GatesDB)'
                for cur_gate=fieldnames(mArgsIn.GatesDB.(tube{1}))'
                    tmpgate=mArgsIn.GatesDB.(tube{1}).(cur_gate{1})([1,3:end]);
                    if ~any(structfun(@(x) isequal(x,tmpgate), allgates))
                        gatename=matlab.lang.makeUniqueStrings(cur_gate{1}, fieldnames(allgates));
                        allgates.(gatename)=tmpgate;
                    end
                end
            end
            %put the logical gate in TubeDB.isgated
            %or maybe calculate from scratch?
            for tube=fieldnames(mArgsIn.GatesDB)'
                % previously (delete): tube_ind=strcmp(tube,[mArgsIn.TubeDB.Tubename]);
                tube_ind=strcmp(tube,matlab.lang.makeValidName([mArgsIn.TubeDB.Tubename], 'ReplacementStyle','hex'));
                for cur_gate=fieldnames(mArgsIn.GatesDB.(tube{1}))'
                    tmpisgated=mArgsIn.GatesDB.(tube{1}).(cur_gate{1})(2);
                    mArgsIn.TubeDB(tube_ind).gatemask.(cur_gate{1})=tmpisgated;
                end
            end
            mArgsIn.GatesDBnew=allgates;
        end
        %insert before this line the text in FileLoadCallback after the comment:
        
        mArgsIn.version=curversion;
        mArgsIn.DBInfo.isChanged=1;
        %updates for next version are in FileLoadCallback
    end
    function mArgsIn=CalculateMarkers(mArgsIn)
        if strcmp(mArgsIn.Display.graph_type,'Histogram')
            for cgraph=get(mArgsIn.Handles.GraphList,'Value')
                mArgsIn.GraphDB(cgraph).Stat.quadp=[];
            end
        else
            for cgraph=get(mArgsIn.Handles.GraphList,'Value')
                if isfield(mArgsIn.GraphDB(cgraph).Stat,'quad')
                    quad=mArgsIn.GraphDB(cgraph).Stat.quad;
                    posx=mArgsIn.GraphDB(cgraph).plotdata(:,1)>quad(1);
                    posy=mArgsIn.GraphDB(cgraph).plotdata(:,2)>quad(2);
                    quad1=sum(and(posx,posy))/length(posx)*100;
                    quad2=sum(and(~posx,posy))/length(posx)*100;
                    quad3=sum(and(~posx,~posy))/length(posx)*100;
                    quad4=sum(and(posx,~posy))/length(posx)*100;
                    %remove the next line
                    mArgsIn.GraphDB(cgraph).Stat.quadp=[quad1,quad2,quad3,quad4];
                else
                    mArgsIn.GraphDB(cgraph).Stat.quadp=[];
                end
            end
        end
        % Recalc the statistics
        if isfield(mArgsIn.Handles,'statwin')
            Args=guidata(mArgsIn.Handles.statwin);
            Args.fCalcStat(mArgsIn);
        end
    end
    function gatemask=calculate_gate_mask(Sample, gate)
        %probably need to make sure it is not a logical or an artifact gate
        %before starting
        switch gate{3}
            case 'logical'
                switch gate{1}
                    case 'Not'
                        cgate=gate{2};
                        gatemask= not( Sample.gatemask.( char( cgate) ) );
                    case 'Xor'
                        cgate1=gate{2}(1);
                        cgate2=gate{2}(2);
                        gatemask=xor(...
                            Sample.gatemask.( char( cgate1) ),...
                            Sample.gatemask.( char( cgate2) ));
                    case 'And'
                        gatemask=true( size( Sample.compdata ,1),1);
                        for cgate=gate{2}'
                            gatemask=and(gatemask,...
                                Sample.gatemask.( char( cgate) ));
                        end
                    case 'Or'
                        gatemask=false( size( Sample.compdata ,1),1);
                        for cgate=gate{2}'
                            gatemask=or(gatemask,...
                                Sample.gatemask.( char( cgate) ));
                        end
                end
            case 'artifact'
                colorind=find(strcmp(Sample.parname,gate{2}),1,'first');
                scaleddata=fcsscaleconvert(Sample.compdata(:,colorind),'lin',1, gate{1}{:});
                gatemask=fcsartifact(scaleddata);
            otherwise %regular 1 or 2 dimensional gate. TBD - redefine the 3rd element to be explicit.
                colorind1=find(strcmp(Sample.parname,gate{2}),1,'first');
                colorind2=find(strcmp(Sample.parname,gate{3}),1,'first');
                if isempty(colorind2)
                    gatemask=gate1d(gate{1}, Sample.compdata, colorind1);
                else
                    gatemask=gate2d(gate{1}, Sample.compdata, colorind1, colorind2);
                end
        end
    end
    function mArgsIn=RecalcGateLogicalMask(mArgsIn,tubename_list)
        %calculate the second element of the gate (the logical mask) from
        %the other elements. first calculate the regular gates and than the
        %logical-derived gates
        %
        %tubename_list is the tubename after matlab.lang.makeValidName
        for ctubename=tubename_list;
            ctubeidx=find(strcmp(matlab.lang.makeValidName([mArgsIn.TubeDB.Tubename]),ctubename),1,'first');
            if isfield(mArgsIn,'GatesDB') && isfield(mArgsIn.GatesDB,(char(ctubename)))
                for gatename=fieldnames(mArgsIn.GatesDB.((char(ctubename))))'
                    gate=mArgsIn.GatesDB.((char(ctubename))).(char(gatename));
                    if isempty(gate{4})
                        colorind=find(strcmp(mArgsIn.TubeDB(ctubeidx).parname,gate{3}),1,'first');
                        mArgsIn.GatesDB.((char(ctubename))).(char(gatename)){2}=...
                            mArgsIn.TubeDB(ctubeidx).compdata(:,colorind)>gate{1}(1) ...
                            & mArgsIn.TubeDB(ctubeidx).compdata(:,colorind)<gate{1}(2);
                    elseif strcmp(gate{4},'artifact')
                        colorind=find(strcmp(mArgsIn.TubeDB(ctubeidx).parname,gate{3}),1,'first');
                        %use the current display settings to scale the data. maybe to ask?
                        scaleddata=fcsscaleconvert(mArgsIn.TubeDB(ctubeidx).compdata(:,colorind),'lin',1, gate{1}{1}, gate{1}{2});
                        mArgsIn.GatesDB.(char(ctubename)).(char(gatename)){2}=fcsartifact(scaleddata);

                    elseif ischar(gate{4}) && strcmp(gate{4},'logical')
                        %this is a logical-derived gate. keep it for later.
                    else
                        colorind(1)=find(strcmp(mArgsIn.TubeDB(ctubeidx).parname,gate{3}),1,'first');
                        colorind(2)=find(strcmp(mArgsIn.TubeDB(ctubeidx).parname,gate{4}),1,'first');
                        mArgsIn.GatesDB.((char(ctubename))).(char(gatename)){2}=...
                            gate2d(gate{1},mArgsIn.TubeDB(ctubeidx).compdata,colorind(1),colorind(2));
                    end
                end
                for gatename=fieldnames(mArgsIn.GatesDB.((char(ctubename))))'
                    gate=mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(gatename));
                    if ischar(gate{4}) && strcmp(gate{4},'logical')
                        %this is a logical-derived gate. do it now.
                        switch gate{1}
                            case 'Not'
                                cgate=gate{3};
                                mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(gatename)){2}=not(mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(cgate)){2});
                            case 'Xor'
                                cgate1=gate{3}(1);
                                cgate2=gate{3}(2);
                                mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(gatename)){2}=xor(mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(cgate1)){2},mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(cgate2)){2});
                            case 'And'
                                gate_ind=true(size(mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(gate{3}(1))){2}));
                                for cgate=gate{3}
                                    gate_ind=and(gate_ind,mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(cgate)){2});
                                end
                                mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(gatename)){2}=gate_ind;
                            case 'Or'
                                gate_ind=false(size(mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(gate{3}(1))){2}));
                                for cgate=gate{3}
                                    gate_ind=or(gate_ind,mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(cgate)){2});
                                end
                                mArgsIn.GatesDB.(matlab.lang.makeValidName(char(ctubename))).(char(gatename)){2}=gate_ind;
                        end
                    end
                end
            end
        end
    end
    function efdbIn=CalculateGatedData(efdbIn)
        % Integrate all gates that should be applied to each plot
        % generates mArgsIn.GraphDB(graph).gatedindex and calculate some
        % stats.
        
        for graph=efdbIn.curGraph
            %check that the tube exists
            try
                tubename=matlab.lang.makeValidName(efdbIn.GraphDB(graph).Data);
            catch err
                keyboard
                rethrow(err)
            end
            tubeidx=find(strcmp([efdbIn.TubeDB.Tubename],efdbIn.GraphDB(graph).Data),1,'first');
            if tubeidx
                percent=zeros(length(efdbIn.GraphDB(graph).Gates),1);
                efdbIn.GraphDB(graph).gatedindex=true(size(efdbIn.TubeDB(tubeidx).compdata,1),1);
                for cur_gate_idx=1:length(efdbIn.GraphDB(graph).Gates)
                    gatename=efdbIn.GraphDB(graph).Gates(cur_gate_idx);
                    %find the gate
                    if isfield(efdbIn,'GatesDBnew') && isfield(efdbIn.GatesDBnew,gatename)
                        gate=efdbIn.GatesDBnew.(char(gatename));
                    else
                        %this gate is not defined mark it with a -1 percent
                        percent(cur_gate_idx)=-1;
                        continue
                    end
                    if ~isfield(efdbIn.TubeDB,'gatemask') || ~isfield(efdbIn.TubeDB(tubeidx).gatemask,gatename)
                        %need to calculate the gatemask
                        efdbIn.TubeDB(tubeidx).gatemask.(char(gatename))=calculate_gate_mask(efdbIn.TubeDB(tubeidx),gate);
                    end
                    num_events_parent=sum(efdbIn.GraphDB(graph).gatedindex);
                    cur_gatemask=efdbIn.TubeDB(tubeidx).gatemask.(char(gatename));
                    efdbIn.GraphDB(graph).gatedindex=efdbIn.GraphDB(graph).gatedindex & cur_gatemask;
                    percent(cur_gate_idx)=sum(efdbIn.GraphDB(graph).gatedindex)/num_events_parent;
                end
                efdbIn.GraphDB(graph).Stat.gatepercent=percent;
            else %tube does not exist
                efdbIn.GraphDB(graph).Stat.gatepercent=0;
                efdbIn.GraphDB(graph).gatedindex=[];
            end
        end
    end
    function Tube=LoadTube(fcsfile)
        Tube.fcsfile=[];
        %who calls this function? FileLoadCallback, Tube menu->Load...
        Tube.Tubename=fcsfile.var_value(strcmp(fcsfile.var_name,'TUBE NAME'));
        if isempty(Tube.Tubename) && ~isempty(strfind(fcsfile.var_value{strcmp(fcsfile.var_name,'$CYT')},'MACSQuant'))
            Tube.Tubename=fcsfile.var_value(strcmp(fcsfile.var_name,'$CELLS'));
        end
        if isempty(Tube.Tubename)
            Tube.Tubename={fcsfile.filename};
            fcsfile=fcssetparam(fcsfile,'TUBE NAME',fcsfile.filename);
        end
        Tube.tubepath=fcsfile.dirname;
        Tube.tubefile=fcsfile.filename;
        for i=1:str2double(fcsfile.var_value{strcmp(fcsfile.var_name,'$PAR')})
            Tube.parname(i)=fcsfile.var_value(strcmp(fcsfile.var_name,['$P' num2str(i) 'N']));
            symbol=fcsfile.var_value(strcmp(fcsfile.var_name,['$P' num2str(i) 'S']));
            if ~isempty(symbol)
                Tube.parsymbol(i)=fcsfile.var_value(strcmp(fcsfile.var_name,['$P' num2str(i) 'S']));
            else
                Tube.parsymbol(i)={''};
            end
        end
        
        if any(strcmp(fcsfile.var_name,'SPILL'))
            spill=textscan(fcsfile.var_value{strcmp(fcsfile.var_name,'SPILL')},'%s','delimiter', ',');
            spill=spill{1};
            mtxsize=str2double(spill{1});
            % The compenstaion parameters names
            Tube.CompensationPrm=spill(2:mtxsize+1);
            % The compensation matrix
            Tube.CompensationMtx=reshape(arrayfun(@str2double,spill(mtxsize+2:end)),mtxsize,mtxsize);
        else
            Tube.CompensationPrm=fcsfile.var_value(cellfun(@isempty,regexp(fcsfile.var_value,'FSC')) ...
                & cellfun(@isempty,regexp(fcsfile.var_value,'SSC')) ...
                & ~cellfun(@isempty,regexp(fcsfile.var_value,'-A$')) ...
                & ~cellfun(@isempty,(regexp(fcsfile.var_name,'\$P[0-9]+N'))));
            mtxsize=length(Tube.CompensationPrm);
            Tube.CompensationMtx=eye(mtxsize);
            spill=[sprintf('%d',mtxsize)...
                sprintf(',%s',Tube.CompensationPrm{:})...
                sprintf(',%d',Tube.CompensationMtx)];
            fcsfile=fcssetparam(fcsfile,'SPILL',spill);
        end
        Tube.fcsfile=fcsfile;
        
        % Compensate the data.
        % check if we want to compensate the data
        Tube.CompensationIndex=[];
        if ~isempty(Tube.CompensationMtx)
            for i=Tube.CompensationPrm'
                Tube.CompensationIndex(end+1)=find(strcmp(char(i),Tube.parname));
            end
            Tube.compdata=fcsfile.fcsdata;
            Tube.compdata(:,Tube.CompensationIndex)=Tube.compdata(:,Tube.CompensationIndex)/(Tube.CompensationMtx');
        else
            Tube.compdata=fcsfile.fcsdata;
        end
    end

    function efdb=abs2relpath(efdb)
        %change all tube paths to relative.
        %mostly effects efdb.TubeDB().tubepath
        
        if java.io.File(efdb.DBInfo.RootFolder).isAbsolute
            rootdir=char(java.io.File(efdb.DBInfo.RootFolder).getCanonicalPath);
        else
            [DBInfodir ,~]=fileparts(efdb.DBInfo.Name);
            rootdir=char(java.io.File([DBInfodir, filesep, efdb.DBInfo.RootFolder]).getCanonicalPath);
        end
        
        for i=1:length(efdb.TubeDB)
            if strfind(efdb.TubeDB(i).tubepath,rootdir)
                efdb.TubeDB(i).tubepath = ...
                    efdb.TubeDB(i).tubepath(length(rootdir)+1:end);
            end
        end
    end
    function efdb=rel2abspath(efdb)
        %change all tube paths to absolute.
        %mostly effect efdb.TubeDB().tubepath
        
        if java.io.File(efdb.DBInfo.RootFolder).isAbsolute
            rootdir=char(java.io.File(efdb.DBInfo.RootFolder).getCanonicalPath);
        else
            [DBInfodir ,~]=fileparts(efdb.DBInfo.Name);
            rootdir=char(java.io.File([DBInfodir, filesep, efdb.DBInfo.RootFolder]).getCanonicalPath);
        end

        for i=1:length(efdb.TubeDB)
            efdb.TubeDB(i).tubepath = ...
                char(java.io.File([rootdir filesep efdb.TubeDB(i).tubepath]).getCanonicalPath);
        end
    end

    function efdb=disable_gui(efdb)
        efdb.DBInfo.enabled_gui=findobj(efdb.Handles.fh,'Enable','on');
        set(efdb.DBInfo.enabled_gui,'Enable','off');
    end
    function efdb=enable_gui(efdb)
        ind_handle=ishandle(efdb.DBInfo.enabled_gui);
        set(efdb.DBInfo.enabled_gui(ind_handle),'Enable','on');
    end
    function efdb=efdb_load(hObject)
        fhIn=ancestor(hObject,'figure');
        efdb=guidata(fhIn);
    end
    function efdb_save(efdb)
        % save the variable efdb into the guidata of the figure stored in
        % efdb
        
        %find the figure object
        fhIn=efdb.Handles.fh;

        % If the save-able parts of the efdb were changed, mark it.
        if ~isempty(guidata(fhIn))
            if ~isequal(rmfield(efdb,'Handles'),rmfield(guidata(fhIn),'Handles'))
                efdb.DBInfo.isChanged=1;
            end
        end
        
        % Save the guidata
        guidata(fhIn,efdb)
    end
end

function EasyFlow_compensation(varargin)
% EasyFlow_FIGPROP Figure properties for the EasyFlow
%

%  Initialization tasks

%  Initialize input/output parameters
hMainFig=varargin{1};
mArgsIn=guidata(hMainFig);
%if there is already an instance running just make it visible and raise it.
if isfield(mArgsIn.Handles,'compensation')
    set(mArgsIn.Handles.compensation,'Visible','on');
    figure(mArgsIn.Handles.compensation);
    return;
end


%  Initialize data structures
%tubeidx=arrayfun(@(x) find(strcmp([mArgsIn.TubeDB.Tubename],x),1,'first'), {mArgsIn.GraphDB(mArgsIn.curGraph).Data});
graph=mArgsIn.curGraph(1);
tubename=mArgsIn.GraphDB(graph).Data;
tubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],tubename),1,'first');
mtxsize=length(mArgsIn.TubeDB(tubeidx).CompensationPrm);
mtxnames=mArgsIn.TubeDB(tubeidx).CompensationPrm;
mtxvalue=mArgsIn.TubeDB(tubeidx).CompensationMtx;

%if some tubes have different compensation - don't show anything.
for cgraph=mArgsIn.curGraph
    ctubename=mArgsIn.GraphDB(cgraph).Data;
    ctubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],ctubename),1,'first');
    if mtxsize~=length(mArgsIn.TubeDB(ctubeidx).CompensationPrm)...
            || any(~strcmp(mtxnames,mArgsIn.TubeDB(ctubeidx).CompensationPrm))...
            || any(any(mtxvalue~=mArgsIn.TubeDB(ctubeidx).CompensationMtx))
        msgbox('There are tubes with different compensation matrices. Cannot open matrix.','EasyFlow','error','modal');
        uiwait;
        return;
    end
end


guisizex=0;
guisizey=0;
scrsz=get(0,'ScreenSize');

%  Construct the figure
fh=figure('Position',[scrsz(3) scrsz(4) 1 1],...
    'MenuBar','none',...
    'Name','FACS GUI Edit Compensation',...
    'NumberTitle','off',...
    'Visible','off',...
    'Resize','off',...
    'CloseRequestFcn',{@fhClose,hMainFig});
mArgsIn.Handles.compensation=fh;
guidata(hMainFig,mArgsIn);
Args.fUpdateComp=@UpdateComp;
guidata(fh,Args);

%  Construct the components
table=uitable(fh,...
    'ColumnName',mtxnames,...
    'RowName',mtxnames,...
    'Data',mtxvalue,...
    'ColumnEditable',true,...
    'CellEditCallback',@ChangeCallback);
set(fh,'Visible','on');
fhpos=[(scrsz(3)-guisizex)/2,(scrsz(4)-guisizey)/2,0,0]+get(table,'Extent')+[0 0 0 20];
set(fh,'Visible','off');
set(fh,'Position',fhpos);
set(table,'Position',[1 1 fhpos(3) fhpos(4)-20]);
uicontrol(fh,...
    'Style','text',...
    'String',['Compensation matrix for ' tubename],...
    'Position',[0 fhpos(4)-20 fhpos(3) 20])
%Context menus
%Gates
TableCM = uicontextmenu('Parent',fh,...
    'Callback',@MenuTable);
uimenu(TableCM,...
    'Label','Copy',...
    'Callback',@MenuTableCopy);
uimenu(TableCM,...
    'Label','Paste',...
    'Callback',@MenuTablePaste);
uimenu(TableCM,...
    'Label','Export',...
    'Callback',@MenuTableExport);
uimenu(TableCM,...
    'Label','Import',...
    'Callback',@MenuTableImport);
uimenu(TableCM,...
    'Label','Use Compensation',...
    'Callback',@MenuTableUseComp);
uimenu(TableCM,...
    'Label','AutoCalc Compensation',...
    'Callback',@MenuTableAutoComp);
set(table,'UIContextMenu',TableCM);

%  Initialization tasks

%  Render GUI visible
set(fh,'Visible','on');


% %  Wait for termination of GUI to give output
% if nargout>0
%     uiwait;%uiresume
%     %  Return the output
%     mOutputArgs{1}=mArgsIn.GraphDB;
%     if nargout==size(mOutputArgs,2)
%         [varargout{1:nargout}] = mOutputArgs{:};
%     end
% end

%  Callbacks.
    function fhClose(hObject,eventdata,hMainFig)
        mArgsIn=guidata(hMainFig);
        mArgsIn.Handles=rmfield(mArgsIn.Handles,'compensation');
        guidata(hMainFig,mArgsIn);
        if isempty(hObject)
            if length(dbstack) == 1
                warning('MATLAB:closereq', ...
                    'Calling closereq from the command line is now obsolete, use close instead');
            end
            close force
        else
            delete(hObject);
        end
    end
    function ChangeCallback(hObject,eventdata)
        mArgsIn=guidata(hMainFig);
        mtxvalue=get(table,'Data');
        
        cM=strtrim(cellstr(num2str(mtxvalue(:),'%.4f')));
        cSpill={num2str(length(mArgsIn.TubeDB(tubeidx).CompensationPrm)) mArgsIn.TubeDB(tubeidx).CompensationPrm{:} cM{:}};
        sep=cell(size(cSpill(:)));
        [sep{:}]=deal(',');
        cSpill=[cSpill(:),sep]';
        Spill=[cSpill{1:end-1}];
        
        %move over all tubes in the curent selected graphs
        for ctubename=unique({mArgsIn.GraphDB(mArgsIn.curGraph).Data})
            ctubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],ctubename),1,'first');
            mArgsIn.TubeDB(ctubeidx).CompensationMtx=mtxvalue;
            %set the new comp in the param of the fcsfile
            mArgsIn.TubeDB(ctubeidx).fcsfile=fcssetparam(mArgsIn.TubeDB(ctubeidx).fcsfile,'SPILL',Spill);
            %recalc compensation
            fcsfile=mArgsIn.TubeDB(ctubeidx).fcsfile;
            uncompdata=fcsfile.fcsdata;
            mArgsIn.TubeDB(ctubeidx).compdata=uncompdata;
            mArgsIn.TubeDB(ctubeidx).compdata(:,mArgsIn.TubeDB(ctubeidx).CompensationIndex)=uncompdata(:,mArgsIn.TubeDB(ctubeidx).CompensationIndex)*inv(mtxvalue');
            
            %recalculate the gate logical indices
            
            mArgsIn=mArgsIn.Handles.RecalcGateLogicalMask(mArgsIn,matlab.lang.makeValidName(ctubename));
            
        end
        
        %needto recalc gated data to show
        mArgsIn=mArgsIn.Handles.CalculateGatedData(mArgsIn);
        mArgsIn.DBInfo.isChanged=1;
        guidata(hMainFig,mArgsIn);
        mArgsIn.Handles.DrawFcn(mArgsIn);
        %figure(gcbf);
    end

    function MenuTable(hObject,eventdata)
        mArgsIn=guidata(hMainFig);
        if isfield(mArgsIn,'copy') && isfield(mArgsIn.copy,'compensation')
            set(findobj(hObject,'Label','Paste'),'Enable','on');
        else
            set(findobj(hObject,'Label','Paste'),'Enable','off');
        end
        
    end
    function MenuTableCopy(hObject,eventdata)
        mArgsIn=guidata(hMainFig);
        mArgsIn.copy.compensation=mtxvalue;
        mArgsIn.DBInfo.isChanged=1;
        guidata(hMainFig,mArgsIn)
    end
    function MenuTablePaste(hObject,eventdata)
        mArgsIn=guidata(hMainFig);
        if isfield(mArgsIn,'copy') && isfield(mArgsIn.copy,'compensation')
            set(table,'Data',mArgsIn.copy.compensation);
            ChangeCallback(table,[]);
        end
    end
    function MenuTableExport(hObject,eventdata)
        export2wsdlg({'Save Compensation Matrix As:'},{'CompMtx'},{mtxvalue});
    end
    function MenuTableImport(hObject,eventdata)
        mArgsIn=guidata(hMainFig);
        vars=evalin('base','who');
        mtxvarname=popupdlg('choose a matrix',vars);
        mtxvar=evalin('base',vars{mtxvarname});

        if size(mtxvalue)==size(mtxvar)
            set(table,'Data',mtxvar);
            ChangeCallback(table,[]);
            else
            msgbox(['The variable ' vars{fitvarname} ' does not contain a matrix of the correct size.'],'EasyFlow','error','modal');
            uiwait;
        end
    end
    function MenuTableUseComp(hObject,eventdata)
        mArgsIn=guidata(hMainFig);
        if ~isfield(mArgsIn.TubeDB,'Tubename')
            msgbox('No open tubes were found.','EasyFlow','error','modal');
            uiwait;
            return;
        end
        S=[mArgsIn.TubeDB.Tubename];
        if isempty(S)
            msgbox('No open tubes were found.','EasyFlow','error','modal');
            uiwait;
            return;
        end
        [Selection,ok] = listdlg('ListString',S,'Name','Select Tubes','PromptString','Select tubes for which to use this compensation.','OKString','Set Compensation');
        if ok==1
            %format the spill
            cM=strtrim(cellstr(num2str(mtxvalue(:),'%.4f')));
            cSpill={num2str(length(mArgsIn.TubeDB(tubeidx).CompensationPrm)) mArgsIn.TubeDB(tubeidx).CompensationPrm{:} cM{:}};
            sep=cell(size(cSpill(:)));
            [sep{:}]=deal(',');
            cSpill=[cSpill(:),sep]';
            Spill=[cSpill{1:end-1}];
            
            for ctubeidx=Selection
                if mtxsize~=length(mArgsIn.TubeDB(ctubeidx).CompensationPrm)...
                        || any(~strcmp(mtxnames,mArgsIn.TubeDB(ctubeidx).CompensationPrm))
                    msgbox(['The tube ' S{ctubeidx} ' has different colors. Cannot use matrix.'],'EasyFlow','error','modal');
                    uiwait;
                    continue;
                end
                
                mArgsIn.TubeDB(ctubeidx).CompensationMtx=mtxvalue;
                %set the new comp in the param of the fcsfile
                mArgsIn.TubeDB(ctubeidx).fcsfile=fcssetparam(mArgsIn.TubeDB(ctubeidx).fcsfile,'SPILL',Spill);
                %recalc compensation
                fcsfile=mArgsIn.TubeDB(ctubeidx).fcsfile;
                uncompdata=fcsfile.fcsdata;
                mArgsIn.TubeDB(ctubeidx).compdata=uncompdata;
                mArgsIn.TubeDB(ctubeidx).compdata(:,mArgsIn.TubeDB(ctubeidx).CompensationIndex)=uncompdata(:,mArgsIn.TubeDB(ctubeidx).CompensationIndex)*inv(mtxvalue');
                
                %recalculate the gate logical indices
                ctubename=mArgsIn.TubeDB(ctubeidx).Tubename;
                mArgsIn=mArgsIn.Handles.RecalcGateLogicalMask(mArgsIn,matlab.lang.makeValidName(ctubename));
            end
            %need to recalc gates but not for the curGraph
            changed_graphs=find(cellfun(@(x) any(strcmp(S(Selection),x)),{mArgsIn.GraphDB.Data}));
            cgraphs=mArgsIn.curGraph;
            mArgsIn.curGraph=changed_graphs;
            mArgsIn=mArgsIn.Handles.CalculateGatedData(mArgsIn);
            mArgsIn.curGraph=cgraphs;
            mArgsIn.DBInfo.isChanged=1;
            guidata(hMainFig,mArgsIn);
            mArgsIn.Handles.DrawFcn(mArgsIn);
        end
    end
    function MenuTableAutoComp(hObject,eventdata)
        [compmat,colorlist]=EFCalcComp;
        mArgsIn=guidata(hMainFig);
        [~,tblIdx,clrIdx]=intersect(table.ColumnName,colorlist);
        table.Data(tblIdx,tblIdx)=compmat(clrIdx,clrIdx);
        ChangeCallback(table,[]);
    end

%  Utility functions for MYGUI
    function UpdateComp(hMainFig)
        mArgsIn=guidata(hMainFig);
        graph=mArgsIn.curGraph(1);
        tubename=mArgsIn.GraphDB(graph).Data;
        tubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],tubename),1,'first');
        mtxsize=length(mArgsIn.TubeDB(tubeidx).CompensationPrm);
        mtxnames=mArgsIn.TubeDB(tubeidx).CompensationPrm;
        mtxvalue=mArgsIn.TubeDB(tubeidx).CompensationMtx;
        
        %if some tubes have different compensation - don't show anything.
        for cgraph=mArgsIn.curGraph
            ctubename=mArgsIn.GraphDB(cgraph).Data;
            ctubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],ctubename),1,'first');
            if mtxsize~=length(mArgsIn.TubeDB(ctubeidx).CompensationPrm)...
                    || any(~strcmp(mtxnames,mArgsIn.TubeDB(ctubeidx).CompensationPrm))...
                    || any(any(mtxvalue~=mArgsIn.TubeDB(ctubeidx).CompensationMtx))
                msgbox('There are tubes with different compensation matrices. Cannot open matrix.','EasyFlow','error','modal');
                uiwait;
                fhClose(fh,[],hMainFig);
                return;
            end
        end
        
        fhpos=get(fh,'Position');
        fhpos=[fhpos(1),fhpos(2),0,0]+get(table,'Extent')+[0 0 0 20];
        set(fh,'Position',fhpos);
        set(table,'Position',[1 1 fhpos(3) fhpos(4)-20]);
        set(findobj(fh,'Type','uicontrol'),'String',['Compensation matrix for ' tubename],'Position',[0 fhpos(4)-20 fhpos(3) 20]);
        set(table,'Data',mtxvalue);
        
    end
end
function EasyFlow_figprop(varargin)
% EasyFlow_FIGPROP Figure properties for the EasyFlow
%

%  Initialization tasks

%  Initialize input/output parameters
hMainFig=varargin{1};
mArgsIn=guidata(hMainFig);
%if there is already an instance running just make it visible and raise it.
if isfield(mArgsIn.Handles,'graphprop')
    set(mArgsIn.Handles.graphprop,'Visible','on');
    figure(mArgsIn.Handles.graphprop);
    return;
end


% Initialize data structures

%  Construct the figure
scrsz=get(0,'ScreenSize');
guisizex=300;
guisizey=200;
fh=figure('Position',[(scrsz(3)-guisizex)/2,(scrsz(4)-guisizey)/2,guisizex,guisizey],...
    'MenuBar','none',...
    'Name','FACS GUI Figure Properties',...
    'NumberTitle','off',...
    'Visible','off',...
    'Resize','off',...
    'CloseRequestFcn',{@fhClose,hMainFig});
mArgsIn.Handles.graphprop=fh;
guidata(hMainFig,mArgsIn);
%  Construct the components
GraphType=uibuttongroup(...
    'Title','GraphType',...
    'Units','pixels',...
    'Position',[0 0 100 200]);
uicontrol(GraphType,...
    'Style','Radio',...
    'String','Histogram',...
    'Position',[0 160 95,20]);
uicontrol(GraphType,...
    'Style','Radio',...
    'String','Dot Plot',...
    'Position',[0 120 95,20]);
uicontrol(GraphType,...
    'Style','Radio',...
    'String','Colored Dot Plot',...
    'Position',[0 80 95,20]);
uicontrol(GraphType,...
    'Style','Radio',...
    'String','Contour',...
    'Position',[0 40 95,20]);
uicontrol(GraphType,...
    'Style','Radio',...
    'String','Filled Contour',...
    'Position',[0 0 95,20]);

Xaxis=uibuttongroup(...
    'Title','Xaxis',...
    'Units','pixels',...
    'Position',[100 100 100 100]);
uicontrol(Xaxis,...
    'Style','Radio',...
    'String','Linear',...
    'Tag','lin',...
    'UserData',[0 Inf 1],...
    'Position',[0 65 95 20]);
uicontrol(Xaxis,...
    'Style','Radio',...
    'String','Logarithmic',...
    'Tag','log',...
    'UserData',[0 Inf 1],...
    'Position',[0 45 95 20]);
uicontrol(Xaxis,...
    'Style','Radio',...
    'String','Hyperbolic',...
    'Tag','logicle',...
    'UserData',[-Inf Inf 1],...
    'Position',[0 25 95 20]);
uicontrol(Xaxis,...
    'Style','Radio',...
    'String','Logicle',...
    'Tag','logicle',...
    'UserData',[-Inf Inf 10^-1.6],...
    'Position',[0 5 95 20]);
Xprm=uibuttongroup(...
    'Units','pixels',...
    'Position',[200 100 100 93]);
uicontrol(Xprm,...
    'Style','checkbox',...
    'Position',[3 70 80 20],...
    'String','AutoAxis',...
    'Value',1,...
    'Tag','AutoXAxis',...
    'Callback',{@XAutoCallback});
uicontrol(Xprm,...
    'Style','Text',...
    'Position',[0 42 48 20],...
    'String','Min',...
    'Value',1,...
    'Enable','off');
uicontrol(Xprm,...
    'Style','Text',...
    'Position',[0 22 48 20],...
    'String','Max',...
    'Value',1,...
    'Enable','off');
uicontrol(Xprm,...
    'Style','Text',...
    'Position',[0 2 48 20],...
    'String','Prm',...
    'Value',1,...
    'Enable','off');
Xparam(1)=uicontrol(Xprm,...
    'Style','Edit',...
    'String','Min',...
    'Position',[48 42 48 20],...
    'Enable','off',...
    'Callback',{@XparamCallback,hMainFig});
Xparam(2)=uicontrol(Xprm,...
    'Style','Edit',...
    'String','Max',...
    'Position',[48 22 48 20],...
    'Enable','off',...
    'Callback',{@XparamCallback,hMainFig});
Xparam(3)=uicontrol(Xprm,...
    'Style','Edit',...
    'String','Prm',...
    'Position',[48 2 48 20],...
    'Enable','off',...
    'Callback',{@XparamCallback,hMainFig});

Yaxis=uibuttongroup(...
    'Title','Yaxis',...
    'Units','pixels',...
    'Position',[100 0 100 100]);
uicontrol(Yaxis,...
    'Style','Radio',...
    'String','Linear',...
    'Tag','ylin',...
    'UserData',[0 Inf 1],...
    'Position',[0 65 95,20]);
uicontrol(Yaxis,...
    'Style','Radio',...
    'String','Logarithmic',...
    'Tag','ylog',...
    'UserData',[0 Inf 1],...
    'Position',[0 45 95,20]);
uicontrol(Yaxis,...
    'Style','Radio',...
    'String','Hyperbolic',...
    'Tag','ylogicle',...
    'UserData',[-Inf Inf 1],...
    'Position',[0 25 95,20]);
uicontrol(Yaxis,...
    'Style','Radio',...
    'String','Logicle',...
    'Tag','ylogicle',...
    'UserData',[-Inf Inf 10^-1.6],...
    'Position',[0 5 95,20]);
Yprm=uibuttongroup('Units','pixels','Position',[200 0 100 93],'Visible','off');
uicontrol(Yprm,'Style','checkbox','Position',[3 70 80 20],'String','AutoAxis','Tag','AutoYAxis','Value',1,'Callback',{@YAutoCallback});
uicontrol(Yprm,'Style','Text','Position',[0 42 48 20],'String','Min','Value',1,'Enable','off');
uicontrol(Yprm,'Style','Text','Position',[0 22 48 20],'String','Max','Value',1,'Enable','off');
uicontrol(Yprm,'Style','Text','Position',[0 2 48 20],'String','Prm','Value',1,'Enable','off');
Yparam(1)=uicontrol(Yprm,'Style','Edit','String','Min','Position',[48 42 48 20],'Enable','off','Callback',{@YparamCallback,hMainFig});
Yparam(2)=uicontrol(Yprm,'Style','Edit','String','Max','Position',[48 22 48 20],'Enable','off','Callback',{@YparamCallback,hMainFig});
Yparam(3)=uicontrol(Yprm,'Style','Edit','String','Prm','Position',[48 2 48 20],'Enable','off','Callback',{@YparamCallback,hMainFig});
Yprmhist=uibuttongroup('Units','pixels','Position',[200 0 100 93],'SelectionChangeFcn',{@YprmhistCallback});
uicontrol(Yprmhist,'Style','Text','Position',[0 62 90 20],'String','Normalize area to:');
uicontrol(Yprmhist,'Style','Radio','Position',[0 42 30 20],'String','1','Tag','Total','Value',1);
uicontrol(Yprmhist,'Style','Radio','Position',[30 42 30 20],'String','%','Tag','Gated');
uicontrol(Yprmhist,'Style','Radio','Position',[60 42 30 20],'String','#','Tag','Abs');
uicontrol(Yprmhist,'Style','Text','Position',[0 22 90 20],'String','Smoothing:','HorizontalAlignment','left');
uicontrol(Yprmhist,'Style','Edit','Position',[35 2 30 20],'String','1','Tag','smoothprm','Enable','on','BackgroundColor',[1 1 1],'Callback',@SmoothCallback);

%  Initialization tasks
set(GraphType,'SelectionChangeFcn',{@GraphTypeSelCh,hMainFig});
set(Xaxis,'SelectionChangeFcn',{@XaxisSelCh,hMainFig});
set(Yaxis,'SelectionChangeFcn',{@YaxisSelCh,hMainFig});
set(GraphType,'SelectedObject',getcolumn(get(GraphType,'Children')',mArgsIn.Display.graph_type_Radio));
set(Xaxis,'SelectedObject',getcolumn(get(Xaxis,'Children')',mArgsIn.Display.graph_Xaxis_Radio));
set(Yaxis,'SelectedObject',getcolumn(get(Yaxis,'Children')',mArgsIn.Display.graph_Yaxis_Radio));

Args.GraphType=GraphType;
Args.Xaxis=Xaxis;
Args.Yaxis=Yaxis;
Args.Xparam=Xparam;
Args.Yparam=Yparam;
Args.SetEnabledBtnsFcn=@SetEnabledBtns;
guidata(fh,Args);

%Initialize
SetEnabledBtns(hMainFig,fh);
%Set the Y axis parameters area
GraphTypeSelCh(GraphType,[],hMainFig)
%getXparam;
for ind=1:3
    set(Args.Xparam(ind),'String',num2str(mArgsIn.Display.graph_Xaxis_param(ind)));
    set(Args.Yparam(ind),'String',num2str(mArgsIn.Display.graph_Yaxis_param(ind)));
end


%  Render GUI visible
set(fh,'Visible','on');

%  Callbacks.
    function fhClose(hObject,eventdata,hMainFig)
        %when it is closed, only make it invisible.
        mArgsIn=guidata(hMainFig);
        mArgsIn.Handles=rmfield(mArgsIn.Handles,'graphprop');
        guidata(hMainFig,mArgsIn);
        if isempty(gcbf)
            if length(dbstack) == 1
                warning('MATLAB:closereq', ...
                    'Calling closereq from the command line is now obsolete, use close instead');
            end
            close force
        else
            delete(gcbf);
        end
    end

    function GraphTypeSelCh(hObject,eventdata,hMainFig)
        mArgsIn=guidata(hMainFig);
        mArgsIn.Display.Changed=1;
        mArgsIn.Display.graph_type=get(get(hObject,'SelectedObject'),'String');
        mArgsIn.Display.graph_type_Radio=find(get(hObject,'Children')==get(hObject,'SelectedObject'));
        guidata(hMainFig,mArgsIn);
        Args=guidata(mArgsIn.Handles.graphprop);
        if strcmp(mArgsIn.Display.graph_type,'Histogram')
            btns=get(Args.Yaxis,'Children');
            set(btns(1),'Enable','off');
            set(btns(2),'Enable','off');
            if get(Args.Yaxis,'SelectedObject')~=btns(3)
                set(Args.Yaxis,'SelectedObject',btns(4));
                YaxisSelCh(Args.Yaxis,[],hMainFig);
            end
            set(Yprmhist,'Visible','on');
            set(Yprm,'Visible','off');
        else
            btns=get(Args.Yaxis,'Children');
            set(btns(1),'Enable','on');
            set(btns(2),'Enable','on');
            set(Yprmhist,'Visible','off');
            set(Yprm,'Visible','on');
        end
        if ~strcmp(eventdata,'dontplot')
            mArgsIn.Handles.DrawFcn(mArgsIn);
            figure(gcbf);
        end
    end
    function XaxisSelCh(hObject,eventdata,hMainFig)
        mArgsIn=guidata(hMainFig);
        mArgsIn.Display.Changed=1;
        mArgsIn.Display.graph_Xaxis=get(get(hObject,'SelectedObject'),'Tag');
        if get(findobj(fh,'Tag','AutoXAxis'),'Value')==1
            mArgsIn.Display.graph_Xaxis_param=get(get(hObject,'SelectedObject'),'UserData');
        end
        mArgsIn.Display.graph_Xaxis_Radio=find(get(hObject,'Children')==get(hObject,'SelectedObject'));
        guidata(hMainFig,mArgsIn);
        mArgsIn.Handles.DrawFcn(mArgsIn);
        figure(gcbf);
    end
    function YaxisSelCh(hObject,eventdata,hMainFig)
        mArgsIn=guidata(hMainFig);
        mArgsIn.Display.Changed=1;
        mArgsIn.Display.graph_Yaxis=get(get(hObject,'SelectedObject'),'Tag');
        if get(findobj(fh,'Tag','AutoYAxis'),'Value')==1
            mArgsIn.Display.graph_Yaxis_param=get(get(hObject,'SelectedObject'),'UserData');
        end
        mArgsIn.Display.graph_Yaxis_Radio=find(get(hObject,'Children')==get(hObject,'SelectedObject'));
        guidata(hMainFig,mArgsIn);
        mArgsIn.Handles.DrawFcn(mArgsIn);
        figure(gcbf);
    end

    function XparamCallback(hObject,eventdata,hMainFig)
        mArgsIn=guidata(hMainFig);
        mArgsIn.Display.Changed=1;
        Args=guidata(mArgsIn.Handles.graphprop);
        for i=1:3
            if ~isnan(str2double(get(Args.Xparam(i),'String')))
                mArgsIn.Display.graph_Xaxis_param(i)=str2double(get(Args.Xparam(i),'String'));
            end
        end
        guidata(hMainFig,mArgsIn);
        mArgsIn.Handles.DrawFcn(mArgsIn);
        figure(gcbf);
    end
    function XAutoCallback(hObject,eventdata)
        mArgsIn=guidata(hMainFig);
        mArgsIn.Display.Changed=1;
        if get(hObject,'Value')==1
            set(get(get(hObject,'Parent'),'Children'),'Enable','off');
            set(hObject,'Enable','on');
            mArgsIn.Display.graph_Xaxis_param=get(get(Xaxis,'SelectedObject'),'UserData');
            mArgsIn.Display.XAuto=1;
        else
            set(get(get(hObject,'Parent'),'Children'),'Enable','on');
            for i=1:3
                if ~isnan(str2double(get(Args.Xparam(i),'String')))
                    mArgsIn.Display.graph_Xaxis_param(i)=str2double(get(Args.Xparam(i),'String'));
                end
            end
            mArgsIn.Display.XAuto=0;
        end
        guidata(hMainFig,mArgsIn);
        mArgsIn.Handles.DrawFcn(mArgsIn);
        figure(gcbf);
    end
    function YprmhistCallback(hObject,eventdata)
        mArgsIn=guidata(hMainFig);
        mArgsIn.Display.Changed=1;
        mArgsIn.Display.histnormalize=get(get(hObject,'SelectedObject'),'Tag');
        guidata(hMainFig,mArgsIn);
        mArgsIn.Handles.DrawFcn(mArgsIn);
        figure(gcbf);
    end
    function YparamCallback(hObject,eventdata,hMainFig)
        mArgsIn=guidata(hMainFig);
        mArgsIn.Display.Changed=1;
        Args=guidata(mArgsIn.Handles.graphprop);
        for i=1:3
            if ~isnan(str2double(get(Args.Yparam(i),'String')))
                mArgsIn.Display.graph_Yaxis_param(i)=str2double(get(Args.Yparam(i),'String'));
            end
        end
        guidata(hMainFig,mArgsIn);
        mArgsIn.Handles.DrawFcn(mArgsIn);
        figure(gcbf);
    end
    function YAutoCallback(hObject,eventdata)
        mArgsIn=guidata(hMainFig);
        mArgsIn.Display.Changed=1;
        if get(hObject,'Value')==1
            set(get(get(hObject,'Parent'),'Children'),'Enable','off');
            set(hObject,'Enable','on');
            mArgsIn.Display.graph_Yaxis_param=get(get(Yaxis,'SelectedObject'),'UserData');
            mArgsIn.Display.YAuto=1;
        else
            %            set(hObject,'Value',1);
            set(get(get(hObject,'Parent'),'Children'),'Enable','on');
            for i=1:3
                if ~isnan(str2double(get(Args.Yparam(i),'String')))
                    mArgsIn.Display.graph_Yaxis_param(i)=str2double(get(Args.Yparam(i),'String'));
                end
            end
            mArgsIn.Display.YAuto=0;
        end
        guidata(hMainFig,mArgsIn);
        mArgsIn.Handles.DrawFcn(mArgsIn);
        figure(gcbf);
    end
    function SmoothCallback(hObject,eventdata)
        mArgsIn=guidata(hMainFig);
        mArgsIn.Display.smoothprm=str2double(get(hObject,'string'));
        mArgsIn.Display.Changed=1;
        guidata(hMainFig,mArgsIn);
        mArgsIn.Handles.DrawFcn(mArgsIn);
    end
%  Utility functions for MYGUI
    function SetEnabledBtns(hMainFig,fh)
        mArgsIn=guidata(hMainFig);
        Args=guidata(fh);
        set(GraphType,'SelectedObject',getcolumn(get(GraphType,'Children')',mArgsIn.Display.graph_type_Radio));
        set(Xaxis,'SelectedObject',getcolumn(get(Xaxis,'Children')',mArgsIn.Display.graph_Xaxis_Radio));
        set(Yaxis,'SelectedObject',getcolumn(get(Yaxis,'Children')',mArgsIn.Display.graph_Yaxis_Radio));
        
        %check validity of 2d plots
        if get(mArgsIn.Handles.Color2PUM,'Value')==1
            btns=get(Args.GraphType,'Children');
            set(btns(1),'Enable','off');
            set(btns(2),'Enable','off');
            set(btns(3),'Enable','off');
            set(btns(4),'Enable','off');
            set(Args.GraphType,'SelectedObject',btns(5));
        else
            btns=get(Args.GraphType,'Children');
            set(btns(1),'Enable','on');
            set(btns(2),'Enable','on');
            set(btns(3),'Enable','on');
            set(btns(4),'Enable','on');
        end
        GraphTypeSelCh(Args.GraphType,'dontplot',hMainFig);
        
        %set the current parameters for the x axis
        if isfield(mArgsIn.Display,'XAuto')
            set(findobj(fh,'Tag','AutoXAxis'),'Value',mArgsIn.Display.XAuto);
            if mArgsIn.Display.XAuto==1
                set(get(get(findobj(fh,'Tag','AutoXAxis'),'Parent'),'Children'),'Enable','off');
                set(findobj(fh,'Tag','AutoXAxis'),'Enable','on');
            else
                set(get(get(findobj(fh,'Tag','AutoXAxis'),'Parent'),'Children'),'Enable','on');
            end
        else
            set(findobj(fh,'Tag','AutoXAxis'),'Value',1);
            set(get(get(findobj(fh,'Tag','AutoXAxis'),'Parent'),'Children'),'Enable','off');
            set(findobj(fh,'Tag','AutoXAxis'),'Enable','on');
        end
        for ind=1:3
            set(Args.Xparam(ind),'String',num2str(mArgsIn.Display.graph_Xaxis_param(ind)));
        end
        
        %set the current parameters for the y axis
        if isfield(mArgsIn.Display,'YAuto')
            set(findobj(fh,'Tag','AutoYAxis'),'Value',mArgsIn.Display.YAuto);
            if mArgsIn.Display.YAuto==1
                set(get(get(findobj(fh,'Tag','AutoYAxis'),'Parent'),'Children'),'Enable','off');
                set(findobj(fh,'Tag','AutoYAxis'),'Enable','on');
            else
                set(get(get(findobj(fh,'Tag','AutoYAxis'),'Parent'),'Children'),'Enable','on');
            end
        else
            set(findobj(fh,'Tag','AutoYAxis'),'Value',1);
            set(get(get(findobj(fh,'Tag','AutoYAxis'),'Parent'),'Children'),'Enable','off');
            set(findobj(fh,'Tag','AutoYAxis'),'Enable','on');
        end
        if strcmp(get(get(GraphType,'SelectedObject'),'String'),'Histogram')
            set(Yprm,'Visible','off');
            set(Yprmhist,'Visible','on');
            if isfield(mArgsIn.Display,'histnormalize')
                set(Yprmhist,'SelectedObject',findobj(Yprmhist,'Tag',mArgsIn.Display.histnormalize));
            else
                set(Yprmhist,'SelectedObject',findobj(Yprmhist,'Tag','Total'));
            end
            if isfield(mArgsIn.Display,'smoothprm')
                set(findobj(Yprmhist,'Tag','smoothprm'),'string',mArgsIn.Display.smoothprm);
            else
                set(findobj(Yprmhist,'Tag','smoothprm'),'string',-1);
            end
            
        else
            for ind=1:3
                set(Args.Yparam(ind),'String',num2str(mArgsIn.Display.graph_Yaxis_param(ind)));
            end
            set(Yprm,'Visible','on');
            set(Yprmhist,'Visible','off');
        end
        
    end

end
function EasyFlow_statwin(varargin)
% EasyFlow_FIGPROP Figure properties for the EasyFlow
%

%  Initialization tasks

%  Initialize input/output parameters
hMainFig=varargin{1};
mArgsIn=guidata(hMainFig);
%if there is already an instance running just make it visible and raise it.
if isfield(mArgsIn.Handles,'statwin')
    set(mArgsIn.Handles.statwin,'Visible','on');
    figure(mArgsIn.Handles.statwin);
    CalcStat(mArgsIn.Handles.statwin,mArgsIn);
    return;
end


% Initialize data structures

%  Construct the figure
scrsz=get(0,'ScreenSize');
guisize=600;
fh=figure('Position',[(scrsz(3)-guisize)/2,(scrsz(4)-guisize/3)/2,guisize,guisize/3],...
    'MenuBar','none',...
    'Name','FACS GUI Statistics',...
    'NumberTitle','off',...
    'Visible','off',...
    'ResizeFcn',{@fhResizeFcn},...
    'CloseRequestFcn',{@fhClose,hMainFig},...
    'KeyPressFcn',{@fhKeyPressFcn});
mArgsIn.Handles.statwin=fh;
guidata(hMainFig,mArgsIn);
%  Construct the components
Args.Handles.table=uitable(fh,...
    'ColumnEditable',false);


%Context menu
StatCM = uicontextmenu('Parent',fh);
uimenu(StatCM,...
    'Label','Save To Workspace',...
    'Callback',{@StatSaveWS,fh});
uimenu(StatCM,...
    'Label','Save To Excel',...
    'Callback',{@StatSaveXL,fh});
uimenu(StatCM,...
    'Label','Copy',...
    'Callback',{@StatCopy,fh});
%set(Args.Handles.StatList,'UIContextMenu',StatCM);
set(Args.Handles.table,'UIContextMenu',StatCM);

%  Initialization tasks
Args.fCalcStat=@(mArgsIn) CalcStat(fh,mArgsIn);
guidata(fh,Args);
CalcStat(fh,mArgsIn);
set(fh,'Position',[scrsz(3) scrsz(4) 1 1]);
set(fh,'vis','on');
table_ext=get(Args.Handles.table,'Extent');
set(fh,'vis','off');
set(Args.Handles.table,'Position',table_ext);
fhpos=[0 0 15 15]+table_ext;
fhpos(3)=min(scrsz(3)*0.9,max(100,fhpos(3)));
fhpos(4)=min(scrsz(4)*0.9,max(100,fhpos(4)));
set(fh,'Position',fhpos);
movegui(fh,'center')

%  Render GUI visible
set(fh,'Visible','on');


%  Callbacks.
    function fhClose(hObject,eventdata,hMainFig)
        % % % %         %when it is closed, only make it invisible.
        mArgsIn=guidata(hMainFig);
        mArgsIn.Handles=rmfield(mArgsIn.Handles,'statwin');
        guidata(hMainFig,mArgsIn);
        if isempty(gcbf)
            if length(dbstack) == 1
                warning('MATLAB:closereq', ...
                    'Calling closereq from the command line is now obsolete, use close instead');
            end
            close force
        else
            delete(gcbf);
        end
        % % % %         set(hObject,'Visible','off');
    end
    function fhResizeFcn(hObject,eventdata)
        Args=guidata(hObject);
        scrsz=get(0,'ScreenSize');
        guipos=get(hObject,'Position');
        guisizex=guipos(3);
        guisizey=guipos(4);
        set(Args.Handles.table,'Position',[0 0 guisizex guisizey]);
    end
    function fhKeyPressFcn(hObject,eventdata)
        if strcmp(eventdata.Modifier,'control')
            if eventdata.Key=='c'
                StatCopy(hObject,eventdata,fh);
            end
        end
    end
    function StatSaveWS(hObject,eventdata,fh)
        Args=guidata(fh);
        stattext=[ {''} get(Args.Handles.table,'ColumnName')';...
            get(Args.Handles.table,'RowName') get(Args.Handles.table,'Data')];
        export2wsdlg({'Save Statistics as:'},{'Stat'},{stattext});
    end
    function StatSaveXL(hObject,eventdata,fh)
        Args=guidata(fh);
        [FileName,PathName] = uiputfile('*.xls');
        if FileName
            if exist([PathName,FileName],'file')
                delete([PathName,FileName])
            end
            stattext=[ {''} get(Args.Handles.table,'ColumnName')';...
                get(Args.Handles.table,'RowName') get(Args.Handles.table,'Data')];
            status=xlswrite([PathName,FileName],stattext);
        end
    end
    function StatCopy(hObject,eventdata,fh)
        Args=guidata(fh);
        stattext=[ {''} get(Args.Handles.table,'ColumnName')';...
            get(Args.Handles.table,'RowName') get(Args.Handles.table,'Data')];
        
        textarray=cellfun(@num2str,stattext,'UniformOutput',0);
        ctab=sprintf('\t');
        spacearray=char(ones(size(textarray,1),1)*ctab);
        stat_text=[char(textarray(:,1))];
        for testnum=1:size(textarray,2)-1
            stat_text=[stat_text, spacearray, char(textarray(:,testnum+1))];
        end
        cnewline=sprintf('\n');
        cnewline=char(ones(size(textarray,1),1)*cnewline);
        stat_text=[stat_text, cnewline]';
        
        %         for cline=1:size(stattext,1)
        %             statstr=sprintf('%s%s\n',statstr,stattext(cline,:));
        %         end
        clipboard('copy',stat_text(:)');
    end

%  Utility functions for MYGUI
    function CalcStat(fh,mArgsIn)
        tests={@counttest,@meantest,@mediantest,@madtest,@stdtest,@percenttotal,@percentgate,@QuadMarker,@fitdata};
        Args=guidata(fh);
        graphs=get(mArgsIn.Handles.GraphList,'String');
        graphs_index=get(mArgsIn.Handles.GraphList,'Value');
        rownames=graphs(graphs_index);
        colnames={};
        StatDB={};
        for testnum=tests(mArgsIn.Statistics.ShowInStatView)
            testfcn=testnum{1};
            newcolname=cellstr(testfcn(mArgsIn));
            newcol=[];
            for cgraph=[1:length(graphs_index)]
                res=testfcn(mArgsIn,graphs_index(cgraph));
                if length(res)>length(newcolname);
                    newcolname{length(res)}=[];
                    if ~isempty(newcol)
                        newcol{end,length(res)}=[];
                    end
                elseif length(res)<length(newcolname);
                    res{length(newcolname)}=[];
                end
                newcol=[newcol;res];
            end
            if ~iscell(newcol)
                newcol=num2cell(newcol);
            end
            StatDB=[StatDB newcol];
            colnames=[colnames newcolname];
        end
        Args.StatDB=StatDB;
        set(Args.Handles.table,'Data',StatDB,...
            'ColumnName',colnames,...
            'RowName',rownames);
        guidata(fh,Args);
    end

%statistics functions. for one argument returns the heading for the column.
%for two arguments return a 1xn array of the statistic. results are cell
%array
    function res=counttest(mArgsIn,cgraph)
        if nargin==1
            res='Count';
        else
            res=sum(mArgsIn.GraphDB(cgraph).gatedindex);
        end
    end
    function res=meantest(mArgsIn,cgraph)
        if nargin==1
            if strcmp(mArgsIn.Display.graph_type,'Histogram')
                res='Mean';
            else
                res={'Mean','Mean'};
            end
        else
            tubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],mArgsIn.GraphDB(cgraph).Data));
            if tubeidx
                if strcmp(mArgsIn.Display.graph_type,'Histogram')
                    coloridx=[find(strcmp([mArgsIn.TubeDB(tubeidx).parname],mArgsIn.GraphDB(cgraph).Color))];
                else
                    coloridx=[find(strcmp([mArgsIn.TubeDB(tubeidx).parname],mArgsIn.GraphDB(cgraph).Color)),...
                        find(strcmp([mArgsIn.TubeDB(tubeidx).parname],mArgsIn.GraphDB(cgraph).Color2))];
                end
                res=mean(mArgsIn.TubeDB(tubeidx).compdata(mArgsIn.GraphDB(cgraph).gatedindex,coloridx));
            else
                res=[];
            end
            res=double(res);
        end
    end
    function res=mediantest(mArgsIn,cgraph)
        if nargin==1
            if strcmp(mArgsIn.Display.graph_type,'Histogram')
                res='Median';
            else
                res={'Median','Median'};
            end
        else
            tubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],mArgsIn.GraphDB(cgraph).Data));
            if tubeidx
                if strcmp(mArgsIn.Display.graph_type,'Histogram')
                    coloridx=[find(strcmp([mArgsIn.TubeDB(tubeidx).parname],mArgsIn.GraphDB(cgraph).Color))];
                else
                    coloridx=[find(strcmp([mArgsIn.TubeDB(tubeidx).parname],mArgsIn.GraphDB(cgraph).Color)),...
                        find(strcmp([mArgsIn.TubeDB(tubeidx).parname],mArgsIn.GraphDB(cgraph).Color2))];
                end
                res=median(mArgsIn.TubeDB(tubeidx).compdata(mArgsIn.GraphDB(cgraph).gatedindex,coloridx));
            else
                res=[];
            end
            res=double(res);
        end
    end
    function res=madtest(mArgsIn,cgraph)
        if nargin==1
            if strcmp(mArgsIn.Display.graph_type,'Histogram')
                res='rSD';
            else
                res={'rSD','rSD'};
            end
        else
            tubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],mArgsIn.GraphDB(cgraph).Data));
            if tubeidx
                if strcmp(mArgsIn.Display.graph_type,'Histogram')
                    coloridx=[find(strcmp([mArgsIn.TubeDB(tubeidx).parname],mArgsIn.GraphDB(cgraph).Color))];
                else
                    coloridx=[find(strcmp([mArgsIn.TubeDB(tubeidx).parname],mArgsIn.GraphDB(cgraph).Color)),...
                        find(strcmp([mArgsIn.TubeDB(tubeidx).parname],mArgsIn.GraphDB(cgraph).Color2))];
                end
                res=0.7413*iqr(mArgsIn.TubeDB(tubeidx).compdata(mArgsIn.GraphDB(cgraph).gatedindex,coloridx),1);
            else
                res=[];
            end
            res=double(res);
        end
    end
    function res=stdtest(mArgsIn,cgraph)
        if nargin==1
            if strcmp(mArgsIn.Display.graph_type,'Histogram')
                res='Std';
            else
                res={'Std','Std'};
            end
        else
            tubeidx=find(strcmp([mArgsIn.TubeDB.Tubename],mArgsIn.GraphDB(cgraph).Data));
            if tubeidx
                if strcmp(mArgsIn.Display.graph_type,'Histogram')
                    coloridx=[find(strcmp([mArgsIn.TubeDB(tubeidx).parname],mArgsIn.GraphDB(cgraph).Color))];
                else
                    coloridx=[find(strcmp([mArgsIn.TubeDB(tubeidx).parname],mArgsIn.GraphDB(cgraph).Color)),...
                        find(strcmp([mArgsIn.TubeDB(tubeidx).parname],mArgsIn.GraphDB(cgraph).Color2))];
                end
                res=std(mArgsIn.TubeDB(tubeidx).compdata(mArgsIn.GraphDB(cgraph).gatedindex,coloridx),1);
            else
                res=[];
            end
            res=double(res);
        end
    end
    function res=percenttotal(mArgsIn,cgraph)
        if nargin==1
            res='% of total';
        else
            if isfield(mArgsIn.GraphDB(cgraph).Stat,'gatepercent')
                res=100*prod(mArgsIn.GraphDB(cgraph).Stat.gatepercent);
            else
                res=100;
            end
            res=double(res);
        end
    end
    function res=percentgate(mArgsIn,cgraph)
        if nargin==1
            res='% gated';
        else
            if isfield(mArgsIn.GraphDB(cgraph).Stat,'gatepercent') && ~isempty(mArgsIn.GraphDB(cgraph).Stat.gatepercent)
                res=100*mArgsIn.GraphDB(cgraph).Stat.gatepercent(end);
            else
                res=[];
            end
            res=double(res);
        end
    end
    function res=QuadMarker(mArgsIn,cgraph)
        if nargin==1
            res={'Q1 %','Q2 %','Q3 %','Q4 %',...
                'Q1 Xmedian','Q2 Xmedian','Q3 Xmedian','Q4 Xmedian',...
                'Q1 Ymedian','Q2 Ymedian','Q3 Ymedian','Q4 Ymedian'};
        else
            if isfield(mArgsIn.GraphDB(cgraph).Stat,'quad') %&& length(mArgsIn.GraphDB(cgraph).Stat.quadp)==4
                quad=mArgsIn.GraphDB(cgraph).Stat.quad;
                posx=mArgsIn.GraphDB(cgraph).plotdata(:,1)>quad(1);
                posy=mArgsIn.GraphDB(cgraph).plotdata(:,2)>quad(2);
                quad1=sum(and(posx,posy))/length(posx)*100;
                quad2=sum(and(~posx,posy))/length(posx)*100;
                quad3=sum(and(~posx,~posy))/length(posx)*100;
                quad4=sum(and(posx,~posy))/length(posx)*100;
                res=[quad1,quad2,quad3,quad4,...
                    median(mArgsIn.GraphDB(cgraph).plotdata(and(posx,posy),1)),...
                    median(mArgsIn.GraphDB(cgraph).plotdata(and(~posx,posy),1)),...
                    median(mArgsIn.GraphDB(cgraph).plotdata(and(~posx,~posy),1)),...
                    median(mArgsIn.GraphDB(cgraph).plotdata(and(posx,~posy),1)),...
                    median(mArgsIn.GraphDB(cgraph).plotdata(and(posx,posy),2)),...
                    median(mArgsIn.GraphDB(cgraph).plotdata(and(~posx,posy),2)),...
                    median(mArgsIn.GraphDB(cgraph).plotdata(and(~posx,~posy),2)),...
                    median(mArgsIn.GraphDB(cgraph).plotdata(and(posx,~posy),2))];
                res=num2cell(double(res));
            else
                res=[];
            end
        end
    end
    function res=fitdata(mArgsIn,cgraph)
        if nargin==1
            res={'Fit Model' 'Fit Param'};
        else
            if isfield(mArgsIn.GraphDB(cgraph),'fit') && ~isempty(mArgsIn.GraphDB(cgraph).fit)
                fmodel=mArgsIn.GraphDB(cgraph).fit{1};
                res=[formula(fmodel) reshape([coeffnames(fmodel) num2cell(coeffvalues(fmodel)')]',2*numcoeffs(fmodel),1)'];
            else
                res=[];
            end
        end
    end
end

function fcsfile = fcsedit(fcsfile)

h=figure('MenuBar','none'...
    ,'Name','EasyFlow - Edit FCS File'...
    ,'NumberTitle','off'...
    );

righticn(:,:,1)=NaN.*ones(16,16);
righticn(:,:,2)=NaN.*ones(16,16);
righticn(:,:,3)=NaN.*ones(16,16);

righticn(7:10,2:10,2)=0.5;
righticn(4:13,11,2)=0.5;
righticn(5:12,12,2)=0.5;
righticn(6:11,13,2)=0.5;
righticn(7:10,14,2)=0.5;
righticn(8:9,15,2)=0.5;

righticn(:,:,1)=rem(1,~isnan(righticn(:,:,2)));
righticn(:,:,3)=rem(1,~isnan(righticn(:,:,2)));

th = uitoolbar(h);
uipushtool(th,'CData',righticn(:,end:-1:1,:),...
           'TooltipString','My push tool',...
           'HandleVisibility','off',...
           'ClickedCallback',@nextfile);
uipushtool(th,'CData',righticn,...
           'TooltipString','My push tool',...
           'HandleVisibility','off',...
           'ClickedCallback',@prevfile);



pos=get(h,'position');
pos(1:2)=[1 1];
table=uitable(h,...
    'Position',pos,...
    'ColumnEditable',logical([0,1]),...
    'ColumnName',{'Variable','Value'},...
    'ColumnWidth',{0,0},...
    'CellEditCallback',@changeparam);



index=1;
loadparam;
uiwait(h);

    function loadparam()
        set(table,'Data',[fcsfile(index).var_name,fcsfile(index).var_value])
        set(table,'ColumnWidth',{0,0})
        get(table,'Extent');
        floor((pos(3)-ans(3)-16)/2);
        set(table,'ColumnWidth',{ans,ans})
    end
    function changeparam(hObject,eventdata)
        data=get(table,'Data');
        %recalc the data starting position
        datastart=256 ...header size
            +1+length(data)*2+length([data{:}]) ...text size
            +5;%fill
        dataend=datastart+length(fcsfile(index).fcsdata)*4-1;
        
        data{strcmp(data(:,1),'$BEGINDATA'),2}=int2str(datastart);
        %enddata is padded to 19 chars
        tmp=char({'1234567890123456789';num2str(dataend)});
        data{strcmp(data(:,1),'$ENDDATA'),2}=tmp(2,:);
        fcsfile(index).Offsets(3)=datastart;
        fcsfile(index).Offsets(4)=dataend;
        %check that these changes don't change the sizes of the sections.
        if datastart~=256 ...header size
                +1+length(data)*2+length([data{:}]) ...text size
                +5 ...%fill
                || dataend~=datastart+length(fcsfile(index).fcsdata)*4-1
            changeparam(hObject,eventdata);
        end
        fcsfile(index).var_name=data(:,1);
        fcsfile(index).var_value=data(:,2);
    end
    function nextfile(hObject,eventData)
        index=mod(index,length(fcsfile))+1;
        loadparam;
    end
    function prevfile(hObject,eventData)
        index=mod(index-2,length(fcsfile))+1;
        loadparam;
    end

end
function fcsfile = fcsload(filename)
%edit and save fcs files
%
%fcsfile=fcsload(filname)
%   loads the file given and stores the data and metadata in the structure
%   fcsfile


curdir=pwd;

%check inputs
%TBD:if no input open a dialog
if nargin==0
    [filename,pathname] = uigetfile('*.fcs','MultiSelect','on');
    if isnumeric(filename)
        error('No file to load.');
    else
        cd(pathname);
    end
else
    [pathname, name, ext] = fileparts(filename);
    filename=[name ext];
    if ~isempty(pathname)
        cd(pathname);
    end
end

if ~iscell(filename)
    filename={filename};
end

%set outputs
fcsfile(1:length(filename))=struct;

for index=1:length(filename)
    curfile=filename{index};
    %open file
    if exist(curfile,'file') && ~exist(curfile,'dir')
        fid = fopen(curfile,'r','b');
    else
        error(['File ',curfile,' does not exist.'])
    end
    fseek(fid,0,'bof');
    
    %read the header
    fcsheader=fread(fid,58,'*char')';
    %check version is FCS3.0
    if ~strcmp(fcsheader(1:6),'FCS3.0')
        %error('Not an FCS3.0 file');
    end
    %get the offsets for the different sections
    %TBD: if offset is 0 it might be stated in the text section
    Offsets=str2num(reshape(fcsheader(11:end),8,6)'); %#ok<ST2NM>
    
    %read text section
    fseek(fid,Offsets(1),'bof');
    fcstext=fread(fid,Offsets(2)-Offsets(1)+1,'*char')';
    %parse text section
    if strcmp('\',fcstext(1))
        %TBR 20150605 parsedtext=textscan(fcstext(2:end),'%s','delimiter',['\' fcstext(1)],'Whitespace','','bufsize',length(fcstext));
        parsedtext=textscan(fcstext(2:end),'%s','delimiter',['\' fcstext(1)],'Whitespace','','EndOfLine','');
    else
        parsedtext=textscan(fcstext(2:end),'%s','delimiter',fcstext(1),'Whitespace','','EndOfLine','');
    end
    var_name=parsedtext{1}(1:2:end);
    var_value=parsedtext{1}(2:2:end);
    if length(var_value)<length(var_name)
        var_name(end)=[];
    end
    %read data section
    %floor is since some FACSs gives the EOF as the end of the data
    %section.
    if strcmp(var_value(strcmp(var_name,'$DATATYPE')),'I')
        switch var_value{strcmp(var_name,'$P1B')}
            case '16'
                fmt='uint16';
                psize=2;
            case '32'
                fmt='uint32';
                psize=4;
        end
    else
        fmt='single';
        psize=4;
    end
    fseek(fid,Offsets(3),'bof');
    fcsdata=[];
    if Offsets(3)==0
        Offsets(3)=str2double(var_value(strcmp(var_name,'$BEGINDATA')));
    end
    if Offsets(4)==0
        Offsets(4)=str2double(var_value(strcmp(var_name,'$ENDDATA')));
    end
    if Offsets(3)~=Offsets(4) 
        if strcmp(var_value(strcmp(var_name,'$BYTEORD')),'1,2,3,4')
            m = memmapfile(curfile,'Offset',Offsets(3),'Format',fmt,'Repeat',floor((Offsets(4)-Offsets(3)+1)/psize));
            fcsdata=m.data;
        else
            m = memmapfile(curfile,'Offset',Offsets(3),'Format',fmt,'Repeat',floor((Offsets(4)-Offsets(3)+1)/psize));
            fcsdata=swapbytes(m.data);
        end
    elseif Offsets(3)==0
    end

    %assume no analysis section
    fcsanalysis='00000000';
    
    %output
    fcsfile(index).fcsheader=fcsheader;
    fcsfile(index).Offsets=Offsets;
    fcsfile(index).fcstext=fcstext;
    fcsfile(index).seperator=fcstext(1);
    fcsfile(index).var_name=var_name;
    fcsfile(index).var_value=var_value;
    mtxdata=reshape(single(fcsdata),...
        str2double(fcsfile(index).var_value{strcmp(fcsfile(index).var_name,'$PAR')}),...
        str2double(fcsfile(index).var_value{strcmp(fcsfile(index).var_name,'$TOT')}))';
    fcsfile(index).fcsdata=mtxdata;
    fcsfile(index).fcsanalysis=fcsanalysis;
    fcsfile(index).filename=curfile;
    fcsfile(index).dirname=pathname;
    %close file
    fclose(fid);
    
end
cd(curdir);

end
function fcsfile = fcssetparam(fcsfile,parname,parval)
%fcsfile=fcssetparam(fcsfile,parname,parval)

for index=1:length(fcsfile)
    id=strcmp(fcsfile(index).var_name,parname);
    if sum(id)==1
        fcsfile(index).var_value{id}=parval;
    else
        fcsfile(index).var_name{end+1}=parname;
        fcsfile(index).var_value{end+1}=parval;
    end
end
end
function fcssave(fcsfile,overwrite) %#ok<INUSD>
%edit and save fcs files
%fcssave(fcsfile,overwrite)
% fcsfile - structure with the fcsfile data
% overwrite - if exist, overwrite without asking. value is ignored.

%use the structure:
% fcsfile
%   var_name
%   var_value
%   fcsdata
%   Offsets
%   dirname
%   filename

curdir=pwd;

for index=1:length(fcsfile)
    
    %filename=fcsfile(index).var_value{strcmp(fcsfile(index).var_name,'$FIL')};
    %TBD: what to do if no $FIL exist.
    filename=fcsfile(index).filename;
    if exist(fcsfile(index).dirname,'dir')
        cd(fcsfile(index).dirname)
    elseif ~isempty(fcsfile(index).dirname)
        error(['Directory ' fcsfile(index).dirname ' does not exist.'])
    end
    
    %open file
    if exist('overwrite','var') || ~exist(filename,'file')
        fid = fopen(filename,'w','b');
    else
        button = questdlg('File already exist. Overwrite?','FCS Save','No');
        if ~strcmp(button,'Yes')
            continue;
        else
            fid = fopen(filename,'w','b');
        end
    end
    fseek(fid,0,'bof');
    
    %verify offsets
    datastart=fcsfile(index).Offsets(3);
    dataend=fcsfile(index).Offsets(4);
    %recalc the data start and end position and the test end position
    while datastart~=256 ...header size
            +1+length(fcsfile(index).var_value)*2+length([fcsfile(index).var_value{:}])+length([fcsfile(index).var_name{:}]) ...text size
            +5 ...%fill
            || dataend~=datastart+length(fcsfile(index).fcsdata(:))*4-1
        datastart=256 ...header size
            +1+length(fcsfile(index).var_value)*2+length([fcsfile(index).var_value{:}])+length([fcsfile(index).var_name{:}]) ...text size
            +5;%fill
        dataend=datastart+length(fcsfile(index).fcsdata(:))*4-1;
        fcsfile(index).var_value{strcmp(fcsfile(index).var_name,'$BEGINDATA')}=int2str(datastart);
        %enddata is padded to 19 chars
        tmp=char({'1234567890123456789';num2str(dataend)});
        fcsfile(index).var_value{strcmp(fcsfile(index).var_name,'$ENDDATA')}=tmp(2,:);
        fcsfile(index).Offsets(2)=datastart-6;
        fcsfile(index).Offsets(3)=datastart;
        fcsfile(index).Offsets(4)=dataend;
    end
    
    
    %remake the text section
    tmp=[fcsfile(index).var_name,fcsfile(index).var_value]';
    sep=cell(size(tmp(:)));
    [sep{:}]=deal(fcsfile(index).seperator);
    tmp=[tmp(:),sep]';
    fcsfile(index).fcstext=[fcsfile(index).seperator,[tmp{:}]];
    
    %remake the header section
    tmp=[char(' '.*ones(6,8-size(num2str(fcsfile(index).Offsets),2))),num2str(fcsfile(index).Offsets)]';
    fcsfile(index).fcsheader=['FCS3.0    ',tmp(:)'];
    
    %write the header
    fwrite(fid,fcsfile(index).fcsheader,'*char');
    %write text section
    fwrite(fid,' '*ones(fcsfile(index).Offsets(1)-ftell(fid),1),'*char');
    fwrite(fid,fcsfile(index).fcstext,'*char');
    %write data section
    fwrite(fid,' '*ones(fcsfile(index).Offsets(3)-ftell(fid),1),'*char');
    if strcmp(fcsfile(index).var_value(strcmp(fcsfile(index).var_name,'$BYTEORD')),'1,2,3,4')
        fwrite(fid,fcsfile(index).fcsdata','float32',0,'l');
    else
        fwrite(fid,fcsfile(index).fcsdata','float32',0,'b');
    end
    %write analysis section
    %assumes no such section
    fwrite(fid,fcsfile(index).fcsanalysis,'*char');
    
    fclose(fid);
    
end

cd(curdir);

end

function GraphDB=fcsbatch(inGraphDB,str1,str2)
%str1 is the string to be replaced
%str 2 is a char array
%

len=length(inGraphDB);
%create GraphDB using temporary first entry
GraphDB=inGraphDB(1);

for str=str2;
    for i=1:len
        GraphDB(end+1)=inGraphDB(i);
        GraphDB(end).Data=regexprep(inGraphDB(i).Data,str1,char(str));
    end
end

GraphDB(1)=[];
end
function [M,AF]=fcscompensate(I)
%fcscompensate(I) returns the compensation matrix, given cell array of matrices each with a
%single color data.
%number of elements in I is the same as size(,2) of each of the elements.
%the n'th element of I is stained with the nth color, measured in the nth
%nth row of each of the elements of I.
%
%better results are when the staining as least homogeneous.
%
%minimize the standard deviation of the overflown data
%but ignore very off points (more than one std away)
%
%if R are the real values for the n colors, and O are the observed ones
%then we have
%   O=M*R+AF
% such that M is the spillover matrix and AF is the autoflouresence and
%   R=inv(M)*(O-AF)

color_num=length(I);
M=zeros(color_num);
AFmat=zeros(color_num);

for stain_color=1:color_num
    for ow_color=1:color_num
        data=I{stain_color};
        %        M(ow_color,stain_color)=fminsearch(@(x) stdstd(x,data(:,ow_color),data(:,stain_color)),0);
        M(ow_color,stain_color)=fminbnd(@(x) mad(data(:,ow_color)-x*data(:,stain_color),1),0,2);
        AFmat(ow_color,stain_color)=median(data(:,ow_color)-M(ow_color,stain_color)*data(:,stain_color));
    end
end

AF=inv(diag(color_num*ones(1,color_num))-M)*sum(AFmat,2);



    function s=stdstd(m,ow,stain)
        A=ow-m*stain;
        s=std(A(abs(A-mean(A))<std(A)));
        i=1;stat=struct;
        for tube=fieldnames(mArgsIn.data)'
            f=fit([1:length(mArgsIn.data.(char(tube)))]',mArgsIn.data.(char(tube))(:,end)/100,'poly1');
            stat(i).name=char(tube);
            stat(i).cpl=1/f.p1;%cells per lambda, actually per second
            stat(i).mcpl=length(mArgsIn.data.(char(tube)))/mArgsIn.data.(char(tube))(end,end)*100;%mean cells per lambda
            i=i+1;
        end
    end
end
function fcscontour(xdat,ydat,ycolor,varargin)
% draw a contour for a fcs data array.
% FCSCONTOUR(xdat,ydat) draws a contour for the two data vectors
% FCSCONTOUR(data,xcolor,ycolor) draws the xcolor and ycolor from the
% data array
%
%optional arguments can also be 'dotplot','contour','contourf','colordotplot'
%than we can have xaxis and yaxis scalings as 'lin' 'log' 'logicle' for x
%and  'ylin' 'ylog' ylogicle' for y, each followed by parameters
%

%parse input parameters
if size(xdat,2)>1
    xcolor=ydat;
    ydat=xdat(:,ycolor);
    xdat=xdat(:,xcolor);
elseif nargin==3
    varargin={ycolor};
elseif nargin>3
    varargin=[{ycolor} varargin];
end
%parse varargin - the optional parameters
option='contour';
xscalefun=@linearscale;
xtickfun=@lineartick;
yscalefun=@linearscale;
ytickfun=@lineartick;
xprm=[];
yprm=[];
for inputstr=find(cellfun(@ischar,varargin))
    switch varargin{inputstr}
        case 'lin'
            xscalefun=@linearscale;
            xtickfun=@lineartick;
            if size(varargin,2)>inputstr && isnumeric(varargin{inputstr+1})
                xprm=varargin{inputstr+1};
            end
        case 'log'
            xscalefun=@logscale;
            xtickfun=@logtick;
            if size(varargin,2)>inputstr && isnumeric(varargin{inputstr+1})
                xprm=varargin{inputstr+1};
            end
        case 'logicle'
            xscalefun=@logicle;
            xtickfun=@logicletick;
            if size(varargin,2)>inputstr && isnumeric(varargin{inputstr+1})
                xprm=varargin{inputstr+1};
            end
        case 'ylin'
            yscalefun=@linearscale;
            ytickfun=@lineartick;
            if size(varargin,2)>inputstr && isnumeric(varargin{inputstr+1})
                yprm=varargin{inputstr+1};
            end
        case 'ylog'
            yscalefun=@logscale;
            ytickfun=@logtick;
            if size(varargin,2)>inputstr && isnumeric(varargin{inputstr+1})
                yprm=varargin{inputstr+1};
            end
        case 'ylogicle'
            yscalefun=@logicle;
            ytickfun=@logicletick;
            if size(varargin,2)>inputstr && isnumeric(varargin{inputstr+1})
                yprm=varargin{inputstr+1};
            end
        otherwise
            option=varargin{inputstr};
    end
end
%parse xprm and yprm
switch length(xprm)
    case 3
        xmin=xprm(1);
        xmax=xprm(2);
        xprm=xprm(3);
    case 2
        xmin=xprm(1);
        xmax=xprm(2);
        xprm=[];
    case 1
        xmin=min(xdat);
        xmax=max(xdat);
    otherwise
        xmin=min(xdat);
        xmax=max(xdat);
        xprm=[];
end
switch length(yprm)
    case 3
        ymin=yprm(1);
        ymax=yprm(2);
        yprm=yprm(3);
    case 2
        ymin=yprm(1);
        ymax=yprm(2);
        yprm=[];
    case 1
        ymin=min(ydat);
        ymax=max(ydat);
    otherwise
        ymin=min(ydat);
        ymax=max(ydat);
        yprm=[];
end
%make the minvalue and maxvalue within the range of samples
xmax=min(xmax,max(xdat));
xmin=max(xmin,min(xdat));
ymax=min(ymax,max(ydat));
ymin=max(ymin,min(ydat));

%take the data in the wanted range only and rescale it
xdat=xscalefun(xdat,xprm);
ydat=yscalefun(ydat,yprm);
inrange=xdat<xscalefun(xmax,xprm) & xdat>xscalefun(xmin,xprm) & ydat<yscalefun(ymax,yprm) & ydat>yscalefun(ymin,yprm);
xdat=xdat(inrange);
ydat=ydat(inrange);

switch option
    case {'dotplot', 'Dot Plot'}
    otherwise
        [mhist,Xm,Ym]=density([xdat,ydat]);
        mhist(isinf(mhist))=0;
        %create x,y indices
        yint=min(max(1,ceil(100*(ydat-min(ydat))/(max(ydat)-min(ydat)))),100);
        xint=min(max(1,ceil(100*(xdat-min(xdat))/(max(xdat)-min(xdat)))),100);
end

switch option
    case {'dotplot', 'Dot Plot'}
        plot(xdat,ydat,'.','MarkerSize',1);
    case {'contourf', 'Filled Contour'}
        [cntr,cntrh]=contourf(Xm,Ym,mhist,10);
        set(cntrh,'LineStyle','none');
    case {'colordotplot' 'Colored Dot Plot'}
        scatter(xdat,ydat,1,(mhist(sub2ind([100 100],yint,xint))));
    otherwise
        plot(xdat,ydat,'.','MarkerSize',1);
        hold on
        contour(Xm,Ym,mhist,10);
        hold off
end
%set labeling of the axes
xtickfun(xmin,xmax,xprm,'X');
ytickfun(ymin,ymax,yprm,'Y');


%these function are the scaling functions.
%INPUT:
%  x a vector or scalar to be transformed
%  prm parameters for the transformation
    function y=linearscale(x,prm)
        y=x;
    end
    function y=logscale(x,prm)
        %  if only a number, returns zero for values less than 1
        %  for an array, returns the log for the positive ones, and -Inf for the
        %  negative ones, thus any number below one is negative and will be
        %  dropped.
        if isscalar(x)
            y=0;
            y(x>1)=log10(x);
        else
            y=log10(x);
            y(x<0)=-Inf;
        end
    end
    function y=logicle(x,prm)
        if ~isscalar(prm)
            prm=1;
        end
        %divide by log10(exp(1)) to get asymptotically to log10
        %divide the argument by 2 to get to log10(x)
        %
        %a is a coefficient that stretches the zero
        %
        %to get from this value back to the original data do:
        % x= 2*sinh(log(10)*y)/prm
        y=asinh(prm*x/2)/log(10);
    end

%these functions set the ticks and labeling for the graphs
%INPUT:
%  minvalue, maxvalue
%  prm parameters for the transformation
%note: for now just ignores the parameters and labels until 1e7.
    function lineartick(minvalue,maxvalue,prm,dim)
        axis auto
    end
    function logtick(minvalue,maxvalue,prm,dim)
        %only strat at 1
        ticksnum=floor(logscale(minvalue,prm)):ceil(logscale(maxvalue,prm));
        nticks=range(ticksnum)+1;
        ticksl=cell(9,nticks);
        ticksl(1,:)=arrayfun(@(x) sprintf('10^{%d}',x),ticksnum,'unif',0);
        ticks=bsxfun(@times,(1:9)',10.^ticksnum);
        set(gca,[dim 'Tick'],logscale(ticks(:),prm))
        set(gca,[dim 'TickLabel'],ticksl)
    end
    function logicletick(minvalue,maxvalue,prm,dim)
        if maxvalue>0
            ticksnumpos=floor(log10(2.2/prm)):ceil(log10(maxvalue));
            ntickspos=range(ticksnumpos)+1;
            tickslpos=cell(9,ntickspos);
            tickslpos(1,:)=arrayfun(@(x) sprintf('10^{%d}',x),ticksnumpos,'unif',0);
            tickspos=bsxfun(@times,(1:9)',10.^ticksnumpos);
        else
            tickspos=[];
            tickslpos=[];
        end
        if minvalue<0
            ticksnumneg=floor(log10(2.2/prm)):ceil(log10(-minvalue));
            nticksneg=range(ticksnumneg)+1;
            tickslneg=cell(9,nticksneg);
            tickslneg(1,:)=arrayfun(@(x) sprintf('10^{%d}',x),ticksnumneg,'unif',0);
            ticksneg=bsxfun(@times,(1:9)',10.^ticksnumneg);
        else
            ticksneg=[];
            tickslneg=[];
        end

        ticks=[-reshape(ticksneg(end:-1:1), 1, []) 0 tickspos(:)'];
        set(gca,[dim 'Tick'],logicle(ticks,prm))
        set(gca,[dim 'TickLabel'],[reshape(tickslneg(end:-1:1),[],1);{0};tickslpos(:)])
    end

end
function simdata=fcsdeconv(indata,iniso)
%OUT=fcsdeconv(DATA,CTRL)
%trys to remove the distribution defined by the data in CTRL from the
%distribution defined by the data in DATA.
%OUT is a sorted events with the resulting distribution
%

%find the quantization step of the data
levels=sort(diff(unique(indata)));
step=median(levels./round(levels/min(levels)));
minvalue=min(min([indata(:);iniso(:)]));
maxvalue=max(max([indata(:);iniso(:)]));
% %change step to get about 50000 bins
step=max(step,floor((maxvalue-minvalue)/step/50000)*step);
bins=-maxvalue:step:maxvalue;

%make the data histogram
h=hist(indata,bins);
h=h./sum(h);
%smooth it as if it would reach 700 events.
%h=smooth(h,round(700/max(h)/length(indata)+1));


%make the isotype histogram
hi=hist(iniso,bins);
hi=hi./sum(hi);
%remove the data that accumulates at the ends of the isotype histogram
hi(end)=0;hi(1)=0;
%smooth it as if it would reach 700 events.
%hi=smooth(hi,round(700/max(hi)/length(iniso)+1));

%do deconv with it
hdec=deconvlucy(h,hi);

%convert regular hist to loghist
simlength=10000;
simdata=zeros(1,sum(round(simlength*hdec)));
position=0;
for i=bins(hdec~=0)
    curlength=round(simlength*(hdec(bins==i)));
    simdata(position+1:position+curlength)=i*ones(1,curlength);
    position=position+curlength;
end
end
function [hout,binsout]=fcshist(varargin)
%plot a histogram.
%
%fcshist(vec1,vec2,vec3,...,vecn)
%   plots all vectors
%fcshist(array,c1,c2,c3,...,cn)
%   plots columns c from array
%
%last param can be 'log','lin','logicle',
%the next one can be parameters, which are [minvalue, maxvalue, param];
%and the next is the y scaling 'ylin' or 'ylog'
%
%also can have 'smooth',smooth_prm. where smooth_prm is the approximate
%mean amount of equivalent counts in a bin. default 700. for no smooth,
%smooth_prm=0;
%
%and 'norm',normprm. normprm is the fraction of the input from a larger
%dataset, such that the sum over the histogram will be proportional to.
%

%parse input variables
smooth_prm=700;
normprm=1;
scalefun=@linearscale;
tickfun=@lineartick;
param=[];
yscale='lin';
for inputstr=find(cellfun(@ischar,varargin))
    switch varargin{inputstr}
        case 'smooth'
            if size(varargin,2)>inputstr && ~ischar(varargin{inputstr+1}) && varargin{inputstr+1}>=0
                smooth_prm=varargin{inputstr+1};
            end
        case 'norm'
            if size(varargin,2)>inputstr && ~ischar(varargin{inputstr+1})
                normprm=varargin{inputstr+1};
            end
        case 'log'
            scalefun=@logscale;
            tickfun=@logtick;
            if size(varargin,2)>inputstr && ~ischar(varargin{inputstr+1})
                param=varargin{inputstr+1};
            end
        case 'lin'
            scalefun=@linearscale;
            tickfun=@lineartick;
            if size(varargin,2)>inputstr && ~ischar(varargin{inputstr+1})
                param=varargin{inputstr+1};
            end
        case 'logicle'
            scalefun=@logicle;
            tickfun=@logicletick;
            if size(varargin,2)>inputstr && ~ischar(varargin{inputstr+1})
                param=varargin{inputstr+1};
            end
        case 'ylin'
            yscale='lin';
        case 'ylog'
            yscale='log';
    end
end
%remove the strings from the end of varargin
if find(cellfun(@ischar,varargin))
    varargin={varargin{1:find(cellfun(@ischar,varargin),1)-1}};
end
%if the input is an array change the input to vectors
if min(size(varargin{1}))~=1
    varargin=num2cell(varargin{1}(:,[varargin{2:end}]),1);
end

switch length(param)
    case 3
        minvalue=param(1);
        maxvalue=param(2);
        param=param(3);
    case 2
        minvalue=param(1);
        maxvalue=param(2);
        param=[];
    case 1
        minvalue=min(cellfun(@min,varargin));
        maxvalue=max(cellfun(@max,varargin));
    otherwise
        minvalue=min(cellfun(@min,varargin));
        maxvalue=max(cellfun(@max,varargin));
        param=[];
end
%make the minvalue and maxvalue within the range of samples
maxvalue=min(maxvalue,max(cellfun(@max,varargin)));
minvalue=max(minvalue,min(cellfun(@min,varargin)));

bins=linspace(scalefun(minvalue,param),scalefun(maxvalue,param),1024);
h=zeros(length(bins),size(varargin,2));


for i=1:(size(varargin,2))
    in=varargin{i};
    htmp=hist(scalefun(in(in<maxvalue & in>minvalue),param),bins);
    %note: one doesnt see the fact that only part of the data is shownexcept
    %in the normalization.
    %smooth it as if it would reach 700 events. but keep it normalized such
    %that the sum divided by number of bins is 1.
    norm=sum(htmp)/length(in);
    htmp=smooth(htmp,round(smooth_prm/mean(htmp(htmp~=0))+1));
    %    h(:,i)=htmp./sum(htmp)*norm*length(bins);
    h(:,i)=htmp./sum(htmp)*norm*normprm/mean(diff(bins));
end

if nargout==0
    plot(bins,h);
    set(gca,'YScale',yscale);
    tickfun(minvalue,maxvalue,param,'X');
else
    hout=h;
    binsout=bins;
end



%these function are the scaling functions.
%INPUT:
%  x a vector or scalar to be transformed
%  prm parameters for the transformation

    function y=linearscale(x,prm)
        y=x;
    end

    function y=logscale(x,prm)
        %  if only a number, returns zero for values less than 1
        %  for an array, returns only positive elements
        if isscalar(x)
            y=0;
            y(x>1)=log10(x);
        else
            y=log10(x(x>0));
        end
    end

    function y=logicle(x,prm)
        if ~isscalar(prm)
            prm=1;
        end
        %divide by log10(exp(1)) to get asymptotically to log10
        %divide the argument by 2 to get to log10(x)
        %
        %a is a coefficient that stretches the zero
        %
        %to get from this value back to the original data do:
        % x= 2*sinh(log(10)*y)/prm
        y=asinh(prm*x/2)/log(10);
    end

%these functions set the ticks and labeling for the graphs
%INPUT:
%  minvalue, maxvalue
%  prm parameters for the transformation
%note: for now just ignores the parameters and labels until 1e7.
    function lineartick(minvalue,maxvalue,prm,dim)
        axis auto
    end
    function logtick(minvalue,maxvalue,prm,dim)
        %only strat at 1
        ticksnum=floor(logscale(minvalue,prm)):ceil(logscale(maxvalue,prm));
        nticks=range(ticksnum)+1;
        ticksl=cell(9,nticks);
        ticksl(1,:)=arrayfun(@(x) sprintf('10^{%d}',x),ticksnum,'unif',0);
        ticks=bsxfun(@times,(1:9)',10.^ticksnum);
        set(gca,[dim 'Tick'],logscale(ticks,prm))
        set(gca,[dim 'TickLabel'],ticksl)
    end
    function logicletick(minvalue,maxvalue,prm,dim)
        if maxvalue>0
            ticksnumpos=floor(log10(2.2*5/prm)):ceil(log10(maxvalue));
            ntickspos=range(ticksnumpos)+1;
            tickslpos=cell(9,ntickspos);
            tickslpos(1,:)=arrayfun(@(x) sprintf('10^{%d}',x),ticksnumpos,'unif',0);
            tickspos=bsxfun(@times,(1:9)',10.^ticksnumpos);
        else
            tickspos=[];
            tickslpos=[];
        end
        if minvalue<0
            ticksnumneg=floor(log10(2.2*5/prm)):ceil(log10(-minvalue));
            nticksneg=range(ticksnumneg)+1;
            tickslneg=cell(9,nticksneg);
            tickslneg(1,:)=arrayfun(@(x) sprintf('-10^{%d}',x),ticksnumneg,'unif',0);
            ticksneg=bsxfun(@times,(1:9)',10.^ticksnumneg);
        else
            ticksneg=[];
            tickslneg=[];
        end

        ticks=[-reshape(ticksneg(end:-1:1),1,[]), 0, tickspos(:)'];
        set(gca,[dim 'Tick'],logicle(ticks,prm))
        set(gca,[dim 'TickLabel'],[reshape(tickslneg(end:-1:1),[],1);{0};tickslpos(:)])
    end

end
function r=fcsrescale(v1,v2)
%use ansaribradley to rescale the distributions of v2 to fit that of v1
r=fminsearch(@(x) -abtest((v1-median(v1)),x*(v2-median(v2))),std(v1)/std(v2));

    function p=abtest(v1,v2)
        [h,p]=ansaribradley(v1,v2);
    end
end
function y=fcsscaleconvert(x,varargin)
%convert numbers between display scales.
%
%fcshist(vec,scale1,scale1prm,scale2,scale2prm)
%   convert the numbers in vec from scale1 to scale to with the given
%   scale parameters.
%
%scale can be 'log','lin','logicle',
%scaleprm is the parameter of the scale. relevant only for the logicle.

scale1fun=@arclinearscale;
param1=1;
scale2fun=@linearscale;
param2=1;

strpos=find(cellfun(@ischar,varargin));
if length(strpos)~=2
    error('Wrong numbers of arguments');
end

switch varargin{strpos(1)}
    case 'log'
        scale1fun=@arclogscale;
    case 'lin'
        scale1fun=@arclinearscale;
    case 'logicle'
        scale1fun=@arclogicle;
        if size(varargin,2)>strpos(1) && ~ischar(varargin{strpos(1)+1})
            param1=varargin{strpos(1)+1};
        else
            param1=1;
        end
end
switch varargin{strpos(2)}
    case 'log'
        scale2fun=@logscale;
    case 'lin'
        scale2fun=@linearscale;
    case 'logicle'
        scale2fun=@logicle;
        if size(varargin,2)>strpos(2) && ~ischar(varargin{strpos(2)+1})
            param2=varargin{strpos(2)+1};
        else
            param2=1;
        end
end

y=scale2fun(scale1fun(x,param1),param2);



%these function are the scaling functions.
%INPUT:
%  x a vector or scalar to be transformed (in a linear scale)
%  prm parameters for the transformation
%  y the scaled vector
    function y=linearscale(x,prm)
        y=x;
    end
    function y=logscale(x,prm)
        %  returns -Inf for values less than 0
        %
        y=log10(x);
        y(x<0)=-Inf;
    end
    function y=logicle(x,prm)
        if ~isscalar(prm)
            prm=1;
        end
        %divide by log10(exp(1)) to get asymptotically to log10
        %divide the argument by 2 to get to log10(x)
        %
        %a is a coefficient that stretches the zero
        %
        %to get from this value back to the original linear data do:
        % x= 2*sinh(log(10)*y)/prm
        y=asinh(prm*x/2)/log(10);
    end

%these function are the inverse scaling functions.
%INPUT:
%  y a vector or scalar to be transformed (scaled)
%  prm parameters for the transformation
%  x the vector in a linear scale
    function x=arclinearscale(y,prm)
        x=y;
    end
    function x=arclogscale(y,prm)
        %  if only a number, returns zero for values less than 1
        %  for an array, returns only positive elements
        x=10.^y;
    end
    function x=arclogicle(y,prm)
        if ~isscalar(prm)
            prm=1;
        end
        %divide by log10(exp(1)) to get asymptotically to log10
        %divide the argument by 2 to get to log10(x)
        %
        %a is a coefficient that stretches the zero
        %
        %to get from this value back to the original data do:
        x = 2*sinh(log(10)*y)/prm;
        % y=asinh(prm*x/2)/log(10);
    end
end
function normalEvents=fcsartifact(x)
% look in the vector x of data points for areas that behave statistically
% different (mean and std)
% returns a vector of logicals 1 - good sample, 0 - bad sample

% calculate running average(m) and running std(d)
windowsize=500;
m=filter(ones(1,windowsize)/windowsize,1,x);
m2=filter(ones(1,windowsize)/windowsize,1,x.^2);
s=sqrt(m2-m.^2);
% find for each point how many std from the mean
cutoff=0.7;
score=[];
score(:,1)=1/cutoff*(m-median(m))./std(m-median(m));
score(:,2)=1/cutoff*(s-median(s))./std(s-median(s));
sctot=prod(abs(score'));
normalEvents=smooth(sctot,windowsize)<1;
end
function result=popupdlg(promptstring,liststring)

figurename='EasyFlow';
%        promptstring='Enter a fit variable name:';
okstring='OK';
cancelstring='Cancel';
%        liststring={'a','b'};
initialvalue=1;
figwidth=160;
border=15;
sep=5;
th=20;%text height
bh=30;%button height

fp = get(0,'defaultfigureposition');
fp(3)=figwidth;
fp(4)=border*2+th*2+2*sep+bh;

fig_props = { ...
    'name'                   figurename ...
    'color'                  get(0,'defaultUicontrolBackgroundColor') ...
    'resize'                 'off' ...
    'numbertitle'            'off' ...
    'menubar'                'none' ...
    'windowstyle'            'modal' ...
    'visible'                'on' ...
    'createfcn'              ''    ...
    'position'               fp   ...
    'closerequestfcn'        'delete(gcbf)' ...
    };
fig=figure(fig_props{:});

prompt_text = uicontrol('style','text','string',promptstring,...
    'horizontalalignment','left',...
    'position',[border fp(4)-border-th fp(3)-2*border th]);

popupmenu = uicontrol('style','popupmenu',...
    'position',[15 fp(4)-border-th-(th+sep) fp(3)-2*border th],...
    'string',liststring,...
    'backgroundcolor','w',...
    'tag','listbox',...
    'value',initialvalue, ...
    'callback', {@doPopupmenuClick});

bw=(fp(3)-2*border-sep)/2;%button width
ok_btn = uicontrol('style','pushbutton',...
    'string',okstring,...
    'position',[border border bw bh],...
    'callback',{@doOK});

cancel_btn = uicontrol('style','pushbutton',...
    'string',cancelstring,...
    'position',[border+bw+sep border bw bh],...
    'callback',{@doCancel});

set([fig, ok_btn, cancel_btn, popupmenu], 'keypressfcn', {@doKeypress});

% make sure we are on screen
movegui(fig)
set(fig, 'visible','on'); drawnow;

uicontrol(popupmenu);
uiwait;

    function doKeypress(hobj,evnt)
        switch evnt.Key
            case 'escape'
                doCancel([],[]);
            case 'return'
                switch get(fig,'currentobj')
                    case cancel_btn
                        doCancel([],[]);
                    case {ok_btn, popupmenu}
                        doOK([],[]);
                end
        end
    end
    function doPopupmenuClick(hobj,evnt)
        
    end
    function doOK(hobj,evnt)
        result=get(popupmenu,'value');
        delete(gcbf)
    end
    function doCancel(hobj,evnt)
        result=[];
        delete(gcbf)
    end

end
function [D,xfull,yfull] = density (d,Nres)
if nargin==1
    Nres=100;
end
dsize=min(size(d,1),10000);
d=d(randperm(dsize),:);
%generate the grid points
xfull=linspace(min(d(:,1)),max(d(:,1)),Nres);
yfull=linspace(min(d(:,2)),max(d(:,2)),Nres);
[xfull,yfull]=meshgrid(xfull,yfull);

dnorm=bsxfun(@rdivide,bsxfun(@minus,d,min(d)),range(d));
x=linspace(0,1,Nres);
y=linspace(0,1,Nres);
[x,y]=meshgrid(x,y);
[lx,ly]=size(x);
gridpoints=[x(:),y(:)];

%find the nearest neighbours
Nnn=round(sqrt(length(dnorm)));
[nn100,nndist]=knnsearch(dnorm,gridpoints,'K',Nnn);
nndist=nndist(:,end);
nndist=reshape(nndist,lx,ly);
D=1./nndist;
%contour(x,y,log(nndist),-1:-0.4:-3)

end
function [compmat,colorlist]=EFCalcComp
%open unstained file. use it to get the colorlist.
[filename,pathname] = uigetfile('*.fcs','Enter Unstained File');
if isnumeric(filename)
    error('No file to load.');
else
    cd(pathname);
    unstained=fcsload(filename);
end
parname_idx= ~cellfun(@isempty,regexp(unstained.var_name,'\$P[0-9]+N'));
parname=unstained.var_value(parname_idx);
colorlist_idx=find(~cellfun(@isempty,regexp(parname,'.+A')));
colorlist=parname(colorlist_idx);

%open single color files
usedcolors=[];
singledata={};
for curcolor = 1:length(colorlist)
    [filename,pathname] = uigetfile('*.fcs',['Enter ' colorlist{curcolor} '-stained File']);
    %TBD:check the the colors in this file are the same
    if ~isnumeric(filename)
        cd(pathname);
        tmpdata=fcsload(filename);
        singledata{end+1}=tmpdata.fcsdata;
        usedcolors(end+1)=colorlist_idx(curcolor);
    end
end
%remove the extra colors
singledata=arrayfun(@(x) x{1}(:,usedcolors),singledata,'UniformOutput',0);

colorlist=parname(usedcolors);
compmat=fcscompensate(singledata);
end


function gate=gate1d(gate,data,gatecol,outcol)
%GATE1D create and edit a one dimensional gate for facs measurments.
%   GATE=GATE1D
%   GATE is [min max height] values for the gate. the user need to click on two
%   points (the min and the max). right click uses Inf.
%
%gate1d
%   create ptope for the data ploted in gca
%gate1d(gate)
%   edit the gate given with the data plotted in gca
%gate1d(gate,data)
%   filters the data according to the gate returns logical places where the
%   data passed the gate
%gate1d(gate,data,gatecol)
%   filters the data in column gatecol according to the gate returns 
%   logical places where the data passed the gate
%gate1d(gate, data, gatecol, outcol)
%   return the data in column outcol whenever the data in gatecol passes
%   the gate.

WBDF = get(gcf,'WindowButtonDownFcn');
WBUF = get(gcf,'WindowButtonUpFcn');
WBMF = get(gcf,'WindowButtonMotionFcn');
pntr = get(gcf,'Pointer');

switch nargin
    case 0
        gate=gate1d_create;
    case 1
        gate=gate1d_create(gate);
    case 2
        gate=gate1d_apply(gate,data);
    case 3
        gate=gate1d_apply(gate,data(:,gatecol));
    case 4
        gatelogical=gate1d_apply(gate,data(:,gatecol));
        gate=data(gatelogical,outcol);
end

set(gcf,'WindowButtonDownFcn', WBDF);
set(gcf,'WindowButtonUpFcn', WBUF);
set(gcf,'WindowButtonMotionFcn', WBMF);
set(gcf,'Pointer', pntr);

    function gate=gate1d_create(gate)
        lh=line('Visible','off');
        ah=gca;
        values=axis;
        nearx=0.01*(values(2)-values(1));
        neary=0.01*(values(4)-values(3));
        editid=0;
        
        switch nargin
            case 0
                xdat=[];
                ydat=[];
                set(gcf,'WindowButtonDownFcn',@btndown)
                set(gcf,'WindowButtonUpFcn','')
                set(gcf,'WindowButtonMotionFcn','')
                set(gcf,'Pointer','crosshair')
            case 1
                editid=1;
                xdat=gate(1:2);
                ydat=[gate(3),gate(3)];
                set(lh,'XData',xdat,'YData',ydat,'Marker','+','Color','r','Visible','on');
                set(gcf,'WindowButtonMotionFcn',@selectchange)
                set(gcf,'WindowButtonUpFcn','')
                set(gcf,'WindowButtonDownFcn',@exitfcn)
        end
        uiwait;
        
        gate=[min(xdat),max(xdat),ydat(1)];
        
        function btndown(src,evnt)
            p=get(ah,'CurrentPoint');
            if strcmp(get(src,'SelectionType'),'normal')
                xdat = p(1,1);
                ydat = p(1,2);
                set(lh,'XData',xdat,'YData',ydat,'Marker','+','Color','r','Visible','on');
                set(src,'WindowButtonMotionFcn',@move)
                set(gcf,'WindowButtonUpFcn',@btnup)
            end
            
        end
        function btnup(src,evnt)
            p=get(ah,'CurrentPoint');
            if strcmp(get(src,'SelectionType'),'normal')
                xdat = [xdat,p(1,1)];
                ydat = [ydat,ydat];
                set(lh,'XData',xdat,'YData',ydat,'Marker','+','Color','r');
                set(gcf,'WindowButtonMotionFcn',@selectchange)
            end
            if editid==0
                set(src,'WindowButtonDownFcn','')
                set(src,'WindowButtonMotionFcn','')
                set(src,'Pointer','Arrow')
                uiresume;
            end
            set(src,'WindowButtonUpFcn','')
        end
        function move(src,evnt)
            p=get(ah,'CurrentPoint');
            set(lh,'XData',[xdat,min(max(p(1,1),values(1)),values(2))],'YData',[ydat,ydat],'Marker','+','Color','r');
        end
        function clickchange(src,evnt)
            p=get(ah,'CurrentPoint');
            if strcmp(get(src,'SelectionType'),'normal')
                if abs(p(1,1)-xdat(1)) < abs(p(1,1)-xdat(2))
                    xdat=xdat(2);
                else
                    xdat=xdat(1);
                end
                ydat = ydat(1);
                set(lh,'XData',[xdat,min(max(p(1,1),values(1)),values(2))],'YData',[ydat,ydat],'Marker','+','Color','r');
                set(src,'WindowButtonMotionFcn',@move)
                set(gcf,'WindowButtonUpFcn',@btnup)
            end
            
        end
        function selectchange(src,evnt)
            p=get(ah,'CurrentPoint');
            if abs(p(1,1)-xdat(1)) < abs(p(1,1)-xdat(2)) && abs(p(1,1)-xdat(1)) < nearx && abs(p(1,2)-ydat(1)) < neary
                set(gcf,'WindowButtonDownFcn',@clickchange)
                set(gcf,'Pointer','left')
            elseif abs(p(1,1)-xdat(1)) > abs(p(1,1)-xdat(2)) && abs(p(1,1)-xdat(2)) < nearx && abs(p(1,2)-ydat(2)) < neary
                set(gcf,'WindowButtonDownFcn',@clickchange)
                set(gcf,'Pointer','right')
            else
                set(gcf,'WindowButtonDownFcn',@exitfcn)
                set(gcf,'Pointer','Arrow')
            end
            
        end
        function exitfcn(src,evnt)
            if strcmp(get(src,'SelectionType'),'alt')
                set(src,'WindowButtonDownFcn','')
                set(src,'WindowButtonUpFcn','')
                set(src,'WindowButtonMotionFcn','')
                uiresume;
            end
        end
    end
    function gatelogical=gate1d_apply(gate,data)
        
        gatelogical=and(data>gate(1),data<gate(2));
        
    end
end
function gate=gate2d(gate,data,datay,gatecoly,outcol)
%GATE2D create a two dimensional gate for facs measurments.
%   GATE=GATE2D
%   Uses the current plot to define a two dimensional gate.
%   GATE is the points surounding the convex area that should be gated.
%   GATE=GATE2D(ptope) edit the gate defined by ptope
%
%gate2d
%   create ptope for the data ploted in gca
%gate2d(gate)
%   edit the gate given with the data plotted in gca
%gate2d(gate,datax,datay)
%   filters the data according to the gate. returns logical places where
%   the data passed the gate
%gate2d(gate,data,gatecolx,gatecoly)
%   filters the data in the columns specified according to the gate.
%   returns logical places where the data passed the gate
%gate2d(gate, data, gatecolx, gatecoly, outcol)
%   returns the data in column outcol whenever the data in gatecolx,
%   gatecoly passes the gate.

WBDF = get(gcf,'WindowButtonDownFcn');
WBUF = get(gcf,'WindowButtonUpFcn');
WBMF = get(gcf,'WindowButtonMotionFcn');
pntr = get(gcf,'Pointer');       

switch nargin
    case 0
        gate=gate2d_create;
    case 1
        gate=gate2d_create(gate);
    case 3
        gate=gate2d_apply(gate,data,datay);
    case 4
        gate=gate2d_apply(gate,data(:,datay),data(:,gatecoly));
    case 5
        gatelogical=gate2d_apply(gate,data(:,datay),data(:,gatecoly));
        gate=data(gatelogical,outcol);
end

set(gcf,'WindowButtonDownFcn', WBDF);
set(gcf,'WindowButtonUpFcn', WBUF);
set(gcf,'WindowButtonMotionFcn', WBMF);
set(gcf,'Pointer', pntr);


    function gate=gate2d_create(gate)
        lh=line('Visible','off');
        ah=gca;
        values=axis;
        nearx=0.01*(values(2)-values(1));
        neary=0.01*(values(4)-values(3));
        
        switch nargin
            case 0
                gate=[];
                set(gcf,'WindowButtonDownFcn',@btndown)
                set(gcf,'Pointer','crosshair')
            case 1
                set(lh,'XData',[gate(1,:),gate(1,1)],'YData',[gate(2,:),gate(2,1)],'Marker','.','Color','r','Visible','on');
                set(gcf,'WindowButtonMotionFcn',@selectchange)
        end
        uiwait;
        %functions for creating new gate
        function btndown(src,evnt)
            p=get(ah,'CurrentPoint');
            if strcmp(get(src,'SelectionType'),'normal')
                gate(1,end+1) = p(1,1);
                gate(2,end) = p(1,2);
                %2010dec gate=makehull(gate);
                set(lh,'XData',gate(1,:),'YData',gate(2,:),'Marker','.','Color','r','Visible','on');
                set(src,'WindowButtonMotionFcn',@move)
            elseif strcmp(get(src,'SelectionType'),'alt')
                set(lh,'XData',[gate(1,:),gate(1,1)],'YData',[gate(2,:),gate(2,1)],'Marker','.','Color','r');
                set(src,'WindowButtonDownFcn','')
                set(src,'WindowButtonMotionFcn','')
                set(src,'Pointer','Arrow')
                uiresume;
            end
            
        end
        function move(src,evnt)
            p=get(ah,'CurrentPoint');
            newp(1,1)=min(max(p(1,1),values(1)),values(2));
            newp(2,1)=min(max(p(1,2),values(3)),values(4));
            newgate=[gate newp];
            set(lh,'XData',newgate(1,:),'YData',newgate(2,:),'Marker','.','Color','r');
        end
        %functions for editing gate
        function selectchange(src,evnt)
            p=get(ah,'CurrentPoint');
            xdist=(gate(1,:)-p(1,1))/nearx;
            ydist=(gate(2,:)-p(1,2))/neary;
            dist=xdist.^2+ydist.^2;
            if min(dist)<10
                pindex=find(dist==min(dist),1);
                %move the selected point to the end
                gate=circshift(gate, -pindex, 2);

                set(lh,'XData',[gate(1,:),gate(1,1)],'YData',[gate(2,:),gate(2,1)],'Marker','.','Color','r');
                set(gcf,'Pointer','fleur')
                set(gcf,'WindowButtonDownFcn',@btndownedit);
            else
                p=get(ah,'CurrentPoint');
                newp(1,1)=min(max(p(1,1),values(1)),values(2));
                newp(2,1)=min(max(p(1,2),values(3)),values(4));
                newgate=[gate newp];
                set(lh,'XData',newgate(1,:),'YData',newgate(2,:),'Marker','.','Color','r');
                set(lh,'XData',[newgate(1,:),newgate(1,1)],'YData',[newgate(2,:),newgate(2,1)],'Marker','.','Color','r');
                set(gcf,'Pointer','arrow')
                set(gcf,'WindowButtonDownFcn',@btndownadd);
                set(gcf,'WindowButtonUpFcn','');
            end
        end
        function btndownedit(src,evnt)
            if strcmp(get(src,'SelectionType'),'alt')
                set(lh,'XData',[gate(1,:),gate(1,1)],'YData',[gate(2,:),gate(2,1)],'Marker','.','Color','r');
                set(src,'WindowButtonDownFcn','')
                set(src,'WindowButtonUpFcn','')
                set(src,'WindowButtonMotionFcn','')
                set(src,'Pointer','Arrow')
                uiresume;
            else
                p=get(ah,'CurrentPoint');
                xdist=(gate(1,:)-p(1,1))/nearx;
                ydist=(gate(2,:)-p(1,2))/neary;
                dist=xdist.^2+ydist.^2;
                pindex=find(dist==min(dist),1);
                %move the selected point to the end and remove
                gate=circshift(gate, -pindex, 2);
                gate(:,end)=[];
                set(gcf,'WindowButtonMotionFcn',@movepoint);
                set(gcf,'WindowButtonUpFcn',@btnupedit);
                set(gcf,'WindowButtonDownFcn','');
            end
        end
        function btndownadd(src,evnt)
            if strcmp(get(src,'SelectionType'),'alt')
                set(lh,'XData',[gate(1,:),gate(1,1)],'YData',[gate(2,:),gate(2,1)],'Marker','.','Color','r');
                set(src,'WindowButtonDownFcn','')
                set(src,'WindowButtonUpFcn','')
                set(src,'WindowButtonMotionFcn','')
                set(src,'Pointer','Arrow')
                uiresume;
            else
                set(gcf,'WindowButtonMotionFcn',@movepoint);
                set(gcf,'WindowButtonUpFcn',@btnupedit);
                set(gcf,'WindowButtonDownFcn','');
            end
        end
        function movepoint(src,evnt)
            p=get(ah,'CurrentPoint');
            newp(1,1)=min(max(p(1,1),values(1)),values(2));
            newp(2,1)=min(max(p(1,2),values(3)),values(4));
            %2010dec newgate=makehull([gate newp]);
            newgate=[gate newp];
            set(lh,'XData',[newgate(1,:),newgate(1,1)],'YData',[newgate(2,:),newgate(2,1)],'Marker','.','Color','r');
        end
        function btnupedit(src,evnt)
            p=get(ah,'CurrentPoint');
            newp(1,1)=min(max(p(1,1),values(1)),values(2));
            newp(2,1)=min(max(p(1,2),values(3)),values(4));
            %2010dec gate=makehull([gate newp]);
            gate=[gate newp];
            set(lh,'XData',[gate(1,:),gate(1,1)],'YData',[gate(2,:),gate(2,1)],'Marker','.','Color','r');
            set(gcf,'WindowButtonMotionFcn',@selectchange);
            set(gcf,'WindowButtonDownFcn',@btndownedit);
            set(gcf,'WindowButtonUpFcn','');
        end
        
    end
    function gate=gate2d_apply(gate,datax,datay)
        gate=inpolygon(datax,datay,gate(1,:),gate(2,:));
    end
end
function gate=gate2d_cntr(gate,data,datay,gatecoly,outcol)
%GATE2D create a two dimensional gate for facs measurments using the contours.
%   GATE=GATE2D_cntr
%   Uses the current plot to define a two dimensional gate based on a
%   density contour plot.
%   You can click to select a contour line or use arrows to move it
%   up/down. Hold the shift key to finely adjust. To choose right click
%   within the contour.
%
%gate2d
%   create ptope for the data ploted in gca
%gate2d(gate)
%   edit the gate given with the data plotted in gca

WBDF = get(gcf,'WindowButtonDownFcn');
WBUF = get(gcf,'WindowButtonUpFcn');
WBMF = get(gcf,'WindowButtonMotionFcn');
pntr = get(gcf,'Pointer');

switch nargin
    case 0
        gate=gate2d_create;
    case 1
        gate=gate2d_create(gate);
end

set(gcf,'WindowButtonDownFcn', WBDF);
set(gcf,'WindowButtonUpFcn', WBUF);
set(gcf,'WindowButtonMotionFcn', WBMF);
set(gcf,'Pointer', pntr);

    function gate=gate2d_create(gate)
        %first get all data oints from current axis
        xpt=get(findobj(gca,'Type','line'),'XData');
        ypt=get(findobj(gca,'Type','line'),'YData');
        if iscell(xpt)
            xpt=[xpt{:}];
        end
        if iscell(ypt)
            ypt=[ypt{:}];
        end
        %generate the log density matrix
        [dm,xmesh,ymesh]=(density([xpt(:),ypt(:)]));
        dm=log(dm);
        hold on
        [C,h]=contour(xmesh,ymesh,dm);
        hold off
        hv=line('Visible','off');
        Cv=[];
        dmv=min(dm(:));
        
        %some variables to be used later
        stepsize=range(dm(:))/20;
        dmax=max(dm(:));
        dmin=min(dm(:));
        ah=gca;
        %make the boundaries minimal
        dm(1,:)=dmin;
        dm(end,:)=dmin;
        dm(:,1)=dmin;
        dm(:,end)=dmin;
        
        switch nargin
            case 0
                gate=[];
                wbdf=get(gcf,'WindowButtonDownFcn');
                wkpf=set(gcf,'WindowKeyPressFcn');
                set(gcf,'Pointer','crosshair')
                
                set(gcf,'WindowButtonDownFcn',@btndown)
                set(gcf,'WindowKeyPressFcn',@keypress)
                set(gcf,'Pointer','crosshair')
            case 1
        end
        uiwait;
        
        function btndown(src,evnt)
            if strcmp(get(src,'SelectionType'),'normal')
                %select specific contour
                delete(hv);
                p=get(ah,'CurrentPoint');
                [xv,xv]=min(abs(xmesh(1,:)-p(1,1)));
                [yv,yv]=min(abs(ymesh(:,1)-p(1,2)));
                dmv=dm(yv,xv);
                hold on
                [Cv,hv]=contour(xmesh,ymesh,dm,[dmv,dmv]);
                hold off
                set(hv,'linewidth',3)
                set(hv,'linecolor','k')
            elseif strcmp(get(src,'SelectionType'),'alt')
                %select the clicked contour
                p=get(ah,'CurrentPoint');
                idx=1;
                csize=[];
                while idx<size(Cv,2)
                    csize(end+1,1)=idx+1;
                    csize(end,2)=idx+Cv(2,idx);
                    idx=idx+1+Cv(2,idx);
                end
                isin=[];
                for i=1:size(csize,1)
                    isin(i)=inpolygon(p(1,1),p(1,2),Cv(1,csize(i,1):csize(i,2)),Cv(2,csize(i,1):csize(i,2)));
                end
                if sum(isin)~=1
                    %in more than one or on the boundary of two
                    return
                end
                gate=Cv(:,csize(isin==1,1):csize(isin==1,2));
                
                
                hold on
                delete(h);
                delete(hv);
                plot(gate(1,:),gate(2,:),'r');
                hold off
                set(src,'WindowButtonDownFcn',wbdf)
                set(gcf,'WindowKeyPressFcn',wkpf)
                set(src,'Pointer','Arrow')
                uiresume;
            end
            
        end
        function keypress(src,evnt)
            if isempty(evnt.Modifier)
                if strcmp(evnt.Key,'f1')
                    %show help
                    msgbox({'You can click to select a contour line or use arrows to move it up/down.',...
                        'Hold the shift key to finely adjust.',...
                        'To select - right click within the contour.'}...
                        ,'EasyFlow','help','modal');
                    uiwait;
                end
                if strcmp(evnt.Key,'uparrow')
                    %move contour
                    delete(hv);
                    dmv=min(dmv+stepsize,dmax);
                    hold on
                    [Cv,hv]=contour(xmesh,ymesh,dm,[dmv,dmv]);
                    hold off
                    set(hv,'linewidth',3)
                    set(hv,'linecolor','k')
                end
                if strcmp(evnt.Key,'downarrow')
                    %move contour
                    delete(hv);
                    dmv=max(dmv-stepsize,dmin);
                    hold on
                    [Cv,hv]=contour(xmesh,ymesh,dm,[dmv,dmv]);
                    hold off
                    set(hv,'linewidth',3)
                    set(hv,'linecolor','k')
                end
            end
            if strcmp(evnt.Modifier,'shift')
                if strcmp(evnt.Key,'uparrow')
                    %move contour
                    delete(hv);
                    dmv=min(dmv+stepsize/20,dmax);
                    hold on
                    [Cv,hv]=contour(xmesh,ymesh,dm,[dmv,dmv]);
                    hold off
                    set(hv,'linewidth',3)
                    set(hv,'linecolor','k')
                end
                if strcmp(evnt.Key,'downarrow')
                    %move contour
                    delete(hv);
                    dmv=max(dmv-stepsize/20,dmin);
                    hold on
                    [Cv,hv]=contour(xmesh,ymesh,dm,[dmv,dmv]);
                    hold off
                    set(hv,'linewidth',3)
                    set(hv,'linecolor','k')
                end
            end
        end
    end
end


