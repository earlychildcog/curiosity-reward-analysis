classdef ROIclass
    % Create ROIs to use for eyetracking analysis
    % usage: obj = ROIclass(area_positions, fileImagBack,  area_labels)
    % Input:
    % area_positions:       numROIs x 4 array, positions for each ROI. Each row contains information for each ROI, in the form [lowest_x_coordinate lowest_y_coordinate width height]
    % fileImagBack:            background image for visualisation.
    % area_labels:          1 x numROIs cell array of strings, contains a label for each ROI
    %
    %
    % Functions:
    % roi.show:             Show figure
    % roi.hide:             Hide figure
    % roi.switch_areas:     Change ROI order. For use for different experimental conditions.
    % roi.update_colour:    Set colours to default values (can be used after switching areas)
    % roi.whichROI(x,y):    Which ROI the point (x,y) belong to. Zero for no roi.
    % roi.close:            Close figure. Destroys ROI object.
    
    properties
        display = struct();
        area            % right now works with two ROIs only (without switching, works for more?)
        area_labels
        image_file
    end
    methods
        function obj = ROIclass(area_positions, fileImagBack,  area_labels)
            arguments
                area_positions (:,4) double
                fileImagBack string {mustBeFile}
                area_labels (1,:) string
            end
            obj.display.fig = figure("Visible","off");                           % start a new figure window
            
            obj.image_file = fileImagBack;
            imagBack = imread(fileImagBack);
            imagBack = rgb2gray(imagBack);

            imshow(imagBack);                                  % show background image
            obj.display.canvas = obj.display.fig.Children;      % save axes
            
            obj.area = [];
            for area_count = 1:size(area_positions,1)
                obj.area = [obj.area images.roi.Rectangle(obj.display.canvas,'Position',area_positions(area_count,:))];
                set(obj.area(area_count),'InteractionsAllowed','none') % We "fix" the ROIs in the figure window
            end
            obj.area_labels = area_labels;
            assert(size(obj.area_labels,2) == size(obj.area,2),'we need a label for each ROI')
            
            obj.update_colour;
            set(obj.display.fig,'CloseRequestFcn',[]); % prevent from closing
        end
        function obj = show(obj)
            obj.display.fig.Visible = 'on';
            obj.update_colour;
        end
        function obj = hide(obj)
            obj.display.fig.Visible = 'off';
        end
        function obj = switch_areas(obj)
            obj.area = obj.area([2 1]);
            obj.area_labels = obj.area_labels([2 1]);
            if obj.display.fig.Visible
                fprintf('To update colour in the figure please use obj.update_colour\n');
            end
        end
        function update_colour(obj)
            set(obj.area(1),'color',[0.2 0.9 0.6])
            set(obj.area(2),'color',[0.7 0.3 0.5])
        end
        function obj = close(obj)
            close(obj.display.fig,'force','hidden');
        end
        function thisROI = whichROI(obj,x,y)        % x and y are columns of gaze position coordinates
            % clear the data fron NaN values
            x(isnan(x)) = -10^6;
            y(isnan(y)) = -10^6;
            thisROI = cell2mat(arrayfun(@(r)inROI(r,x,y),obj.area,'UniformOutput',false));
            thisROI = thisROI.*[1:size(obj.area,2)];
            thisROI = sum(thisROI,2);
        end
        function delete(obj)
            obj.close;
        end
    end
end