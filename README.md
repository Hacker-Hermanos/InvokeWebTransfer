# InvokeWebTransfer: Bash Script for File Transfer Command Generation

## Description

This project provides a Bash script, InvokeWebTransfer.sh, designed to generate file transfer commands for various methods (bitsadmin, certutil, PowerShell's Invoke-WebRequest, and .Net.WebClient) based on files within a specified webroot directory (default is /var/www/html). It supports multiple flags for customizing the output based on the user's needs.

## Features

- Generates file transfer commands for different utilities.
- Supports bitsadmin, certutil, Invoke-WebRequest, and Net.WebClient.
- Option to specify network interface, IP address, port, and webroot path.
- Sorts the output commands for easy readability.

## Prerequisites

- Bash environment

## Usage

```bash
./script_name.sh [options]
```

### Options

- `-b, --bitsadmin` Use bitsadmin for file transfers.
- `-c, --cradle` Use cradle mode for PowerShell (iwr or webclient).
- `-cu, --certutil` Use certutil for file transfers.
- `-i, --ip IP` Specify the IP address or hostname.
- `-n, --network IFACE` Specify the network interface.
- `-p, --port PORT` Specify the port (default is 80).
- `-s, --silent` Silent mode, do not print banner.
- `-w, --webroot PATH` Specify the webroot path.
- `-wc, --webclient` Use webclient for file transfers.
- `-h, --help` Display the help message and exit.

### Example

```bash
./script_name.sh -n eth0 -w /var/www/html -cu
```

This command generates certutil-based file transfer commands for files in `/var/www/html`, using the `eth0` network interface's IP address.

## Installation

1. Clone the repository or download the script.
2. Make the script executable: `chmod +x script_name.sh`.
3. Run the script with desired options.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute to the project.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.
