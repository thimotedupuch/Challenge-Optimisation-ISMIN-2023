using JuMP, HiGHS

"Renvoie un booléen indiquant si la case cible positionnée 
à l'emplacement (x_cible,y_cible) est visible par le surveillant
positionné à l'emplacement (x_surv,y_surv) sur la grille."
function is_visible(x_cible, y_cible, x_surv, y_surv, grille)
    if grille[x_surv, y_surv] == 2  # Le surveillant est sur un obstacle
        return false
    end

    Δx = x_cible - x_surv
    Δy = y_cible - y_surv
    
    if Δx == 0 && Δy == 0 # le surveillant et la cible sont sur la même case
        return true
    end

    # Vérification sur une seule ligne
    if Δx == 0
        δy = sign(Δy)
        for j in y_surv+δy:δy:y_cible-δy
            if grille[x_surv, j] == 2  # Il y a un obstacle sur la ligne
                return false
            end
        end
        return true
    end

    # Vérification sur une seule colonne
    if Δy == 0
        δx = sign(Δx)
        for i in x_surv+δx:δx:x_cible-δx
            if grille[i, y_surv] == 2  # Il y a un obstacle sur la colonne
                return false
            end
        end
        return true
    end

    return false  # Les cases cible et surveillant sont sur des lignes et colonnes différentes
end

assign(object) = object == "CIBLE" ? 1 : 2 # si ce n'est pas une cible, c'est un obstacle


"Lis un fichier d'instance et renvoie la grille correspondante."
function parse_instance_file(filename)
    file = open(filename)
    lines = readlines(file)

    nb_lignes_fichier = size(lines)[1]
    nb_lignes = parse(Int,lines[1][end-1:end])
    nb_colonnes = parse(Int,lines[2][end-1:end])

    grille = zeros(nb_lignes,nb_colonnes)

    for i ∈ 4:nb_lignes_fichier # les 3 premières lignes sont sautées
        line = lines[i]
        parts = split(line)
        objet = parts[1]
        x = parse(Int,parts[2]) + 1
        y = parse(Int,parts[3]) + 1

        int_objet = assign(objet)
        grille[x,y] = int_objet
    end

    return grille
end


"Configure le modèle en ajoutant les variables de décision, les contraintes et l'objectif."
function configure(model,grille)
    nb_lignes, nb_colonnes = size(grille)
    set_silent(model) # Supprime les messages d'optimisation qui s'affichent
    # Variables de décision
    @variable(model, surveillant[1:nb_lignes, 1:nb_colonnes], Bin)

    # Contrainte : Chaque cible doit être surveillée (au moins une fois)
    for i in 1:nb_lignes
        for j in 1:nb_colonnes
            if grille[i, j] == 1 # Si c'est une cible 
                @constraint(model, 
                sum(surveillant[x, y] for x in 1:nb_lignes, y in 1:nb_colonnes
                if is_visible(i, j, x, y, grille) && grille[x, y] != 2) >= 1)
            end
        end
    end

    # Objectif: Minimiser le nombre de surveillants
    @objective(model, Min, sum(surveillant[i, j] for i in 1:nb_lignes, j in 1:nb_colonnes))
end
