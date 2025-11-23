import math

def factorial(n):
    if n < 0:
        raise ValueError("Factorial not defined for negative numbers")
    return math.factorial(n)

def fibonacci(n):
    if n < 0:
        raise ValueError("Fibonacci not defined for negative numbers")
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
