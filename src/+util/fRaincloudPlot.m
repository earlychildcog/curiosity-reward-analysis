%% fRaincloudPlot - plots a raincloud plot (similar to JASP plots)
%
% Use as fig = raincloud_plot(data)
%   each dataset is a column vector, collected into a matrix of colunmns 
%   or a cell array; fig is a handle for the figure generated
%
% See below for optional inputs.
%    e.g.:    opts.labels={'1','2'}; fig = raincloud_plot(data, opts);
%
% Written by Cecile Gal - 20/02/25
% Used Claude to modify
% Based on Tom Rhys Marshall: https://github.com/RainCloudPlots
% Who used https://micahallen.org/2018/03/15/introducing-raincloud-plots/
% Inspired by https://m.xkcd.com/1967/
%


function fig = fRaincloudPlot(data, opts)

% ---------------------------- INPUT ----------------------------
%
% data - column vectors of data to be plotted, required.
%
% --------------------- OPTIONAL ARGUMENTS ----------------------
%
% opts.colors             - for each dataset group (default 1st color of linspecer(2) or blue)
% opts.labels             - what to write under each boxplot, cell array of strings
% opts.x_label            - what to write under boxplot opts.labels (e.g. conditions), cell array of strings
% opts.y_label            - what the values in boxplot represent, cell array of strings
% opts.x_lim              - set the limit of the x axis e.g., to make different
%                        plots comparable
% opts.y_lim              - set the limit of the y axis e.g., to make different
%                        plots comparable
% opts.font_size          - in points, for whole picture (default 18)
% opts.line_width         - for all the lines in plot (box, 0 line, densities... - default 1.5)
% opts.plotLines          - Plot grey lines between points of same index in each
%                        boxplot e.g., representing same participant (default yes: 1)
% opts.point_size         - Size of data points on boxplots (default 60 similar to JASP)
% opts.alpha_points       - Transparency of points (0-1; default .7)
% opts.alpha_box          - Transparency of box patches (0-1; default .2)
% opts.alpha_density      - Transparency of density curve patches (0-1; default .4)
% opts.alpha_lines        - Transparency of density lines linking boxplot points (0-1; default .5)
% opts.density_height     - how large should the cloud be (default: .75 similar to JASP)
% opts.density_type       - choice of density algo ('ks' or 'rath'). Default = 'ks'
% opts.band_width         - band width of smoothing kernel (default = 1, same as
%                        JASP) - better not to play too much with this

%
% ---------------------------- OUTPUT ----------------------------
% fig - figure handle
%
% ------------------------ EXAMPLE USAGE -------------------------
%
% opts.labels={'1','2'}; opts.y_label={'Amplitude (\muV)'}; opts.y_lim=[-40 30];
% fig = raincloud_plot(data, opts);
%

arguments
    data (:,:) {mustBeNumeric}
    opts.colors (:,3) {mustBeNumeric}         = []
    opts.labels (1,:) cell {mustBeText}       = {''}
    opts.x_label (1,:) cell {mustBeText}      = {''}
    opts.y_label (1,:) cell {mustBeText}      = {''}
    opts.x_lim (1,:) {mustBeNumeric}          = []
    opts.y_lim (1,:) {mustBeNumeric}          = []
    opts.density_type string                  = 'ks'
    opts.density_height (1,1) {mustBeNumeric} = .75
    opts.band_width (1,1) {mustBeNumeric}     = 1
    opts.line_width (1,1) {mustBeNumeric}     = 1.5
    opts.box_width (1,1) {mustBeNumeric}      = .5
    opts.box_positions (1,:) {mustBeNumeric}  = NaN
    opts.plotLines (1,1) logical              = 1
    opts.point_size (1,1) {mustBeNumeric}     = 60
    opts.font_size (1,1) {mustBeNumeric}      = 18
    opts.alpha_density (1,1) {mustBeNumeric}  = .4
    opts.alpha_lines (1,1) {mustBeNumeric}    = .5
    opts.alpha_box (1,1) {mustBeNumeric}      = .2
    opts.alpha_points (1,1) {mustBeNumeric}   = .7
    opts.make_new_figure (1,1) logical        = 1
end

% Prepare data - handle cell arrays or matrices and get the number of datasets
if iscell(data)
    % Handle cell array input
    nDatasets = length(data);
    
    % Get maximum length of data across all cells
    maxLength = 0;
    for i = 1:nDatasets
        if ~isempty(data{i}) && numel(data{i}) > 0 && ~all(isnan(data{i}(:)))
            maxLength = max(maxLength, length(data{i}(:)));
        end
    end
    
    % Default maxLength if all datasets are empty
    if maxLength == 0
        maxLength = 1;
    end
    
    % Convert to matrix format with NaNs for missing or empty values
    matrixData = nan(maxLength, nDatasets);
    for i = 1:nDatasets
        if ~isempty(data{i}) && numel(data{i}) > 0
            currentData = data{i}(:);
            matrixData(1:length(currentData), i) = currentData;
        end
    end
    dataMatrix = matrixData;
    
