from flask import Flask, jsonify, request
import logging
import os
from datetime import datetime

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint for Kubernetes liveness probe"""
    return jsonify({
        "status": "healthy",
        "service": "payment-gateway",
        "timestamp": datetime.utcnow().isoformat()
    }), 200

@app.route('/ready', methods=['GET'])
def readiness():
    """Readiness check endpoint for Kubernetes readiness probe"""
    return jsonify({
        "status": "ready",
        "service": "payment-gateway"
    }), 200

@app.route('/api/v1/process-payment', methods=['POST'])
def process_payment():
    """Process a payment transaction"""
    try:
        data = request.get_json()
        logger.info(f"Processing payment: {data}")
        
        return jsonify({
            "transaction_id": "txn_12345",
            "status": "success",
            "amount": data.get('amount', 0),
            "merchant_id": data.get('merchant_id', 'unknown')
        }), 200
    except Exception as e:
        logger.error(f"Payment processing error: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@app.route('/api/v1/transactions', methods=['GET'])
def get_transactions():
    """Fetch recent transactions"""
    return jsonify({
        "transactions": [
            {"id": "txn_001", "amount": 100, "status": "success"},
            {"id": "txn_002", "amount": 250, "status": "success"}
        ]
    }), 200

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)