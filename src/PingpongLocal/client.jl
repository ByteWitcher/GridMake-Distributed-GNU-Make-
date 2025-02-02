using Sockets
using Dates
using CSV
using DataFrames

const HOST = "127.0.0.1"
const PORT = 2000

results = Vector{Tuple{Int64, Float64, Float64}}()  # Créer un tableau pour stocker les résultats avec le bon type

function send_message_to_server(size::Int)
    client = connect(HOST, PORT)
    message = "A" ^ size  # Créer un message de taille N
    println("Sending message of size $size to server")
    write(client, message)
    flush(client)

    # Attendre la réponse du serveur (pong)
    pong = readavailable(client)
    println("Response from server: $(String(pong))")

    close(client)
end

function ping_pong_test(N::Int)
    t1 = now()
    send_message_to_server(N)
    t2 = now()
    # Calculate RTT
    rtt = (t2 - t1).value / 1e9  # Convert to seconds

    println("Time taken for message size $N: $rtt milliseconds")

    if N == 1
        println("RTT: $rtt seconds")
        push!(results, (N, rtt, 0.0))  # Ajouter un tuple avec zéro pour le débit
    else
        throughput = N / (rtt - (rtt / 2))
        println("Throughput: $throughput messages per second")
        push!(results, (N, rtt, throughput))  


    end
end

function save_results_to_csv(results::Vector{Tuple{Int64, Float64, Float64}})
    open("results_moyennes.csv", "w") do file
        write(file, "Message Size,Time Taken (ms),Throughput\n")
        for (size, time, throughput) in results
            write(file, "$size,$time,$throughput\n")
        end
    end
end

for size in [1, 10, 100, 1000, 10000]
    ping_pong_test(size)
end

# Sauvegarder les résultats dans le fichier CSV
save_results_to_csv(results)
