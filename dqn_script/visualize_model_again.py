import os
import numpy as np

ACTION_ID_TO_NAME = {
    0: "idle", 1: "move_left", 2: "move_right", 3: "jump", 4: "jab", 5: "heavy_blow", 
    6: "upper_cut", 7: "fireball", 8: "grapple", 9: "guard", 10: "dash"
}
ACTION_NAME_TO_ID = {name: id for id, name in ACTION_ID_TO_NAME.items()}

def visualize_saved_model(model_path):
    import matplotlib.pyplot as plt
    import torch
    
    if not os.path.exists(model_path):
        print(f"Model file not found at {model_path}")
        return
    
    try:
        checkpoint = torch.load(model_path, map_location=torch.device('cpu'))
        
        fig = plt.figure(figsize=(15, 10))
        
        plt.figtext(0.5, 0.95, f"Model Stats - Steps: {checkpoint.get('steps_done', 'N/A')} | Epsilon: {checkpoint.get('epsilon', 'N/A'):.4f}",
                   ha="center", fontsize=14, bbox={"facecolor":"orange", "alpha":0.3, "pad":5})
        
        if 'memory' in checkpoint and len(checkpoint['memory']) > 0:
            ax1 = plt.subplot(221)
            actions = [m[1] for m in checkpoint['memory']]
            action_ids, counts = np.unique(actions, return_counts=True)
            
            action_names = [f"{id} ({ACTION_ID_TO_NAME.get(id, 'Unknown')})" for id in action_ids]
            
            ax1.bar(action_names, counts)
            ax1.set_title('Action Distribution')
            ax1.tick_params(axis='x', rotation=45)
            
            ax2 = plt.subplot(222)
            rewards = [m[2] for m in checkpoint['memory']]
            ax2.hist(rewards, bins=20)
            ax2.set_title('Reward Distribution')
            ax2.set_xlabel('Reward Value')
            ax2.set_ylabel('Frequency')
            
            ax3 = plt.subplot(212)
            
            # first layer w as feature importance
            if 'model_state_dict' in checkpoint:
                weights = checkpoint['model_state_dict']['fc1.weight'].abs().mean(dim=0).numpy()
                ax3.bar(range(len(weights)), weights)
                ax3.set_title('Feature Importance (Avg Abs Weight)')
                ax3.set_xlabel('State Feature Index')
                ax3.set_ylabel('Importance')
        else:
            plt.figtext(0.5, 0.5, "No memory data found in file", ha="center", fontsize=14)
        
        plt.tight_layout()
        plt.show()
        
    except Exception as e:
        print(f"Error visualizing model: {e}")

visualize_saved_model("E:\\Licenta\\Project\\_game_prototype\\dqn_script\\dqn_model_newer (1).pth")