else
    % Handle matrix input - each column is a dataset
    [~, nDatasets] = size(data);
    dataMatrix = data;
end

% Identify empty datasets
emptyDatasets = false(1, nDatasets);
for i = 1:nDatasets
    emptyDatasets(i) = all(isnan(dataMatrix(:, i)));
end

% Generate default colors if not provided or expand if needed
% Count non-empty datasets for color assignment
nonEmptyDatasets = sum(~emptyDatasets);

if isempty(opts.colors)
    if exist('linspecer','file')==2
        allopts.colors = linspecer(nonEmptyDatasets);
    else
        % Use default MATLAB opts.colors
        allopts.colors = repmat(defaultopts.colors, ceil(nonEmptyDatasets/size(defaultopts.colors, 1)), 1);
        allopts.colors = allopts.colors(1:nonEmptyDatasets, :);
    end
    
    % Assign opts.colors to datasets (empty datasets get a default gray color)
    opts.colors = zeros(nDatasets, 3);
    nonEmptyCounter = 1;
    for i = 1:nDatasets
        if emptyDatasets(i)
            opts.colors(i, :) = [0.8 0.8 0.8]; % Gray for empty datasets
        else
            opts.colors(i, :) = allopts.colors(nonEmptyCounter, :);
            nonEmptyCounter = nonEmptyCounter + 1;
        end
    end
elseif size(opts.colors, 1) == 1 && nDatasets > 1
    % Replicate the single color for all non-empty boxes
    originalColor = opts.colors;
    opts.colors = zeros(nDatasets, 3);
    for i = 1:nDatasets
        if emptyDatasets(i)
            opts.colors(i, :) = [0.8 0.8 0.8]; % Gray for empty datasets
        else
            opts.colors(i, :) = originalColor;
        end
    end
elseif size(opts.colors, 1) < nDatasets
    % Handle provided opts.colors, ensuring empty datasets get gray
    originalopts.colors = opts.colors;
    opts.colors = zeros(nDatasets, 3);
    nonEmptyCounter = 1;
    for i = 1:nDatasets
        if emptyDatasets(i)
            opts.colors(i, :) = [0.8 0.8 0.8]; % Gray for empty datasets
        else
            if nonEmptyCounter <= size(originalopts.colors, 1)
                opts.colors(i, :) = originalopts.colors(nonEmptyCounter, :);
            else
                % Recycle opts.colors if needed
                colIdx = mod(nonEmptyCounter-1, size(originalopts.colors, 1)) + 1;
                opts.colors(i, :) = originalopts.colors(colIdx, :);
            end
            nonEmptyCounter = nonEmptyCounter + 1;
        end
    end
end

% Generate default labels if not provided
if isempty(opts.labels)
    opts.labels = cell(1, nDatasets);
    for i = 1:nDatasets
        opts.labels{i} = num2str(i);
    end
elseif length(opts.labels) < nDatasets
    % Extend opts.labels if too few provided
    originalopts.labels = opts.labels;
    opts.labels = cell(1, nDatasets);
    for i = 1:length(originalopts.labels)
        opts.labels{i} = originalopts.labels{i};
    end
    for i = length(originalopts.labels)+1:nDatasets
        opts.labels{i} = num2str(i);
    end
end

% Modify opts.labels for empty datasets (append empty to clarify)
if ~isempty(emptyDatasets)
    for iEmpty = 1:size(emptyDatasets,1)
        if emptyDatasets(iEmpty)
            opts.labels{iEmpty} = [opts.labels{iEmpty} ' (empty)'];
        end
    end
end

% Set positions for boxplots if not provided
if isnan(opts.box_positions) || length(opts.box_positions) ~= nDatasets
    opts.box_positions = 1:nDatasets;
end

% Set offset to plot density curves (to the right of boxplots)
if length(opts.box_positions) > 1
    density_offset = opts.box_positions(end) + (opts.box_positions(2) - opts.box_positions(1));
else
    density_offset = opts.box_positions(end) + opts.box_positions(end);
end
height = opts.density_height * (max(dataMatrix,[],'all') - min(dataMatrix,[],'all'))/2; % Use the range of the data to normalise

% Create axes
if opts.make_new_figure
    fig = figure;
end
hold on
yline(0,'--',color=[.5 .5 .5 .3])

