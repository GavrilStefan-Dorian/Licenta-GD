import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
import random
from collections import deque
import pickle
import time
import os

last_auto_save_time = time.time()

class QNetwork(nn.Module):
    def __init__(self, state_size, action_size):
        super(QNetwork, self).__init__()
        self.fc1 = nn.Linear(state_size, 128)
        self.fc2 = nn.Linear(128, 256)
        self.fc3 = nn.Linear(256, 128)
        self.fc4 = nn.Linear(128, action_size)

    def forward(self, x):
        x = torch.relu(self.fc1(x))
        x = torch.relu(self.fc2(x))
        x = torch.relu(self.fc3(x))
        return self.fc4(x)


class FightingGameDQN:
    def __init__(self, state_size, action_size, load_model=None):
        self.state_size = state_size
        self.action_size = action_size
        self.memory = deque(maxlen=10000)
        self.gamma = 0.95  # discount rate
        self.epsilon = 1.0  # exploration rate
        self.epsilon_min = 0.1
        self.epsilon_decay = 0.99
        self.learning_rate = 0.002

        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model = QNetwork(state_size, action_size).to(self.device)
        self.target_model = QNetwork(state_size, action_size).to(self.device)
        self.update_target_model()
        self.optimizer = optim.Adam(self.model.parameters(), lr=self.learning_rate)
        self.criterion = nn.MSELoss()

        if load_model:
            self.load_model(load_model)

    def update_target_model(self):
        self.target_model.load_state_dict(self.model.state_dict())

    def remember(self, state, action, reward, next_state, done):
        state_tensor = self._process_state(state)
        next_state_tensor = self._process_state(next_state)
        self.memory.append((state_tensor, action, reward, next_state_tensor, done))

    def _process_state(self, state_dict):
        """Convert game state dictionary to tensor"""
        # Extract relevant features from the state dictionary
        features = [
            state_dict["my_health"] / 100.0,
            state_dict["enemy_health"] / 100.0,
            state_dict["normalized_distance"],
            state_dict["relative_position"],  # -1 = enemy is left, 1 = enemy is right
            state_dict["my_on_ground"],  # 1 = on ground, 0 = in air
            state_dict["enemy_on_ground"],
            state_dict["my_is_attacking"],
            state_dict["enemy_is_attacking"],
            state_dict["my_is_guarding"],
            state_dict["enemy_is_guarding"],
            state_dict["my_is_vulnerable"],
            state_dict["enemy_is_vulnerable"],
            state_dict["my_position_x"] / 1000.0,  # Normalized screen position
            state_dict["enemy_position_x"] / 1000.0,
            state_dict["time_since_last_action"] / 60.0  # Normalized by frames (60fps)
        ]
        return torch.tensor(features, dtype=torch.float32).to(self.device)

    def act(self, state, training=False):
        """Returns action to take based on current state"""
        if training and random.random() <= self.epsilon:
            # Exploration: choose random action
            return random.randrange(self.action_size)

        state_tensor = self._process_state(state)
        self.model.eval()
        with torch.no_grad():
            state_tensor = state_tensor.unsqueeze(0)
            q_values = self.model(state_tensor)
            action = torch.argmax(q_values[0]).item()
        self.model.train()
        return action

    def replay_training(self, batch_size=64):
        """Train the model on a batch of experiences"""
        if len(self.memory) < batch_size:
            return

        batch = random.sample(self.memory, batch_size)

        states = torch.stack([experience[0] for experience in batch])
        actions = torch.tensor([experience[1] for experience in batch],
                               dtype=torch.long).unsqueeze(1).to(self.device)
        rewards = torch.tensor([experience[2] for experience in batch],
                               dtype=torch.float32).to(self.device)
        next_states = torch.stack([experience[3] for experience in batch])
        dones = torch.tensor([experience[4] for experience in batch],
                             dtype=torch.float32).to(self.device)

        # Current Q Values
        curr_q_values = self.model(states).gather(1, actions)

        # Next Q Values using target network
        with torch.no_grad():
            next_q_values = self.target_model(next_states).max(1)[0]
            target_q_values = rewards + (1 - dones) * self.gamma * next_q_values
            target_q_values = target_q_values.unsqueeze(1)

        # Update model
        loss = self.criterion(curr_q_values, target_q_values)
        self.optimizer.zero_grad()
        loss.backward()
        self.optimizer.step()

        # Update exploration rate
        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay

    def save_model(self, filepath):
        """Save model and training parameters"""
        data = {
            "model_state": self.model.state_dict(),
            "target_model_state": self.target_model.state_dict(),
            "optimizer_state": self.optimizer.state_dict(),
            "epsilon": self.epsilon,
            "memory": list(self.memory)
        }
        with open(filepath, "wb") as f:
            pickle.dump(data, f)

    def load_model(self, filepath):
        """Load model and training parameters"""
        try:
            with open(filepath, "rb") as f:
                data = pickle.load(f)

            self.model.load_state_dict(data["model_state"])
            self.target_model.load_state_dict(data["target_model_state"])
            self.optimizer.load_state_dict(data["optimizer_state"])
            self.epsilon = data["epsilon"]
            self.memory = deque(data["memory"], maxlen=10000)
            print(f"Model loaded from {filepath}")
        except Exception as e:
            print(f"Failed to load model: {e}")


