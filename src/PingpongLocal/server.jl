using Sockets

const HOST = "127.0.0.1"
const PORT = 2000

function start_server()
    # Conversion de l'adresse IP en IPAddr
    server = listen(parse.(IPAddr, [HOST])[1], PORT)
    println("Server listening on $HOST:$PORT")
    
    while true
        client = accept(server)
        @async handle_client(client)
    end
end

function handle_client(client::TCPSocket)
    try
        # Lire le message envoyé par le client
        message = readavailable(client)
        # S'assurer que tout le message est reçu
        println("Message received: $(String(message))")
        
        # Envoyer un pong de taille 1
        send_pong(client)
    finally
        close(client)
    end
end

function send_pong(client::TCPSocket)
    pong = "Pong"  # Message de taille 1
    write(client, pong)
    flush(client)
end

start_server()
