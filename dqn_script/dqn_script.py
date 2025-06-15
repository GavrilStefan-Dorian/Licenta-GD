import os
import time
import random
import logging
import threading
import subprocess
import re
from collections import deque
from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

STATE_KEYS = [
    "my_health", "enemy_health", "my_position_x", "my_position_y", "enemy_position_x", "enemy_position_y",
    "normalized_distance", "relative_position", "my_on_ground", "enemy_on_ground", "my_is_attacking", 
    "enemy_is_attacking", "my_is_guarding", "enemy_is_guarding", "my_is_vulnerable", "enemy_is_vulnerable",
    "time_since_last_action"
]

ACTION_ID_TO_NAME = {
    0: "idle", 1: "move_left", 2: "move_right", 3: "jump", 4: "jab", 5: "heavy_blow", 
    6: "upper_cut", 7: "fireball", 8: "grapple", 9: "guard", 10: "dash"
}
ACTION_NAME_TO_ID = {name: id for id, name in ACTION_ID_TO_NAME.items()}


class QNetwork(nn.Module):
    def __init__(self, state_size, action_size):
        super(QNetwork, self).__init__()
        self.fc1 = nn.Linear(state_size, 128)
        self.fc2 = nn.Linear(128, 256)
        self.fc3 = nn.Linear(256, 128)
        self.fc4 = nn.Linear(128, action_size)
        self._init_weights(self)

    def _init_weights(self, module):
        if isinstance(module, nn.Linear):
            nn.init.xavier_uniform_(module.weight)
            if module.bias is not None:
                nn.init.constant_(module.bias, 0)

    def forward(self, x):
        x = torch.relu(self.fc1(x))
        x = torch.relu(self.fc2(x))
        x = torch.relu(self.fc3(x))
        return self.fc4(x)


