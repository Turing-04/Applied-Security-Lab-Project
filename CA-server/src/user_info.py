from typing import Dict

UserInfo = Dict[str, str]
"""
e.g. {"uid": "lb", "lastname": "Bruegger", "firstname": "Lukas", 
     "email": "lb@imovies.ch"}
"""

def validate_user_info(user_info: UserInfo):
    for key, val in user_info.items():
        assert key in ["uid", "lastname", "firstname", "email"]
        assert isinstance(val, str)