using JuMP
using HiGHS


function is_visible(x_cible, y_cible, x_surv, y_surv, grille)
    if grille[x_surv, y_surv] == 2  # Le surveillant est sur un obstacle
        return false
    end

    dx = x_cible - x_surv
    dy = y_cible - y_surv

    if dx == 0 && dy == 0
        return true
    end

    # Vérification sur une seule ligne
    if dx == 0
        direction = sign(dy)
        for j in y_surv+direction:direction:y_cible-direction
            if grille[x_surv, j] == 2  # Il y a un obstacle sur la ligne
                return false
            end
        end
        return true
    end

    # Vérification sur une seule colonne
    if dy == 0
        direction = sign(dx)
        for i in x_surv+direction:direction:x_cible-direction
            if grille[i, y_surv] == 2  # Il y a un obstacle sur la colonne
                return false
            end
        end
        return true
    end

    return false  # Les cases cible et surveillant ne sont ni sur une ligne, ni sur une colonne
end

f = open("Instances/gr16.txt","r") 
lines = readlines(f)

nb_lignes_fichier = size(lines)[1]

nb_lignes = parse(Int,lines[1][end-1:end])
nb_colonnes = parse(Int,lines[2][end-1:end])

# 0 -> il n'y a rien sur la case
# 1 -> il y a une cible
# 2 -> il y a un obstacle

grille = zeros(nb_lignes,nb_colonnes)

function assign(objet)
    if objet == "CIBLE"
        return 1
    else objet == "OBSTACLE"
        return 2
    end
end

assign("CIBLE")
assign("OBSTACLE")


for i in 4:size(lines)[1] # 1ère, 2ème et 3èeme lignes inutiles
    line = lines[i]
    parts = split(line)
    objet = parts[1] # objet est 
    x = parse(Int,parts[2]) + 1
    y = parse(Int,parts[3]) + 1

    int_objet = assign(objet)
    grille[x,y] = int_objet
end

m = Model(HiGHS.Optimizer)

# Variables de décision
@variable(m, surveillant[1:nb_lignes, 1:nb_colonnes], Bin)

# Contrainte 1: Chaque cible doit être surveillée (au moins une fois)
for i in 1:nb_lignes
    for j in 1:nb_colonnes
        if grille[i, j] == 1 # Si c'est une cible 
            @constraint(m, sum(surveillant[x, y] for x in 1:nb_lignes, y in 1:nb_colonnes 
                        if is_visible(i, j, x, y, grille) && grille[x, y] != 2) >= 1)
        end
    end
end


# Objectif: Minimiser le nombre de surveillants
@objective(m, Min, sum(surveillant[i, j] for i in 1:nb_lignes, j in 1:nb_colonnes))

# limite de temps
set_time_limit_sec(m, 180.0)


# Résolution du modèle
optimize!(m)
    


# Affichage des positions des surveillants


resultats_optim = []

println("Surveillants positionnés:",objective_value(m))
for i in 1:nb_lignes
    for j in 1:nb_colonnes
        if value(surveillant[i, j]) > 0.5
            push!(resultats_optim,(i-1,j-1))
        end
    end
end


println(resultats_optim)


fichier = open("Submissions/res_16.txt", "w")
write(fichier,"EQUIPE theo_thimote.jpeg")
write(fichier,"INSTANCE 16")
for resultat in resultats_optim
    x, y = resultat
    write(fichier, "$x $y\n")
end
close(fichier)
