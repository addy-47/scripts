#!/usr/bin/env python3
"""
String processing utilities for testing edge cases
"""

def clean_whitespace(text):
    """Remove extra whitespace from string"""
    return ' '.join(text.split())

def to_title_case(text):
    """Convert to title case"""
    return text.title()

def reverse_string(text):
    """Reverse a string"""
    return text[::-1]

def count_words(text):
    """Count words in text"""
    return len(text.split())
