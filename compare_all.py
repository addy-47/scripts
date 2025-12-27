import json
import pandas as pd
import sys

def compare_all():
    try:
        py_df = pd.read_csv('verification_data/py_all_nodes.csv')
        go_df = pd.read_csv('verification_data/go_all_nodes.csv')
        
        py_nodes = py_df.set_index('gcp_asset_name').to_dict('index')
        go_nodes = go_df.set_index('gcp_asset_name').to_dict('index')
    except Exception as e:
        print(f"Error loading CSVs: {e}")
        return
    
    common = set(py_nodes.keys()) & set(go_nodes.keys())
    py_only = set(py_nodes.keys()) - set(go_nodes.keys())
    go_only = set(go_nodes.keys()) - set(py_nodes.keys())
    
    print(f"--- RESOURCE PARITY ---")
    print(f"Common Resources: {len(common)}")
    print(f"Missing in Go: {len(py_only)}")
    print(f"Extra in Go: {len(go_only)}")
    
    for asset in sorted(list(py_only)):
        print(f"[MISSING] {asset}")
        
    failures = 0
    for asset in sorted(list(common)):
        # 1. Summary Comparison
        py_sum_str = py_nodes[asset]['summary_data']
        go_sum_str = go_nodes[asset]['summary_data']
        
        py_sum = json.loads(py_sum_str) if isinstance(py_sum_str, str) else {}
        go_sum = json.loads(go_sum_str) if isinstance(go_sum_str, str) else {}
        
        if py_sum.keys() != go_sum.keys():
            print(f"[FAIL] {asset}: Summary Key Mismatch")
            print(f"  PY: {list(py_sum.keys())}")
            print(f"  GO: {list(go_sum.keys())}")
            failures += 1
        elif py_sum != go_sum:
            # Check for value mismatch
            diffs = {k: (py_sum[k], go_sum[k]) for k in py_sum if py_sum[k] != go_sum[k]}
            print(f"[FAIL] {asset}: Summary Value Mismatch: {diffs}")
            failures += 1
            
        # 2. Root ID Comparison
        py_root = py_nodes[asset]['root_resource_id']
        go_root = go_nodes[asset]['root_resource_id']
        if py_root != go_root:
            print(f"[FAIL] {asset}: Root ID Mismatch. PY={py_root} GO={go_root}")
            failures += 1

    print(f"\nTotal Failures: {failures}")

if __name__ == '__main__':
    compare_all()
