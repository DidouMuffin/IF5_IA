%% Chapitre 5 - Validation industrielle
clear;
clc;

dossierSrc = fileparts(mfilename('fullpath'));
dossierProjet = fileparts(dossierSrc);
addpath(dossierSrc);

load(fullfile(dossierProjet, 'netTL.mat'), 'netTL');
load(fullfile(dossierProjet, 'netCAE.mat'), 'netCAE');

%% 1 - Temps moyen de classification NEU
racineNEU = fullfile(dossierProjet, 'data', 'train');
imdsNEU = imageDatastore(racineNEU, 'IncludeSubfolders', true);
nbNEU = min(20, numel(imdsNEU.Files));
indicesNEU = round(linspace(1, numel(imdsNEU.Files), nbNEU));
tempsNEU = zeros(nbNEU, 1);

% Premiere prediction hors chronometre pour initialiser le reseau.
inspectImage(readimage(imdsNEU, 1), netTL, [], 'NEU');
for i = 1:nbNEU
    I = readimage(imdsNEU, indicesNEU(i));
    debut = tic;
    inspectImage(I, netTL, [], 'NEU');
    tempsNEU(i) = toc(debut);
end
fprintf('NEU - temps moyen sur %d images : %.4f s\n', nbNEU, mean(tempsNEU));

%% 2 - Carte d'erreur habituelle des bouteilles saines
racineBottle = fullfile(dossierProjet, 'data', 'mvtec', 'bottle');
imdsReference = imageDatastore(fullfile(racineBottle, 'train', 'good'), ...
    'FileExtensions', '.png');
nbReference = numel(imdsReference.Files);
cartesSaines = zeros(128, 128, nbReference, 'single');
for i = 1:nbReference
    I = readimage(imdsReference, i);
    [~, ~, erreur] = inspectImage(I, [], netCAE, 'bottle');
    cartesSaines(:, :, i) = imfilter(erreur, ones(3, 3) / 9, 'replicate');
end

% Tolérance par pixel : moyenne des erreurs saines et deux écarts-types.
reference = mean(cartesSaines, 3) + 2 * std(cartesSaines, 1, 3);
fprintf('Bottle - carte de référence calculée sur %d images train/good.\n', nbReference);
clear cartesSaines

%% 3 - Scores et temps de traitement des images de test
imdsBottle = imageDatastore(fullfile(racineBottle, 'test'), 'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames', 'FileExtensions', '.png');

nbImages = numel(imdsBottle.Files);
scores = zeros(nbImages, 1);
scoresLocaux = zeros(nbImages, 1);
temps = zeros(nbImages, 1);
inspectImage(readimage(imdsBottle, 1), [], netCAE, 'bottle', reference);

for i = 1:nbImages
    I = readimage(imdsBottle, i);
    debut = tic;
    [~, scores(i), ~, ~, erreur] = inspectImage(I, [], netCAE, 'bottle', reference);
    temps(i) = toc(debut);
    scoresLocaux(i) = score_bouteille(erreur, []);
end

%% 4 - Calibration sur des bouteilles saines puis validation
idxSaines = find(imdsBottle.Labels == 'good');
idxDefauts = find(imdsBottle.Labels ~= 'good');
assert(numel(idxSaines) >= 3 && ~isempty(idxDefauts), ...
    'Il faut au moins trois images good et une image defectueuse.');

% Tirage reproductible. Les images de calibration sont exclues des taux.
rng(0);
idxSaines = idxSaines(randperm(numel(idxSaines)));
nbCalibration = floor(numel(idxSaines) / 3);
idxCalibration = idxSaines(1:nbCalibration);
idxSainesTest = idxSaines(nbCalibration+1:end);

% Avec peu d'images, prendre le plus grand score sain de calibration.
seuil = max(scores(idxCalibration));


fauxRejets = nnz(scores(idxSainesTest) > seuil);
faussesAcceptations = nnz(scores(idxDefauts) <= seuil);
FRR = 100 * fauxRejets / numel(idxSainesTest);
FAR = 100 * faussesAcceptations / numel(idxDefauts);

% Comparer les deux mesures sur les memes images, avec des seuils distincts.
seuilLocal = max(scoresLocaux(idxCalibration));
FRRlocal = 100 * mean(scoresLocaux(idxSainesTest) > seuilLocal);
FARlocal = 100 * mean(scoresLocaux(idxDefauts) <= seuilLocal);
fprintf('Score local précédent - FRR : %.2f %% | FAR : %.2f %%\n', FRRlocal, FARlocal);

fprintf('Score avec référence - seuil calibre sur %d images saines : %.5f\n', nbCalibration, seuil);
fprintf('Bottle - temps moyen de traitement sur %d images : %.4f s\n', nbImages, mean(temps));
fprintf('FRR : %.2f %% (%d/%d)\n', FRR, fauxRejets, numel(idxSainesTest));
fprintf('FAR : %.2f %% (%d/%d)\n', FAR, faussesAcceptations, numel(idxDefauts));

reel = [false(numel(idxSainesTest), 1); true(numel(idxDefauts), 1)];
predit = scores([idxSainesTest; idxDefauts]) > seuil;
categoriesBottle = {'Saine', 'Defectueuse'};
figure;
confusionchart(categorical(double(reel), [0 1], categoriesBottle), ...
    categorical(double(predit), [0 1], categoriesBottle));
title('Bottle - score avec référence, validation hors calibration');

modeleSHA256 = empreinte_modele(fullfile(dossierProjet, 'netCAE.mat'));
save(fullfile(dossierProjet, 'calibrationBottleReference.mat'), ...
    'seuil', 'reference', 'modeleSHA256');
