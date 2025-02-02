using CSV
using DataFrames
using Plots

gr()  # Choisir le backend GR

# Charger les résultats à partir du fichier CSV
function load_results(file_path::String)
    df = CSV.read(file_path, DataFrame)
    return df
end

# Générer le graphique
function generate_graph(df::DataFrame)
    # Créer un graphique pour le temps de réponse
    p1 = plot(df[!, 1], df[!, 2], 
        xlabel="Taille du message (octets)", 
        ylabel="Temps pris (s)", 
        title="Temps de réponse en fonction de la taille du message", 
        label="Temps de réponse", 
        legend=:topright,
        marker=:circle,
        color=:blue)

    # Créer un graphique pour le débit
    p2 = plot(df[!, 1], df[!, 3], 
        ylabel="Débit (messages par seconde)", 
        label="Débit", 
        color=:red)

    # Combiner les graphiques
    plot!(p1, p2)

    # Afficher le graphique
    display(p1)
end

# Main
function main()
    file_path = "results_moyennes.csv"  
    df = load_results(file_path)
    generate_graph(df)
end

main()
savefig("temps_de_reponse_debit.png")  # Sauvegarder le graphique sous forme d'image