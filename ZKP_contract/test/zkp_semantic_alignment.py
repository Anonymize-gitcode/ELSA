"""
ZKP-Specific Semantic Alignment (Neural Perspective)

This module implements the neural perspective of the dual-perspective integration,
using fine-tuned LLM for constraint-to-logic translation to bridge the semantic gap
between proof constraints and state logic.
"""

import os
import openai
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass


@dataclass
class SemanticHint:
    """
    Semantic hint mapping implicit mathematical constraints to security invariants
    """
    constraint: str  # Mathematical constraint from ZKP
    security_invariant: str  # High-level security property
    guidance: str  # Detection guidance for symbolic techniques
    confidence: float  # Confidence score [0, 1]


class ZKPSemanticAligner:
    """
    ZKP-specific semantic alignment using fine-tuned LLM
    
    The model is optimized for constraint-to-logic translation, generating semantic
    hints that map implicit mathematical constraints to high-level security invariants,
    providing precise guidance for subsequent detection.
    
    Note: This implementation uses GPT-3.5 as a substitute for the fine-tuned LLaMa-3.2-3B
    mentioned in the paper. In production, replace with the actual fine-tuned model.
    """
    
    def __init__(self, api_key: Optional[str] = None, model: str = "gpt-3.5-turbo"):
        """
        Initialize the semantic aligner
        
        Args:
            api_key: OpenAI API key (or path to fine-tuned model)
            model: Model identifier (default: gpt-3.5-turbo)
        """
        if api_key:
            openai.api_key = api_key
        else:
            openai.api_key = os.getenv('OPENAI_API_KEY', '...')
        
        self.model = model
        
        # ZKP-specific constraint patterns
        self.zkp_patterns = {
            'range_constraint': r'(\w+)\s*∈\s*\[(\d+),\s*(\d+)\]',
            'equality_constraint': r'(\w+)\s*==?\s*(\w+)',
            'polynomial_constraint': r'(\w+)\^(\d+)',
            'modular_arithmetic': r'(\w+)\s*mod\s*(\w+)',
            'commitment_scheme': r'commit\((\w+)\)',
            'proof_verification': r'verify\((\w+),\s*(\w+)\)',
        }
    
    def identify_zkp_constraints(self, solidity_code: str) -> List[str]:
        """
        Identify ZKP-specific mathematical constraints in Solidity code
        
        These constraints often appear in:
        - Require statements with complex conditions
        - Cryptographic primitive calls
        - Proof verification logic
        """
        constraints = []
        lines = solidity_code.split('\n')
        
        for line in lines:
            # Look for require statements with mathematical expressions
            if 'require' in line and any(op in line for op in ['**', 'mod', 'mulmod', 'addmod']):
                constraints.append(line.strip())
            
            # Look for cryptographic function calls
            if any(crypto in line.lower() for crypto in ['verify', 'proof', 'commitment', 'witness']):
                constraints.append(line.strip())
            
            # Look for complex modular arithmetic
            if 'mod' in line or 'mulmod' in line or 'addmod' in line:
                constraints.append(line.strip())
        
        return constraints
    
    def translate_constraint_to_invariant(self, constraint: str, context: str = "") -> SemanticHint:
        """
        Translate a mathematical constraint to a security invariant using LLM
        
        This is the core constraint-to-logic translation function that bridges
        the semantic gap between ZKP constraints and vulnerability detection.
        """
        prompt = f"""You are a security expert specializing in Zero-Knowledge Proof (ZKP) smart contracts.

Given a mathematical constraint from a ZKP smart contract, translate it into:
1. A high-level security invariant that must hold
2. Specific guidance for vulnerability detection

Mathematical Constraint:
{constraint}

Contract Context:
{context}

Provide your analysis in the following format:
SECURITY_INVARIANT: [Clear statement of what must be guaranteed]
DETECTION_GUIDANCE: [Specific checks for vulnerability detection techniques]
RATIONALE: [Brief explanation of the semantic gap this addresses]

Focus on common ZKP vulnerabilities:
- Range constraint violations
- Proof verification bypasses
- Commitment scheme weaknesses
- Arithmetic overflow in field operations
- Replay attacks on proofs
"""
        
        try:
            response = openai.ChatCompletion.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are an expert in ZKP smart contract security."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,  # Lower temperature for more consistent results
                max_tokens=500
            )
            
            content = response['choices'][0]['message']['content'].strip()
            
            # Parse the response
            security_invariant = ""
            guidance = ""
            
            for line in content.split('\n'):
                if line.startswith('SECURITY_INVARIANT:'):
                    security_invariant = line.replace('SECURITY_INVARIANT:', '').strip()
                elif line.startswith('DETECTION_GUIDANCE:'):
                    guidance = line.replace('DETECTION_GUIDANCE:', '').strip()
            
            # Calculate confidence based on response quality
            confidence = 0.8 if security_invariant and guidance else 0.5
            
            return SemanticHint(
                constraint=constraint,
                security_invariant=security_invariant,
                guidance=guidance,
                confidence=confidence
            )
            
        except Exception as e:
            print(f"Error in constraint translation: {e}")
            return SemanticHint(
                constraint=constraint,
                security_invariant="Translation failed",
                guidance="Manual inspection required",
                confidence=0.0
            )
    
    def generate_semantic_hints(self, solidity_code: str) -> List[SemanticHint]:
        """
        Generate semantic hints for all ZKP constraints in the contract
        
        This function orchestrates the complete neural perspective analysis,
        producing hints that guide the symbolic techniques.
        """
        constraints = self.identify_zkp_constraints(solidity_code)
        hints = []
        
        for constraint in constraints:
            hint = self.translate_constraint_to_invariant(constraint, solidity_code)
            hints.append(hint)
        
        return hints
    
    def align_with_symbolic_analysis(
        self, 
        symbolic_candidates: List,  # From constraint_guided_abstraction
        semantic_hints: List[SemanticHint]
    ) -> List[Tuple[any, SemanticHint, float]]:
        """
        Align neural semantic hints with symbolic vulnerability candidates
        
        This bridges the two perspectives, combining formal verification with
        semantic understanding to reduce false positives.
        
        Returns: List of (candidate, hint, alignment_score) tuples
        """
        alignments = []
        
        for candidate in symbolic_candidates:
            best_hint = None
            best_score = 0.0
            
            # Find the most relevant semantic hint for this candidate
            for hint in semantic_hints:
                # Calculate semantic similarity (simplified)
                score = self._calculate_alignment_score(candidate, hint)
                
                if score > best_score:
                    best_score = score
                    best_hint = hint
            
            if best_hint and best_score > 0.5:  # Threshold for meaningful alignment
                alignments.append((candidate, best_hint, best_score))
        
        return alignments
    
    def _calculate_alignment_score(self, candidate, hint: SemanticHint) -> float:
        """
        Calculate alignment score between a symbolic candidate and semantic hint
        
        Uses keyword matching and semantic similarity (simplified version)
        """
        # Extract key terms from candidate path
        candidate_text = ' '.join(candidate.P).lower()
        
        # Check for keyword overlap
        constraint_keywords = set(hint.constraint.lower().split())
        candidate_keywords = set(candidate_text.split())
        
        overlap = len(constraint_keywords & candidate_keywords)
        total = len(constraint_keywords | candidate_keywords)
        
        if total == 0:
            return 0.0
        
        # Jaccard similarity weighted by hint confidence
        similarity = overlap / total
        return similarity * hint.confidence


