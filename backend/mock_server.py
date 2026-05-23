from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)

DB_FILE = 'db.json'

def load_db():
  if os.path.exists(DB_FILE):
    with open(DB_FILE, 'r') as f:
      return json.load(f)
  return {
    'users': [{
      'user': {
        'id': '1',
        'email': 'admin@desby.com',
        'name': 'Admin User',
        'userType': 'tailor',
        'createdAt': datetime.now().isoformat(),
      },
      'accessToken': 'jwt-token-123',
      'refreshToken': 'refresh-jwt-token-123',
      'expiresIn': 3600,
    }]
  }

def save_db(db):
  with open(DB_FILE, 'w') as f:
    json.dump(db, f)

db = load_db()

@app.route('/api/auth/register', methods=['GET', 'POST', 'OPTIONS'])
def register():
  if request.method == 'OPTIONS':
    return '', 200
  data = request.json
  print('Register:', data)
  
  user = {
    'id': str(len(db['users']) + 1),
    'email': data['email'],
    'name': data['name'],
    'userType': data['userType'],
    'createdAt': datetime.now().isoformat(),
  }

  new_record = {
    'user': user,
    'accessToken': 'jwt-token-123',
    'refreshToken': 'refresh-jwt-token-123',
    'expiresIn': 3600,
  }

  db['users'].append(new_record)
  save_db(db)

  return jsonify({
    'user': user,
    'accessToken': new_record['accessToken'],
    'refreshToken': new_record['refreshToken'],
    'expiresIn': new_record['expiresIn'],
    'success': True,
    'message': 'Registered successfully',
  })

@app.route('/api/auth/login', methods=['POST'])
def login():
  data = request.json
  print('Login:', data)
  email = data.get('email')

  # Simple login: check if email exists
  for record in db['users']:
    if record['user']['email'] == email:
      return jsonify(record)

  return jsonify({'message': 'User not found'}), 404

@app.route('/api/auth/logout', methods=['POST'])
def logout():
  print('Logout')
  return jsonify({'success': True, 'message': 'Logged out successfully'})

@app.route('/api/analytics/dashboard/stats/<userId>', methods=['GET'])
def dashboard_stats(userId):
  return jsonify({
    'totalOrders': 24,
    'pendingOrders': 8,
    'completedOrders': 16,
    'totalRevenue': 12500.50,
    'totalClients': 42,
    'averageRating': 4.8,
    'lastUpdated': datetime.now().isoformat()
  })

@app.route('/api/orders/list/<userId>', methods=['GET'])
def recent_orders(userId):
  return jsonify([
    {'id': '101', 'clientName': 'John Doe', 'status': 'Pending', 'amount': 250.0, 'date': '2026-05-01'},
    {'id': '102', 'clientName': 'Jane Smith', 'status': 'Completed', 'amount': 450.0, 'date': '2026-04-28'},
    {'id': '103', 'clientName': 'Robert Brown', 'status': 'In Progress', 'amount': 150.0, 'date': '2026-04-25'},
  ])

@app.route('/api/clients/<userId>', methods=['GET'])
def recent_clients(userId):
  return jsonify([
    {'id': 'c1', 'name': 'Alice Johnson', 'email': 'alice@example.com', 'phone': '123456789'},
    {'id': 'c2', 'name': 'Bob Wilson', 'email': 'bob@example.com', 'phone': '987654321'},
  ])

if __name__ == '__main__':
  app.run(host='0.0.0.0', port=3000, debug=True)

