from flask import Flask, render_template, request, jsonify
import pandas as pd
import os
import boto3
import json

app = Flask(__name__)

# Configure upload folder
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'csv'}

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def convert_rating_to_numeric(rating):
    """
    Convert text ratings to numeric values
    """
    rating_map = {
        'Strongly Agree': 5,
        'Agree': 4,
        'Neutral': 3,
        'Disagree': 2,
        'Strongly Disagree': 1,
        'Extremely Satisfied': 5,
        'Satisfied': 4,
        'Neither Satisfied nor Dissatisfied': 3,
        'Dissatisfied': 2,
        'Extremely Dissatisfied': 1
    }
    return rating_map.get(str(rating).strip(), None)

def get_bedrock_summary(feedback):
    """
    Get summary of feedback using Amazon Bedrock
    """
    try:
        # Initialize Bedrock client with specific region
        bedrock = boto3.client(
            service_name='bedrock-runtime',
            region_name='us-east-1'
        )
        
        # Prepare the feedback text for summarization
        positive_feedback = "\n".join(feedback['highlights'])
        improvement_feedback = "\n".join(feedback['recommendations'])
        
        prompt = f"""Human: Please analyze these course feedback comments and provide a concise summary:

        Positive Feedback:
        {positive_feedback}

        Areas for Improvement:
        {improvement_feedback}

        Please provide a brief summary that includes:
        1. Key positive themes
        2. Main areas for improvement
        3. Overall sentiment

        Assistant: """

        # Prepare the request body with correct parameter name
        body = json.dumps({
            "prompt": prompt,
            "max_tokens_to_sample": 2000,
            "temperature": 0.7,
            "top_p": 1
        })

        # Make the API call
        response = bedrock.invoke_model(
            modelId="anthropic.claude-v2",
            body=body
        )
        
        # Parse the response
        response_body = json.loads(response.get('body').read())
        summary = response_body.get('completion', '').strip()
        
        return summary
        
    except Exception as e:
        print(f"Error getting Bedrock summary: {str(e)}")
        return None

def analyze_instructor_ratings(df, enable_ai=False):
    """
    Analyze instructor ratings from the CSV file
    """
    try:
        results = {}
        
        # Calculate Instructor CSAT (QID127, QID128, QID129)
        instructor_questions = ['QID127', 'QID128', 'QID129']
        instructor_ratings = []
        
        for qid in instructor_questions:
            if qid in df.columns:
                ratings = df[qid].apply(convert_rating_to_numeric)
                ratings = pd.to_numeric(ratings, errors='coerce')
                instructor_ratings.extend(ratings.dropna().tolist())
        
        if instructor_ratings:
            instructor_csat = round(float(sum(instructor_ratings)) / len(instructor_ratings), 2)
            results['Instructor CSAT'] = instructor_csat
        
        # Calculate Combined Overall Score (QID1 and QID2)
        overall_ratings = []
        if 'QID1' in df.columns:
            qid1_ratings = df['QID1'].apply(convert_rating_to_numeric)
            qid1_ratings = pd.to_numeric(qid1_ratings, errors='coerce')
            overall_ratings.extend(qid1_ratings.dropna().tolist())
        if 'QID2' in df.columns:
            qid2_ratings = df['QID2'].apply(convert_rating_to_numeric)
            qid2_ratings = pd.to_numeric(qid2_ratings, errors='coerce')
            overall_ratings.extend(qid2_ratings.dropna().tolist())
        
        if overall_ratings:
            overall_score = round(float(sum(overall_ratings)) / len(overall_ratings), 2)
            results['Overall Satisfaction'] = overall_score
            
        # Calculate Content Score (QID31, QID67, QID32)
        content_questions = ['QID31', 'QID67', 'QID32']
        content_ratings = []
        
        for qid in content_questions:
            if qid in df.columns:
                ratings = df[qid].apply(convert_rating_to_numeric)
                ratings = pd.to_numeric(ratings, errors='coerce')
                content_ratings.extend(ratings.dropna().tolist())
        
        if content_ratings:
            content_score = round(float(sum(content_ratings)) / len(content_ratings), 2)
            results['Content'] = content_score
            
        # Determine if ILT or VILT and calculate Classroom Score
        # Check if it's VILT by looking for QID130 responses
        is_vilt = False
        if 'QID130' in df.columns:
            vilt_ratings = df['QID130'].apply(convert_rating_to_numeric)
            vilt_ratings = pd.to_numeric(vilt_ratings, errors='coerce')
            if not vilt_ratings.empty and vilt_ratings.notna().any():
                is_vilt = True
        
        classroom_ratings = []
        if is_vilt:
            # Virtual classroom metrics (QID130, QID59)
            if 'QID130' in df.columns:
                ratings = df['QID130'].apply(convert_rating_to_numeric)
                ratings = pd.to_numeric(ratings, errors='coerce')
                classroom_ratings.extend(ratings.dropna().tolist())
            if 'QID59' in df.columns:
                ratings = df['QID59'].apply(convert_rating_to_numeric)
                ratings = pd.to_numeric(ratings, errors='coerce')
                classroom_ratings.extend(ratings.dropna().tolist())
        else:
            # In-person classroom metrics (QID58, QID59)
            if 'QID58' in df.columns:
                ratings = df['QID58'].apply(convert_rating_to_numeric)
                ratings = pd.to_numeric(ratings, errors='coerce')
                classroom_ratings.extend(ratings.dropna().tolist())
            if 'QID59' in df.columns:
                ratings = df['QID59'].apply(convert_rating_to_numeric)
                ratings = pd.to_numeric(ratings, errors='coerce')
                classroom_ratings.extend(ratings.dropna().tolist())
        
        if classroom_ratings:
            classroom_score = round(float(sum(classroom_ratings)) / len(classroom_ratings), 2)
            results['Classroom'] = classroom_score
            results['Delivery_Type'] = 'Virtual (VILT)' if is_vilt else 'In-Person (ILT)'
        
        # Extract feedback
        feedback = {
            'recommendations': [],
            'highlights': []
        }
        
        if 'QID138_TEXT' in df.columns:
            texts = df['QID138_TEXT'].dropna().tolist()
            feedback['recommendations'].extend([
                str(text).strip() 
                for text in texts 
                if str(text).strip()
            ])
        
        if 'QID142_TEXT' in df.columns:
            texts = df['QID142_TEXT'].dropna().tolist()
            feedback['highlights'].extend([
                str(text).strip() 
                for text in texts 
                if str(text).strip()
            ])
        
        results['feedback'] = feedback
        
        # Only get AI summary if enabled and there's feedback to analyze
        if enable_ai and (feedback['highlights'] or feedback['recommendations']):
            ai_summary = get_bedrock_summary(feedback)
            if ai_summary:
                results['ai_summary'] = ai_summary
        
        print("Analysis Results:", results)
        return results
        
    except Exception as e:
        print(f"Error analyzing data: {str(e)}")
        import traceback
        traceback.print_exc()
        return None

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/analyze', methods=['POST'])
def analyze():
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file uploaded'}), 400
        
        file = request.files['file']
        enable_ai = request.form.get('enableAI') == 'true'
        
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        if file and allowed_file(file.filename):
            # Read the CSV file
            df = pd.read_csv(file)
            
            # Analyze the data
            results = analyze_instructor_ratings(df, enable_ai)
            
            if results is None:
                return jsonify({'error': 'Error analyzing data'}), 500
                
            return jsonify(results)
            
        return jsonify({'error': 'Invalid file type'}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