class DualPerspectiveIntegration:
    """
    Integrates symbolic and neural perspectives for comprehensive ZKP vulnerability detection
    
    This class bridges constraint-guided context abstraction (symbolic) with
    ZKP-specific semantic alignment (neural), streamlining the verification task.
    """
    
    def __init__(self, api_key: Optional[str] = None):
        self.semantic_aligner = ZKPSemanticAligner(api_key)
    
    def analyze_contract(self, solidity_code: str) -> Dict:
        """
        Perform complete dual-perspective analysis on a ZKP contract
        
        Returns:
            Dictionary containing:
            - symbolic_candidates: Formal vulnerability candidates
            - semantic_hints: Neural-generated semantic hints  
            - aligned_findings: Integrated results from both perspectives
            - high_confidence_vulnerabilities: Final filtered results
        """
        from constraint_guided_abstraction import ConstraintGuidedAbstraction
        
        # Symbolic Perspective: Constraint-guided context abstraction
        print("Running symbolic analysis...")
        symbolic = ConstraintGuidedAbstraction(solidity_code)
        candidates = symbolic.extract_all_candidates()
        unsafe_candidates = symbolic.verify_candidates()
        
        # Neural Perspective: ZKP-specific semantic alignment
        print("Running neural semantic alignment...")
        semantic_hints = self.semantic_aligner.generate_semantic_hints(solidity_code)
        
        # Dual-Perspective Integration
        print("Aligning symbolic and neural perspectives...")
        all_unsafe = []
        for vuln_class, cands in unsafe_candidates.items():
            all_unsafe.extend(cands)
        
        alignments = self.semantic_aligner.align_with_symbolic_analysis(
            all_unsafe, 
            semantic_hints
        )
        
        # Filter high-confidence vulnerabilities
        high_confidence = [
            (cand, hint) for cand, hint, score in alignments 
            if score > 0.7  # High alignment threshold
        ]
        
        return {
            'symbolic_candidates': candidates,
            'unsafe_candidates': unsafe_candidates,
            'semantic_hints': semantic_hints,
            'aligned_findings': alignments,
            'high_confidence_vulnerabilities': high_confidence,
            'statistics': {
                'total_candidates': len(candidates),
                'unsafe_candidates': len(all_unsafe),
                'semantic_hints': len(semantic_hints),
                'high_confidence': len(high_confidence)
            }
        }


