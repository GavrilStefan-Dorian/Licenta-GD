import pickle
import os
import torch
import numpy as np
import matplotlib.pyplot as plt
from pprint import pprint


def inspect_pickle_file(filepath):
    """Inspect and display the contents of a DQN pickle file"""
    print(f"Analyzing model file: {filepath}")
    print("-" * 80)

    if not os.path.exists(filepath):
        print(f"Error: File {filepath} does not exist")
        return

    try:
        with open(filepath, "rb") as f:
            data = pickle.load(f)

        # Display high-level overview
        print("Model data structure:")
        print(f"Keys in saved model: {list(data.keys())}")
        print("-" * 80)

        # Epsilon value (exploration rate)
        print(f"Epsilon value: {data['epsilon']:.4f}")

        # Memory replay buffer
        memory = data.get('memory', [])
        print(f"Memory buffer size: {len(memory)} experiences")
        if memory and len(memory) > 0:
            print("\nSample from memory buffer (5 items):")
            for i, exp in enumerate(memory[:5]):
                state, action, reward, next_state, done = exp
                print(f"  Experience {i}:")
                print(f"    Action: {action}")
                print(f"    Reward: {reward}")
                print(f"    Done: {done}")
                print(f"    State shape: {state.shape if hasattr(state, 'shape') else 'N/A'}")

        # Model architecture
        if 'model_state' in data:
            print("\nModel architecture:")
            for layer_name, param in data['model_state'].items():
                if isinstance(param, torch.Tensor):
                    print(f"  {layer_name}: shape {param.shape}, dtype {param.dtype}")

        # Target model architecture
        if 'target_model_state' in data:
            print("\nTarget model architecture:")
            for layer_name, param in data['target_model_state'].items():
                if isinstance(param, torch.Tensor):
                    print(f"  {layer_name}: shape {param.shape}, dtype {param.dtype}")

        # Optimizer state
        if 'optimizer_state' in data:
            print("\nOptimizer state:")
            print(f"  Type: {data['optimizer_state'].get('name', 'Unknown')}")
            if 'param_groups' in data['optimizer_state']:
                for i, group in enumerate(data['optimizer_state']['param_groups']):
                    print(f"  Parameter group {i}:")
                    for param, value in group.items():
                        if param != 'params':
                            print(f"    {param}: {value}")

        # Visualize weight distributions
        if 'model_state' in data:
            plt.figure(figsize=(12, 6))
            weights_count = 0

            for name, param in data['model_state'].items():
                if isinstance(param, torch.Tensor) and 'weight' in name:
                    weights_count += 1
                    if weights_count <= 4:  # Plot at most 4 weight distributions
                        plt.subplot(2, 2, weights_count)
                        plt.hist(param.numpy().flatten(), bins=50, alpha=0.7)
                        plt.title(f'Weight Distribution: {name}')
                        plt.xlabel('Weight Value')
                        plt.ylabel('Frequency')

            if weights_count > 0:
                plt.tight_layout()
                plt.savefig(f"{os.path.splitext(filepath)[0]}_weights.png")
                print(f"\nWeight distribution plots saved to {os.path.splitext(filepath)[0]}_weights.png")

        return data

    except Exception as e:
        print(f"Error reading pickle file: {str(e)}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    # Replace with your model path
    filepath = "E:/Licenta/Project/_game_prototype/dqn_script/models/fighting_ai_model_round.pkl"
    data = inspect_pickle_file(filepath)

    # Ask user if they want to see more details
    if data:
        more_details = input("\nDo you want to see more details about specific components? (y/n): ")
        if more_details.lower() == 'y':
            print("\nAvailable components for detailed inspection:")
            print("1. Memory buffer samples")
            print("2. Model weights")
            print("3. Optimizer state")
            choice = input("Enter your choice (1-3): ")

            if choice == '1' and 'memory' in data:
                print("\nDetailed memory buffer inspection:")
                for i, exp in enumerate(data['memory'][:10]):  # First 10 experiences
                    state, action, reward, next_state, done = exp
                    print(f"\nExperience {i}:")
                    print(f"Action: {action}")
                    print(f"Reward: {reward}")
                    print(f"Done: {done}")
                    print("State tensors:")
                    if hasattr(state, 'shape'):
                        print(state)

            elif choice == '2' and 'model_state' in data:
                print("\nDetailed model weights inspection:")
                for name, param in data['model_state'].items():
                    if isinstance(param, torch.Tensor):
                        print(f"\n{name}:")
                        print(f"Shape: {param.shape}")
                        print(f"Mean: {param.mean().item():.6f}")
                        print(f"Std: {param.std().item():.6f}")
                        print(f"Min: {param.min().item():.6f}")
                        print(f"Max: {param.max().item():.6f}")

            elif choice == '3' and 'optimizer_state' in data:
                print("\nDetailed optimizer state inspection:")
                pprint(data['optimizer_state'])