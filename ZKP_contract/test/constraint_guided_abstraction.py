"""
Constraint-Guided Context Abstraction (Symbolic Perspective)

This module implements the symbolic perspective of the dual-perspective integration,
defining vulnerability candidates as 4-tuples and applying formal safety predicates.
"""

import os
import re
from typing import List, Dict, Set, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class VulnerabilityClass(Enum):
    """Seven representative vulnerability classes based on formal specifications"""
    INTEGER_OVERFLOW = "SWC-101"
    UNPROTECTED_WITHDRAWAL = "SWC-105"
    REENTRANCY = "SWC-107"
    ASSERT_VIOLATION = "SWC-110"
    SIGNATURE_REPLAY = "SWC-121"
    ARBITRARY_WRITE = "SWC-124"
    DOS_GAS_LIMIT = "SWC-128"


@dataclass
class VulnerabilityCandidate:
    """
    Vulnerability candidate modeled as 4-tuple: c = ⟨s, t, P, Φ⟩
    
    Attributes:
        s: Sensitive source (entry point)
        t: State-changing sink (impact point)
        P: Syntactic execution segment (s ⇝ t)
        Phi: Safety predicate (semantic invariants from SWC standards)
    """
    s: str  # Source location (line number or identifier)
    t: str  # Sink location
    P: List[str]  # Execution path from s to t
    Phi: str  # Safety predicate expression
    vuln_class: VulnerabilityClass
    
    def __repr__(self):
        return f"⟨{self.s}, {self.t}, P[{len(self.P)}], Φ: {self.Phi}⟩"


class SafetyPredicates:
    """
    Formal safety predicates for seven representative vulnerability classes
    Based on Table 1 in the paper
    """
    
    @staticmethod
    def integer_overflow(path: List[str]) -> Tuple[bool, str]:
        """
        Integer Overflow: ∀op ∈ P, isSafe(op)
        Source: Arithmetic Operation → Sink: State Variable
        """
        predicate = "∀op ∈ P, isSafe(op)"
        
        # Check for unchecked arithmetic operations
        unsafe_ops = []
        for line in path:
            # Match arithmetic operations: +, -, *, /
            if re.search(r'[+\-*/]\s*=|=\s*.*[+\-*/]', line):
                # Check if it's not in a SafeMath or checked block
                if not re.search(r'SafeMath|checked\s*\{', line):
                    unsafe_ops.append(line)
        
        is_safe = len(unsafe_ops) == 0
        return is_safe, predicate
    
    @staticmethod
    def unprotected_withdrawal(source: str, path: List[str]) -> Tuple[bool, str]:
        """
        Unprotected Withdrawal: isAuth(msg.sender)
        Source: Function Entry → Sink: Asset Transfer
        """
        predicate = "isAuth(msg.sender)"
        
        # Check for authorization before transfer
        has_auth_check = False
        for line in path:
            if re.search(r'require\s*\(.*msg\.sender|onlyOwner|modifier\s+\w+Auth', line):
                has_auth_check = True
                break
        
        is_safe = has_auth_check
        return is_safe, predicate
    
    @staticmethod
    def reentrancy(path: List[str]) -> Tuple[bool, str]:
        """
        Reentrancy: order(t, s) ⟹ t ≺ s
        Source: External Call → Sink: State Update
        Pattern: State update must precede external call
        """
        predicate = "order(t, s) ⟹ t ≺ s"
        
        # Find positions of external call and state update
        external_call_idx = -1
        state_update_idx = -1
        
        for idx, line in enumerate(path):
            if re.search(r'\.call\(|\.transfer\(|\.send\(|\.delegatecall\(', line):
                if external_call_idx == -1:
                    external_call_idx = idx
            if re.search(r'\w+\s*=\s*[^=]|balance\[|mapping\[', line):
                state_update_idx = idx
        
        # Safe if state update comes before external call
        is_safe = (external_call_idx == -1 or state_update_idx == -1 or 
                   state_update_idx < external_call_idx)
        return is_safe, predicate
    
    @staticmethod
    def assert_violation(path: List[str]) -> Tuple[bool, str]:
        """
        Assert Violation: P ∩ Inv_unsafe = ∅
        Source: External Input → Sink: Assert/Panic
        """
        predicate = "P ∩ Inv_unsafe = ∅"
        
        # Check if execution path can reach unsafe invariants
        unsafe_patterns = [
            r'assert\s*\(\s*false',
            r'require\s*\(\s*false',
            r'unchecked\s*\{.*assert',
        ]
        
        has_unsafe = False
        for line in path:
            for pattern in unsafe_patterns:
                if re.search(pattern, line):
                    has_unsafe = True
                    break
        
        is_safe = not has_unsafe
        return is_safe, predicate
    
    @staticmethod
    def signature_replay(path: List[str]) -> Tuple[bool, str]:
        """
        Signature Replay: isFresh(sig) ∧ isRevocable
        Source: Crypto Primitive → Sink: Nonce/Balance
        """
        predicate = "isFresh(sig) ∧ isRevocable"
        
        # Check for nonce usage and signature freshness
        has_nonce_check = False
        has_revocation = False
        
        for line in path:
            if re.search(r'nonce\[|nonces\[|_nonce', line):
                has_nonce_check = True
            if re.search(r'revoke|invalidate|blacklist', line):
                has_revocation = True
        
        is_safe = has_nonce_check and has_revocation
        return is_safe, predicate
    
    @staticmethod
    def arbitrary_write(source: str, path: List[str]) -> Tuple[bool, str]:
        """
        Arbitrary Write: isAuth(msg.sender) ∧ isSafe(idx)
        Source: User Input → Sink: Storage Slot
        """
        predicate = "isAuth(msg.sender) ∧ isSafe(idx)"
        
        # Check for authorization and index validation
        has_auth = False
        has_validation = False
        
        for line in path:
            if re.search(r'require\s*\(.*msg\.sender|onlyOwner', line):
                has_auth = True
            if re.search(r'require\s*\(.*<|require\s*\(.*>|bounds check', line):
                has_validation = True
        
        is_safe = has_auth and has_validation
        return is_safe, predicate
    
    @staticmethod
    def dos_gas_limit(path: List[str]) -> Tuple[bool, str]:
        """
        DoS (Gas Limit): gasCost(P) < Limit_block
        Source: Iteration/Loop → Sink: State Change
        """
        predicate = "gasCost(P) < Limit_block"
        
        # Check for unbounded loops
        has_unbounded_loop = False
        
        for line in path:
            # Match loops without clear bounds
            if re.search(r'while\s*\(.*\)|for\s*\(.*\.length\)', line):
                # Check if there's a gas limit or iteration cap
                if not re.search(r'gasleft\(\)|gas\s*<|MAX_ITERATIONS', line):
                    has_unbounded_loop = True
        
        is_safe = not has_unbounded_loop
        return is_safe, predicate