class DQNAgent:
    def __init__(self, state_size, action_size, model_path=None):
        self.state_size = state_size
        self.action_size = action_size
        self.memory = deque(maxlen=20000)
        self.gamma = 0.99  
        self.epsilon = 1.0  
        self.epsilon_min = 0.01
        self.epsilon_decay = 0.995  
        self.learning_rate = 0.0005
        self.batch_size = 64
        self.update_target_every = 10

        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        logger.info(f"Using device: {self.device}")

        self.model = QNetwork(state_size, action_size).to(self.device)
        self.target_model = QNetwork(state_size, action_size).to(self.device)
        self.optimizer = optim.AdamW(self.model.parameters(), lr=self.learning_rate)
        self.criterion = nn.SmoothL1Loss()

        if model_path:
            if os.path.exists(model_path):
                logger.info(f"Found existing model at {model_path}, loadding")
                self.load_model(model_path)
            else:
                logger.info(f"No model found at {model_path}, starting fresh")
        
        self.update_target_model()
        self.steps_done = 0

    def calculate_reward(self, old_state, new_state):
        reward = 0.0

        my_health_change = new_state.get("my_health", 0.0) - old_state.get("my_health", 0.0)
        enemy_health_change = old_state.get("enemy_health", 0.0) - new_state.get("enemy_health", 0.0)

        reward += my_health_change * 0.5 
        reward += enemy_health_change * 1.0

        if new_state.get("my_is_attacking") and new_state.get("normalized_distance", 1.0) < 0.15:
            reward += 0.2  

        if my_health_change < 0:
            reward -= 0.5 

        if enemy_health_change > 0:
            reward += 1.0 

        if new_state.get("my_is_guarding") and new_state.get("enemy_is_attacking"):
            reward += 0.5  

        stage_width = 1920.0  
        stage_margin = stage_width * 0.2
        if new_state.get("enemy_position_x", 0.0) < stage_margin or new_state.get("enemy_position_x", 0.0) > stage_width - stage_margin:
            if new_state.get("my_position_x", 0.0) > stage_margin and new_state.get("my_position_x", 0.0) < stage_width - stage_margin:
                reward += 0.3  

        optimal_distance = 0.2  
        distance_diff = abs(new_state.get("normalized_distance", 1.0) - optimal_distance)
        reward += (0.5 - distance_diff) * 0.1  

        return reward

    def update_target_model(self):
        self.target_model.load_state_dict(self.model.state_dict())
        logger.info("Target model updated.")

    def remember(self, state, action, reward, next_state, done):
        self.memory.append((
            self._process_state_to_list(state), 
                            action, reward, 
            self._process_state_to_list(next_state), 
                            done
        ))

    def _process_state_to_list(self, state_dict_or_list):
        if isinstance(state_dict_or_list, list): 
            return state_dict_or_list
        if not isinstance(state_dict_or_list, dict):
            logger.error(f"Invalid state format: {state_dict_or_list}. Expected dict.")
            return [0.0] * self.state_size 

        processed_state = []
        for key in STATE_KEYS:
            value = state_dict_or_list.get(key)
            if isinstance(value, bool):
                processed_state.append(1.0 if value else 0.0)
            elif isinstance(value, (int, float)):
                processed_state.append(float(value))
            else:
                logger.warning(f"State key '{key}' has unexpected value '{value}' (type: {type(value)}). Using 0.0.")
                processed_state.append(0.0)
        
        if len(processed_state) != self.state_size:
             logger.error(f"State size mismatch. Expected {self.state_size}, got {len(processed_state)} for state: {state_dict_or_list}")
             processed_state = (processed_state + [0.0] * self.state_size)[:self.state_size]
        return processed_state


    def act(self, state_dict, training=True): # state_dict is raw dict from Godot
        self.steps_done +=1
        if training and random.random() <= self.epsilon:
            return random.randrange(self.action_size) 
        
        state_list = self._process_state_to_list(state_dict)
        state_tensor = torch.tensor([state_list], dtype=torch.float32).to(self.device)
        
        self.model.eval() 
        with torch.no_grad():
            action_values = self.model(state_tensor)
        if training: 
            self.model.train()
            
        return torch.argmax(action_values).item() 

    def replay_training(self):
        if len(self.memory) < self.batch_size:
            return 0.0 # Not enough samples

        minibatch = random.sample(self.memory, self.batch_size)
        
        states = torch.tensor([s[0] for s in minibatch], dtype=torch.float32).to(self.device)
        actions = torch.tensor([s[1] for s in minibatch], dtype=torch.long).unsqueeze(1).to(self.device)
        rewards = torch.tensor([s[2] for s in minibatch], dtype=torch.float32).to(self.device)
        next_states = torch.tensor([s[3] for s in minibatch], dtype=torch.float32).to(self.device)
        dones = torch.tensor([s[4] for s in minibatch], dtype=torch.bool).to(self.device)

        current_q_values = self.model(states).gather(1, actions).squeeze(1)

        with torch.no_grad():
            next_q_values_target = self.target_model(next_states).max(1)[0]
        
        expected_q_values = rewards + (self.gamma * next_q_values_target * (~dones))

        loss = self.criterion(current_q_values, expected_q_values)

        self.optimizer.zero_grad()
        loss.backward()
        torch.nn.utils.clip_grad_norm_(self.model.parameters(), 1.0) # Gradient clipping
        self.optimizer.step()

        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay
        
        if self.steps_done % self.update_target_every == 0:
            self.update_target_model()
            
        return loss.item()

    def save_model(self, filepath):
        try:
            os.makedirs(os.path.dirname(filepath), exist_ok=True)
            
            save_data = {
                'model_state_dict': self.model.state_dict(),
                'target_model_state_dict': self.target_model.state_dict(),
                'optimizer_state_dict': self.optimizer.state_dict(),
                'epsilon': self.epsilon,
                'steps_done': self.steps_done,
                'memory': list(self.memory),
                'save_time': time.time()
            }
            
            torch.save(save_data, filepath)
            
            if os.path.exists(filepath):
                logger.info(f"Model is at {filepath} - File size: {os.path.getsize(filepath)} bytes")
            else:
                logger.error(f"Model save failed - File not created at {filepath}")
                
        except Exception as e:
            logger.error(f"Error saving model: {e}", exc_info=True)

    def load_model(self, filepath):
        try:
            if not os.path.exists(filepath):
                logger.warning(f"Model file not found at {filepath}. Make new model.")
                return

            try:
                checkpoint = torch.load(filepath, map_location=self.device)
                self.model.load_state_dict(checkpoint['model_state_dict'])
                self.target_model.load_state_dict(checkpoint['target_model_state_dict'])
                
                if 'epsilon' in checkpoint:
                    self.epsilon = checkpoint['epsilon']
                    logger.info(f"Loaded epsilon: {self.epsilon} from checkpoint")
                
                self.steps_done = checkpoint.get('steps_done', 0)
                
                if 'memory' in checkpoint and len(checkpoint['memory']) > 0:
                    sample_size = min(5000, len(checkpoint['memory']))
                    self.memory = deque(random.sample(checkpoint['memory'], sample_size), maxlen=self.memory.maxlen)
                    
                logger.info(f"Model loaded from {filepath} - {self.steps_done} steps done, epsilon={self.epsilon}")
            except Exception as e:
                logger.error(f"Error during model loading: {e}", exc_info=True)
                logger.info("Initializing fresh model due to load error")
                
        except Exception as e:
            logger.error(f"Fatal error loading model from {filepath}: {e}", exc_info=True)

