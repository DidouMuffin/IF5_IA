function construireInspectionApp(fig)
% Construit l'interface dans la fenetre fournie par App Designer.

dossierProjet = fileparts(fileparts(mfilename('fullpath')));
imageOriginale = [];
netTL = [];
netCAE = [];

fig.Name = 'IF5 - Inspection industrielle';
fig.Position(3:4) = [1020 650];

grille = uigridlayout(fig, [4 2]);
grille.BackgroundColor = [0.95 0.96 0.98];
grille.Padding = [16 14 16 14];
grille.RowHeight = {'1x', 38, 68, 105};
grille.ColumnWidth = {'1x', '1x'};
axOriginal = uiaxes(grille);
axOriginal.Layout.Row = 1;
axOriginal.Layout.Column = 1;
title(axOriginal, 'Image originale');
axResultat = uiaxes(grille);
axResultat.Layout.Row = 1;
axResultat.Layout.Column = 2;
title(axResultat, 'Résultat');
axis(axOriginal, 'image', 'off');
axis(axResultat, 'image', 'off');

actions = uigridlayout(grille, [1 3]);
actions.Layout.Row = 2;
actions.Layout.Column = [1 2];
actions.Padding = [0 0 0 0];
uibutton(actions, 'Text', 'Charger une image', 'ButtonPushedFcn', @charger);
mode = uidropdown(actions, 'Items', {'Métal - NEU', 'Bouteille - MVTec'}, ...
    'ValueChangedFcn', @effacerResultat);
uibutton(actions, 'Text', 'Analyser avec IA', 'ButtonPushedFcn', @analyser, ...
    'FontWeight', 'bold', 'BackgroundColor', [0.14 0.30 0.52], 'FontColor', [1 1 1]);

% Bandeau unique pour la décision et les valeurs associées.
bandeau = uigridlayout(grille, [2 1]);
bandeau.Layout.Row = 3;
bandeau.Layout.Column = [1 2];
bandeau.RowHeight = {25, '1x'};
bandeau.RowSpacing = 0;
bandeau.Padding = [12 6 12 6];
resultat = uilabel(bandeau, 'FontSize', 17, 'FontWeight', 'bold');
detail = uilabel(bandeau, 'FontSize', 13, 'WordWrap', 'on');

panneau = uipanel(grille, 'Title', 'Filtres');
panneau.Layout.Row = 4;
panneau.BackgroundColor = [1 1 1];
panneau.Layout.Column = [1 2];
controles = uigridlayout(panneau, [2 3]);
controles.RowHeight = {34, '1x'};
controles.ColumnWidth = {175, 140, '1x'};
filtres = uidropdown(controles, 'Items', ...
    {'Moyenneur 3x3', 'Gaussien 5x5', 'Médian 3x3', 'Sobel', 'Prewitt', 'Canny'});
uibutton(controles, 'Text', 'Appliquer le filtre', 'ButtonPushedFcn', @filtrer);
sigma = uislider(controles, 'Limits', [0.5 2.5], 'Value', 1, ...
    'ValueChangedFcn', @(src, ~) afficherSigma(src.Value));