class ConstraintGuidedAbstraction:
    """
    Main class for constraint-guided context abstraction
    Extracts vulnerability candidates C = {c1, c2, ..., cn}
    """
    
    def __init__(self, solidity_code: str):
        self.code = solidity_code
        self.lines = solidity_code.split('\n')
        self.candidates: List[VulnerabilityCandidate] = []
    
    def identify_sources_and_sinks(self, vuln_class: VulnerabilityClass) -> List[Tuple[int, int]]:
        """
        Identify potential (source, sink) pairs for a given vulnerability class
        Returns list of (source_line, sink_line) tuples
        """
        pairs = []
        
        if vuln_class == VulnerabilityClass.INTEGER_OVERFLOW:
            # Source: arithmetic operations, Sink: state variables
            for i, line in enumerate(self.lines):
                if re.search(r'[+\-*/]\s*=', line):
                    pairs.append((i, i))
        
        elif vuln_class == VulnerabilityClass.UNPROTECTED_WITHDRAWAL:
            # Source: function entry, Sink: transfer/send
            func_starts = []
            transfers = []
            for i, line in enumerate(self.lines):
                if re.search(r'function\s+\w+', line):
                    func_starts.append(i)
                if re.search(r'\.transfer\(|\.send\(|\.call\{value:', line):
                    transfers.append(i)
            
            for func in func_starts:
                for transfer in transfers:
                    if transfer > func:
                        pairs.append((func, transfer))
                        break
        
        elif vuln_class == VulnerabilityClass.REENTRANCY:
            # Source: external call, Sink: state update
            ext_calls = []
            state_updates = []
            for i, line in enumerate(self.lines):
                if re.search(r'\.call\(|\.transfer\(|\.delegatecall\(', line):
                    ext_calls.append(i)
                if re.search(r'\w+\s*=\s*[^=]', line) and 'balance' in line.lower():
                    state_updates.append(i)
            
            for call in ext_calls:
                for update in state_updates:
                    if update > call:  # State update after call (vulnerable pattern)
                        pairs.append((call, update))
        
        # Add other vulnerability class mappings...
        
        return pairs
    
    def extract_execution_path(self, source_line: int, sink_line: int) -> List[str]:
        """
        Extract syntactic execution segment P where s ⇝ t
        """
        if source_line > sink_line:
            source_line, sink_line = sink_line, source_line
        
        return [self.lines[i].strip() for i in range(source_line, sink_line + 1) 
                if self.lines[i].strip()]
    
    def build_vulnerability_candidate(
        self, 
        source_line: int, 
        sink_line: int, 
        vuln_class: VulnerabilityClass
    ) -> VulnerabilityCandidate:
        """
        Build a complete vulnerability candidate 4-tuple
        """
        path = self.extract_execution_path(source_line, sink_line)
        
        # Apply appropriate safety predicate
        predicates = SafetyPredicates()
        
        # Call appropriate predicate function with correct arguments
        if vuln_class == VulnerabilityClass.INTEGER_OVERFLOW:
            _, phi = predicates.integer_overflow(path)
        elif vuln_class == VulnerabilityClass.UNPROTECTED_WITHDRAWAL:
            _, phi = predicates.unprotected_withdrawal(f"Line {source_line}", path)
        elif vuln_class == VulnerabilityClass.REENTRANCY:
            _, phi = predicates.reentrancy(path)
        elif vuln_class == VulnerabilityClass.ASSERT_VIOLATION:
            _, phi = predicates.assert_violation(path)
        elif vuln_class == VulnerabilityClass.SIGNATURE_REPLAY:
            _, phi = predicates.signature_replay(path)
        elif vuln_class == VulnerabilityClass.ARBITRARY_WRITE:
            _, phi = predicates.arbitrary_write(f"Line {source_line}", path)
        elif vuln_class == VulnerabilityClass.DOS_GAS_LIMIT:
            _, phi = predicates.dos_gas_limit(path)
        else:
            phi = "No predicate defined"
        
        candidate = VulnerabilityCandidate(
            s=f"Line {source_line}",
            t=f"Line {sink_line}",
            P=path,
            Phi=phi,
            vuln_class=vuln_class
        )
        
        return candidate
    
    def extract_all_candidates(self) -> List[VulnerabilityCandidate]:
        """
        Extract all vulnerability candidates C from the contract
        """
        self.candidates = []
        
        for vuln_class in VulnerabilityClass:
            pairs = self.identify_sources_and_sinks(vuln_class)
            
            for source, sink in pairs:
                candidate = self.build_vulnerability_candidate(source, sink, vuln_class)
                self.candidates.append(candidate)
        
        return self.candidates
    
    def verify_candidates(self) -> Dict[str, List[VulnerabilityCandidate]]:
        """
        Verify candidates against their safety predicates
        Returns dict: {vuln_class: [unsafe_candidates]}
        """
        unsafe_candidates = {}
        
        for candidate in self.candidates:
            predicates = SafetyPredicates()
            vuln_class = candidate.vuln_class
            
            # Call appropriate verification function with correct arguments
            is_safe = True
            if vuln_class == VulnerabilityClass.INTEGER_OVERFLOW:
                is_safe, _ = predicates.integer_overflow(candidate.P)
            elif vuln_class == VulnerabilityClass.UNPROTECTED_WITHDRAWAL:
                is_safe, _ = predicates.unprotected_withdrawal(candidate.s, candidate.P)
            elif vuln_class == VulnerabilityClass.REENTRANCY:
                is_safe, _ = predicates.reentrancy(candidate.P)
            elif vuln_class == VulnerabilityClass.ASSERT_VIOLATION:
                is_safe, _ = predicates.assert_violation(candidate.P)
            elif vuln_class == VulnerabilityClass.SIGNATURE_REPLAY:
                is_safe, _ = predicates.signature_replay(candidate.P)
            elif vuln_class == VulnerabilityClass.ARBITRARY_WRITE:
                is_safe, _ = predicates.arbitrary_write(candidate.s, candidate.P)
            elif vuln_class == VulnerabilityClass.DOS_GAS_LIMIT:
                is_safe, _ = predicates.dos_gas_limit(candidate.P)
            
            if vuln_class in [
                VulnerabilityClass.INTEGER_OVERFLOW,
                VulnerabilityClass.UNPROTECTED_WITHDRAWAL,
                VulnerabilityClass.REENTRANCY,
                VulnerabilityClass.ASSERT_VIOLATION,
                VulnerabilityClass.SIGNATURE_REPLAY,
                VulnerabilityClass.ARBITRARY_WRITE,
                VulnerabilityClass.DOS_GAS_LIMIT
            ]:
                if not is_safe:
                    class_name = vuln_class.value
                    if class_name not in unsafe_candidates:
                        unsafe_candidates[class_name] = []
                    unsafe_candidates[class_name].append(candidate)
        
        return unsafe_candidates


def main():
    """
    Example usage of constraint-guided context abstraction
    """
    # Example Solidity code
    example_code = """
    pragma solidity ^0.8.0;
    
    contract Example {
        mapping(address => uint256) public balances;
        
        function withdraw(uint256 amount) public {
            require(balances[msg.sender] >= amount);
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success);
            balances[msg.sender] -= amount;  // Vulnerable: state update after external call
        }
    }
    """
    
    # Initialize abstraction
    abstraction = ConstraintGuidedAbstraction(example_code)
    
    # Extract all candidates
    candidates = abstraction.extract_all_candidates()
    print(f"Extracted {len(candidates)} vulnerability candidates")
    
    # Verify against safety predicates
    unsafe = abstraction.verify_candidates()
    
    for vuln_class, candidates in unsafe.items():
        print(f"\n{vuln_class}: {len(candidates)} unsafe candidates")
        for c in candidates:
            print(f"  {c}")


if __name__ == "__main__":
    main()
