function empreinte = empreinte_modele(fichier)
% Identifie le modèle par son contenu, indépendamment de la date de copie.

    fid = fopen(fichier, 'rb');
    if fid == -1
        error('Impossible de lire le modèle %s.', fichier);
    end
    fermeture = onCleanup(@() fclose(fid));
    octets = fread(fid, Inf, '*int8');
    sha = java.security.MessageDigest.getInstance('SHA-256');
    sha.update(octets);
    empreinte = lower(reshape(dec2hex(typecast(sha.digest(), 'uint8'), 2).', 1, []));
end
