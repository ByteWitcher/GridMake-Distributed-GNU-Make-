# GridMake

This project involves the development of a distributed version of GNU Make, implemented in Julia and deployed on Grid'5000, a large-scale testbed for distributed and parallel computing. GNU Make is a widely used build automation tool, but its traditional implementation is not optimized for distributed execution across multiple nodes. Our solution enhances parallelization and efficiency by leveraging Julia's high-performance computing capabilities to distribute build tasks across a computing cluster.

## Installation

To use `gridmake`, add the `src/Command` directory to your PATH:

1. Open your `.bashrc` file:

```
nano ~/.bashrc
```

2. Add the following line at the end of the file:

```
export PATH="$PATH:/path/to/repository/src/Command"
```

Replace `/path/to/repository` with the actual path to the repository.

3. Save the file and exit the editor.

4. Apply the changes:

```
source ~/.bashrc
```

5. Make the `gridmake` command executable:

```
chmod u+x /path/to/repository/src/Command/gridmake
```

Replace `/path/to/repository` with the actual path to the repository.

## Usage

1. Create a directory for your `Makefile`:

```
mkdir mydir
```

2. Place your `Makefile` and its dependencies inside this directory.

3. Move to the newly created directory:

```
cd mydir
```

4. Execute `gridmake`:

```
gridmake
```

5. Wait for `gridmake` to process your `Makefile`.
