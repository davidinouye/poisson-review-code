function [h,ax,BigAx,hhist,pax] = poissonplotmatrix(opts, varargin)
%PLOTMATRIX Scatter plot matrix.
%   PLOTMATRIX(X,Y) scatter plots the columns of X against the columns
%   of Y.  If X is P-by-M and Y is P-by-N, PLOTMATRIX will produce a
%   N-by-M matrix of axes. PLOTMATRIX(Y) is the same as PLOTMATRIX(Y,Y)
%   except that the diagonal will be replaced by HISTOGRAM(Y(:,i)).
%
%   PLOTMATRIX(...,'LineSpec') uses the given line specification in the
%   string 'LineSpec'; '.' is the default (see PLOT for possibilities).
%
%   PLOTMATRIX(AX,...) uses AX as the BigAx instead of GCA.
%
%   [H,AX,BigAx,P,PAx] = PLOTMATRIX(...) returns a matrix of handles
%   to the objects created in H, a matrix of handles to the individual
%   subaxes in AX, a handle to big (invisible) axes that frame the
%   subaxes in BigAx, a vector of handles for the histogram plots in
%   P, and a vector of handles for invisible axes that control the
%   histogram axes scales in PAx.  BigAx is left as the CurrentAxes so
%   that a subsequent TITLE, XLABEL, or YLABEL will be centered with
%   respect to the matrix of axes.
%
%   Example:
%       x = randn(50,3); y = x*[-1 2 1;2 0 1;1 -2 3;]';
%       plotmatrix(y)

%   Copyright 1984-2015 The MathWorks, Inc.

% Parse possible Axes input
assert(isstruct(opts), 'Opts should be structure');

[cax,args,nargs] = axescheck(varargin{:});
if nargs < 1
    error(message('MATLAB:narginchk:notEnoughInputs'));
elseif nargs > 3
    error(message('MATLAB:narginchk:tooManyInputs'));
end
nin = nargs;

sym = '.'; % Default scatter plot symbol.
dohist = 0;

if ischar(args{nin}),
    sym = args{nin};
    [~,~,~,msg] = colstyle(sym);
    if ~isempty(msg), error(msg); end
    nin = nin - 1;
end

if nin==1, % plotmatrix(y)
    rows = size(args{1},2); cols = rows;
    x = args{1}; y = args{1};
    dohist = 1;
elseif nin==2, % plotmatrix(x,y)
    rows = size(args{2},2); cols = size(args{1},2);
    x = args{1}; y = args{2};
else
    error(message('MATLAB:plotmatrix:InvalidLineSpec'));
end
% CHANGE
x = max(0,round(x));
y = max(0,round(y));
axisColor = [0.7,0.7,0.7];
labelColor = [0.2,0.2,0.2];

% Don't plot anything if either x or y is empty
hhist = gobjects(0);
pax = gobjects(0);
if isempty(rows) || isempty(cols),
    if nargout>0, h = gobjects(0); ax = gobjects(0); BigAx = gobjects(0); end
    return
end

if ~ismatrix(x) || ~ismatrix(y)
    error(message('MATLAB:plotmatrix:InvalidXYMatrices'))
end
if size(x,1)~=size(y,1) || size(x,3)~=size(y,3),
    error(message('MATLAB:plotmatrix:XYSizeMismatch'));
end

% Create/find BigAx and make it invisible
BigAx = newplot(cax);
fig = ancestor(BigAx,'figure');
hold_state = ishold(BigAx);
set(BigAx,'Visible','off','color','none');
% Set axis square for bigAx
%set(BigAx,'PlotBoxAspectRatio',[1 1 1], 'DataAspectRatioMode','auto');


if any(sym=='.'),
    units = get(BigAx,'units');
    set(BigAx,'units','pixels');
    pos = get(BigAx,'Position');
    set(BigAx,'units',units);
    markersize = max(1,min(15,round(15*min(pos(3:4))/max(1,size(x,1))/max(rows,cols))));
else
    markersize = get(0,'DefaultLineMarkerSize');
end

%% Initialize options
if(isfield(opts,'maxX'))
    maxX = opts.maxX;
else
    maxX = round(quantile(x(:),0.99));
end
if(~isfield(opts,'labels'))
    opts.labels = cellfun(@num2str, num2cell(1:size(x,2)), 'UniformOutput', false);
end
if(isfield(opts,'meanPair'))
    dohist = false;
    if(~isfield(opts,'maxVal'))
        opts.maxVal = max(opts.meanPair(:));
    end
    space = 0;
else
    space = 0; % 2 percent space between axes
end

% Create and plot into axes
ax = gobjects(rows,cols);
pos = get(BigAx,'Position');
pos = [pos(1),pos(2),pos(3),pos(4)*0.85];
width = pos(3)/cols;
height = pos(4)/rows;

pos(1:2) = pos(1:2) + space*[width height];
m = size(y,1);
k = size(y,3);
xlim = zeros([rows cols 2]);
ylim = zeros([rows cols 2]);
BigAxHV = get(BigAx,'HandleVisibility');
BigAxParent = get(BigAx,'Parent');
paxes = findobj(fig,'Type','axes','tag','PlotMatrixScatterAx');

