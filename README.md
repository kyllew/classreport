Class Report Calculator
A web application that analyzes course feedback data and generates comprehensive reports including CSAT scores and AI-powered feedback summaries using AWS Bedrock.

Features
Calculate Overall Satisfaction scores
Generate Instructor CSAT metrics
Analyze Content and Classroom feedback
AI-powered feedback summarization using AWS Bedrock
Clean, responsive web interface
Support for both ILT and VILT course formats
Prerequisites
Python 3.8 or higher
AWS account with Bedrock access
AWS CLI configured with appropriate credentials
Required Python packages (see requirements.txt)
Installation
Clone the repository:
bash
Copy code
git clone github.com/yourusername/class-report-calculator.git
cd class-report-calculator
Create and activate a virtual environment:
bash
Copy code
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
Install required packages:
bash
Copy code
pip install -r requirements.txt
Configure AWS credentials:
bash
Copy code
aws configure
Enter your AWS credentials when prompted:

AWS Access Key ID
AWS Secret Access Key
Default region (use 'us-east-1' for Bedrock)
Default output format (json)
Project Structure
class-report-calculator/
├── CsatAnalyser/
│   ├── __init__.py
│   ├── main.py
│   └── templates/
│       └── index.html
├── requirements.txt
└── README.md
Required Packages
Create a requirements.txt file with the following dependencies:

flask==2.0.1
pandas==1.3.3
boto3==1.28.0
python-dotenv==0.19.0
Usage
Start the Flask application:
bash
Copy code
python -m flask run
Open your web browser and navigate to:
http://localhost:5000
Upload your CSV file containing course feedback data. The file should include the following columns:
QID1, QID2 (Overall Satisfaction)
QID127, QID128, QID129 (Instructor metrics)
QID31, QID67, QID32 (Content metrics)
