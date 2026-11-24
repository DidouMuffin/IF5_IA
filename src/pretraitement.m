Igray = rgb2gray(I);
imshow(Igray)

Ifilt = medfilt2(Igray, [3 3]);

Iresize = imresize(Ifilt, [224 224]);

imageAugmenter = imageDataAugmenter( ...
 'RandRotation',[-10,10], ...
 'RandXTranslation',[-5,5], ...
 'RandYTranslation',[-5,5]);
augimds = augmentedImageDatastore([224 224], imds, 'DataAugmentation',
imageAugmenter);