labelSigma = uilabel(controles, 'Text', 'Sigma gaussien 1.00');
afficherEtat('En attente d''une image', '', 'neutre');

    function afficherEtat(titre, description, etat)
        switch etat
            case 'ok'
                fond = [0.88 0.96 0.91];
                encre = [0.09 0.36 0.22];
            case 'anomalie'
                fond = [1.00 0.90 0.90];
                encre = [0.58 0.12 0.16];
            case 'attention'
                fond = [1.00 0.95 0.83];
                encre = [0.48 0.29 0.06];
            otherwise
                fond = [0.89 0.93 0.98];
                encre = [0.13 0.27 0.43];
        end
        bandeau.BackgroundColor = fond;
        resultat.FontColor = encre;
        detail.FontColor = encre;
        resultat.Text = titre;
        detail.Text = description;
    end

    function afficherImageResultat(img, titre)
        colorbar(axResultat, 'off');
        imshow(img, 'Parent', axResultat);
        colormap(axResultat, gray(256));
        title(axResultat, titre, 'Interpreter', 'none');
    end

    function afficherSigma(valeur)
        labelSigma.Text = sprintf('Sigma gaussien %.2f', valeur);
    end

    function charger(~, ~)
        [fichier, dossier] = uigetfile({ ...
            '*.png;*.jpg;*.jpeg;*.bmp;*.tiff;*.tif', 'Images'});
        if isequal(fichier, 0)
            return
        end
        try
            [img, palette] = imread(fullfile(dossier, fichier));
            if ~isempty(palette)
                img = im2uint8(ind2rgb(img, palette));
            end
            if ~ismember(size(img, 3), [1 3])
                error('Sélectionner une image RGB ou en niveaux de gris.');
            end
            imageOriginale = img;
            imshow(img, 'Parent', axOriginal);
            title(axOriginal, fichier, 'Interpreter', 'none');
            effacerResultat([], []);
        catch erreur
            afficherEtat('Impossible d''ouvrir cette image', ...
                'Vérifie le format du fichier et réessaie.', 'attention');
            uialert(fig, erreur.message, 'Lecture de l''image');
        end
    end

    function effacerResultat(~, ~)
        if isempty(imageOriginale)
            afficherEtat('En attente d''une image', '', 'neutre');
        else
            afficherImageResultat(imageOriginale, 'Image à analyser');
            afficherEtat('Image prête à analyser', '', 'neutre');
        end
    end

    function filtrer(~, ~)
        if isempty(imageOriginale)
            uialert(fig, 'Charge une image pour appliquer un filtre.', 'Filtrage');
            return
        end
        img = imageOriginale;
        if size(img, 3) == 3
            img = rgb2gray(img);
        end
        switch filtres.Value
            case 'Moyenneur 3x3'
                img = imfilter(img, fspecial('average', [3 3]), 'replicate');
            case 'Gaussien 5x5'
                img = imfilter(img, fspecial('gaussian', [5 5], sigma.Value), 'replicate');
            case 'Médian 3x3'
                img = medfilt2(img, [3 3], 'symmetric');
            otherwise
                img = edge(img, lower(filtres.Value));
        end
        afficherImageResultat(img, filtres.Value);
        afficherEtat('Filtre appliqué', filtres.Value, 'neutre');
    end

    function analyser(~, ~)
        if isempty(imageOriginale)
            uialert(fig, 'Charge une image pour lancer l''analyse.', 'Inspection');
            return
        end
        try
            if strcmp(mode.Value, 'Métal - NEU')
                if isempty(netTL)
                    modele = load(fullfile(dossierProjet, 'netTL.mat'), 'netTL');
                    netTL = modele.netTL;
                end
                [classe, ~, ~, confiance] = inspectImage(imageOriginale, netTL, [], 'NEU');
                afficherImageResultat(imageOriginale, 'Image classée');
                afficherEtat(['Métal | ' strrep(classe, '_', ' ')], ...
                    sprintf('Confiance %.2f %%', 100 * confiance), 'neutre');
            else
                if isempty(netCAE)
                    modele = load(fullfile(dossierProjet, 'netCAE.mat'), 'netCAE');
                    netCAE = modele.netCAE;
                end
                [seuil, calibre, reference] = seuil_bottle(dossierProjet);
                [~, score, carte] = inspectImage(imageOriginale, [], netCAE, 'bottle', reference);
                % Échelle adaptée à l'image, graduée en erreur quadratique.
                limite = max(double(max(carte(:))), eps);
                imshow(carte, [0 limite], 'Parent', axResultat);
                colormap(axResultat, hot(256));
                echelle = colorbar(axResultat);
                echelle.Label.String = 'Erreur quadratique';
                if isempty(reference)
                    title(axResultat, 'Carte d''erreur brute | Échelle par image');
                    nomScore = 'Score local';
                else
                    title(axResultat, 'Excès d''erreur par rapport aux bouteilles saines');
                    nomScore = 'Score avec référence';
                end

                if ~calibre
                    afficherEtat('Calibration requise', ...
                        'Lancer validation_industrielle.', 'attention');
                else
                    valeurs = sprintf('%s %.5f | Seuil %.5f', nomScore, score, seuil);
                    if score > seuil
                        afficherEtat('Bouteille | Anomalie détectée', valeurs, 'anomalie');
                    else
                        afficherEtat('Bouteille | Aucune anomalie détectée', valeurs, 'ok');
                    end
                end
            end
        catch erreur
            afficherImageResultat(imageOriginale, 'Image à analyser');
            afficherEtat('Échec de l''analyse', erreur.message, 'attention');
            uialert(fig, erreur.message, 'Inspection');
        end
    end
end
