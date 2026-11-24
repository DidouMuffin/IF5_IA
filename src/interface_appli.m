
function interface_appli

    %% Initialisation

    imgOrigine = [];
    imgProcess = [];
    netTL = [];

    % Chemin du projet
    dossierSrc = fileparts(mfilename('fullpath'));
    dossierProjet = fileparts(dossierSrc);


    %% Creation de la fenetre

    fig = figure( ...
        'Name', 'Systeme de Detection de Defauts - PoitouTech Automation', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'ToolBar', 'none', ...
        'Position', [100 100 1100 700], ...
        'Color', [0.94 0.94 0.94]);


    %% Titre de l'interface

    uicontrol('Parent', fig, ...
        'Style', 'text', ...
        'String', 'SYSTEME INTEGRE DE DETECTION DE DEFAUTS', ...
        'Position', [50 650 1000 40], ...
        'FontSize', 16, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', [0.94 0.94 0.94]);


    %% Zones d'affichage

    axOrigine = axes('Parent', fig, ...
        'Units', 'pixels', ...
        'Position', [50 250 450 350], ...
        'Box', 'on');

    title(axOrigine, 'IMAGE ORIGINALE');
    axis(axOrigine, 'image');


    axProcess = axes('Parent', fig, ...
        'Units', 'pixels', ...
        'Position', [550 250 450 350], ...
        'Box', 'on');

    title(axProcess, 'IMAGE TRAITEE / ANALYSEE');
    axis(axProcess, 'image');


    %% Panneau de traitement

    uipanel('Parent', fig, ...
        'Title', 'Traitement d''Image', ...
        'Position', [0.03 0.1 0.45 0.15], ...
        'BackgroundColor', [0.9 0.95 1]);


    %% Bouton de chargement

    uicontrol('Parent', fig, ...
        'Style', 'pushbutton', ...
        'String', 'Charger Image', ...
        'Position', [60 90 140 35], ...
        'Callback', @onLoadImage);


    %% Menu des filtres

    uicontrol('Parent', fig, ...
        'Style', 'text', ...
        'String', 'Filtre :', ...
        'Position', [220 110 100 20], ...
        'BackgroundColor', [0.9 0.95 1]);

    popFilter = uicontrol('Parent', fig, ...
        'Style', 'popupmenu', ...
        'String', {'Moyenneur 3x3', ...
                   'Gaussien 5x5', ...
                   'Median 3x3', ...
                   'Sobel', ...
                   'Prewitt', ...
                   'Canny'}, ...
        'Position', [220 90 120 25], ...
        'Value', 1);


    %% Bouton appliquer filtre

    uicontrol('Parent', fig, ...
        'Style', 'pushbutton', ...
        'String', 'Appliquer Filtre', ...
        'Position', [350 90 120 35], ...
        'Callback', @onApplyFilter);


    %% Slider du gaussien

    uicontrol('Parent', fig, ...
        'Style', 'text', ...
        'String', 'Sigma du filtre gaussien :', ...
        'Position', [60 135 160 20], ...
        'BackgroundColor', [0.9 0.95 1]);

    lblParam = uicontrol('Parent', fig, ...
        'Style', 'text', ...
        'String', '1.00', ...
        'Position', [465 135 50 20], ...
        'BackgroundColor', [0.9 0.95 1]);

    sldParam = uicontrol('Parent', fig, ...
        'Style', 'slider', ...
        'Position', [220 140 250 20], ...
        'Min', 0.5, ...
        'Max', 2.5, ...
        'Value', 1, ...
        'Callback', @(src, ~) set(lblParam, 'String', ...
            sprintf('%.2f', get(src, 'Value'))));


    %% Classification par IA - NOUVEAU

    % Bouton de classification
    uicontrol('Parent', fig, ...
        'Style', 'pushbutton', ...
        'String', 'Classifier avec IA', ...
        'Position', [735 85 240 40], ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'Callback', @onClassifyImage);


    %% Zones d'informations

    lblResultat = uicontrol('Parent', fig, ...
        'Style', 'text', ...
        'String', 'Aucune classification', ...
        'Position', [550 185 480 25], ...
        'FontSize', 11, ...
        'FontWeight', 'bold', ...
        'BackgroundColor', [0.94 0.94 0.94]);

    lblConfiance = uicontrol('Parent', fig, ...
        'Style', 'text', ...
        'String', 'Confiance : ---', ...
        'Position', [550 145 480 25], ...
        'FontSize', 10, ...
        'BackgroundColor', [0.94 0.94 0.94]);

    statusBar = uicontrol('Parent', fig, ...
        'Style', 'text', ...
        'String', 'En attente de chargement...', ...
        'Position', [50 15 1000 30], ...
        'ForegroundColor', [1 1 1], ...
        'BackgroundColor', [0.3 0.3 0.3]);


    %% Fonction : Chargement d'une image

    function onLoadImage(~, ~)

        [file, path] = uigetfile( ...
            {'*.png;*.jpg;*.jpeg;*.bmp;*.tiff;*.tif', ...
            'Fichiers images'}, ...
            'Selectionnez une image');

        if isequal(file, 0)
            return;
        end

        % Lecture
        img = imread(fullfile(path, file));

        % Niveaux de gris
        if size(img, 3) == 3
            imgGray = rgb2gray(img);
        else
            imgGray = img;
        end

        imgOrigine = imgGray;
        imgProcess = imgGray;

        % Affichage
        imshow(imgOrigine, 'Parent', axOrigine);
        title(axOrigine, 'IMAGE ORIGINALE');

        imshow(imgProcess, 'Parent', axProcess);
        title(axProcess, 'IMAGE TRAITEE / ANALYSEE');

        % Informations
        set(statusBar, ...
            'String', ['Image chargee : ', file], ...
            'BackgroundColor', [0.2 0.6 0.2]);

        set(lblResultat, ...
            'String', 'Image prete pour analyse');

        set(lblConfiance, ...
            'String', 'Confiance : ---');

    end


    %% Fonction : Application des filtres

    function onApplyFilter(~, ~)

        if isempty(imgOrigine)
            warndlg('Veuillez charger une image.', ...
                'Aucune image');
            return;
        end

        img = imgOrigine;
        val = get(popFilter, 'Value');
        param = get(sldParam, 'Value');

        switch val

            case 1 % Moyenneur
                h = fspecial('average', [3 3]);
                imgF = imfilter(img, h, 'replicate');
                filtreNom = 'Moyenneur 3x3';

            case 2 % Gaussien
                h = fspecial('gaussian', [5 5], param);
                imgF = imfilter(img, h, 'replicate');
                filtreNom = 'Gaussien 5x5';

            case 3 % Median
                imgF = medfilt2(img, [3 3], 'symmetric');
                filtreNom = 'Median 3x3';

            case 4 % Sobel
                imgF = edge(img, 'sobel');
                filtreNom = 'Sobel';

            case 5 % Prewitt
                imgF = edge(img, 'prewitt');
                filtreNom = 'Prewitt';

            case 6 % Canny
                imgF = edge(img, 'canny');
                filtreNom = 'Canny';

        end

        imgProcess = imgF;

        imshow(imgProcess, 'Parent', axProcess);
        title(axProcess, ['FILTRE : ', filtreNom]);

        set(statusBar, ...
            'String', ['Filtre applique : ', filtreNom]);

    end


    %% Fonction : Classification ResNet-18 - NOUVEAU

    function onClassifyImage(~, ~)

        % Verification de l'image
        if isempty(imgOrigine)
            warndlg('Veuillez charger une image.', ...
                'Aucune image');
            return;
        end

        % Chargement du reseau
        if isempty(netTL)

            fichierReseau = fullfile( ...
                dossierProjet, 'netTL.mat');

            if ~isfile(fichierReseau)
                errordlg('Fichier netTL.mat introuvable.', ...
                    'Erreur');
                return;
            end

            donnees = load(fichierReseau, 'netTL');
            netTL = donnees.netTL;

        end

        % Preparation de l'image
        img224 = imresize(imgOrigine, [224 224]);

        % Conversion en 3 canaux
        if size(img224, 3) == 1
            img224 = repmat(img224, [1 1 3]);
        end

        % Classification
        [classe, scores] = classify(netTL, img224);

        % Score de confiance du reseau
        confiance = max(scores) * 100;

        % Affichage du resultat
        set(lblResultat, 'String', ...
            ['Defaut reconnu : ', char(classe)]);

        set(lblConfiance, 'String', ...
            sprintf('Confiance : %.2f %%', confiance));

        set(statusBar, 'String', ...
            'Classification terminee');

    end

end
