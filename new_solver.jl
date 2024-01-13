using JuMP, HiGHS, Printf
include("functions.jl") # fonctions parse_instance_file, configure

for file in readdir("./Instances/")
    grille = parse_instance_file("./Instances/" * file)
    m = Model(HiGHS.Optimizer) # HiGHS.Optimizer est un solveur LP
    configure(m, grille) # configure le modèle m à partir de la grille
    optimize!(m) # résout le problème
    @printf("Instance %-9s:\t%-3d surveillants\t%s\n", 
            file, 
            round(Int, objective_value(m)),
            termination_status(m))
end
