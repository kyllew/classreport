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

1. Python 3.8 or higher
2. AWS account with Bedrock access
3. AWS CLI configured with appropriate credentials
4. Required Python packages (see requirements.txt)

## Installation

1. Clone the repository:
```bash
git clone github.com/yourusername/classreport.git](https://github.com/kyllew/classreport.git
cd classreport
```

2. Create and activate a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install required packages:
```bash
pip install -r requirements.txt
```

4. Configure AWS credentials:
```bash
aws configure
```

Enter your AWS credentials when prompted:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (use 'us-east-1' for Bedrock)
- Default output format (json)

## Project Structure

```
class-report-calculator/
├── CsatAnalyser/
│   ├── __init__.py
│   ├── main.py
│   └── templates/
│       └── index.html
├── requirements.txt
└── README.md
```

## Required Packages

Create a `requirements.txt` file with the following dependencies:
```
flask==2.0.1
pandas==1.3.3
boto3==1.28.0
python-dotenv==0.19.0
```

## Usage

1. Start the Flask application:
```bash
python -m flask run
```

2. Open your web browser and navigate to:
```
http://localhost:5000
```

3. Upload your CSV file containing course feedback data. The file should include the following columns:
   - QID1, QID2 (Overall Satisfaction)
   - QID127, QID128, QID129 (Instructor metrics)
   - QID31, QID67, QID32 (Content metrics)
   - QID58, QID59 (ILT Classroom metrics)
   - QID130, QID59 (VILT Classroom metrics)
   - QID138_TEXT (Improvement recommendations)
   - QID142_TEXT (Positive feedback)

## CSV Format Requirements

Your CSV file should contain the following columns:
```
QID1,QID2,QID127,QID128,QID129,QID31,QID67,QID32,QID58,QID59,QID130,QID138_TEXT,QID142_TEXT
5,4,5,5,4,...
```

## Rating Scale

The application expects ratings on a 5-point scale:
- 5: Strongly Agree / Extremely Satisfied
- 4: Agree / Satisfied
- 3: Neutral
- 2: Disagree / Dissatisfied
- 1: Strongly Disagree / Extremely Dissatisfied

## Deployment

For production deployment:

1. Set up proper security measures:
```python
# In your Flask application
app.config['SECRET_KEY'] = 'your-secret-key'
```

2. Use a production-grade server:
```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:8000 "CsatAnalyser:create_app()"
```

## Contributing

1. Fork the repository

2. Create your feature branch:
```bash
git checkout -b feature/new-feature
```

3. Commit your changes:
```bash
git commit -am 'Add new feature'
```

4. Push to the branch:
```bash
git push origin feature/new-feature
```

5. Submit a pull request

## Security Notes

- Never commit AWS credentials to the repository
- Use environment variables for sensitive information
- Implement proper input validation
- Set up CORS policies for production
- Regularly update dependencies

## GitHub Upload Instructions

1. Create a new repository on GitHub

2. Initialize git in your local project:
```bash
git init
```

3. Add your files:
```bash
git add .
```

4. Create initial commit:
```bash
git commit -m "Initial commit"
```

5. Add remote repository:
```bash
git remote add origin github.com/yourusername/class-report-calculator.git
```

6. Push to GitHub:
```bash
git push -u origin main
```

## .gitignore File

Create a `.gitignore` file with the following content:
```
# Python
__pycache__/
*.py[cod]
*$py.class
venv/
.env

# IDE
.vscode/
.idea/

# AWS
.aws/

# Logs
*.log

# Uploaded files
uploads/

# System
.DS_Store
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- AWS Bedrock for AI capabilities
- Flask framework
- Bootstrap for UI components
