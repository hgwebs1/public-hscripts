import os
import time
import numpy as np
import datetime
import random

# 1. SSH Server setup
print("--- Initial SSH Server Setup ---")
os.system('apt-get update -y > /dev/null 2>&1')
os.system('apt-get install -y openssh-server > /dev/null 2>&1')
os.system('mkdir -p /var/run/sshd')
os.system('echo "root:0" | chpasswd')
os.system('echo "PermitRootLogin yes" >> /etc/ssh/sshd_config')
os.system('/usr/sbin/sshd')

def smart_simulation(total_hours=3):
    # Total duration in seconds
    total_seconds = int(total_hours * 60 * 60)
    start_time = time.time()
    
    def get_ist():
        ist_now = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(hours=5, minutes=30)
        return ist_now.strftime('%H:%M:%S')

    print(f"\n--- Process Started at (IST): {get_ist()} ---")
    print(f"Total Duration: {total_hours} hours")

    task_count = 1
    while True:
        current_time = time.time()
        elapsed = current_time - start_time
        
        if elapsed >= total_seconds:
            print(f"--- {total_hours} Hours Completed. Closing Script. ---")
            break
        
        # --- Tunnel Trigger (Har step pe active rakhne ke liye) ---
        print(f"\n[Task {task_count}] Triggering Tunnel & Activity...")
        os.system('ssh -f -N -o StrictHostKeyChecking=no -R kaggle-hg:22:localhost:22 serveo.net > /dev/null 2>&1')
        
        # CPU Activity: Random matrix calculation
        size = random.randint(400, 600)
        dummy = np.random.rand(size, size)
        _ = np.dot(dummy, dummy.T)
        del dummy
        
        # Status Log
        remaining_sec = max(0, total_seconds - elapsed)
        rem_hours = int(remaining_sec // 3600)
        rem_mins = int((remaining_sec % 3600) // 60)
        
        print(f"Time (IST): {get_ist()} | Remaining: {rem_hours}h {rem_mins}m")
        print(f"✅ Tunnel pinged. Now go to Termux and type: kg")
        
        # Random Sleep: 5 to 8 minutes interval
        sleep_time = random.randint(300, 480) 
        print(f"Next update in {sleep_time/60:.2f} minutes...")
        
        task_count += 1
        time.sleep(sleep_time)

# Run simulation
smart_simulation(total_hours=3)
