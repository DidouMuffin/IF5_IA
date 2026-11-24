function [score, carte] = score_bouteille(erreur, reference)
% Score local : moyenne du 1 % des erreurs les plus élevées.

    carte = erreur;
    if ~isempty(reference)
        erreurLissee = imfilter(erreur, ones(3, 3) / 9, 'replicate');
        carte = max(erreurLissee - reference, 0);

        % Masquer le cadre de l'image et le retirer du calcul du score.
        marge = 4;
        interieur = carte(1+marge:end-marge, 1+marge:end-marge);
        carte = zeros(size(carte), 'like', carte);
        carte(1+marge:end-marge, 1+marge:end-marge) = interieur;
    else
        interieur = carte;
    end

    erreursTriees = sort(interieur(:), 'descend');
    nbPixels = ceil(0.01 * numel(erreursTriees));
    score = mean(erreursTriees(1:nbPixels));
end
