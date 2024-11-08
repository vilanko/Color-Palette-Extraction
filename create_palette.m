% Specify the folder containing images
imageFolder = '/path';
imageFiles = dir(fullfile(imageFolder, '*.jpg')); 

% Initialize people detector
peopleDetector = peopleDetectorACF;

% Preallocate a large array to collect all foreground pixels across images
% Assuming each image might contribute up to 1,000,000 pixels
maxPixels = 1000000 * length(imageFiles);
allForegroundPixels = zeros(maxPixels, 3); % 3 for RGB channels
pixelCount = 0;  % Counter to track the number of stored pixels

% Loop over each image file
for i = 1:length(imageFiles)
    % Read the image
    imgPath = fullfile(imageFolder, imageFiles(i).name);
    try  
        img = imread(imgPath);
    catch
        warning('Could not read the image: %s. Skipping...', imageFiles(i).name);
        continue;
    end
    img = imresize(img, 0.5);
    % Detect people and get bounding boxes
    [bboxes, scores] = detect(peopleDetector, img);
    if ~isempty(bboxes)
        % Check if at least two bounding boxes were found
        if size(bboxes, 1) > 1
            areas = bboxes(:, 3) .* bboxes(:, 4);
            [~, sortedIdx] = sort(areas, 'descend');
            largestBBox1 = bboxes(sortedIdx(1), :);
            largestBBox2 = bboxes(sortedIdx(2), :);
            
            % Calculate combined bounding box
            xMin = min(largestBBox1(1), largestBBox2(1));
            yMin = min(largestBBox1(2), largestBBox2(2));
            xMax = max(largestBBox1(1) + largestBBox1(3), largestBBox2(1) + largestBBox2(3));
            yMax = max(largestBBox1(2) + largestBBox1(4), largestBBox2(2) + largestBBox2(4));
            combinedBBox = [xMin, yMin, xMax - xMin, yMax - yMin];
        else
            combinedBBox = bboxes(1, :);
        end
        croppedImg = imcrop(img, combinedBBox);
        % Convert to grayscale and segment foreground
        grayImg = rgb2gray(croppedImg);
        initialMask = false(size(grayImg));
        initialMask(10:end-10, 10:end-10) = true;
        foregroundMask = activecontour(grayImg, initialMask, 100, 'Chan-Vese');

        % Extract RGB values of only the foreground pixels
        R = croppedImg(:, :, 1);
        G = croppedImg(:, :, 2);
        B = croppedImg(:, :, 3);
        foregroundPixels = [R(foregroundMask), G(foregroundMask), B(foregroundMask)];

        % Update pixel count and add foreground pixels to the preallocated array
        numPixels = size(foregroundPixels, 1);
        allForegroundPixels(pixelCount + 1 : pixelCount + numPixels, :) = foregroundPixels;
        pixelCount = pixelCount + numPixels;
    else
        warning('No people detected in image: %s', imageFiles(i).name);
    end   
end

% Trim any unused rows from the preallocated array
allForegroundPixels = allForegroundPixels(1:pixelCount, :);

% Apply k-means clustering on all collected foreground pixels to get a combined palette
k = 6;  % Number of clusters
[~, centroids] = kmeans(double(allForegroundPixels), k, 'Replicates', 5);

% Display the combined color palette as swatches
figure;
for i = 1:k
    color = uint8(centroids(i, :));  % Convert to uint8 for display
    subplot(1, k, i);
    imshow(repmat(reshape(color, [1 1 3]), 100, 100));
    title(['Color ', num2str(i)]);
end
