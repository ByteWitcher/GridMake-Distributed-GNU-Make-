using Distributed
using Statistics

struct Metric
    worker::Int
    data_size::Int
    rtt::Float64
    throughput::Float64
end

nfsMetrics = Metric[]
scpMetrics = Metric[]

sizes = vcat(1:100,[1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576])

# Function to read hostnames and exclude the master node
function get_worker_hosts()
    worker_hosts = []
    all_hosts = ENV["OAR_NODE_FILE"] # Contains the name of a file which lists all reserved hosts
    println("Node file: $all_hosts")
    master_host = strip(read(`hostname`, String)) # Read the hostname as a String from the master host
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

# Function to create test files
function create_file(file_path::String, data_size::Int)
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

function main()
    # Fetching hostnames of other nodes
    hostnames = get_worker_hosts()
    println("Hosts: ", hostnames)

    # Add workers for each host
    print("Adding workers... ")
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
    
    # Function to be executed by other nodes
    @everywhere function worker_function(file_path::String)
        if file_path == ""
            return "a"
        end
        try
            read(file_path, String)
        catch e
            println("File read error: $file_path, Error: $e")
            rethrow(e)
        end
    end

    # Creating test files on master to measure NFS performance
    for i in sizes
        file_path = "nfs_test_file_$i.txt"
        println("Generating the file of size $i KB...")
        create_file(file_path, i)
        println("File generated")
    end

    # Creating test files on master to measure SCP performance
    for i in sizes
        file_path = "/tmp/scp_test_file_$i.txt"
        println("Generating the file of size $i KB...")
        create_file(file_path, i)
        println("File generated")
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

    # Measuring NFS performance
    println("\nMeasuring NFS performance...")
    for p in workers()
        println("Worker $p is ready for NFS performance measurement")
        for i in sizes
            try
                rtt = @elapsed begin
                    fetch(@spawnat p worker_function("nfs_test_file_$i.txt")) 
                end
                throughput = i / ((rtt - rtts[p]) * 1024)
                push!(nfsMetrics, Metric(p, i, rtt*1000, throughput))
                println("NFS: Worker $p ===> Size: $i KB, RTT: $(rtt*1000) ms, Throughput: $throughput Mbytes/s")
            catch e
                println("Error retrieving result from worker $p: $e")
                rethrow(e)
            end
        end
        println("NFS performance measurement completed for worker $p\n")
    end

    # Measuring SCP performance
    println("Measuring SCP performance...")
    for p in workers()
        println("Worker $p is ready for SCP performance measurement")
        for i in sizes
            try
                rtt = @elapsed begin
                    run(`scp "/tmp/scp_test_file_$i.txt" "$(hostnames[p-1]):/tmp/scp_test_file_$i.txt"`)
                    fetch(@spawnat p worker_function("/tmp/scp_test_file_$i.txt"))
                end
                throughput = i / ((rtt - rtts[p]) * 1024)
                push!(scpMetrics, Metric(p, i, rtt*1000, throughput))
                println("SCP: Worker $p ===> Size: $i KB, RTT: $(rtt*1000) ms, Throughput: $throughput Mbytes/s")
            catch e
                println("Error retrieving result from worker $p: $e")
                rethrow(e)
            end
        end
        println("SCP performance measurement completed for worker $p\n")
    end

    # Group metrics by data size (size)
    nfs_size_groups = Dict{Int, Vector{Metric}}()
    scp_size_groups = Dict{Int, Vector{Metric}}()

    for m in nfsMetrics
        if !haskey(nfs_size_groups, m.data_size)
            nfs_size_groups[m.data_size] = []
        end
        push!(nfs_size_groups[m.data_size], m)
    end

    for m in scpMetrics
        if !haskey(scp_size_groups, m.data_size)
            scp_size_groups[m.data_size] = []
        end
        push!(scp_size_groups[m.data_size], m)
    end


    # Write metrics to a file
    println("Writing metrics to file...")
    open("nfs-results.txt", "w") do f
        for m in nfsMetrics
            println(f, "Worker: $(m.worker), Size: $(m.data_size) KB, RTT: $(m.rtt) ms, Throughput: $(m.throughput) Mbytes/s")
        end
        
        # Write the average metrics for each size
        println(f, "\nAverage latency: $(latency*1000) ms")
        println(f, "Average metrics by size:")
        for size in sizes
            group = nfs_size_groups[size]
            avg_rtt = mean([m.rtt for m in group])
            avg_throughput = mean([m.throughput for m in group])
            println(f, "Size: $(size) KB, RTT: $(avg_rtt) ms, Throughput: $(avg_throughput) Mbytes/s")
        end
    end
    println("NFS metrics written to file")
    open("scp-results.txt", "w") do f
        for m in scpMetrics
            println(f, "Worker: $(m.worker), Size: $(m.data_size) KB, RTT: $(m.rtt) ms, Throughput: $(m.throughput) Mbytes/s")
        end
        
        # Write the average metrics for each size
        println(f, "\nAverage latency: $(latency*1000) ms")
        println(f, "Average metrics by size:")
        for size in sizes
            group = scp_size_groups[size]
            avg_rtt = mean([m.rtt for m in group])
            avg_throughput = mean([m.throughput for m in group])
            println(f, "Size: $(size) KB, RTT: $(avg_rtt) ms, Throughput: $(avg_throughput) Mbytes/s")
        end
    end
    println("SCP metrics written to file")
end

@time main()