for iData = 1:nDatasets
    curr_data = dataMatrix(:,iData);

    % Add jittered points
    X = opts.box_positions(iData)*ones(size(curr_data)) + (rand(size(curr_data))-0.5)*opts.box_width;
    scatter(X, curr_data, opts.point_size, opts.colors(iData,:), 'filled', 'MarkerFaceAlpha', opts.alpha_points);

    % Add lines to link participants' points
    if iData > 1
        if opts.plotLines
            % Add lines current dataset to last dataset
            line([lastX,X]',[last_data,curr_data]', color=[.7 .7 .7 opts.alpha_lines], LineWidth=opts.line_width)
        end
        % Add boxplots onto last dataset (over the points and lines)
        h = boxplot(last_data, 'Positions', opts.box_positions(iData-1), 'Widths', opts.box_width, 'colors', 'k', 'Symbol', '');
        set(h,'Linewidth', opts.line_width);
        % Set boxplot fills with alpha
        hBox = findobj(h, 'Tag', 'Box');
        patch(get(hBox(1),'XData'),get(hBox(1),'YData'),opts.colors(iData-1,:),'FaceAlpha',opts.alpha_box,'LineStyle','none');
        last_data = curr_data;
        lastX = X;
    else
        last_data = curr_data;
        lastX = X;
    end
    if nDatasets < 2 || iData == nDatasets
        % Add boxplots
        h = boxplot(curr_data, 'Positions', opts.box_positions(iData), 'Widths', opts.box_width, 'colors', 'k', 'Symbol', '');
        set(h,'Linewidth', opts.line_width);
        % Set boxplot fills with alpha
        hBox = findobj(h, 'Tag', 'Box');
        patch(get(hBox(1),'XData'),get(hBox(1),'YData'),opts.colors(iData,:),'FaceAlpha',opts.alpha_box,'LineStyle','none');
    end


    % Calculate bandwidth based on data range (maximum range of either
    data_range  = max(curr_data) - min(curr_data);
    curr_opts.band_width  = (opts.band_width/10)*data_range;
    % calculate kernel density
    [f{iData}, Xi(iData,:), ~] = calculate_kernel_density(curr_data,opts.density_type,curr_opts.band_width);

    % Plot density curves (to the right of boxplots)
    % Dataset density - using patch for vertical shading
    % height = opts.density_height * (max(data) - min(data)); % Use the range of the data to normalise
    patch([zeros(size(f{iData})) + density_offset, f{iData} * height + density_offset], [Xi(iData,:), Xi(iData,:)], ...
        opts.colors(iData,:), 'FaceAlpha', opts.alpha_density, 'EdgeColor', 'k', 'LineWidth', opts.line_width);
end

hold off

% Set x opts.labels
xticks(opts.box_positions); xticklabels(opts.labels);

% Set opts.x_lim
if isempty(opts.x_lim)
    opts.x_lim = [opts.box_positions(1)/2, density_offset + 1.2*opts.box_positions(1)];
end
xlim(opts.x_lim);

% Set y axis limits so we can see the end of the density curves
if isempty(opts.y_lim)
    y1 = min(Xi,[],'all'); y2 = max(Xi,[],'all');
    ylim([y1-.05*(y2-y1), y2+.05*(y2-y1)])
else
    ylim(opts.y_lim);
end

xlabel(opts.x_label);
ylabel(opts.y_label);

set(gca,'box','off'); % take off ticks at top and right that somehow appeared

fontsize(opts.font_size,"points");
set(gca, 'FontSize', opts.font_size);

% ax = gca(gcf); ax.XAxis.FontSize = XAxis_opts.font_size;

% Function def:  calculate kernel density
function [f, Xi, u] = calculate_kernel_density(X, density_type, band_width)
switch density_type
    case 'ks'
        [f, Xi, u] = ksdensity(X, 'bandwidth', band_width);
        
    case 'rash'
        % must have https://github.com/CPernet/Robust_Statistical_Toolbox
        % for this to work
        
        % check for rst_RASH function (from Robust stats toolbox) in path, fail if not found
        assert(exist('rst_RASH', 'file') == 2, 'Could not compute density using RASH method. Do you have the Robust Stats toolbox on your path?');
        
        [Xi, f] = rst_RASH(X);
        u = NaN; % not sure how to handle this with RASH yet
end
% NORMALISE -- not normalising properly, giving up
% Calculate the range of the data (to normalise density curve)
% databounds.range  = max(X) - min(X);
% databounds.center = max(X) - databounds.range/2;
% % Normalise curve's range (basis of cloud) to the range of the data
% Xirange = max(Xi)-min(Xi);
% Xi = (Xi/Xirange) * databounds.range + databounds.center;
end

end