# Create a simple Flask server
from flask import Flask, request, jsonify

app = Flask(__name__)
ai_agent = None

# Action mapping - tailored to your game's actions
ACTION_MAP = {
    0: "idle",
    1: "move_left",
    2: "move_right",
    3: "jump",
    4: "jab",
    5: "heavy_blow",
    6: "upper_cut",
    7: "fireball",
    8: "grapple",
    9: "guard",
    10: "dash"
}


@app.route('/initialize', methods=['POST'])
def initialize():
    global ai_agent
    data = request.get_json()
    state_size = data.get('state_size', 15)
    action_size = data.get('action_size', 11)
    model_path = data.get('model_path', None)

    ai_agent = FightingGameDQN(state_size, action_size, model_path)
    return jsonify({'success': True})


@app.route('/get_action', methods=['POST'])
def get_action():
    try:
        game_state = request.get_json()
        action_id = ai_agent.act(game_state, training=True)
        return jsonify({
            'action': ACTION_MAP[action_id],
            'action_id': action_id,
            'success': True
        })
    except Exception as e:
        return jsonify({'error': str(e), 'success': False})


@app.route('/train_step', methods=['POST'])
def train_step():
    try:
        data = request.get_json()
        state = data['current_state']
        action = data['action']
        reward = data['reward']
        next_state = data['next_state']
        done = data.get('done', False)

        ai_agent.remember(state, action, reward, next_state, done)
        ai_agent.replay_training()

        if done:
            ai_agent.update_target_model()

        if len(ai_agent.memory) % 100 == 0:
            print(f"Training stats: Memory size={len(ai_agent.memory)}, Epsilon={ai_agent.epsilon:.4f}")

        current_time = time.time()
        if current_time - last_auto_save_time > 300:
            save_dir = "E:/Licenta/Project/_game_prototype/dqn_script/models"
            os.makedirs(save_dir, exist_ok=True)
            save_path = f"{save_dir}/fighting_ai_model_auto.pkl"
            ai_agent.save_model(save_path)
            print(f"Auto-saved model to {save_path} (Training progress: epsilon={ai_agent.epsilon:.4f})")
            last_auto_save_time = current_time
        
        return jsonify({
            'success': True,
            'epsilon': ai_agent.epsilon,
            'memory_size': len(ai_agent.memory)
        })
    except Exception as e:
        return jsonify({'error': str(e), 'success': False})


@app.route('/save_model', methods=['POST'])
def save_model():
    try:
        data = request.get_json()
        filepath = data.get('filepath', 'fighting_ai_model.pkl')
        ai_agent.save_model(filepath)
        return jsonify({'success': True, 'message': f'Model saved to {filepath}'})
    except Exception as e:
        return jsonify({'error': str(e), 'success': False})


if __name__ == '__main__':
    print("Starting AI server on http://localhost:5000")
    print("Remember to initialize the AI first with a POST to /initialize")
    app.run(host='localhost', port=5000, debug=False, threaded=True)