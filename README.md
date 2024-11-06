
# Color Palette Extraction Using People Detection and Foreground Segmentation

# Overview
This MATLAB script is designed to extract dominant colors from images of fashion runways by using a people detection algorithm and foreground segmentation techniques. The extracted colors are presented as a combined color palette, which could be useful for fashion analysis, trend prediction, or visual studies.

# Steps in the Code

1. Specify Image Folder and Load Images
The script begins by defining the folder where the images are stored and loading all .jpg files from that folder.
The dir function is used to get information about the image files, preparing for processing.

2. Initialize the People Detector
The script initializes the peopleDetectorACF object, which is used to detect people in each image.

3. Preallocate Memory for Foreground Pixels
To handle a large number of collected RGB pixels efficiently, a preallocated array is created. This ensures optimal performance during pixel storage.

4. Loop Through Each Image
The script loops through each image, reads it, and attempts to detect people using the initialized detector. If an image cannot be read, a warning is issued, and the script skips that image.

5. Detect People and Process Bounding Boxes
If at least two bounding boxes are found, the code combines the bounding boxes into a single region of interest that includes the largest detected people.
If only one bounding box is found, it crops the image using that bounding box.
If no bounding boxes are detected, a warning is logged.

6. Foreground Segmentation Using Active Contours
The cropped image is converted to grayscale, and active contour segmentation (Chan-Vese method) is applied to segment the foreground, isolating the fashion-related pixels.

7. Extract RGB Values of Foreground Pixels
The script extracts the RGB values of the pixels identified as part of the foreground and stores them in the preallocated array.

8. Apply K-means Clustering to Form a Color Palette
After collecting all foreground pixels from all images, k-means clustering is used to find k dominant colors.

9. Display the Extracted Color Palette
The dominant colors are displayed as swatches, each representing one of the k clusters identified by k-means.

# Notes
# Error Handling: 
Warnings are issued for unreadable images and images where no people are detected.
# Performance: 
The script is optimized using preallocation and efficient MATLAB functions.
# Requirements
MATLAB with Image Processing Toolbox.
A set of fashion runway images for analysis.
# Applications
This script can be useful for fashion data analysis, visual inspiration, or automated color palette generation from fashion images.

