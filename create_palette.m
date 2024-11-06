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
    
    % Detect people and get bounding boxes
    [bboxes, scores] = detect(peopleDetector, img);
    
    % Check if at least two bounding boxes were found
    if size(bboxes, 1) >= 2
        % Calculate area of each bounding box
        areas = bboxes(:, 3) .* bboxes(:, 4);
        
        % Find indices of the two largest bounding boxes
        [~, sortedIdx] = sort(areas, 'descend');
        largestBBox1 = bboxes(sortedIdx(1), :);
        largestBBox2 = bboxes(sortedIdx(2), :);
        
        % Calculate the combined bounding box
        xMin = min(largestBBox1(1), largestBBox2(1));
        yMin = min(largestBBox1(2), largestBBox2(2));
        xMax = max(largestBBox1(1) + largestBBox1(3), largestBBox2(1) + largestBBox2(3));
        yMax = max(largestBBox1(2) + largestBBox1(4), largestBBox2(2) + largestBBox2(4));
        
        % Width and height of the combined bounding box
        combinedWidth = xMax - xMin;
        combinedHeight = yMax - yMin;
        
        % Create the combined bounding box and crop the image
        combinedBBox = [xMin, yMin, combinedWidth, combinedHeight];
        croppedImg = imcrop(img, combinedBBox);
        
    elseif size(bboxes, 1) == 1
        croppedImg = imcrop(img, bboxes);
    else
        warning('No people detected in image: %s', imageFiles(i).name);
    end
    
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
