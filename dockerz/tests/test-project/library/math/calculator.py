#!/usr/bin/env python3
"""
Simple calculator module for testing edge cases
"""

def add(a, b):
    return a + b

def subtract(a, b):
    return a - b

def multiply(a, b):
    return a * b

def divide(a, b):
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b

class Calculator:
    def __init__(self):
        self.history = []
    
    def calculate(self, operation, a, b):
        result = operation(a, b)
        self.history.append(f"{a} -> {b} = {result}")
        return result
# Output test change
