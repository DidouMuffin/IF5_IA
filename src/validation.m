
%% Chapitre 5 - Etape 7 : Validation industrielle

clear;
clc;
close all;

% Acces aux fonctions du projet
addpath('src');

% Chargement des modeles
load('netTL.mat', 'netTL');
load('netCAE.mat', 'netCAE');

%% 1 - Temps de traitement ResNet-18

% Chargement d'une image NEU
imdsNEU = imageDatastore('data/train', ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

Ineu = readimage(imdsNEU, 1);

% Mesure du temps de classification
tic;
[label, ~, ~] = inspectImage(Ineu, netTL, netCAE, 'NEU');
tempsNEU = toc;

disp(['Classe reconnue : ', label]);
fprintf('Temps ResNet-18 : %.4f s\n', tempsNEU);


%% 2 - Evaluation de l'autoencodeur

% Chargement des images Bottle
imdsBottle = imageDatastore('data/mvtec/bottle/test', ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

nbImages = numel(imdsBottle.Files);

scores = zeros(nbImages, 1);
temps = zeros(nbImages, 1);

% Analyse de toutes les images
for i = 1:nbImages

    I = readimage(imdsBottle, i);

    tic;
    [~, scores(i), ~] = inspectImage( ...
        I, netTL, netCAE, 'bottle');
    temps(i) = toc;

end

% Temps moyen de traitement
tempsMoyen = mean(temps);

fprintf('Temps moyen autoencodeur : %.4f s\n', tempsMoyen);


%% 3 - Calcul des taux FRR et FAR

% Seuil utilise dans le chapitre 4
seuil = 0.01;

% Identification des images
idxNormal = imdsBottle.Labels == 'good';
idxDefaut = imdsBottle.Labels ~= 'good';

% Calcul du FRR
FRR = sum(scores(idxNormal) > seuil) ...
    / sum(idxNormal) * 100;

% Calcul du FAR
FAR = sum(scores(idxDefaut) <= seuil) ...
    / sum(idxDefaut) * 100;

% Affichage des resultats
fprintf('FRR : %.2f %%\n', FRR);
fprintf('FAR : %.2f %%\n', FAR);
