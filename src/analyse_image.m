
%% Analyse des images - Chapitre 2

clear;
clc;
close all;

dossierSrc = fileparts(mfilename('fullpath'));
dossierProjet = fileparts(dossierSrc);
addpath(dossierSrc);

%% Chargement de la base de donnees

root = fullfile(dossierProjet, 'data', 'train');

imds = imageDatastore(root, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

countEachLabel(imds)

%% Affichage d'une image

I = readimage(imds, 1);

figure;
imshow(I);
title(string(imds.Labels(1)));

%% Conversion en niveaux de gris

if size(I, 3) == 3
    Igray = rgb2gray(I);
else
    Igray = I;
end

figure;
imshow(Igray);
title('Image en niveaux de gris');

%% Filtrage spatial - Median 3x3

Ifilt = medfilt2(Igray, [3 3]);

figure;

subplot(1, 2, 1);
imshow(Igray);
title('Image originale');

subplot(1, 2, 2);
imshow(Ifilt);
title('Filtre median 3x3');

%% Redimensionnement de l'image

Iresize = imresize(Ifilt, [224 224]);

figure;

subplot(1, 2, 1);
imshow(Ifilt);
title('Image avant redimensionnement');

subplot(1, 2, 2);
imshow(Iresize);
title('Image 224x224');

% Affichage des dimensions
disp('Dimensions originales :');
disp(size(Ifilt));

disp('Dimensions apres redimensionnement :');
disp(size(Iresize));

%% Augmentation des donnees

imageAugmenter = imageDataAugmenter( ...
    'RandRotation', [-10, 10], ...
    'RandXTranslation', [-5, 5], ...
    'RandYTranslation', [-5, 5]);

augimds = augmentedImageDatastore([224 224], imds, ...
    'DataAugmentation', imageAugmenter);

%% Etape 6 - Analyses statistiques

% Calcul de la moyenne et de l'ecart-type
meanVal = mean(Igray(:));
stdVal = std(double(Igray(:)));

% Affichage des resultats
disp('Intensite moyenne :');
disp(meanVal);

disp('Ecart-type :');
disp(stdVal);

% Histogramme des niveaux de gris
figure;
imhist(Igray);
title('Histogramme des niveaux de gris');
xlabel('Intensite lumineuse');
ylabel('Nombre de pixels');

