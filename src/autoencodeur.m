%% Chapitre 4 - Autoencodeur

clear;
clc;
close all;

%% Etape 5.a - Preparation des donnees

% Chargement des images normales
imdsTrain = imageDatastore( ...
    'data/mvtec/bottle/train/good', ...
    'FileExtensions', '.png');

% Chargement des images de test
imdsTest = imageDatastore( ...
    'data/mvtec/bottle/test', ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

% Lecture d'une image normale
I = readimage(imdsTrain, 1);

% Redimensionnement et normalisation
I = im2single(imresize(I, [128 128]));

% Affichage
figure;
imshow(I);
title('Image normale - Bottle');

% Nombre d'images
disp('Images d''entrainement :');
disp(numel(imdsTrain.Files));

disp('Images de test par categorie :');
countEachLabel(imdsTest)

%% Etape 5.b - Architecture de l'autoencodeur

layers = [
    imageInputLayer([128 128 3], 'Name', 'input')

    % Encodeur
    convolution2dLayer(3, 32, 'Padding', 'same')
    reluLayer
    maxPooling2dLayer(2, 'Stride', 2)

    convolution2dLayer(3, 16, 'Padding', 'same')
    reluLayer
    maxPooling2dLayer(2, 'Stride', 2)

    % Decodeur
    transposedConv2dLayer(4, 16, ...
        'Stride', 2, 'Cropping', 'same')
    reluLayer

    transposedConv2dLayer(4, 32, ...
        'Stride', 2, 'Cropping', 'same')
    reluLayer

    convolution2dLayer(3, 3, 'Padding', 'same')
    regressionLayer
];

%% Etape 5.c - Entrainement de l'autoencodeur 

%Preparation des images d'entrainement
nbImages = numel(imdsTrain.Files);
XTrain = zeros(128, 128, 3, nbImages, 'single');

for i = 1:nbImages

    I = readimage(imdsTrain, i);
    I = imresize(I, [128 128]);

    if size(I,3) == 1
        I = repmat(I, [1 1 3]);
    end

    XTrain(:,:,:,i) = im2single(I);
end

%% Parametres d'entrainement

options = trainingOptions('adam', ...
    'MaxEpochs', 10, ...
    'MiniBatchSize', 32, ...
    'InitialLearnRate', 1e-3, ...
    'Plots', 'training-progress');

%% Entrainement du réseau

netCAE = trainNetwork(XTrain, XTrain, layers, options);

%% Sauvegarde du modele

save('netCAE.mat', 'netCAE');


%% Etape 6 - Test de detection d'anomalies

% Chargement du modele entraine
load('netCAE.mat', 'netCAE');

% Chargement des images de test
imdsTest = imageDatastore( ...
    'data/mvtec/bottle/test', ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

% Lecture d'une image
Itest = readimage(imdsTest, 15);

% Redimensionnement et normalisation
X = im2single(imresize(Itest, [128 128]));

% Reconstruction de l'image
Xrec = predict(netCAE, X);

% Calcul de la carte d'erreur
errMap = mean((X - Xrec).^2, 3);

% Affichage des resultats
figure;

subplot(1, 3, 1);
imshow(X);
title('Image originale');

subplot(1, 3, 2);
imshow(Xrec);
title('Image reconstruite');

subplot(1, 3, 3);
imshow(mat2gray(errMap));
title('Carte d''erreur');


%% Test avec une image normale

% Recherche d'une image normale
idxNormal = find(imdsTest.Labels == 'good', 1);

% Lecture de l'image
Inormal = readimage(imdsTest, idxNormal);

% Redimensionnement et normalisation
Xnormal = im2single(imresize(Inormal, [128 128]));

% Reconstruction
XrecNormal = predict(netCAE, Xnormal);

% Calcul de l'erreur
errNormal = mean((Xnormal - XrecNormal).^2, 3);

% Score d'anomalie
scoreNormal = mean(errNormal(:));

% Affichage du score
disp(['Score image normale : ', num2str(scoreNormal)]);

% Affichage des images
figure;

subplot(1, 3, 1);
imshow(Xnormal);
title('Image normale');

subplot(1, 3, 2);
imshow(XrecNormal);
title('Reconstruction');

subplot(1, 3, 3);
imshow(mat2gray(errNormal));
title('Carte d''erreur');


%% Etape 7 - Comparaison des scores

% Calcul du score pour chaque image de test
scores = zeros(numel(imdsTest.Files), 1);

for i = 1:numel(imdsTest.Files)

    I = readimage(imdsTest, i);
    X = im2single(imresize(I, [128 128]));

    Xrec = predict(netCAE, X);

    errMap = mean((X - Xrec).^2, 3);
    scores(i) = mean(errMap(:));

end

% Separation des images normales et defectueuses
idxNormal = imdsTest.Labels == 'good';
idxDefaut = imdsTest.Labels ~= 'good';

% Affichage des scores moyens
disp('Score moyen des images normales :');
disp(mean(scores(idxNormal)));

disp('Score moyen des images defectueuses :');
disp(mean(scores(idxDefaut)));

% Affichage des scores
figure;
hold on;

plot(find(idxNormal), scores(idxNormal), 'go');
plot(find(idxDefaut), scores(idxDefaut), 'ro');

xlabel('Numero de l''image');
ylabel('Score d''anomalie');
title('Comparaison des scores');
legend('Images normales', 'Images defectueuses');
grid on;


%% Etape 8 - Comparaison des reconstructions

% Selection de deux images
idxNormal = find(imdsTest.Labels == 'good', 1);
idxDefaut = find(imdsTest.Labels ~= 'good', 1);

indices = [idxNormal idxDefaut];

figure;

for i = 1:2

    % Lecture et preparation de l'image
    I = readimage(imdsTest, indices(i));
    X = im2single(imresize(I, [128 128]));

    % Reconstruction
    Xrec = predict(netCAE, X);

    % Carte d'erreur
    errMap = mean((X - Xrec).^2, 3);

    % Image originale
    subplot(2, 3, (i-1)*3+1);
    imshow(X);
    title('Image originale');

    % Image reconstruite
    subplot(2, 3, (i-1)*3+2);
    imshow(Xrec);
    title('Reconstruction');

    % Carte d'erreur
    subplot(2, 3, (i-1)*3+3);
    imshow(mat2gray(errMap));
    title('Carte d''erreur');

end