app = Flask(__name__)
CORS(app)
ai_agent = None

def is_colab():
    try:
        import google.colab
        return True
    except:
        return False

if is_colab():
    print("Running in Google Colab - setting up Drive for model persistence")
    
    if os.path.exists('/content/drive/MyDrive'):
        model_dir = "/content/drive/MyDrive/fighting_game_ai"
        os.makedirs(model_dir, exist_ok=True)
        model_save_path = os.path.join(model_dir, "new_dqn_model.pth")
        print(f"Model will be saved to: {model_save_path}")
        
    else:
        print(f"Not mount Google Drive")
        model_save_path = os.path.join(os.getcwd(), "models", "dqn_model.pth")
        print(f"Instead, temporary local path: {model_save_path}")
else:
    # For local runs
    model_save_path = os.path.join(os.getcwd(), "models", "dqn_model.pth")
    os.makedirs(os.path.dirname(model_save_path), exist_ok=True)

@app.route('/status', methods=['GET'])
def status():
    global ai_agent
    if ai_agent is None:
        return jsonify({'status': 'waiting', 'message': 'Agent not initialized'}), 200
    return jsonify({
        'status': 'success',
        'message': 'Agent is active.',
        'epsilon': ai_agent.epsilon,
        'memory_size': len(ai_agent.memory),
        'steps_done': ai_agent.steps_done
    })

