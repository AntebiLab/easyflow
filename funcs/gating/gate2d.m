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