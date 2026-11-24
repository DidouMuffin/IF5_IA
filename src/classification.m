
%% Chapitre 3 - Classification supervisee

clear;
clc;
close all;

%% Etape 5.a - Chargement du dataset

root = fullfile(pwd, 'data', 'train');

imds = imageDatastore(root, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

% Separation des images : 80% / 20%
[imdsTrain, imdsTest] = splitEachLabel(imds, 0.8, 'randomized');

% Verification des groupes
disp('Images pour l''entrainement :');
countEachLabel(imdsTrain)

disp('Images pour le test :');
countEachLabel(imdsTest)


%% Etape 5.b - Preparation du reseau

% Chargement du reseau ResNet-18
net = resnet18;

% Conversion en graphe de couches
lgraph = layerGraph(net);

% Nombre de categories
numClasses = numel(categories(imdsTrain.Labels));

% Nouvelles couches de sortie
newLayers = [
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];

% Remplacement des couches
lgraph = replaceLayer(lgraph, 'fc1000', newLayers(1));

lgraph = replaceLayer(lgraph, ...
    'ClassificationLayer_predictions', newLayers(3));


%% Etape 5.c - Entrainement du modele

% Preparation des images pour ResNet-18
inputSize = [224 224];

augTrain = augmentedImageDatastore(inputSize, imdsTrain, ...
    'ColorPreprocessing', 'gray2rgb');

augTest = augmentedImageDatastore(inputSize, imdsTest, ...
    'ColorPreprocessing', 'gray2rgb');

% Parametres d'entrainement
options = trainingOptions('adam', ...
    'MiniBatchSize', 32, ...
    'MaxEpochs', 6, ...
    'InitialLearnRate', 1e-4, ...
    'ValidationData', augTest, ...
    'ValidationFrequency', 10, ...
    'Plots', 'training-progress');

% Entrainement du reseau
netTL = trainNetwork(augTrain, lgraph, options);

%% Etape 6 - Evaluation du modele

% Classification des images de test
[YPred, scores] = classify(netTL, augTest);

% Categories reelles
YTest = imdsTest.Labels;

% Calcul de la precision
accuracy = mean(YPred == YTest);

% Affichage des resultats
disp(['Accuracy = ', num2str(accuracy*100), '%']);

% Matrice de confusion
figure;
confusionchart(YTest, YPred);
title('Matrice de confusion - ResNet18');


%% Chapitre 5 - Evaluation des performances

% Calcul des indicateurs
[precision, recall, f1] = evaluateMetrics(YTest, YPred);

% Noms des categories
classes = categories(YTest);

% Affichage des resultats
resultats = table(classes, precision, recall, f1, ...
    'VariableNames', {'Classe', 'Precision', 'Rappel', 'F1'});

disp(resultats);



%% Chapitre 5 - Etape 5.a : Test de robustesse

% Lecture d'une image de test
I = readimage(imdsTest, 5);

% Redimensionnement
I = imresize(I, [224 224]);

% Conversion en 3 canaux
if size(I, 3) == 1
    I = repmat(I, [1 1 3]);
end

% Rotation de 10 degres
Irot = imrotate(I, 10, 'bilinear', 'crop');

% Bruit gaussien en niveaux de gris
Inoise = imnoise(I(:,:,1), 'gaussian', 0, 0.01);
Inoise = repmat(Inoise, [1 1 3]);

%% Classification

classeOrigine = classify(netTL, I);
classeRotation = classify(netTL, Irot);
classeBruit = classify(netTL, Inoise);

% Affichage des resultats
disp(['Classe reelle : ', char(imdsTest.Labels(5))]);
disp(['Image originale : ', char(classeOrigine)]);
disp(['Image avec rotation : ', char(classeRotation)]);
disp(['Image avec bruit : ', char(classeBruit)]);

%% Affichage des images

figure;

subplot(1, 3, 1);
imshow(I);
title('Image originale');

subplot(1, 3, 2);
imshow(Irot);
title('Rotation 10 degres');

subplot(1, 3, 3);
imshow(Inoise);
title('Bruit gaussien');

%% Resultats du test de robustesse

disp(['Classe reelle : ', char(imdsTest.Labels(5))]);

disp(['Image originale : ', char(classeOrigine)]);
disp(['Image avec rotation : ', char(classeRotation)]);
disp(['Image avec bruit : ', char(classeBruit)]);


%% Etape 5.b - Variation de luminosite

% Modification de la luminosite
Isombre = imadjust(I, [], [], 1.5);
Iclair = imadjust(I, [], [], 0.7);

% Classification des images
classeSombre = classify(netTL, Isombre);
classeClair = classify(netTL, Iclair);

% Affichage des resultats
disp(['Classe reelle : ', char(imdsTest.Labels(5))]);
disp(['Image originale : ', char(classeOrigine)]);
disp(['Image sombre : ', char(classeSombre)]);
disp(['Image claire : ', char(classeClair)]);

%% Affichage des images

figure;

subplot(1, 3, 1);
imshow(I);
title('Image originale');

subplot(1, 3, 2);
imshow(Isombre);
title('Image assombrie');

subplot(1, 3, 3);
imshow(Iclair);
title('Image eclaircie');


%% Sauvegarde du modele ResNet-18

save('netTL.mat', 'netTL');


%% Chapitre 5 - Etape 6 : Test de la fonction inspectImage

% Acces aux fonctions du projet
addpath('src');

% Chargement des modeles sauvegardes
load('netTL.mat', 'netTL');
load('netCAE.mat', 'netCAE');

% Test avec une image NEU

imdsNEU = imageDatastore('data/train', ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

Ineu = readimage(imdsNEU, 1);

[label, score, errMap] = inspectImage( ...
    Ineu, netTL, netCAE, 'NEU');

disp(['Defaut reconnu : ', label]);

% Test avec une bouteille

imdsBottle = imageDatastore('data/mvtec/bottle/test', ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

Ibottle = readimage(imdsBottle, 15);

[label, score, errMap] = inspectImage( ...
    Ibottle, netTL, netCAE, 'bottle');

disp(['Score d''anomalie : ', num2str(score)]);

figure;
imshow(mat2gray(errMap));
title('Carte d''erreur - Bottle');