@app.route('/initialize', methods=['POST'])
def initialize():
    global ai_agent
    try:
        data = request.get_json()
        if not data:
            return jsonify({'status': 'error', 'message': 'No data provided for initialization.'}), 400
        
        state_size = data.get('state_size')
        action_size = data.get('action_size')

        if state_size is None or action_size is None:
            return jsonify({'status': 'error', 'message': 'state_size and action_size are required.'}), 400
        if state_size != len(STATE_KEYS):
             logger.warning(f"Client state_size {state_size} differs from server's expected {len(STATE_KEYS)}. Using server's.")
             state_size = len(STATE_KEYS)


        ai_agent = DQNAgent(state_size, action_size, model_path=model_save_path)
        logger.info(f"Agent initialized with state_size={state_size}, action_size={action_size}")
        return jsonify({'status': 'success', 'message': 'Agent initialized'})
    except Exception as e:
        logger.error(f"Error during initialization: {e}", exc_info=True)
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/get_action', methods=['POST'])
def get_action():
    global ai_agent
    if ai_agent is None:
        return jsonify({'status': 'error', 'message': 'Agent not initialized'}), 400
    try:
        state_dict = request.get_json(force=True) 
        if not state_dict:
             return jsonify({'status': 'error', 'message': 'No state_dict provided for get_action.'}), 400

        action_id = ai_agent.act(state_dict, training=True)
        if action_id not in ACTION_ID_TO_NAME:
            error_msg = f"Invalid action_id: {action_id}"
            logger.error(error_msg)
            return jsonify({'status': 'error', 'message': error_msg}), 500
        
        action_name = ACTION_ID_TO_NAME[action_id]
        logger.info(f"[{time.strftime('%H:%M:%S')}] ACTION: {action_name.upper()}")
        
        return jsonify({'status': 'success', 'action_name': action_name}) 
    except Exception as e:
        logger.error(f"Error in /get_action: {e}", exc_info=True)
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/train_step', methods=['POST'])
def train_step():
    global ai_agent
    if ai_agent is None:
        return jsonify({'status': 'error', 'message': 'Agent not initialized'}), 400
    try:
        data = request.get_json()
        if not data:
            return jsonify({'status': 'error', 'message': 'No data provided for train_step.'}), 400

        reward = ai_agent.calculate_reward(data['current_state'], data['next_state'])

        if data['action'] == 0:
            reward -= 2

        ai_agent.remember(
            data['current_state'], 
            data['action'],  
            reward, 
            data['next_state'], 
            data['done']
        )
        
        loss = ai_agent.replay_training()
            
        return jsonify({'status': 'success', 'message': 'trained', 'loss': loss if loss is not None else 'N/A'})
    except Exception as e:
        logger.error(f"Error in train_step: {e}", exc_info=True)
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/save_model_manual', methods=['POST']) 
def save_model_manual():
    global ai_agent
    if ai_agent is None:
        return jsonify({'status': 'error', 'message': 'Agent not initialized'}), 400
    try:
        ai_agent.save_model(model_save_path)
        return jsonify({'status': 'success', 'message': f'Model saved to {model_save_path}'})
    except Exception as e:
        logger.error(f"Error in /save_model_manual: {e}", exc_info=True)
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/training_stats', methods=['GET'])
def training_stats():
    global ai_agent
    if ai_agent is None:
        return jsonify({'status': 'error', 'message': 'Agent not initialized'}), 400
    
    version_info = {
        'timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
        'model_path': model_save_path,
        'epsilon': ai_agent.epsilon,
        'memory_size': len(ai_agent.memory),
        'steps_done': ai_agent.steps_done,
        'is_colab': is_colab()
    }
    
    return jsonify(version_info)

def run_flask():
    port = int(os.environ.get("PORT", 5050))
    logger.info(f"Starting Flask server on port {port}")
    app.run(host='0.0.0.0', port=port, threaded=True)

def start_cloudflare_tunnel():
    process = subprocess.Popen(
        ["cloudflared", "tunnel", "--url", "http://localhost:5050"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        universal_newlines=True
    )
    
    tunnel_url = None
    for _ in range(60):
        output = process.stdout.readline().strip()
        if output:
            print(f"  {output}")
            if "trycloudflare.com" in output:
                match = re.search(r'https://[a-z0-9\-]+\.trycloudflare\.com', output)
                if match:
                    tunnel_url = match.group(0)
                    break
        time.sleep(0.1)
    
    if tunnel_url:
        print(f"\nserver is at: {tunnel_url}")

    return process, tunnel_url

if __name__ == '__main__':
    if os.path.exists(model_save_path):
        print(f"Found existing model at {model_save_path}")
    else:
        print(f"No model exists yet at {model_save_path}, create after saving")
    
    threading.Thread(target=run_flask, daemon=True).start()
    print("Flask server started")

    process, url = start_cloudflare_tunnel()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        if ai_agent:
            print("Saving model before exit")
            ai_agent.save_model(model_save_path)
        process.terminate()
        print("Server shut down")