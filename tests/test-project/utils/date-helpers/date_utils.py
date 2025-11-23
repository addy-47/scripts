from datetime import datetime, timedelta

def format_date(date_obj, format_str="%Y-%m-%d"):
    """Format date object to string"""
    return date_obj.strftime(format_str)

def add_days(date_obj, days):
    """Add days to a date"""
    return date_obj + timedelta(days=days)

def get_weekday(date_obj):
    """Get weekday name"""
    return date_obj.strftime("%A")

def is_weekend(date_obj):
    """Check if date is weekend"""
    return date_obj.weekday() >= 5
