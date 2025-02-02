using Distributed
using Statistics

struct Metric
    worker::Int
    data_size::Int
    rtt::Float64
    throughput::Float64
end

metrics = Metric[]

sizes = vcat(1:100,[1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576])

# Function to read hostnames and exclude the master node
function get_worker_hosts()
    worker_hosts = []
    all_hosts = ENV["OAR_NODE_FILE"]
    println("Hosts file: $all_hosts")
    master_host = strip(read(`hostname`, String))  # Get the hostname of the master node
    println("Master host: $master_host")
    open(all_hosts, "r") do f
        for line in eachline(f)
            worker_host = strip(line)
            if worker_host != master_host
                push!(worker_hosts, worker_host)
            end
        end
    end
    return unique(worker_hosts)
end

function main()
    # Fetching hostnames of other nodes
    hostnames = get_worker_hosts()
    println("Worker hosts: ", hostnames)
    
    # Add workers for each host
    println("Adding workers...")
    for host in hostnames
        try
            println("Attempting to add worker for host: $host")
            addprocs([(host, 1)], exename="/opt/julia-1.9.4/bin/julia")
            println("Worker added for host: $host")
        catch e
            println("Error adding worker for host: $host, Error: $e")
            rethrow(e)
        end
    end
    println("Workers added: ", workers())

    # Defining functions in other nodes 
    # Function to create test files in each node to eliminate NFS latency
    @everywhere function create_file(file_path::String, data_size::Int)
        data = "a" ^ (data_size * 1024)
        open(file_path, "w") do file
            write(file, data)
        end
        # Check if the file exists and is accessible
        if !isfile(file_path)
            println("The file does not exist: $file_path")
            exit(1)
        end
    end

    # Function to be executed by other nodes upon receiving ping
    @everywhere function worker_function(file_path::String)
        if file_path == ""
            return "a"
        end
        try
            return read(file_path, String)
        catch e
            println("File read error: $file_path, Error: $e")
            rethrow(e)
        end
    end
    
    # Creating test files
    for p in workers()
        for i in sizes
            file_path = "/tmp/test_file_$(i)_worker_$p.txt"
            println("Generating the file of size $i KB at worker $p...")
            @spawnat p create_file(file_path, i)
            println("File generated")
        end
    end

    # Establish TCP connections in advance to eliminate any initialization delay during subsequent operations and calculating rtt0
    rtts = Dict{Int, Float64}()
    println("\nInitiating TCP connections...")
    for p in workers()
        println("Attempting to open connection with worker $p...")
        for i in 1:25
            try
                rtt = @elapsed begin
                    fetch(@spawnat p worker_function(""))
                end
                println("Establishing connection with worker $p: RTT: $(rtt*1000) ms")
                if i == 25
                    rtts[p] = rtt
                end
            catch e
                println("Error encountered while connecting to worker $p: $e")
                rethrow(e)
            end
        end
        println("Connection successfully established with worker $p\n")
    end
    
    # Calculating average latency
    latency = 0
    for p in workers()
        latency += rtts[p]
    end
    latency /= length(workers())

    println("All TCP connection attempts completed")
    println("Average latency: $(latency*1000) ms")

    # Begin pinging operations
    println("\nPinging workers...")
    for p in workers()
        println("Worker $p is ready for Ping Pong")
        for i in sizes
            try
                rtt = @elapsed begin
                    result = fetch(@spawnat p worker_function("/tmp/test_file_$(i)_worker_$p.txt"))
                    # Writing the received data into a file
                    open("/tmp/received_test_file_$(i)_worker_$p.txt", "w") do f
                        write(f, result)
                    end
                end
                throughput = i / ((rtt - rtts[p]) * 1024)
                push!(metrics, Metric(p, i, rtt*1000, throughput))
                println("Worker $p ===> Size: $i KB, RTT: $(rtt*1000) ms, Throughput: $throughput Mbytes/s")
            catch e
                println("Error retrieving result from worker $p: $e")
                rethrow(e)
            end
        end
        println("Ping Pong completed for worker $p\n")
    end

    # Group metrics by data size (size)
    size_groups = Dict{Int, Vector{Metric}}()

    for m in metrics
        if !haskey(size_groups, m.data_size)
            size_groups[m.data_size] = []
        end
        push!(size_groups[m.data_size], m)
    end

    # Write metrics to a file
    println("Writing metrics to file...")
    open("pingpong-io-results.txt", "w") do f
        for m in metrics
            println(f, "Worker: $(m.worker), Size: $(m.data_size) KB, RTT: $(m.rtt) ms, Throughput: $(m.throughput) Mbytes/s")
        end
        
        # Write the average metrics for each size
        println(f, "\nAverage latency: $(latency*1000) ms")
        println(f, "Average metrics by size:")
        for size in sizes
            group = size_groups[size]
            avg_rtt = mean([m.rtt for m in group])
            avg_throughput = mean([m.throughput for m in group])
            println(f, "Size: $(size) KB, RTT: $(avg_rtt) ms, Throughput: $(avg_throughput) Mbytes/s")
        end
    end
    println("Metrics written to file")

end

@time main()
