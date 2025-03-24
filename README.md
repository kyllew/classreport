# Class Report Calculator

A web application that analyzes course feedback data and generates comprehensive reports including CSAT scores and AI-powered feedback summaries using AWS Bedrock.

## Features

- Calculate Overall Satisfaction scores
- Generate Instructor CSAT metrics
- Analyze Content and Classroom feedback
- AI-powered feedback summarization using AWS Bedrock
- Clean, responsive web interface
- Support for both ILT and VILT course formats

## Prerequisites

- Python 3.8 or higher
- AWS account with Bedrock access
- AWS CLI configured with appropriate credentials

## Installation and Setup

### MacBook (macOS)

1. **Install Python**
   ```bash
   # Install Homebrew (if not already installed)
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

   # Install Python
   brew install python
   ```

2. **Clone the Repository**
   ```bash
   git clone https://github.com/kyllew/classreport.git
   cd classreport
   ```

3. **Create Virtual Environment**
   ```bash
   python3 -m venv wenv
   source wenv/bin/activate
   ```

4. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

5. **Configure AWS Credentials**
   ```bash
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Default region (us-east-1)
   # Default output format (json)
   ```

6. **Run the Application**
   ```bash
   # Set Flask application
   export FLASK_APP=main
   # Optional: Enable debug mode
   export FLASK_DEBUG=1
   # Run Flask
   python3 -m flask run
   
   # Alternative command:
   python3 -m flask --app main run
   ```

### Windows

1. **Install Python**
   - Download Python from [python.org](https://www.python.org/downloads/windows/)
   - During installation, check "Add Python to PATH"

2. **Install Git** (if not already installed)
   - Download from [git-scm.com](https://git-scm.com/download/win)

3. **Open Command Prompt or PowerShell**
   ```powershell
   # Clone the Repository
   git clone https://github.com/kyllew/classreport.git
   cd classreport

   # Create Virtual Environment
   python -m venv wenv
   wenv\Scripts\activate

   # Install Dependencies
   pip install -r requirements.txt
   ```

4. **Configure AWS Credentials**
   ```powershell
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Default region (us-east-1)
   # Default output format (json)
   ```

5. **Run the Application**
   ```powershell
   # Set Flask application
   $env:FLASK_APP = "main"
   # Optional: Enable debug mode
   $env:FLASK_DEBUG = "1"
   # Run Flask
   python -m flask run
   
   # Alternative command:
   python -m flask --app main run
   ```

## Project Structure

```
classreport/
├── main.py                 # Main Flask application
├── requirements.txt        # Python dependencies
├── README.md              # Project documentation
├── templates/             # HTML templates
│   └── index.html         # Main interface template
└── uploads/              # Directory for uploaded files
```

## Required Packages

Current dependencies in `requirements.txt`:
```
numpy==1.24.3
pandas==2.0.3
flask==2.3.2
boto3==1.28.0
python-dotenv==1.0.0
openpyxl==3.1.2
gunicorn==20.1.0
requests==2.31.0
jinja2==3.1.2
markupsafe==2.1.3
```

## Usage

1. Start the Flask application:
```bash
python -m flask --app main run
```

2. Open your web browser and navigate to:
http://localhost:5000

3. Upload your CSV file containing course feedback data. The file should include the following columns:
   - QID1, QID2 (Overall Satisfaction)
   - QID127, QID128, QID129 (Instructor metrics)
   - QID31, QID67, QID32 (Content metrics)
   - QID58, QID59 (ILT Classroom metrics)
   - QID130, QID59 (VILT Classroom metrics)
   - QID138_TEXT (Improvement recommendations)
   - QID142_TEXT (Positive feedback)

## Troubleshooting

### Common Issues

1. **Flask Application Not Found**
   - Ensure you're in the correct directory
   - Use `python -m flask --app main run`
   - Or set environment variable: `export FLASK_APP=main` (Mac/Linux) or `$env:FLASK_APP = "main"` (Windows)

2. **NumPy/Pandas Compatibility Issues**
   If you encounter a "numpy.dtype size changed" error:
   ```bash
   # Deactivate and remove existing environment
   deactivate
   rm -rf wenv
   
   # Create new environment and install packages in correct order
   python3 -m venv wenv
   source wenv/bin/activate
   pip install --upgrade pip setuptools wheel
   pip install numpy==1.24.3
   pip install pandas==2.0.3
   pip install -r requirements.txt
   ```

3. **AWS Credentials**
   - Ensure your AWS IAM user has Bedrock access
   - Verify credentials are correctly configured
   - Check region matches Bedrock service region

4. **Python/Dependencies**
   - Confirm Python version: `python --version`
   - Ensure virtual environment is activated
   - Try reinstalling dependencies: `pip install -r requirements.txt`

5. **Virtual Environment**
   - Mac/Linux: `source wenv/bin/activate`
   - Windows: `wenv\Scripts\activate`
   - Verify activation: `which python` or `where python`

## Security Notes

- Never commit AWS credentials to the repository
- Use environment variables for sensitive information
- Implement proper input validation
- Set up CORS policies for production
- Regularly update dependencies

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- AWS Bedrock for AI capabilities
- Flask framework
- Bootstrap for UI components