def main():
    """
    Example usage of dual-perspective integration
    """
    example_zkp_contract = """
    pragma solidity ^0.8.0;
    
    contract ZKPExample {
        mapping(address => bytes32) public commitments;
        mapping(address => uint256) public balances;
        
        function verifyAndWithdraw(
            uint256 amount,
            bytes32 proof,
            bytes32 commitment
        ) public {
            // ZKP constraint: Verify proof matches commitment
            require(verify(proof, commitment), "Invalid proof");
            
            // Range constraint: Amount must be within valid range
            require(amount > 0 && amount <= 1000000, "Invalid amount");
            
            // State change after external verification
            require(balances[msg.sender] >= amount, "Insufficient balance");
            
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");
            
            balances[msg.sender] -= amount;
        }
        
        function verify(bytes32 proof, bytes32 commitment) internal pure returns (bool) {
            // Simplified proof verification (actual ZKP verification would be more complex)
            return keccak256(abi.encodePacked(proof)) == commitment;
        }
    }
    """
    
    # Initialize dual-perspective integration
    integration = DualPerspectiveIntegration()
    
    # Analyze contract
    print("Analyzing ZKP contract with dual-perspective integration...\n")
    results = integration.analyze_contract(example_zkp_contract)
    
    # Display results
    print("="*70)
    print("ANALYSIS RESULTS")
    print("="*70)
    
    print(f"\nStatistics:")
    for key, value in results['statistics'].items():
        print(f"  {key}: {value}")
    
    print(f"\n{'='*70}")
    print("SEMANTIC HINTS (Neural Perspective)")
    print('='*70)
    for hint in results['semantic_hints']:
        print(f"\nConstraint: {hint.constraint}")
        print(f"Security Invariant: {hint.security_invariant}")
        print(f"Guidance: {hint.guidance}")
        print(f"Confidence: {hint.confidence:.2f}")
    
    print(f"\n{'='*70}")
    print("HIGH-CONFIDENCE VULNERABILITIES (Dual Perspective)")
    print('='*70)
    for cand, hint in results['high_confidence_vulnerabilities']:
        print(f"\nVulnerability: {cand.vuln_class.value}")
        print(f"Location: {cand.s} → {cand.t}")
        print(f"Safety Predicate: {cand.Phi}")
        print(f"Semantic Guidance: {hint.guidance}")


if __name__ == "__main__":
    main()