for i=rows:-1:1,
    for j=cols:-1:1,
        axPos = [pos(1)+(j-1)*width pos(2)+(rows-i)*height ...
            width*(1-space) height*(1-space)];
        findax = findaxpos(paxes, axPos);
        if isempty(findax),
            ax(i,j) = axes('Position',axPos,'HandleVisibility',BigAxHV,'parent',BigAxParent);
            set(ax(i,j),'visible','on');
        else
            ax(i,j) = findax(1);
        end
        % CHANGE
        %hh(i,j,:) = plot(reshape(x(:,j,:),[m k]), ...
        %    reshape(y(:,i,:),[m k]),sym,'parent',ax(i,j))';
        %set(hh(i,j,:),'markersize',markersize);
        %set(ax(i,j),'xlimmode','auto','ylimmode','auto','xgrid','off','ygrid','off')
        
        if(i ~= j); 
            hh(i,j,:) = imagesc( 0:maxX, 0:maxX, Xt2Z( [reshape(y(:,i,:),[m k]), reshape(x(:,j,:),[m k])], maxX), 'parent', ax(i,j) )';
        end % histogram
        if(isfield(opts,'meanPair'))
            cla(ax(i,j));
            temp = (1-opts.meanPair(i,j)/opts.maxVal);
            blockColor = min(max(temp,0),1)*ones(1,3); % Clip color
            set(ax(i,j),'color',blockColor);
            set(ax(i,j),'XColor', blockColor, 'YColor', blockColor);
            set(ax(i,j),'xtick','');
            set(ax(i,j),'ytick','');
        else
            set(ax(i,j),'XColor', axisColor, 'YColor', axisColor);
        end
        
        if(j == 1)
            ylabel(opts.labels{i},'color',labelColor, 'Rotation',0,'HorizontalAlignment', 'right', 'VerticalAlignment','middle'); 
        end
        if(i == 1)
            xlabel(opts.labels{j},'color',labelColor, 'Rotation',45,'HorizontalAlignment', 'left', 'VerticalAlignment','middle');
            set(ax(i,j),'xaxisLocation','top');
        end
        %set(ax(i,j),'PlotBoxAspectRatio',[1 1 1], 'DataAspectRatioMode','auto');
        %set(ax(i,j), 'visible', 'off');
        xlim(i,j,:) = get(ax(i,j),'xlim');
        ylim(i,j,:) = get(ax(i,j),'ylim');
    end
end


%xlimmin = min(xlim(:,:,1),[],1); xlimmax = max(xlim(:,:,2),[],1);
%ylimmin = min(ylim(:,:,1),[],2); ylimmax = max(ylim(:,:,2),[],2);

% Try to be smart about axes limits and labels.  Set all the limits of a
% row or column to be the same and inset the tick marks by 10 percent.
%{
inset = .15;
for i=1:rows,
    set(ax(i,1),'ylim',[ylimmin(i,1) ylimmax(i,1)])
    dy = diff(get(ax(i,1),'ylim'))*inset;
    set(ax(i,:),'ylim',[ylimmin(i,1)-dy ylimmax(i,1)+dy])
end
dx = zeros(1,cols);
for j=1:cols,
    set(ax(1,j),'xlim',[xlimmin(1,j) xlimmax(1,j)])
    dx(j) = diff(get(ax(1,j),'xlim'))*inset;
    set(ax(:,j),'xlim',[xlimmin(1,j)-dx(j) xlimmax(1,j)+dx(j)])
end
%}

%set(BigAx,'XTick',get(ax(rows,1),'xtick'),'YTick',get(ax(rows,1),'ytick'), ...
%    'userdata',ax,'tag','PlotMatrixBigAx')
set(ax,'tag','PlotMatrixScatterAx');
set(ax(:),'xticklabel','','xtick',0:maxX);
set(ax(:),'yticklabel','','ytick',0:maxX);
set(ax(:),'YDir','normal');

if dohist, % Put a histogram on the diagonal for plotmatrix(y) case
    paxes = findobj(fig,'Type','axes','tag','PlotMatrixHistAx');
    pax = gobjects(1, rows);
    for i=rows:-1:1,
        axPos = get(ax(i,i),'Position');
        findax = findaxpos(paxes, axPos);
        if isempty(findax),
            histax = axes('Position',axPos,'HandleVisibility',BigAxHV,'parent',BigAxParent);
            set(histax,'visible','on');
        else
            histax = findax(1);
        end
        hhist(i) = histogram(histax,y(:,i,:),(0:(maxX+1)));
        set(hhist(i), 'EdgeColor', 'none','FaceColor', [0.1, 0.1, 0.1]);
        set(histax,'xtick',[],'ytick',[],'xgrid','off');
        set(histax,'xlim',[0,maxX+1]);
        set(histax,'XColor', axisColor, 'YColor', axisColor);
        %set(histax,'visible','off');
        set(histax,'tag','PlotMatrixHistAx');
        %set(histax,'PlotBoxAspectRatio',[1 1 1], 'DataAspectRatioMode','auto');
        pax(i) = histax;  % ax handles for histograms
    end
end

% Make BigAx the CurrentAxes
set(fig,'CurrentAx',BigAx)
if ~hold_state,
    set(fig,'NextPlot','replacechildren')
end

% Also set Title and X/YLabel visibility to on and strings to empty
set([get(BigAx,'Title'); get(BigAx,'XLabel'); get(BigAx,'YLabel')], ...
    'String','','Visible','on')

if nargout~=0,
    h = hh;
end



function findax = findaxpos(ax, axpos)
tol = eps;
findax = [];
for i = 1:length(ax)
    axipos = get(ax(i),'Position');
    diffpos = axipos - axpos;
    if (max(max(abs(diffpos))) < tol)
        findax = ax(i);
        break;
    end
end


