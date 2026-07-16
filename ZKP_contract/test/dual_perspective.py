"""
Run Dual-Perspective Integration Analysis on ZKP Contracts

This script demonstrates the complete dual-perspective integration pipeline:
1. Symbolic Perspective: Constraint-guided context abstraction
2. Neural Perspective: ZKP-specific semantic alignment
3. Integration: Bridging both perspectives for enhanced detection
"""

import os
import sys
import json
from pathlib import Path

# Add parent directory to path
sys.path.append(str(Path(__file__).parent))

from constraint_guided_abstraction import ConstraintGuidedAbstraction, VulnerabilityClass
from zkp_semantic_alignment import ZKPSemanticAligner, DualPerspectiveIntegration


def process_single_contract(contract_path: str, output_dir: str, api_key: str = None):
    """
    Process a single Solidity contract with dual-perspective analysis
    """
    print(f"\n{'='*70}")
    print(f"Processing: {contract_path}")
    print('='*70)
    
    # Read contract
    with open(contract_path, 'r', encoding='utf-8') as f:
        solidity_code = f.read()
    
    # Run dual-perspective integration
    integration = DualPerspectiveIntegration(api_key)
    results = integration.analyze_contract(solidity_code)
    
    # Prepare output
    contract_name = Path(contract_path).stem
    output_data = {
        'contract': contract_name,
        'statistics': results['statistics'],
        'vulnerabilities': []
    }
    
    # Process high-confidence findings
    for cand, hint in results['high_confidence_vulnerabilities']:
        vuln_entry = {
            'type': cand.vuln_class.value,
            'vulnerability_class': cand.vuln_class.name,
            'source': cand.s,
            'sink': cand.t,
            'execution_path_length': len(cand.P),
            'safety_predicate': cand.Phi,
            'semantic_hint': {
                'constraint': hint.constraint,
                'security_invariant': hint.security_invariant,
                'guidance': hint.guidance,
                'confidence': hint.confidence
            }
        }
        output_data['vulnerabilities'].append(vuln_entry)
    
    # Save results
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, f"{contract_name}_dual_perspective.json")
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, indent=2)
    
    print(f"\n✓ Results saved to: {output_path}")
    print(f"✓ Found {len(output_data['vulnerabilities'])} high-confidence vulnerabilities")
    
    return output_data


def process_dataset(dataset_dir: str, output_dir: str, api_key: str = None):
    """
    Process all contracts in a dataset directory
    """
    dataset_path = Path(dataset_dir)
    
    # Find all .sol files
    sol_files = list(dataset_path.glob("**/*.sol"))
    
    if not sol_files:
        print(f"No .sol files found in {dataset_dir}")
        return
    
    print(f"\n{'='*70}")
    print(f"Processing {len(sol_files)} contracts from {dataset_dir}")
    print('='*70)
    
    results_summary = {
        'total_contracts': len(sol_files),
        'processed': 0,
        'failed': 0,
        'total_vulnerabilities': 0,
        'vulnerabilities_by_type': {}
    }
    
    for sol_file in sol_files:
        try:
            result = process_single_contract(str(sol_file), output_dir, api_key)
            results_summary['processed'] += 1
            results_summary['total_vulnerabilities'] += len(result['vulnerabilities'])
            
            # Count by type
            for vuln in result['vulnerabilities']:
                vuln_type = vuln['type']
                results_summary['vulnerabilities_by_type'][vuln_type] = \
                    results_summary['vulnerabilities_by_type'].get(vuln_type, 0) + 1
                    
        except Exception as e:
            print(f"✗ Failed to process {sol_file}: {e}")
            results_summary['failed'] += 1
    
    # Save summary
    summary_path = os.path.join(output_dir, "analysis_summary.json")
    with open(summary_path, 'w') as f:
        json.dump(results_summary, f, indent=2)
    
    print(f"\n{'='*70}")
    print("ANALYSIS COMPLETE")
    print('='*70)
    print(f"Processed: {results_summary['processed']}/{results_summary['total_contracts']}")
    print(f"Failed: {results_summary['failed']}")
    print(f"Total vulnerabilities: {results_summary['total_vulnerabilities']}")
    print(f"\nVulnerabilities by type:")
    for vuln_type, count in sorted(results_summary['vulnerabilities_by_type'].items()):
        print(f"  {vuln_type}: {count}")
    print(f"\nSummary saved to: {summary_path}")


def demonstrate_table1_rules():
    """
    Demonstrate the seven formal specification rules from Table 1
    """
    print("\n" + "="*70)
    print("TABLE 1: Seven Representative Formal Specification Rules")
    print("="*70 + "\n")
    
    rules = [
        {
            'class': 'Integer Overflow',
            'source': 'Arithmetic Op',
            'sink': 'State Variable',
            'predicate': '∀op ∈ P, isSafe(op)'
        },
        {
            'class': 'Unprotected Withdrawal',
            'source': 'Function Entry',
            'sink': 'Asset Transfer',
            'predicate': 'isAuth(msg.sender)'
        },
        {
            'class': 'Reentrancy',
            'source': 'External Call',
            'sink': 'State Update',
            'predicate': 'order(t, s) ⟹ t ≺ s'
        },
        {
            'class': 'Assert Violation',
            'source': 'External Input',
            'sink': 'Assert/Panic',
            'predicate': 'P ∩ Inv_unsafe = ∅'
        },
        {
            'class': 'Signature Replay',
            'source': 'Crypto Prim.',
            'sink': 'Nonce/Balance',
            'predicate': 'isFresh(sig) ∧ isRevocable'
        },
        {
            'class': 'Arbitrary Write',
            'source': 'User Input',
            'sink': 'Storage Slot',
            'predicate': 'isAuth(msg.sender) ∧ isSafe(idx)'
        },
        {
            'class': 'DoS (Gas Limit)',
            'source': 'Iteration/Loop',
            'sink': 'State Change',
            'predicate': 'gasCost(P) < Limit_block'
        }
    ]
    
    for i, rule in enumerate(rules, 1):
        print(f"{i}. {rule['class']}")
        print(f"   Source: {rule['source']}")
        print(f"   Sink: {rule['sink']}")
        print(f"   Safety Predicate: {rule['predicate']}")
        print()


def main():
    """
    Main entry point for dual-perspective analysis
    """
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Run dual-perspective integration analysis on ZKP contracts'
    )
    parser.add_argument(
        'input',
        help='Input contract file or dataset directory'
    )
    parser.add_argument(
        '--output',
        default='./result/dual_perspective',
        help='Output directory for results (default: ./result/dual_perspective)'
    )
    parser.add_argument(
        '--api-key',
        help='OpenAI API key (or set OPENAI_API_KEY environment variable)'
    )
    parser.add_argument(
        '--show-table',
        action='store_true',
        help='Display Table 1 formal specification rules'
    )
    parser.add_argument(
        '--dataset',
        action='store_true',
        help='Process entire dataset directory'
    )
    
    args = parser.parse_args()
    
    if args.show_table:
        demonstrate_table1_rules()
    
    if args.dataset:
        process_dataset(args.input, args.output, args.api_key)
    else:
        process_single_contract(args.input, args.output, args.api_key)


if __name__ == "__main__":
    main()
