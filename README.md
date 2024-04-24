# Scripts Repository
Welcome to my personal repository for scripts that I use on a daily basis in Linux Bash and Python!

# Usage
Feel free to explore the scripts in this repository. You can use them as they are or modify them to suit your needs.

# How to Use
To use these scripts:
Clone this repository to your local machine:
```bash
git clone https://github.com/yourusername/your-repo.git
```

Navigate to the repository directory:
```bash
cd scripting
```

Run the scripts using the appropriate command:
```bash
# For Linux bash scripts
chmod +x ./script1.sh
./script1.sh
```
```bash
python script2.py
```

Make sure to check the script comments for any additional instructions or dependencies.

# Installation
## AWS CLI
To install the AWS Command Line Interface (CLI), follow these steps:

Ensure you have Python installed on your system. If not, follow the instructions below for Python installation.
Install the AWS CLI:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Verify the installation by running:
```bash
aws --version
```

Additional resource: [AWS CLI installation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

# Python
To install Python, follow these steps:

Linux: Most Linux distributions come with Python pre-installed. You can check the version using:
```bash
python --version
```

If Python is not installed, you can install it using your package manager. 

For example, on Ubuntu, you can use:
```bash
sudo apt-get update -y
sudo apt-get install -y python3
```

For example, on CentOS, you can use:
```bash
sudo yum update -y
sudo yum install -y python3
```

macOS: macOS comes with Python 2.x pre-installed. However, it's recommended to install Python 3.x for compatibility. You can use Homebrew to install Python 3:
```bash
brew install python3
```

Windows: Visit the [official Python website](https://www.python.org/downloads/) and download the installer for Windows. Run the installer and follow the on-screen instructions.

# Contributions
Contributions are welcome! If you have any improvements or additional scripts to add, feel free to open a pull request.
