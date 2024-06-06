using DelimitedFiles, JuMP, HiGHS


function parse_instance(filename)
    instance = replace(readdlm(filename), "CIBLE" => 1, "OBSTACLE" => 2)
    grille = zeros(Int, instance[1, 2], instance[2, 2])
    for (object, x, y) ∈ eachrow(instance)[3:end]
        grille[x+1, y+1] = object
    end
    return grille
end

function is_visible(x_cible, y_cible, x_surv, y_surv, g)
    if g[x_surv, y_surv] == 2 # Le surveillant est sur un obstacle
        return false
    elseif (x_cible, y_cible) == (x_surv, y_surv)
        return true # le surveillant et la cible sont sur la même case
    end

    Δx = x_cible - x_surv
    Δy = y_cible - y_surv

    if Δx == 0 # Sur une même ligne
        δy = sign(Δy)
        return all([g[x_surv, j] != 2 for j ∈ y_surv+δy:δy:y_cible-δy])

    elseif Δy == 0 # Sur une même colonne
        δx = sign(Δx)
        return all([g[i, y_surv] != 2 for i ∈ x_surv+δx:δx:x_cible-δx])
    end

    return false # La cible et le surveillant sont sur des lignes et colonnes différentes
end

function solve(g)
    m = Model(HiGHS.Optimizer)
    set_silent(m)
    @variable(m, surv[axes(g, 1), axes(g, 2)], Bin)
    for i ∈ axes(g, 1), j ∈ axes(g, 2)
        if g[i, j] == 1 # pour chaque cible
            @constraint(m, sum(surv[x, y] for x in axes(g, 1), y in axes(g, 2)
                               if is_visible(i, j, x, y, g) && g[x, y] != 2) >= 1)
        end
    end

    @objective(m, Min, sum(surv[i, j] for i in axes(g, 1), j in axes(g, 2)))
    optimize!(m)
    println("Nb de surveillants : ", round(Int, objective_value(m)))
    return round.(Int, value.(surv))
end

function write_submission(sol, n_instance)
    filepath = "./Submissions/sol" * string(n_instance) * ".txt"
    io = open(filepath, "w")
    write(io, "EQUIPE nom_equipe\nINSTANCE " * string(n_instance) * "\n")
    for x ∈ axes(sol, 1), y ∈ axes(sol, 2)
        if sol[x, y] == 1
            write(io, "$(x-1) $(y-1)\n")
        end
    end
    close(io)
end


@time for n ∈ 1:16
    grille = parse_instance("./Instances/gr" * string(n) * ".txt")
    solution = solve(grille)
    write_submission(solution, n)
end

#=
34.587726 seconds (2.19 M allocations: 131.601 MiB, 
0.11% gc time, 3.26% compilation time: 12% of which was recompilation)
=#
