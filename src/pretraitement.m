% Pretraiter une image I deja chargee.
% Si I est absente, selectionner une image pour executer le script seul.
if ~exist('I', 'var') || isempty(I)
    [fichier, dossier] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif', 'Images'});
    if isequal(fichier, 0)
        return;
    end
    I = imread(fullfile(dossier, fichier));
end

if size(I, 3) == 3
    Igray = rgb2gray(I);
else
    Igray = I;
end

Ifilt = medfilt2(Igray, [3 3], 'symmetric');
Iresize = imresize(Ifilt, [224 224]);

figure;
imshowpair(Igray, Iresize, 'montage');
title('Image initiale / Filtre median et redimensionnement');
